//
//  PGL-CDFilterStack.swift
//  Glance
//
//  Created by Will on 11/30/18.
//  Copyright © 2018 Will. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import CoreImage
import Photos
import PhotosUI

var PersistentContainer: NSPersistentContainer = {
       /*
        The persistent container for the application. This implementation
        creates and returns a container, having loaded the store for the
        application to it. This property is optional since there are legitimate
        error conditions that could cause the creation of the store to fail.
       */
       let container = NSPersistentContainer(name: "Surreality")
       container.loadPersistentStores(completionHandler: { (storeDescription, error) in
           if let error = error as NSError? {
               // Replace this implementation with code to handle the error appropriately.
               // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

               /*
                Typical reasons for an error here include:
                * The parent directory does not exist, cannot be created, or disallows writing.
                * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                * The device is out of space.
                * The store could not be migrated to the current model version.
                Check the error message to determine what the actual problem was.
                */
               fatalError("Unresolved error \(error), \(error.userInfo)")
           }
       })
       return container
   }()

struct PGLStackType {
   var name: String
}

let StackTypeKey = "StackTypes"
// key for the AppUserDefaults instance of UserDefaults


extension PGLFilterStack {

    convenience init(readName: String) {
        self.init()
        stackName = readName
        let removedFilter = removeDefaultFilter() // remove existing filters from the init()
        NSLog("PGLFilterStack init has removed defaultFilter = \(String(describing: removedFilter))")
        readCDStack(titled: readName)
    }


    func readCDStack(titled: String){


        let moContext = PersistentContainer.viewContext
        let request =  NSFetchRequest<CDFilterStack>(entityName: "CDFilterStack")
        // assume we are reading by title
        request.predicate = NSPredicate(format: "title == %@", titled)
        request.fetchLimit = 1

        var readResults: [CDFilterStack]!
        do {  readResults = try moContext.fetch(request) }
        catch { fatalError("CDFilterStack error")}

//        for aCDStack in readResults {
            // multiple stacks with the same title??? allow?
            // no.. assume only one match..
        if let aCDStack = readResults.first {
            storedStack = aCDStack
            if let thumbNailPGNImage = aCDStack.thumbnail {
                thumbnail = UIImage(data: thumbNailPGNImage) // thumbnail is png format data aCDStack.thumbnail
            }
            //stackName is set in the init(readName:)

           exportAlbumIdentifier = storedStack?.exportAlbumIdentifier
            exportAlbumName = storedStack?.exportAlbumName

            NSLog("PGL-CDFilter readCDStack titled \(titled)" )
            for aCDFilter in aCDStack.filters! {


                if let myCDFilter = aCDFilter as? CDStoredFilter {
                    NSLog("PGL-CDFilter readCDStack filter = \(String(describing: myCDFilter.ciFilterName))" )
                    if let filterBuilder = PGLFilterCategory.getFilterDescriptor(aFilterName: myCDFilter.ciFilterName!, cdFilterClass: myCDFilter.pglSourceFilterClass!)
                    {  if let newSource = filterBuilder.pglSourceFilter()
                        {
                            newSource.localFilter = myCDFilter.ciFilter!
                            newSource.storedFilter = myCDFilter
                            newSource.resetAttributesToLocalFilter() // this could also be a didSet inside of newSource.localFilter
                            // looks like this makes all the created attributes still work !
                            // attributes update to the localFilter...
                            // read the inputCollection - convert the CDImageList to inputCollection on the correct parm

                            newSource.readCDImageList(parentStack: self)
                            // other attributes to update???

                            append(newSource)
                        }
                    else {NSLog("PGL-CDFilter readCDStack FAILS pglSourceFilter  filter = \(String(describing: myCDFilter.ciFilterName))") }

                    } else {NSLog("PGL-CDFilter readCDStack FAILS filterBuilder for filter = \(String(describing: myCDFilter.ciFilterName))") }
            }
        }
        }
    }


