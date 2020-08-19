//
//  PGLFilterStack.swift
//  PictureGlance
//
//  Created by Will on 3/18/17.
//  Copyright © 2017 Will. All rights reserved.
//

import Foundation
import CoreImage
import UIKit
import Photos
import PhotosUI

// let defaultFilterName = "DistortionDemo"
// let defaultFilterName = "CIDepthOfField"
//let defaultFilterName = "CISourceInCompositing"
// let defaultFilterName = "CILinearGradient"
//let defaultFilterName = "CIAdditionCompositing"
//let defaultFilterName = "CIDissolveTransition"
 let defaultFilterName = kPImages


//let defaultFilterPosition = PGLFilterCategoryIndex(category: 6, filter: 0, catCodeName: "CICategoryCompositeOperations", filtCodeName: defaultFilterName)
//let defaultFilterPosition = PGLFilterCategoryIndex(category: 10, filter: 4, catCodeName: "CICategoryTransition", filtCodeName: defaultFilterName)
let defaultFilterPosition = PGLFilterCategoryIndex(category: 11, filter: 13, catCodeName: "CICategoryTransition", filtCodeName: defaultFilterName)



class PGLFilterStack  {
    // when the filter is changed - keep the old one until the new filter is applied
    // remove the apply logic.. do not keep the old one until applied.. one less button
    
   
    let  kFilterSettingsKey = "FilterSettings"
    let  kFilterOrderKey = "FilterOrder"

    var activeFilters = [PGLSourceFilter]()  // make private?
   
    var cropRect: CGRect { get
    {   return CGRect(x: 0, y: 0, width: TargetSize.width, height: TargetSize.height)

        }
    }

    var activeFilterIndex = 0


    var stackName:String = "S1"  // Date().description(with: Locale.current)
    var parentAttribute: PGLFilterAttribute?

    var parentStack: PGLFilterStack?
    lazy var imageCIContext: CIContext = {return Renderer.ciContext}()

    var frameValueDeltas = PGLFilterChange()
    var storedStack: CDFilterStack? // managedObject write/read to Core Data
    var thumbnail: UIImage? //  for Core Data store

    var stackType = "type"
    var exportAlbumName: String?
    var exportAlbumIdentifier: String?



@IBInspectable  var useOldImageFeedback = false // set to true to use the old image input

    // MARK: Init default
    init(){

//        setStartupDefault()

    }
    // let defaultImageName = "shoreline"
    // let defaultImageName = "GridImage"

    func setStartupDefault() {
//        setDefault(initialImage: PGLTestImage.gridImage(withSize: CGSize(width: 791.5, height: 834.0)) ) //(0.0, 0.0, 791.5, 834.0)
//        let startingImage = (CIImage(image: (UIImage(named: "John+Ann" ))!))!
//        let johnAnnId = "ABB0A167-F79A-4916-9172-8ADC8377EF0E/L0/001"
            // get more ids by a break at PGLFilterAttribute setImageCollectionInput(cycleStack: PGLImageList)
            // in the futureit would be good to select the users favorites..
            // have an option to also pull a saved collection from the data store.. need to keep the name in some app attributes.
        let startImageList = PGLImageList(localAssetIDs: [String](), albumIds: [String]()  )
        let startingFilter = (PGLFilterDescriptor(defaultFilterName, PGLTransitionFilter.self))!


        setDefault(initialList: startImageList   , filterDescriptor: startingFilter ) // with nil parms uses defaults in setDefault declaration

    }

    func setDefault(initialList: PGLImageList,
                    filterDescriptor: PGLFilterDescriptor ) {

        if let filter = filterDescriptor.pglSourceFilter() {
            let inputAttribute = filter.attribute(nameKey: kCIInputImageKey )
            inputAttribute?.setImageCollectionInput(cycleStack: initialList)

            filter.uiPosition = defaultFilterPosition
//            filter.setCIContext(detectorContext: imageCIContext)  // imageCIContext is set by the MetalController viewDidLoad
            appendFilter(filter)
//            NSLog("PGLFilterStack #setDefault image color space = \(String(describing: initialImage.colorSpace))")
        } else
        { NSLog("PGLFilterStack FAILED setDefault")}

    }


