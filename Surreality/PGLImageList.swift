//
//  PGLImageList.swift
//  Glance
//
//  Created by Will on 1/27/19.
//  Copyright © 2019 Will. All rights reserved.
//

import Foundation
import UIKit
import Photos
import CoreImage
import Accelerate

enum NextElement {
    case even
    case odd
    case each
}

class PGLImageList {
    // array of CIImage with current position
    // increment will move forward and on the end reverse in opposite direction
    // holds the source of each image in the photoLibrary

    var imageAssets = [PGLAsset]() {
        didSet {
            // objects are assets, they are the metadata from the photolibrary.. not the image
            assetIDs = [String]()
            for anAsset in imageAssets {
                assetIDs.append(anAsset.localIdentifier)
            }
        }
    }
    var inputStack: PGLFilterStack? // remove this var? imageParms will have an inputStack.. not the imageList
    var firstImage: CIImage? // caches the first image as the most common case

    var position = 0
    let options: PHImageRequestOptions
    var targetSize: CGSize { get {
        return TargetSize
        }
    }

    // storable var
    var assetIDs = [String]()
    var collectionTitle = String()  // imageAssets may have multiple albums
    var nextType = NextElement.each // normally increments each image in sequence

//    var isAssetList = true // hold PGLAssets.. or holds CIImages
    var isAssetList: Bool {
        get{
            return images.isEmpty && !imageAssets.isEmpty
        }
    }
    private var images = [CIImage]()
    let doResize = true  // working on scaling... boolean switch here
    var userSelection: PGLUserAssetSelection?

    // MARK: Init
    init(){

        options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true
    }


    convenience init(localAssetIDs: [String],albumIds: [String]) {
        // this init assumes two matching arrays of same size localId and albumid
        if (localAssetIDs.count != albumIds.count) {
            fatalError("PGLImageList init fails on localAssetIDs.count != albumIds.count")
        }
        self.init()
        assetIDs = localAssetIDs
        if !assetIDs.isEmpty {
            imageAssets = getAssets(localIds: localAssetIDs, albums: albumIds )

        }

    }

    convenience init(localPGLAssets: [PGLAsset]) {
        self.init()
        imageAssets = localPGLAssets
        assetIDs = imageAssets.map({ $0.localIdentifier})


    }

    func setUserSelection(toAttribute: PGLFilterAttribute  ){
        // create a PGLUserSelection object from
        // the imageAssets
//        var newbie: PGLUserAssetSelection

        if let firstAsset = imageAssets.first {
            let thisAlbumSource = firstAsset.asPGLAlbumSource()
            let newbie = PGLUserAssetSelection(assetSources: thisAlbumSource)


           for nextAsset in imageAssets.suffix(from: 1) {
               newbie.append(nextAsset)
            }
            userSelection = newbie
        }
    }

// MARK: State
    func hasImageStack() -> Bool {
        // will return image from the stack instead of the objects
        return inputStack != nil
    }

    func isSingular() -> Bool {
        // answer true if only one element in the objects
            return sizeCount()  == 1
    }

    func sizeCount() -> Int {
          if isAssetList {
              return imageAssets.count
          }
          else {
              return images.count
          }
      }

      func isEmpty() -> Bool {
           return (imageAssets.isEmpty) && (images.isEmpty)
      }

    // MARK: Clone
    func cloneEven(toParm: PGLFilterAttribute) -> PGLImageList {
        // answer copy of self set to increment only even images
        // sets self to increment only odd
        NSLog("PGLImageList #cloneEven toParm = \(toParm)")
        let newList = PGLImageList(localPGLAssets: imageAssets)
        newList.nextType = NextElement.odd
//        newList.collectionTitle = "Odd-" + self.collectionTitle  // O for Odd
        newList.position = 1
        newList.images = self.images
//        newList.isAssetList = self.isAssetList

        self.nextType = NextElement.even
        self.position = 0 // zero is even number
//        self.collectionTitle = "Even-" + self.collectionTitle  // E for Even

        let oddUserSelection = self.userSelection?.cloneOdd(toParm: toParm)
       
        newList.userSelection = oddUserSelection
        return newList
    }