    func writeCDStack() -> CDFilterStack {
        NSLog("PGLFilterStack #writeCDStack name = \(stackName)")

        let moContext = PersistentContainer.viewContext

            if (storedStack == nil ) { // new stack needed
                storedStack = NSEntityDescription.insertNewObject(forEntityName: "CDFilterStack", into: moContext) as? CDFilterStack
                storedStack?.created = Date()
            } else { storedStack?.modified = Date()}
            storedStack?.title = stackName
            storedStack?.type = stackType
            storedStack?.exportAlbumName = exportAlbumName
            storedStack?.exportAlbumIdentifier = exportAlbumIdentifier

            storedStack?.thumbnail = stackThumbnail()  // data format of small png image

            for aFilter in activeFilters {

                let theFilterStoredObject = aFilter.cdFilterObject()
                // does not need to add if the filter exists in the relation already
                storedStack?.addToFilters(theFilterStoredObject)
            }
            return storedStack!  // force error if not set
    }

    

    func delete() {
        // delete this stack from the data store

        let moContext = PersistentContainer.viewContext
        if storedStack != nil {
            moContext.delete(storedStack!)
        }

    }
    func stackThumbnail() -> Data? {
        // output image in thumbnail size and png data format


        let outputImage = stackOutputImage(false)
        let uiOutput = UIImage(ciImage: outputImage )
//        return uiOutput.pngData() // big size

//         the code below produces a thumbnail that is too small.
        let magicNum: CGFloat  = 800.0  // 44.0 numerator for ratio to max dimension of the image
       let outputSize = uiOutput.size

        var ratio: CGFloat = 0
        ratio = magicNum / max(outputSize.width, outputSize.height)

        let smallSize = CGSize(width: (ratio * outputSize.width), height: (ratio * outputSize.height))
        let smallRect = CGRect(origin: CGPoint.zero, size: smallSize)

        UIGraphicsBeginImageContext(smallSize)
        uiOutput.draw(in: smallRect)


        let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
      return thumbnail?.pngData()

    }

}
// ================= end extension PGLFilterStack ======================

extension PGLSourceFilter {
    // core data methods
    // MARK: CoreData

    func cdFilterObject() -> CDStoredFilter {
        // create or update to the coreData store


        let moContext = PersistentContainer.viewContext
        if storedFilter == nil {
            NSLog("PGLSourceFilter #cdFilterObject storedFilter insertNewObject \(String(describing: filterName))")
            storedFilter =  NSEntityDescription.insertNewObject(forEntityName: "CDStoredFilter", into: moContext) as? CDStoredFilter
            storedFilter!.ciFilter = self.localFilter
            storedFilter!.ciFilterName = self.filterName
            storedFilter!.pglSourceFilterClass = self.classStringName()

             createCDImageList() // creates for all the input parms
            
        }
        // create the related imageLists of the inputCollection of the image parms


        return storedFilter!
        // moContext save at the stack save
    }



    func getCDParmImage(attribute: PGLFilterAttribute) -> CDParmImage? {
        // 4EntityModel
        // gets or creates the entity for the parm

        let existingParmImages = readCDParmImages()
        if let cdImageParm = existingParmImages.first(where: {$0.parmName == attribute.attributeName} )
             { return cdImageParm }
        else  // create the cdImageParm
        {   if hasStorableRelations(imageAttribute: attribute) {
                let newStoredImageParm =  createNewCDImageParm(attribute: attribute)
                return newStoredImageParm
            } else { return nil }
        }
    }