    // MARK: Filter access/move
    func hasAnimationFilter() -> Bool {
      return  activeFilters.contains { (aFilter: PGLSourceFilter) -> Bool in
            aFilter.hasAnimation
        }
    }
    func filterAt(tabIndex: Int) -> PGLSourceFilter {
        if( ( activeFilterIndex >= 0 )
            //            && (0 <= tabIndex )
            //            && (tabIndex < activeFilters.count)
            // two different errors don't tackle both in same method
            // activeFilterIndex = - 1 is first filter was removed
            // so start over with default
            )
        { return activeFilters[tabIndex]
        } else {
            //            setDefault()
            return activeFilters[0]
        }
    }
    func moveActiveAhead() {
        //advance activeFilterIndex
        activeFilterIndex = min(activeFilterIndex + 1, activeFilters.count - 1) // zero based array
        // don't advance past the last one
    }

    func moveActiveBack() {
        //advance activeFilterIndex
        activeFilterIndex = max(activeFilterIndex - 1, 0)
        // don't advance past the last one
    }

    func stackNextFilter() {
        if (activeFilterIndex == activeFilters.count - 1) {
           addFilterAfter()

        } else {
            moveActiveAhead()
        }
    }

    func firstFilterIsActive() -> Bool {
        return activeFilterIndex == 0
    }

    func lastFilterIsActive() -> Bool {
        return activeFilterIndex == (activeFilters.count - 1)
    }

    // MARK: Add/Remove filters

    fileprivate func stackFilterName(_ forFilter: PGLSourceFilter, index: Int?) -> (String) {
        // answer filter number , filter name , and arrow point chars
        // "2 Source In ->"
        let positionNumber =  1 + (index ?? activeFilterIndex) // zero based array
        let positionString = "\(positionNumber)"
        let answer = (positionString + " " + forFilter.filterName + "->")
        NSLog("PGLFilterStack #stackFilterName = \(answer)")
        return answer
    }

    func addFilterAfter()  {

        let currentFilter = activeFilters[activeFilterIndex]
        let currentFilterClass = type(of: currentFilter) // create the correct subclass of PGLSourceFilter
        if let newInstance = currentFilterClass.init(filter: currentFilter.filterName, position: currentFilter.uiPosition ) {
            newInstance.setInput(image: currentFilter.inputImage(), source: currentFilter.sourceDescription(attributeKey: kCIInputImageKey))
            // do subclasses of PGLSourceFilter have other vars to set??
        addFilterAfter(newFilter: newInstance)
        }


    }

    func addFilterAfter(newFilter: PGLSourceFilter) {
        // assumes activeFilterIndex is set to the endingPoint
//        moveActiveAhead()
//        moveInputsFrom(activeFilters[activeFilterIndex], newFilter)
        let nextFilterIndex = activeFilterIndex + 1
        if lastFilterIsActive() {
            // appending so output of newFilter does not go to input of next filter
            // and there are no other image parms to also connect
            newFilter.setInput(image: currentFilter().outputImage(), source: stackFilterName(currentFilter(), index: nextFilterIndex) )
              // and set output of newClone to the input of the next activeFilter
            newFilter.setSourceFilter(sourceLocation: (source: self, at: nextFilterIndex), attributeKey: kCIInputImageKey)
            activeFilters.insert(newFilter, at: nextFilterIndex)
            activeFilterIndex = nextFilterIndex
        } else {
             let nextFilter = activeFilters[nextFilterIndex]
             moveInputsFrom(nextFilter, newFilter)
            // now output of the newFilter goes to next filter
            activeFilters.insert(newFilter, at: nextFilterIndex)
            let followingIndex = nextFilterIndex + 1 // now on the following filter

            let  followingFilter = activeFilters[followingIndex]
            followingFilter.setInput(image: newFilter.outputImage(), source: stackFilterName(newFilter, index: nextFilterIndex) )
            followingFilter.setSourceFilter(sourceLocation: (source: self, at: nextFilterIndex ), attributeKey: kCIInputImageKey)
            activeFilterIndex = followingIndex
        }

          updateFilterList()

    }