    // MARK:  Accessors
    func getAssets(localIds: [String]) -> [PGLAsset] {
        // in this case we do not have the album of the asset
        // OBSOLETE - remove
        let idFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: nil)
        let resultIndexSet = IndexSet.init(integersIn: (0..<idFetchResult.count))
        let assetItems = idFetchResult.objects(at: resultIndexSet)
        //return assetItems as! [PGLAsset]
        var pglAssetItems = [PGLAsset]()
        for anItem in assetItems {
            
            pglAssetItems.append(PGLAsset(anItem, collectionId: nil, collectionLocalTitle: nil)) // no albums !! Fix this?
        }
        return pglAssetItems
    }

    func getAssets(localIds: [String],albums: [String]) -> [PGLAsset] {
        // in this case we do  have the album of the asset
       // this assumes two matching arrays of same size localId and albums



        let idFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIDs, options: nil)
        let resultIndexSet = IndexSet.init(integersIn: (0..<idFetchResult.count))
        let assetItems = idFetchResult.objects(at: resultIndexSet)
        //return assetItems as! [PGLAsset]
        var pglAssetItems = [PGLAsset]()
        for (index,anItem) in assetItems.enumerated() {

            pglAssetItems.append(PGLAsset(anItem, collectionId: albums[index] , collectionLocalTitle: nil))
                // PGLAsset will read collectionTitle 
        }
        return pglAssetItems
    }

    func sourceImageAlbums() -> [String]? {
        var albumIds = [String]()
        let sourceMap = imageAssets.map { ($0.albumId ) }
            // may have nil values
        for element in sourceMap {
                albumIds.append(element)
        }

        if albumIds.isEmpty { return nil} else
        {return albumIds }

    }

    func sourceAssetCollection() -> PHAssetCollection? {
        return userSelection?.sections.first?.value.sectionSource
    }



    func image(atIndex: Int) -> CIImage? {
           var answerImage: CIImage?


           if isAssetList {
               answerImage = imageFrom(selectedAsset: imageAssets[atIndex]) ?? CIImage.empty()
           }
           else { // has images
               answerImage = images[atIndex]
           }
           if doResize {
               answerImage = self.scaleToFrame(ciImage: answerImage!, newSize: self.targetSize) }

          return answerImage
       }

    func currentDisparityMap(target: PGLFilterAttributeImage)  {
         let targetAsset = imageAssets[position]
        if targetAsset.hasDepthData {
            NSLog("PGLImageList #currentDisparityMap hasDepthData target")
            let answerImage = image(atIndex: position)
            target.requestDisparityMap(asset: targetAsset.asset, image: answerImage!)
        }

    }

    fileprivate func imageFrom(selectedAsset: PGLAsset) ->CIImage? {
           // READS the CIImage

           var pickedCIImage: CIImage?
           PHImageManager.default().requestImage(for: selectedAsset.asset, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
               guard let theImage = image else { return  }
//            let auxDataType = kCGImageAuxiliaryDataTypeDisparity
//            let auxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(theImage as! CGImageSource, 0, auxDataType)
                selectedAsset.hasDepthData = true //  get this set later.. (auxDataInfo != nil)
               if let convertedImage = CoreImage.CIImage(image: theImage ) {
                let theOrientation = CGImagePropertyOrientation(theImage.imageOrientation)


                pickedCIImage = convertedImage.oriented(theOrientation)

               }
           })
           return pickedCIImage
       }




    func normalize3(scaledCIDisparity: CIImage?) -> CIImage? {
        // based upon option 3 answer in
        // https://stackoverflow.com/questions/55433107/how-to-normalize-pixel-values-of-an-uiimage-in-swift/55434232#55434232
        // uses Accelerate func vImageContrastStretch_ARGB8888

        if scaledCIDisparity == nil {
            return scaledCIDisparity
        }
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let cgImage = PGLOffScreenRender().renderCGImage(source: scaledCIDisparity!) else { return nil }

        var format = vImage_CGImageFormat(bitsPerComponent: UInt32(cgImage.bitsPerComponent),
                                          bitsPerPixel: UInt32(cgImage.bitsPerPixel),
                                          colorSpace: Unmanaged.passRetained(colorSpace),
                                          bitmapInfo: cgImage.bitmapInfo,
                                          version: 0,
                                          decode: nil,
                                          renderingIntent: cgImage.renderingIntent)

        var source = vImage_Buffer()
        var result = vImageBuffer_InitWithCGImage(
            &source,
            &format,
            nil,
            cgImage,
            vImage_Flags(kvImageNoFlags))

      

        guard result == kvImageNoError else { return nil }

        defer { free(source.data) }

        var destination = vImage_Buffer()
        result = vImageBuffer_Init(
            &destination,
            vImagePixelCount(cgImage.height),
            vImagePixelCount(cgImage.width),
            32,
            vImage_Flags(kvImageNoFlags))

        guard result == kvImageNoError else { return nil }

        result = vImageContrastStretch_ARGB8888(&source, &destination, vImage_Flags(kvImageNoFlags))
        guard result == kvImageNoError else { return nil }

        defer { free(destination.data) }

        let scaledCGImage =  vImageCreateCGImageFromBuffer(&destination, &format, nil, nil, vImage_Flags(kvImageNoFlags), nil)

//        guard let thisCGoutput = scaledCGImage as? CGImage else { return CIImage.empty() }
        let returnImage = scaledCGImage?.takeRetainedValue() //Gets the value of this unmanaged reference as a managed reference and consumes an unbalanced retain of it.
        return CIImage(cgImage: returnImage! )

    }

        func firstImageIndex() -> Int {
            switch nextType {
            case NextElement.each, NextElement.even:
                return 0
            case NextElement.odd:
                if sizeCount()  == 1 {
                    return 0  // only one element have use the zero element
                }
                else { return 1 }
            }
        }
        func first() -> CIImage? {
            if isEmpty() {
                return CIImage.empty() }
            if hasImageStack() { return inputStack?.stackOutputImage(false)}  // needs scaleToFrame??
            if firstImage == nil
            {   let firstIndexValue = firstImageIndex()
                firstImage =  image(atIndex: firstIndexValue)
    //            NSLog("PGLImageList first() collectionTitle = \(collectionTitle) at \(firstIndexValue)")
            }
            return firstImage
        }

       fileprivate func scaleToFrame(ciImage: CIImage, newSize: CGSize) -> CIImage {
           // make all the images scale to the same size and origin
           let xTransform:CGFloat = 0.0 - ciImage.extent.origin.x
           let yTransform:CGFloat = 0.0  - ciImage.extent.origin.y
           //move to zero
           let translateToZeroOrigin = CGAffineTransform.init(translationX: xTransform, y: yTransform)

           let sourceExtent = ciImage.extent
           let xScale = newSize.width / sourceExtent.width
           let yScale =  newSize.height / sourceExtent.height
           let scaleTransform = CGAffineTransform.init(scaleX: xScale, y: yScale)

           return ciImage.transformed(by: translateToZeroOrigin.concatenating(scaleTransform))
       }


    // MARK: Updates
    func append(newImage: PGLAsset) {
        imageAssets.append(newImage)
        assetIDs.append(newImage.localIdentifier)
    }


    func increment() -> CIImage? {
        if hasImageStack() { return inputStack?.stackOutputImage(false)} // needs scaleToFrame??
        if isEmpty() {return nil } // guard
        if sizeCount()  == 1 { return first() } // guard - nothing to increment

//      NSLog("PGLImageList nextType = \(nextType) #increment start position = \(position)")
        let answerImage =  image(atIndex: position)

        // at zero assumes first object already shown
        if nextType == NextElement.each {
            position = position + 1 }
        else { position = position + 2 } // skip by 2 }

        if position >= sizeCount()  {
            // start over
//            imageAssets.reverse()
//            images.reverse() // in opposite direction
            switch nextType {
            case  NextElement.odd :
                position = 1 // skips the old end
            case NextElement.even, NextElement.each  :
                position = 0  // avoid sizeCount()  = 2 issue
            }
        }

//         NSLog("PGLImageList nextType = \(nextType) #increment end position = \(position)")
        return answerImage
    }

     // may hold objects or images
        func setImages(ciImageArray: [CIImage]) {
    //        NSLog("PGLImageList setImages( ciImageArray = \(ciImageArray)")
            images = ciImageArray
    //        isAssetList = false

        }


}