    func createNewCDImageParm(attribute: PGLFilterAttribute) -> CDParmImage {
        // 4EntityModel

        let moContext = PersistentContainer.viewContext


        guard let newCDImageParm =  NSEntityDescription.insertNewObject(forEntityName: "CDParmImage", into: moContext) as? CDParmImage
            else { fatalError("Failure creating new CDParmImage") }
        newCDImageParm.parmName = attribute.attributeName
        newCDImageParm.filter = storedFilter  // stores the relationship
        newCDImageParm.inputStack = attribute.inputStack?.writeCDStack()  // stores the relationship

        // start 7/6/20 new datamodel relationships
         if attribute.inputStack != nil {
                    // there is an input stack to this parm
            storedFilter?.parentOfStack =  attribute.inputStack!.storedStack
        }
        // end 7/6/20 new datamodel relationships

        // create related CDImageList
        if attribute.inputCollection != nil {
            guard let storedImageList =  NSEntityDescription.insertNewObject(forEntityName: "CDImageList", into: moContext) as? CDImageList
                else { fatalError("Failure creating new CDImageList") }

            if let collectionPGLAssets = attribute.inputCollection?.imageAssets {
                storedImageList.assetIDs = collectionPGLAssets.map({$0.localIdentifier})
                storedImageList.albumIds = collectionPGLAssets.map({$0.albumId})

                }


            storedImageList.attributeName = attribute.attributeName
            newCDImageParm.inputAssets = storedImageList  // stores the relationship
            }
        
        return newCDImageParm
    }

    func getImageList(imageParmName: String) -> CDImageList? {
        // 4EntityModel  but NOT USED  Delete?
        // returns nil if the list was not created/stored
        // the relation returns all ImageLists of the filter
        // return the imageList matching the parm attributeName
        let myCDParmImages = readCDParmImages()
        if let cdImageParm = myCDParmImages.first(where: {$0.parmName == imageParmName} ) {
            return cdImageParm.inputAssets
        } else { return nil }
    }

    func removeOldImageList(imageParmName: String) {
        // 4EntityModel
        let myCDParmImages = readCDParmImages()
        // does not use the getCDParmImage(attribute:) method - that creates CDImageList if none exists..
        // we are deleting here.. don't create one to delete

        if let cdImageParm = myCDParmImages.first(where: {$0.parmName == imageParmName} ) {
            cdImageParm.inputAssets = nil // does this remove the related CDImageList row?
        }
    }

    func readCDImageList(parentStack: PGLFilterStack) {
            // remove - not a 4EntityModel method?
        if let pglImageParms = imageParms() {
            let myCDParmImages = readCDParmImages()

            for pglImageParm in pglImageParms {
                if let cdImageParm = myCDParmImages.first(where: {$0.parmName == pglImageParm.attributeName} ) {
                    // three cases of input  - 1. filter output, 2.  stack output, 3. stored photo image
                    if cdImageParm.filter != self.storedFilter {
                        // another filter output is the input to this parm
                        NSLog("PGLFilterStack readCDImageList case filter not matching")
                    } else {
                    if let aCDImageList = cdImageParm.inputAssets // one to one
                    { let newPGLList = PGLImageList(localAssetIDs: (aCDImageList.assetIDs)!,albumIds: (aCDImageList.albumIds!))
                         newPGLList.setUserSelection(toAttribute: pglImageParm)
                          pglImageParm.setImageCollectionInput(cycleStack: newPGLList)
                        }
                    if let anInputStack = cdImageParm.inputStack // one to one
                    { let newChildStack = PGLFilterStack(readName: anInputStack.title!)
                        newChildStack.parentStack = parentStack
                        newChildStack.parentAttribute = pglImageParm
                        pglImageParm.inputStack = newChildStack

                        }
                    }
                }

            }
        }
    }
    
    func createCDImageList() {
        // 4EntityModel
        // create new CDImageList for every parm
        if let myImageParms = imageParms() {
            for anImageParm in myImageParms {
                getCDParmImage(attribute: anImageParm) // creates where relationship does not exist
            }
        }

    }

    func readCDParmImages() -> [CDParmImage] {
        // 4EntityModel
        // load all the cdParmImages
        if let result = storedFilter?.input?.allObjects as? [CDParmImage] {
            return result
        } else { return [CDParmImage]() }

    }

    // MARK: PGLSourceFilter support