    func addFilterBefore(newFilter: PGLSourceFilter) {
        // assumes activeFilterIndex is correct
        if firstFilterIsActive() {
            // remove inputs of newFilter
            // set outputs to oldFirstFilter
            let otherKeys = newFilter.imageInputAttributeKeys
            for anImageKey in otherKeys{
                newFilter.setImageValue(newValue: CIImage.empty(), keyName: anImageKey)
                }
            let oldActiveFilter = activeFilters[activeFilterIndex ]
            oldActiveFilter.setInput(image: newFilter.outputImage(), source: stackFilterName(newFilter, index: 0) )
            oldActiveFilter.setSourceFilter(sourceLocation: (source: self, at: 0), attributeKey: kCIInputImageKey)
            activeFilters.insert(newFilter, at: 0)
            activeFilterIndex = 0
        } else {
            // set input of newFilter as the  old inputs of old ActiveFilter
            // set output of newFilter to input of old ActiveFilter

           let oldActiveFilter = activeFilters[activeFilterIndex ]
            moveInputsFrom(oldActiveFilter, newFilter)

            activeFilters.insert(newFilter, at: activeFilterIndex )
                       // pushes old active forward one..
           oldActiveFilter.setInput(image: newFilter.outputImage(), source: stackFilterName(newFilter, index: activeFilterIndex) )
           oldActiveFilter.setSourceFilter(sourceLocation: (source: self, at: activeFilterIndex), attributeKey: kCIInputImageKey)


        }
          updateFilterList()

    }


    


    
    func append(_ newFilter: PGLSourceFilter) {
        // private - assumes inputs are set
        activeFilters.append(newFilter)
        activeFilterIndex = activeFilters.count - 1 // zero based index
        updateFilterList()
    }

    func appendFilter(_ newFilter: PGLSourceFilter) {
        // called from the UI - connect the output to input
//        NSLog("PGLFilterStack -> appendFilter = \(newFilter.filterName)")
        if !activeFilters.isEmpty {
            let currentFilter = activeFilters[activeFilterIndex]
            newFilter.setInput(image: currentFilter.outputImage(),source: stackFilterName(currentFilter, index: activeFilterIndex))

        }
        newFilter.setSourceFilter(sourceLocation: (source: self, at: activeFilterIndex), attributeKey: kCIInputImageKey)
        append(newFilter)
     

    }
   
    
    fileprivate func moveInputsFrom(_ oldFilter: PGLSourceFilter, _ newFilter: PGLSourceFilter) {

       let otherKeys = newFilter.imageInputAttributeKeys
        
        for anImageKey in otherKeys{
            if oldFilter.imageInputAttributeKeys.contains(anImageKey) {
                let inputAttribute = oldFilter.attribute(nameKey: anImageKey)
                if let oldValue = oldFilter.localFilter.value(forKey: anImageKey) as? CIImage
                {newFilter.setImageValue(newValue: oldValue, keyName: anImageKey)
                let newAttribute = newFilter.attribute(nameKey: anImageKey)
                    if let oldInputCollection = inputAttribute?.inputCollection {
                        newAttribute?.inputCollection = oldInputCollection
                        newAttribute?.setTargetAttributeOfUserAssetCollection()
                        // this setting of inputCollection
                        // does NOT setup clones
                        // therefore it does not call
                        // setImageCollectionInput

                    }
                    
                if let oldSource = oldFilter.getSourceFilterLocation(attributeKey: kCIInputImageKey)
                    { newFilter.setSourceFilter(sourceLocation: oldSource, attributeKey: kCIInputImageKey) }
                     let oldSourceDescription = oldFilter.sourceDescription(attributeKey: anImageKey)
                        // sourceDescription is always string - could be "blank" string
                    newFilter.setSource(description: oldSourceDescription, attributeKey: anImageKey)

                }
            }
            
         else
                 { newFilter.setImageValue(newValue: CIImage.empty(), keyName: anImageKey)
                    }
            }
        }
    
    func replaceFilter(at: Int, newFilter: PGLSourceFilter) {
        if at < activeFilters.count  {
            // in range
            let oldFilter = activeFilters[at]
            moveInputsFrom(oldFilter, newFilter)

            activeFilters[at] = newFilter
            updateFilterList()
            // a delete and add of storedFilters
            if newFilter.storedFilter != nil {
                storedStack?.replaceFilters(at: at, with: newFilter.storedFilter!) }

        }
    }

    
    func removeLastFilter() -> PGLSourceFilter? {
        var removedFilter: PGLSourceFilter?
        if !activeFilters.isEmpty {
           if let myLastFilter = activeFilters.last
               { storedStack?.removeFromFilters(myLastFilter.cdFilterObject())
                 removedFilter = activeFilters.removeLast()
                activeFilterIndex = activeFilters.count - 1 // zero based index

                }
//             setStartupDefault()

        }
            return removedFilter //may be nil

    }

     func removeDefaultFilter() -> PGLSourceFilter? {
            var removedFilter: PGLSourceFilter?
            if !activeFilters.isEmpty {
                    removedFilter = activeFilters.removeLast()
                    activeFilterIndex = activeFilters.count - 1 // zero based index
            }
                return removedFilter //may be nil

        }

