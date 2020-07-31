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
        NSLog("PGLFilterStack init has removed defaultFilter = \(removedFilter)")
        readCDStack(titled: readName)
    }


    func readCDStack(titled: String){

        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        let moContext = myAppDelegate.persistentContainer.viewContext
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
                    NSLog("PGL-CDFilter readCDStack filter = \(myCDFilter.ciFilterName)" )
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
                        else {NSLog("PGL-CDFilter readCDStack FAILS pglSourceFilter  filter = \(myCDFilter.ciFilterName)") }

                } else {NSLog("PGL-CDFilter readCDStack FAILS filterBuilder for filter = \(myCDFilter.ciFilterName)") }
            }
        }
        }
    }


    func writeCDStack() -> CDFilterStack {
        NSLog("PGLFilterStack #writeCDStack name = \(stackName)")
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        let moContext = myAppDelegate.persistentContainer.viewContext

            if (storedStack == nil ) { // new stack needed
                storedStack = NSEntityDescription.insertNewObject(forEntityName: "CDFilterStack", into: moContext) as? CDFilterStack
                storedStack?.created = Date()
            } else { storedStack?.modified = Date()}
            storedStack?.title = stackName
            storedStack?.type = stackType
            storedStack?.exportAlbumName = exportAlbumName
            storedStack?.exportAlbumIdentifier = exportAlbumIdentifier


            storedStack?.thumbnail = stackThumbnail()  // data format of small png image

//         filters were added to the cdStack at add/remove time

            for aFilter in activeFilters {
//                storedStack?.filterNames?.append(aFilter.filterName)
                // remove filterNames from the datamodel... it's not used..
                // the filters relationship is used
                
                NSLog("PGLFilterStack #writeCDStack filter = \(aFilter.filterName)")
                let theFilterStoredObject = aFilter.cdFilterObject()
                // does not need to add if the filter exists in the relation already

                    // a new filter added
                    NSLog("PGLFilterStack #writeCDStack NEW FILTER \(aFilter.filterName)")
                // isn't the filter already in the relation to the storedStack?
                storedStack?.addToFilters(theFilterStoredObject)

            }

            return storedStack!  // force error if not set


    }

    

    func delete() {
        // delete this stack from the data store
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        let moContext = myAppDelegate.persistentContainer.viewContext
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

        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        let moContext = myAppDelegate.persistentContainer.viewContext
        if storedFilter == nil {
            NSLog("PGLSourceFilter #cdFilterObject storedFilter nil insertNewObject")
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
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        let moContext = myAppDelegate.persistentContainer.viewContext


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
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        let moContext = myAppDelegate.persistentContainer.viewContext

        if let initialStack = firstStack() {
          initialStack.writeCDStack()
        }

    if moContext.hasChanges {
    do { try moContext.save()
        NSLog("PGLAppStack #writeCDStacks save called")
        } catch { fatalError(error.localizedDescription) }
            }

    }

}