    func hasStorableRelations(imageAttribute: PGLFilterAttribute) -> Bool {
        // answer true if there is an inputCollection or a parent stack to be stored
        // otherwise false - do not create CDParmImage or CDImageList rows
        return (imageAttribute.inputCollection != nil || imageAttribute.inputStack != nil )
    }
    func imageParms() -> [PGLFilterAttribute]? {
         // 4EntityModel
        // all parms that take an image as input

        if imageInputAttributeKeys.isEmpty {return nil }
        var imageAttributes = [PGLFilterAttribute]()

        for imageParmKey in imageInputAttributeKeys {
            if let thisImageAttribute = attribute(nameKey: imageParmKey) {
                imageAttributes.append(thisImageAttribute) }
            else { continue // to next element in the loop }
            }
        }
        return imageAttributes
    }

}  // ================ end extension PGLSourceFilter =========================

extension PGLAppStack {
     func firstStack() -> PGLFilterStack? {
        if pushedStacks.isEmpty {
          return  viewerStack
        } else { return pushedStacks.first}
    }

    func writeCDStacks(){
        // store starting from the top level
        // each stack will write in turn as it is referenced
        // do not need to iterate the collection

        let moContext = PersistentContainer.viewContext

        if let initialStack = firstStack() {
          initialStack.writeCDStack()
        }

    if moContext.hasChanges {
    do { try moContext.save()
        NSLog("PGLAppStack #writeCDStacks save called")
        } catch { fatalError(error.localizedDescription) }
            }

    }

    func saveStack(metalRender: Renderer) {
        let targetStack = firstStack()!
        let serialQueue = DispatchQueue(label: "queue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        serialQueue.async {
           self.saveToPhotosLibrary(stack: targetStack, metalRender: metalRender)
               // call first so the albumIdentifier can be stored
           NSLog("saveAction calls writeCDStacks")
            self.writeCDStacks()
        }
    }

    func saveToPhotosLibrary( stack: PGLFilterStack, metalRender: Renderer ) {
                      // check if the album exists..) {
               // save the output of this stack to the photos library
                               // Create a new album with the entered title.
              
               var assetCollection: PHAssetCollection?

        NSLog("readCDStack saveToPhotosLibrary = \(String(describing: stack.exportAlbumIdentifier))")
              if let existingAlbumId = stack.exportAlbumIdentifier {
                   let fetchResult  = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [existingAlbumId], options: nil)
                   assetCollection = fetchResult.firstObject
                NSLog("PGLImageController #saveToPhotosLibrary append to existing assetCollection \(String(describing: assetCollection))")
              } else {
                   // check for existing albumName
               if let aAlbumExportName = stack.exportAlbumName {
                   // find it or or create it.
                   // leave assetCollection as nil to create

                 // fatalError( "PHAssetCollection needs to search for a matching album title #saveToPhotosLibrary")
                   // how to do this???
                let albums = stack.getAlbums()
                let matching = stack.filterAlbums(source: albums, titleString: aAlbumExportName)
                   if matching.count > 0 {
                       assetCollection = matching.last!.assetCollection
                   }


                   }
               }


               // get the metal context -
               guard let uiImageOutput = metalRender.captureImage()

                   else { fatalError("outputImage fails in #saveToPhotosLibrary")}


               NSLog("PGLFilterStack #saveToPhotosLibrary uiImageOutput = \(uiImageOutput)")
               // Add the asset to the photo library.
                      PHPhotoLibrary.shared().performChanges({
                          let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: uiImageOutput)
                       // either get or create the target album

                       if assetCollection == nil {
                           // new collection
                           let assetCollectionRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: stack.exportAlbumName ?? "exportAlbum")


                           assetCollectionRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                           stack.exportAlbumIdentifier = assetCollectionRequest.placeholderForCreatedAssetCollection.localIdentifier

                       } else {
                           // asset collection exists
                       let addAssetRequest = PHAssetCollectionChangeRequest(for: assetCollection!)
                              addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                       }

                      }, completionHandler: {success, error in
                          if !success { print("Error creating the asset: \(String(describing: error))") }
                      })


           }






}