    func removeAllFilters() {
        if storedStack != nil {
            // then the filters must have storedFilter objects too
            let filterRange = NSRange(location: 0, length: (activeFilters.count - 1))
            let filterIndexSet = NSIndexSet(indexesIn: filterRange )
            storedStack?.removeFromFilters(at: filterIndexSet)
        }
        activeFilters = [PGLSourceFilter]()
        activeFilterIndex = -1 // nothing
        setStartupDefault() // need at least one filter
    }

    func removeFilter(position: Int) -> PGLSourceFilter?{
        // returns removedFilter
        switch activeFilterIndex {
        case -1  :
            // somehow empty stack is removing a filter
            removeAllFilters()
            return nil
        case _ where ( activeFilters.count == 1) :
            // removing only filter in the stack
            removeAllFilters()
            return nil
        case _ where (position >= activeFilters.count - 1) :
            // on last filter
            return removeLastFilter()
        default:
            // all other cases where stack has multiple filters, take out a mid point
            let oldFilter = activeFilters.remove(at: position)
            activeFilterIndex = position
            // now outputs of prior filter go to the new activeOne inputs
            let newFilter = activeFilters[activeFilterIndex]
            moveInputsFrom(oldFilter, newFilter)
            if oldFilter.storedFilter != nil {
                storedStack?.removeFromFilters(oldFilter.storedFilter!)}
            return oldFilter
        }

    }

    func hasMultipleFilters()-> Bool {
        return activeFilters.count > 1
    }

    func queuePosition() -> Stack {
        if !hasMultipleFilters() {
            return Stack.begin
        }
        if (activeFilterIndex == 0) {
            return Stack.begin
        }
        if activeFilterIndex < activeFilters.count - 1 {
            return Stack.middle
        }
        if activeFilterIndex == activeFilters.count - 1 {
            return Stack.end
        }
        return Stack.end // default return
    }
    // MARK: Output


    func outputImage() -> CIImage? {
        // this does not do the chaining of output to input used by stackOutputImage
        if activeFilterIndex >= 0 {
            return activeFilters.last!.outputImage() }
        else {
            return CIImage.empty() }
    }

    func stackOutputImage(_ showCurrentFilterImage: Bool) -> CIImage {
        //assumes that inputImage has been set
        if activeFilterIndex < 0 {
            return CIImage.empty() }

        if useOldImageFeedback {
            // always false - only changes with inspectable var in the debugger
            if let startImage = activeFilters.first?.inputImage() {
                return imageUpdate(startImage, showCurrentFilterImage)
            }
            else {
                return CIImage.empty() }
        } else {
            return imageUpdate(nil, showCurrentFilterImage)  // uses current image already set in the filter
        }
    }

    func scaleToFrame(ciImage: CIImage, newSize: CGSize) -> CIImage {
        // make all the images scale to the same size
//        NSLog("PGLFilterStack scaleToFrame newSize = \(newSize)")
//        NSLog("PGLFilterStack scaleToFrame image = \(ciImage.extent)")
        let sourceExtent = ciImage.extent
        let xScale = newSize.width / sourceExtent.width
        let yScale =  newSize.height / sourceExtent.height
        let scaleTransform = CGAffineTransform.init(scaleX: xScale, y: yScale)
//        NSLog("PGLFilterStack scaleToFrame transform = \(scaleTransform)")
        return ciImage.transformed(by: scaleTransform)
    }

    func imageUpdate(_ inputImage: CIImage?, _ showCurrentFilterImage: Bool) -> CIImage {
        // send the inputImage to the activeFilters

        var thisImage = inputImage
        var filter: PGLSourceFilter
        var imagePosition: Int
//       NSLog("PGLFilterStack #imageUpdate inputImage = \(String(describing: inputImage))")
        if showCurrentFilterImage {
            imagePosition = activeFilterIndex
        } else {
            imagePosition = activeFilters.count - 1 // zero based array
        }

        for index in 0...imagePosition { // only show up to the current filter in the stack
            filter = activeFilters[index]
            if thisImage != nil {

                if thisImage!.extent.isInfinite {
                    // issue CIColorDodgeBlendMode -> CIZoomBlur -> CIToneCurve
                    // -> CIColorInvert -> CIHexagonalPixellate -> CICircleSplashDistortion)
                    // clamp and crop if infinite extent
//                  NSLog("PGLFilterStack imageUpdate thisImage has input of infinite extent")
                    let clampedImage = thisImage?.clampedToExtent()
                    thisImage = clampedImage?.cropped(to: cropRect)
//                    NSLog("PGLFilterStack imageUpdate clamped and cropped to  \(String(describing: thisImage?.extent))")
                }
                filter.setInput(image: thisImage, source: nil)
            }
                // else just use the already set input image

            if let newOutputImage = filter.outputImage() {
                if newOutputImage.extent.isInfinite {
//                    NSLog("PGLFilterStack imageUpdate newOutputImage has input of infinite extent")
                }
                thisImage = filter.scaleOutput(ciOutput: newOutputImage, stackCropRect: cropRect)
                    // most filters do not implement scaleOutput
                    // crop in the PGLRectangleFilter scales the crop to fill the extent

            } else {
               thisImage = inputImage
//                NSLog("PGLAppStack #outputFilterStack() no output image at \(index) from filter = \(filter.filterName)")
                }
        }
        return thisImage ?? CIImage.empty()
      
    }

    func basicFilterOutput() -> CIImage {
        //bypass all the input changes and chaining

        return  currentFilter().outputImage() ??
            CIImage.empty()
    }
    func updateFilterList() {}

    // MARK: flattened Filters

    func addChildFilters(_ level: Int, into: inout Array<PGLFilterIndent>) {
    // make sure to travers the appStack in the same order
    // adds/deletes of filters require the whole flatten array to regenerate.
        var indexCounter = 0
        for aFilter in activeFilters {
//            into.append(PGLFilterIndent(level, aFilter))
            into.append(PGLFilterIndent(level, aFilter, inStack: self,index: indexCounter))
            let nextLevel = level + 1
            aFilter.addChildFilters(nextLevel, into: &into)
            indexCounter += 1
        }

    }

    func stackRowCount() -> Int {
        // number of filters including the filters of child stacks
        var childRowCount = 0
        for aFilter in activeFilters {
            childRowCount += aFilter.stackRowCount()
        }
        return childRowCount
    }

    // MARK: Navigation / numbering


    func currentFilter() -> PGLSourceFilter {
         return filterAt(tabIndex: activeFilterIndex)
    }
    func nextFilter()  -> PGLSourceFilter? {
        // either add new if currently at last or move to next in the stack
        stackNextFilter()  // this changes the filter by adding to the stack
        //        filterUpdate(updatedFilter: currentFilter()!)
        return filterAt(tabIndex: activeFilterIndex)
    }

    func priorFilter() -> PGLSourceFilter? {
        // either move to prior in the stack or just the first if only 1

        moveActiveBack() // this changes the filter by adding to the stack
        //        filterUpdate(updatedFilter: currentFilter()!)
        return filterAt(tabIndex: activeFilterIndex)
    }

    func newFilterTab() {
        // load new tab for another filter
        // should modify the stack and sets the input from the prior stack elements

        addFilterAfter()
    }

 

    func filterNumber() -> Int {
        return  activeFilterIndex + 1
    }

    func currentFilterPosition() -> PGLFilterCategoryIndex {
        let theCurrentFilter = filterAt(tabIndex: activeFilterIndex)
        return theCurrentFilter.uiPosition
    }

    func filterName() -> String {
        if activeFilterIndex < 0 { return ""}
        let theCurrentFilter = filterAt(tabIndex: activeFilterIndex)
        return theCurrentFilter.localizedName()
    }

    func filterNumLabel(maxLen: Int?) -> String {
        var categoryName: String
        // now prefix with category
//        "OLD Prefix A, B, C for filters order indicator.. was numbers "
//            UILocalizedIndexedCollation.
//            let answerStr = String( (Character.init(Unicode.Scalar(filterNumber() + 64)!)) )
                    // 65 is ASCII for capital A
        // shorten some long categories
        // truncate string to 24 chars

        let filterCategory = currentFilter().filterCategories.first ?? ""
        // usually has prefix of "CICategory". remove it
        if filterCategory.hasPrefix("CICategory") {
            categoryName = String(filterCategory.dropFirst(10))
        } else {
            categoryName = filterCategory
        }
        if categoryName.hasPrefix("Composite"){
            categoryName = String(categoryName.dropFirst(9))
        }

        if categoryName.hasSuffix("Effect"){
            categoryName = String(categoryName.dropLast(6))
        }
        

        if categoryName.hasSuffix("Adjustment"){
            categoryName = String(categoryName.dropLast(10))
        }

        let returnString = String(categoryName + " -" + filterName())

        if let localMax = maxLen {
            return String(returnString.prefix(localMax) ) }
        else { return returnString }


    }

    func nextStackName() -> String {
        // this stack name + filterNumberLabel of the current filter
        return "-> " + stackName + " " + filterNumLabel(maxLen: 20)
    }

    func replace(updatedFilter: PGLSourceFilter) {

        updatedFilter.setCIContext(detectorContext: imageCIContext)
        replaceFilter(at: activeFilterIndex, newFilter: updatedFilter)
    }

   
// MARK: Save Image

    func writeCDStacks(){
           // store starting from the top level
           // each stack will write in turn as it is referenced
           // do not need to iterate the collection

           let moContext = PersistentContainer.viewContext

        self.writeCDStack()

       if moContext.hasChanges {
       do { try moContext.save()
           NSLog("PGLAppStack #writeCDStacks save called")
           } catch { fatalError(error.localizedDescription) }
               }

       }

    func saveStackImage() -> Bool {
//        let serialQueue = DispatchQueue(label: "queue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
//        serialQueue.async {
           let photoSaveSuccess = self.saveToPhotosLibrary(stack: self)
               // call first so the albumIdentifier can be stored
           NSLog("saveAction calls writeCDStacks")
            self.writeCDStacks()
            return photoSaveSuccess
//        }
    }

    func saveToPhotosLibrary( stack: PGLFilterStack )   -> Bool {
                      // check if the album exists..) {
               // save the output of this stack to the photos library
                               // Create a new album with the entered title.

               var assetCollection: PHAssetCollection?


              if let existingAlbumId = stack.exportAlbumIdentifier {
                   let fetchResult  = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [existingAlbumId], options: nil)
                   assetCollection = fetchResult.firstObject

              } else {
                   // check for existing albumName
               if let aAlbumExportName = stack.exportAlbumName {
                   // find it or or create it.
                   // leave assetCollection as nil to create

                 // fatalError( "PHAssetCollection needs to search for a matching album title #saveToPhotosLibrary")
                   // how to do this???
                  let albums = getAlbums()
                    let matching = filterAlbums(source: albums, titleString: aAlbumExportName)
                   if matching.count > 0 {
                       assetCollection = matching.last!.assetCollection
                   }


                   }
               }

               return self.saveHEIFToPhotosLibrary(exportCollection: assetCollection, stack: stack)


    }

    func saveHEIFToPhotosLibrary(exportCollection: PHAssetCollection?, stack: PGLFilterStack) -> Bool {
//        if let heifImageData = PGLOffScreenRender().getOffScreenHEIF(filterStack: stack) {
        if let uiImageOutput = PGLOffScreenRender().captureUIImage(filterStack: stack) {

        PHPhotoLibrary.shared().performChanges({
         // heif form   let creationRequest = PHAssetCreationRequest.forAsset()

        //  UIImage from.
           let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: uiImageOutput)
//           heif from  creationRequest.addResource(with: .fullSizePhoto, data: heifImageData, options: nil)

            if exportCollection == nil {
                // new collection
                let assetCollectionRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: stack.exportAlbumName ?? "exportAlbum")


                assetCollectionRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                stack.exportAlbumIdentifier = assetCollectionRequest.placeholderForCreatedAssetCollection.localIdentifier

            } else {
                // asset collection exists
                let addAssetRequest = PHAssetCollectionChangeRequest(for: exportCollection!)
                addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
            }


            }, completionHandler: {success, error in
                  if !success { print("Error creating the asset: \(String(describing: error))") }

              })
            return true
        }
         else { NSLog("getOffScreenHEIF fails in PGLFilterStack #saveHEIFToPhotosLibrary")
                return false
        }
}



    // MARK: photos Output
      func filterAlbums(source: [PGLUUIDAssetCollection], titleString: String?) -> [PGLUUIDAssetCollection] {
             if titleString == nil { return source }
             else { return source.filter { $0.contains(titleString)} }
         }

      func getAlbums() -> [PGLUUIDAssetCollection] {
          // make this generic with types parm?
          var answer = [PGLUUIDAssetCollection]()
          let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular , options: nil)
          for index in 0 ..< (albums.count ) {
                  answer.append( PGLUUIDAssetCollection( albums.object(at: index))!)

          }
          NSLog("PGLImageCollectionMasterController #getAlbums count = \(answer.count)")
          return answer
      }

}

