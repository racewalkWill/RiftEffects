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
import os


struct PGLStackType {
   var name: String
}

let StackTypeKey = "StackTypes"
// key for the AppUserDefaults instance of UserDefaults

enum savePhotoError: Error {
    case nilReturn
    case otherSaveError
    case jpegError
    case heifError
}

enum PhotoLibSaveFormat: String {
    case JPEG = "JPEG"
    case HEIF = "HEIF"
}

extension PGLFilterStack {


        func on(cdStack: CDFilterStack) {
            // change this to a convience init.. caller does not need to create PGLFilterStack first

            storedStack = cdStack
            stackName = cdStack.title ?? "untitled"
            stackType = cdStack.type ?? "unTyped"
            if let thumbNailPGNImage = cdStack.thumbnail {
                thumbnail = UIImage(data: thumbNailPGNImage) // thumbnail is png format data aCDStack.thumbnail
            }

           exportAlbumIdentifier = cdStack.exportAlbumIdentifier
            exportAlbumName = cdStack.exportAlbumName
            let sortDescription = NSSortDescriptor(key: "stackPosition", ascending: true)
            let sortedFilter = cdStack.filters!.sortedArray(using: [sortDescription])
            Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGL-CDFilter PGLFilterStack init storedStack" )
            for aCDFilter in sortedFilter {
                // load stack to filter relationship

                if let myCDFilter = aCDFilter as? CDStoredFilter {
                    Logger(subsystem: LogSubsystem, category: LogCategory).debug("PGLFilterStack init storedStack on filter = \(String(describing: myCDFilter.ciFilterName))" )
//                    NSLog("PGLFilterStack filters on \(aCDFilter.stackPosition)")
                    guard let newSource = PGLSourceFilter.readPGLFilter(myCDFilter: myCDFilter)

                    else { return }
                    appendFilter(newSource)

                }
            }
        }


    func setToNewStack() {
        for filterIndex in 0..<activeFilters.count {
            let aFilter = activeFilters[filterIndex]
            aFilter.setToNewImageList()
            aFilter.storedFilter = nil
        }
        storedStack = nil
    }
    func writeCDStack(moContext: NSManagedObjectContext) -> CDFilterStack {
//        NSLog("PGLFilterStack #writeCDStack name = \(stackName)")


            if (storedStack == nil ) { // new stack needed
                storedStack = NSEntityDescription.insertNewObject(forEntityName: "CDFilterStack", into: moContext) as? CDFilterStack
                storedStack?.created = Date()
                }
            storedStack?.modified = Date()  // modified date may equal created on first save
            storedStack?.title = stackName
            storedStack?.type = stackType
            storedStack?.exportAlbumName = exportAlbumName
            storedStack?.exportAlbumIdentifier = exportAlbumIdentifier

            // only on the top level stack should a thumbnail be saved
            // skip child stack thumbnails
        if parentAttribute == nil {
            storedStack?.thumbnail = stackThumbnail()  // data format of small png image
        }
    //        for aFilter in activeFilters {
            for filterIndex in 0..<activeFilters.count {
                let aFilter = activeFilters[filterIndex]
                if aFilter.storedFilter == nil {
                    let theFilterStoredObject = aFilter.createCDFilterObject(moContext: moContext, stackPosition: Int16(filterIndex))
                    // moves images to cache to reduce storage
                    // does not need to add if the filter exists in the relation already
                    // storedStack?.addToFilters(theFilterStoredObject)
                    // add at the correct position !
                    storedStack?.addToFilters(theFilterStoredObject)
                    //storedStack?.insertIntoFilters(theFilterStoredObject, at: filterIndex)

                } else {
                    // further check on the relationship
                    aFilter.storedFilter?.stackPosition = Int16(filterIndex)
                        // always reset this for order changes

                    if aFilter.storedFilter?.stack == nil {
                        // make sure we have the order correct
                        // appends cdStoredfilter to the stack relationship

                        storedStack?.addToFilters(aFilter.storedFilter!)
                    }
                }
                aFilter.writeFilter(moContext: moContext) // handles imageparms move to cache etc..


            }
            return storedStack!  // force error if not set
    }

    func restoreCDstackImageCache() {
        // drill to all the filters and restoreImageCache after the moContext.save()
        for aFilter in activeFilters {
            aFilter.restoreImageInputsFromCache()
        }

    }

  
    func stackThumbnail() -> Data? {
        // output image in thumbnail size and png data format

        let outputImage = stackOutputImage(false)
        let uiOutput = outputImage.thumbnailUIImage()
       return uiOutput.pngData() // converts to data

    }

}
// ================= end extension PGLFilterStack ======================

extension PGLSourceFilter {
    // core data methods
    // MARK: CoreData

    class func readPGLFilter(myCDFilter: CDStoredFilter) -> PGLSourceFilter? {
        guard let filterBuilder = PGLFilterCategory.getFilterDescriptor(aFilterName: myCDFilter.ciFilterName!, cdFilterClass: myCDFilter.pglSourceFilterClass!)
            else { return nil }
         guard let newSource = filterBuilder.pglSourceFilter()
             else { return nil}

        newSource.localFilter = myCDFilter.ciFilter!
        newSource.storedFilter = myCDFilter
        newSource.resetAttributesToLocalFilter()
        if let parmImages = myCDFilter.input?.allObjects as? [CDParmImage] {
            // attach the cdParmImage to the matching filter attribute
            for aCDParmImage in parmImages {
                if let thisImageAttribute = newSource.attribute(nameKey: aCDParmImage.parmName!) as? PGLFilterAttributeImage {
                    thisImageAttribute.readCDParmImage(cdImageParm: aCDParmImage)
                }
            }
        }
        return newSource

    }

    func createCDFilterObject(moContext: NSManagedObjectContext, stackPosition: Int16) -> CDStoredFilter {
        // create cdFilter object
        // do not store filter image inputs in the CoreData..
        // saves storage memory - the localId will be saved and used to restore inputs
        // pglImageParms will handle the localId

        // get dictionary of attribute name and the current value in the filter

//        let moContext = PersistentContainer.viewContext

            if storedFilter == nil {
//                NSLog("PGLSourceFilter #cdFilterObject storedFilter insertNewObject \(String(describing: filterName))")
                storedFilter =  NSEntityDescription.insertNewObject(forEntityName: "CDStoredFilter", into: moContext) as? CDStoredFilter

            }
            storedFilter?.stackPosition = stackPosition
            storedFilter!.ciFilter = self.localFilter
            storedFilter!.ciFilterName = self.filterName
            storedFilter!.pglSourceFilterClass = self.classStringName()

            return storedFilter!
            // moContext save at the stack save

    }

    func writeFilter(moContext: NSManagedObjectContext) {
        // prepare image cache
        // create imageList
        // assumes createCDFilterObject has created the storedFilter if needed
//        NSLog("PGLSourceFilter #writeFilter filter \(String(describing: filterName))")
        imageInputCache = moveImageInputsToCache()
        createCDImageList(moContext: moContext) // creates for all the input parms

    }

    func moveImageInputsToCache() -> [String :CIImage?] {
        var localCache = [String : CIImage?]()
//        NSLog("PGLSourceFilter #moveImageInputsToCache filter \(String(describing: filterName))")


        for aImageKey in imageInputAttributeKeys {
//            NSLog("PGLSourceFilter #moveImageInputsToCache on \(aImageKey)")
            localCache[aImageKey] = valueFor(keyName: aImageKey) as? CIImage
            self.removeImageValue(keyName: aImageKey)
        }

        return localCache
    }

    func restoreImageInputsFromCache() {
        // from the filter var imageInputCache
//       NSLog("PGLSourceFilter #restoreImageInputsFromCache filter \(String(describing: filterName))")
        for (attributeName, image ) in imageInputCache {
            if let aCIImage = image {
                setImageValue(newValue: aCIImage, keyName: attributeName)
            }
            if let parm = attribute(nameKey: attributeName){
                if parm.hasFilterStackInput() {
                    // drill down to restore child stack filters too
                    let childStack = parm.inputStack
                    childStack?.restoreCDstackImageCache()
                }
            }

        }
        imageInputCache = [String :CIImage?]() // clear the cache
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

//    func readCDImageList(parentStack: PGLFilterStack)
    func setToNewImageList() {
        // set all of the core data vars to nil to save as new stack
        if let myImageParms = imageParms() {
            for anImageParm in myImageParms {
                if let childInputStack = anImageParm.inputStack {
                    childInputStack.setToNewStack() // will clear child filters
                }
                anImageParm.storedParmImage?.inputAssets = nil
                anImageParm.storedParmImage = nil
            }
        }

    }
    func createCDImageList(moContext: NSManagedObjectContext) {
        // 4EntityModel
        // create new CDImageList for every parm

        // remove - the source filter should not create the Image List
        // the ParmImage should control the Image List relationship

        if let myImageParms = imageParms() {
            for anImageParm in myImageParms {
                anImageParm.createNewCDImageParm(moContext: moContext)
                 // creates where relationship does not exist
            }
        }

    }

    func readCDParmImages() -> [CDParmImage] {
        // 4EntityModel
        // load all the cdParmImages
        if let result = storedFilter?.input?.allObjects as? [CDParmImage] {
            for aParmImage in result {
                if let cdChildStack = aParmImage.inputStack {
                    let pglChildStack = PGLFilterStack()
                    pglChildStack.on(cdStack: cdChildStack)

                }
            }
            return result
        } else { return [CDParmImage]() }

    }

    // MARK: PGLSourceFilter support


    func imageParms() -> [PGLFilterAttributeImage]? {
         // 4EntityModel
        // all parms that take an image as input

        if imageInputAttributeKeys.isEmpty {return nil }
        var imageAttributes = [PGLFilterAttributeImage]()

        for imageParmKey in imageInputAttributeKeys {
            if let thisImageAttribute = attribute(nameKey: imageParmKey) as? PGLFilterAttributeImage {
                imageAttributes.append(thisImageAttribute) }
            else { continue // to next element in the loop }
            }
        }
        return imageAttributes
    }

}  // ================ end extension PGLSourceFilter =========================

extension PGLFilterAttributeImage {

    func readCDParmImage(cdImageParm: CDParmImage) {
        // load relationships to the imageParm either input stack or Image List
        if let childStack = cdImageParm.inputStack  {
            let newPGLChildStack = PGLFilterStack()
            newPGLChildStack.on(cdStack: childStack)
            newPGLChildStack.parentAttribute = self
            self.inputStack = newPGLChildStack
                // in the UI inputStack is set with the PGLAppStack.addChildStackTo:(parm:)
                // Notice the didSet in inputStack: it hooks output of stack to input of the attribute
            setImageParmState(newState: ImageParm.inputChildStack)
        } else {
            // load relation inputAssets and attach an ImageList as input
            if let inputImageList = cdImageParm.inputAssets {
                // convert the stored cloudIDs in the cdImageParm to localIdentifiers
//                let aCloudID = PHCloudIdentifier(stringValue: "thisisATest")
                let storedCloudStrings = inputImageList.assetIDs ?? [String]()
                let cloudIDs: [PHCloudIdentifier] = storedCloudStrings.map({ (cloudString: String )
                        in  PHCloudIdentifier(stringValue: cloudString )})

                let localIds = cloudId2LocalId(assetCloudIdentifiers: cloudIDs)

                let cloudAlbums = inputImageList.albumIds ?? [String]()

                let cloudAlbumIDs: [PHCloudIdentifier] = cloudAlbums.map({ (cloudString: String )
                    in  PHCloudIdentifier(stringValue: cloudString )})

                let localAlbums = cloudId2LocalId(assetCloudIdentifiers: cloudAlbumIDs)
                let newImageList = PGLImageList(localAssetIDs: (localIds),albumIds: (localAlbums) )
                    // in limited Library mode some photos may not load
                newImageList.validateLoad()
                
                newImageList.on(imageParm: self)

            }
        }
    }

    func createNewCDImageParm(moContext: NSManagedObjectContext) {
        // 4EntityModel
//        NSLog("PGLFilterAttributeImage #createNewCDImageParm filter \(String(describing: attributeName ))")
//        let moContext = PersistentContainer.viewContext

        if self.storedParmImage == nil {
            guard let newCDImageParm =  NSEntityDescription.insertNewObject(forEntityName: "CDParmImage", into: moContext) as? CDParmImage
                else {
                DispatchQueue.main.async {
                    // put back on the main UI loop for the user alert
                    let alert = UIAlertController(title: "Data Create Error", message: "Data creation failure ", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                        Logger(subsystem: LogSubsystem, category: LogCategory).error("The userSaveErrorAlert Data Create Error")
                    }))
                    let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                    myAppDelegate.displayUser(alert: alert)
                    }
                return
            }
            newCDImageParm.parmName = self.attributeName
            newCDImageParm.filter = self.aSourceFilter.storedFilter // creates relationship
            self.storedParmImage = newCDImageParm
        }

        // create related CDImageList
        if self.inputCollection != nil {
            if storedParmImage?.inputAssets == nil {
            guard let storedImageList =  NSEntityDescription.insertNewObject(forEntityName: "CDImageList", into: moContext) as? CDImageList
                else {
                DispatchQueue.main.async {
                    // put back on the main UI loop for the user alert
                    let alert = UIAlertController(title: "Data Create Error", message: "Data creation failure ", preferredStyle: .alert)

                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
                        Logger(subsystem: LogSubsystem, category: LogCategory).error ("The userSaveErrorAlert Data Create Error.")
                    }))
                    let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                    myAppDelegate.displayUser(alert: alert)
                    }
                return
            }
                storedParmImage?.inputAssets = storedImageList // sets up the relationship parm to inputAssets
            }
            if let theAssetIdentifiers = self.inputCollection?.assetIDs {
                // on the iPhone PHPicker the imageAssets do not have the identifiers
                // use the inputCollection identifiers
                let cloudAssetIDs = localId2CloudId(localIdentifiers: theAssetIdentifiers)
                storedParmImage?.inputAssets?.assetIDs = cloudAssetIDs
            }
            else {
            if let imageListAssets = self.inputCollection?.imageAssets {

                let cloudIDs = localId2CloudId(localIdentifiers: imageListAssets.map({$0.localIdentifier}))
                storedParmImage?.inputAssets?.assetIDs = cloudIDs }

                }
            // albums are set in the getAssets(localIds: [String],albums: [String])

            if let localListAssets = self.inputCollection?.imageAssets {
                var mappedCloudIds = [String]()
                let myAlbumIds = localListAssets.map({$0.albumId})

                for eachAlbumID in myAlbumIds {
                    let thisAlbumMapping  = localId2CloudId(localIdentifiers: [ eachAlbumID ] )
                    mappedCloudIds.append(contentsOf: thisAlbumMapping)
                }

                // local2CloudId will return a single cloudAlbum if the albumIds are the same...
                // we expect a matching same size array.. every local image asset has a cloudAlbumId
               // therefore need to iterate and map each albumID one, by one

                storedParmImage?.inputAssets?.albumIds = mappedCloudIds

            }

            }
        if self.inputStack != nil {
            // a child stack exists
            if self.storedParmImage?.inputStack == nil {
                // create a cdFilterStack for the child stack input to the parm
                if let childCDStack = self.inputStack?.writeCDStack(moContext: moContext) {
                    self.storedParmImage?.inputStack = childCDStack
                }
                    // store the relationship


            }
        }


    }

    func localId2CloudId(localIdentifiers: [String]) -> [String] {
        var mappedIdentifiers = [String]()
       let library = PHPhotoLibrary.shared()
        let iCloudIDs = library.cloudIdentifierMappings(forLocalIdentifiers: localIdentifiers)
        for aCloudID in iCloudIDs {
            //'Dictionary<String, Result<PHCloudIdentifier, Error>>.Element' (aka '(key: String, value: Result<PHCloudIdentifier, Error>)')
            let cloudResult: Result = aCloudID.value
            // Result is an enum .. not a tuple
            switch cloudResult {
                case .success(let success):
                    let newValue = success.stringValue
                    mappedIdentifiers.append(newValue)
                case .failure(_):
                    // do error notify to user
//                    let iCloudError = savePhotoError.otherSaveError
//                    userSaveErrorAlert(withError: iCloudError)
                    Logger(subsystem: LogSubsystem, category: LogCategory).error("iCloud Error occurred in localId2CloudId" )
            }
        }
        return mappedIdentifiers
    }

    func cloudId2LocalId(assetCloudIdentifiers: [PHCloudIdentifier]) -> [String] {
            // patterned error handling per documentation
        var localIDs = [String]()
        let localIdentifiers: [PHCloudIdentifier: Result<String, Error>]
           = PHPhotoLibrary
                .shared()
                .localIdentifierMappings(
                  for: assetCloudIdentifiers)

        for cloudIdentifier in assetCloudIdentifiers {
            guard let identifierMapping = localIdentifiers[cloudIdentifier] else {
                print("Failed to find a mapping for \(cloudIdentifier).")
                continue
            }
            switch identifierMapping {
                case .success(let success):
                    localIDs.append(success)
                case .failure(let failure) :
                    let thisError = failure as? PHPhotosError
                    switch thisError?.code {
                        case .identifierNotFound:
                            // Skip the missing or deleted assets.
                            print("Failed to find the local identifier for \(cloudIdentifier). \(String(describing: thisError?.localizedDescription)))")
                        case .multipleIdentifiersFound:
                            // Prompt the user to resolve the cloud identifier that matched multiple assets.
                            print("Found multiple local identifiers for \(cloudIdentifier). \(String(describing: thisError?.localizedDescription))")
//                            if let selectedLocalIdentifier = promptUserForPotentialReplacement(with: thisError.userInfo[PHLocalIdentifiersErrorKey]) {
//                                localIDs.append(selectedLocalIdentifier)

                        default:
                            print("Encountered an unexpected error looking up the local identifier for \(cloudIdentifier). \(String(describing: thisError?.localizedDescription))")
                    }
              }
            }
        return localIDs
    }
}




// ================ end extension PGLFilterAttributeImage =========================

// ================ start extension PGLImageList  =========================
extension PGLImageList {
    func on(imageParm: PGLFilterAttributeImage) {
        self.setUserSelection(toAttribute: imageParm)
        imageParm.setImageCollectionInput(cycleStack: self)
    }
}

// ================ end extension PGLImageList  =========================

// ================ start extension PGLAppStack =========================
extension PGLAppStack {
     func firstStack() -> PGLFilterStack? {
        if pushedStacks.isEmpty {
          return  viewerStack
        } else { return pushedStacks.first}
    }

    func rollbackStack() {
        // removes unsaved changes from the NSManagedObjectContext
        let moContext = dataProvider.persistentContainer.viewContext
        moContext.rollback()

    }

    func writeCDStacks(){
        // store starting from the top level
        // each stack will write in turn as it is referenced
        // do not need to iterate the collection

        // stop the display timer while writing the stacks to core data
        // filter image inputs are nil for core data then restored on completion
        

        if let initialStack = self.firstStack() {
            let dataViewContext = dataProvider.persistentContainer.viewContext
            let myCDStack = initialStack.writeCDStack(moContext: dataViewContext)
            // filter images are moved to a cache before the save
            dataProvider.saveStack(aStack: myCDStack, in: dataViewContext , shouldSave: true )
            // post notification to update PGLOpenStackViewController
            // with the new or updated stack
            // send only the objectID to the main UI process

            let stackHasSavedNotification = Notification(name: PGLStackHasSavedNotification, object: nil, userInfo: [ "stackObjectID": myCDStack.objectID, "stackType" : myCDStack.type as Any])
            NotificationCenter.default.post(stackHasSavedNotification)
            }


      // now restore all the cached input images
        if let initialStack = firstStack() {
         initialStack.restoreCDstackImageCache()
            // bring back the image cache to filter inputs after save runs
            }
    }



    func userSaveErrorAlert(withError: Error) {
        DispatchQueue.main.async {
            // all UI needs to be in the main queue including creation of UIAlertController
        let alert = UIAlertController(title: "Save Error", message: "Try again with 'Save As' command", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in
            Logger(subsystem: LogSubsystem, category: LogCategory).error ("The userSaveErrorAlert \(withError.localizedDescription)")
        }))

        let userAlertNotification =  Notification(name: PGLUserAlertNotice, object: nil , userInfo: ["alertController" : alert])
        NotificationCenter.default.post(userAlertNotification)
        }
    }


    func setToNewStack() {
        // save as.. command..
        // reset core data vars to nil for save as new records
        rollbackStack() // discards any coredata changes
            // or update to persistant state

        firstStack()?.setToNewStack() // create new
    }

    func saveStack(metalRender: Renderer) {

//        NSLog("PGLAppStack #saveStack start")
//        let serialQueue = DispatchQueue(label: "queue", qos: .utility, attributes: [], autoreleaseFrequency: .workItem, target: nil)
//        serialQueue.async {
        let targetStack = self.firstStack()!
//            NSLog("PGLAppStack #saveStack serialQueue execution start")
        DoNotDrawWhileSave = true
        defer {
            DoNotDrawWhileSave = false } // executes at the end of this function
        if targetStack.shouldExportToPhotos {
            switch metalRender.currentPhotoFileFormat {
                case .JPEG:
                    self.saveJPEGToPhotosLibrary(stack: targetStack, metalRender: metalRender)
                case .HEIF:
                    self.saveToHEIFPhotosLibrary(stack: targetStack, metalRender: metalRender)
                default:
                    return // not supported format??
            }
//           NSLog("PGLAppStack #saveStack calls writeCDStacks")
        }
        // there is a guard for unsaved changes in
        // the moContext save
        // okay if writeCDStacks is called from multiple imageControllers
        self.writeCDStacks()
    }

    fileprivate func fetchExistingAlbum(_ stack: PGLFilterStack, _ assetCollection: inout PHAssetCollection?) {
        // ======== move album logic to method
        //        NSLog("saveToPhotosLibrary = \(String(describing: stack.exportAlbumIdentifier))")
        if let existingAlbumId = stack.exportAlbumIdentifier {
            let fetchResult  = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [existingAlbumId], options: nil)
            assetCollection = fetchResult.firstObject
            //                NSLog("PGLImageController #saveToPhotosLibrary append to existing assetCollection \(String(describing: assetCollection))")
        } else {
            // check for existing albumName
            if let aAlbumExportName = stack.exportAlbumName { // maybe nil

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
    }

    fileprivate func photoLibPerformHEIFChange(_ stack: PGLFilterStack, _ heifData: Data?, _ assetCollection: PHAssetCollection?) {
        do { try PHPhotoLibrary.shared().performChangesAndWait( {

            let creationRequest = PHAssetCreationRequest.forAsset()
            let fileNameOption = PHAssetResourceCreationOptions()
            fileNameOption.originalFilename = stack.stackName
            creationRequest.addResource(
                with: PHAssetResourceType.photo,
                data: heifData!,
                options: fileNameOption)

            if ( assetCollection == nil ) && ( stack.exportAlbumName != nil) {
                // new collection
                let assetCollectionRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: stack.exportAlbumName ?? "exportAlbum")
                assetCollectionRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                stack.exportAlbumIdentifier = assetCollectionRequest.placeholderForCreatedAssetCollection.localIdentifier
                //                            NSLog("PGLAppStack #saveToPhotosLibrary new assetCollectionRequest = \(assetCollectionRequest)")

            } else {
                // asset collection exists
                if assetCollection != nil {
                    let addAssetRequest = PHAssetCollectionChangeRequest(for: assetCollection!)
                    addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                    //                            NSLog("PGLAppStack #saveToPhotosLibrary existing assetCollection adds = \(String(describing: addAssetRequest))")
                }
            }

        } )
        } catch  { userSaveErrorAlert(withError: error)}
    }

    func saveToHEIFPhotosLibrary( stack: PGLFilterStack, metalRender: Renderer ) {
                // NOT called if targetStack.shouldExportToPhotos = false
                // check if the album exists..)
               // save the output of this stack to the photos library
                // Create a new album with the entered title.
              
        var assetCollection: PHAssetCollection?
        var heifData: Data?

        fetchExistingAlbum(stack, &assetCollection)
        // ======== move album logic to method

        if stack.shouldExportToPhotos {
               // Add the asset to the photo library
                // album name may not be entered or used if limited photo library access
            do {
                heifData = try metalRender.captureHEIFImage()
                //throw saveHEIFError.nilReturn
            }
            catch {
//                Logger(subsystem: LogSubsystem, category: LogCategory).error ("saveToPhotosLibrary metalRender failed at capture image data)
                userSaveErrorAlert(withError: error)
                return
            }
            photoLibPerformHEIFChange(stack, heifData, assetCollection)

        }


           }

    fileprivate func photoLibPerformJPEGChange(_ uiImageOutput: UIImage?, _ assetCollection: PHAssetCollection?, _ stack: PGLFilterStack) {
        if uiImageOutput == nil {
            let imageRenderError = savePhotoError.otherSaveError
            userSaveErrorAlert(withError: imageRenderError)
            return
        }
        do { try PHPhotoLibrary.shared().performChangesAndWait( {

            let creationRequest = PHAssetChangeRequest.creationRequestForAsset(from: uiImageOutput!)

            if ( assetCollection == nil ) && ( stack.exportAlbumName != nil) {
                // new collection
                let assetCollectionRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: stack.exportAlbumName ?? "exportAlbum")
                assetCollectionRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                stack.exportAlbumIdentifier = assetCollectionRequest.placeholderForCreatedAssetCollection.localIdentifier

            } else {
                // asset collection exists
                if assetCollection != nil {
                    let addAssetRequest = PHAssetCollectionChangeRequest(for: assetCollection!)
                    addAssetRequest?.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                    //                            NSLog("PGLAppStack #saveToPhotosLibrary existing assetCollection adds = \(String(describing: addAssetRequest))")
                }
            }

        } )
        } catch  { userSaveErrorAlert(withError: error)}
    }

    func saveJPEGToPhotosLibrary( stack: PGLFilterStack, metalRender: Renderer ) {
                // NOT called if targetStack.shouldExportToPhotos = false
                // check if the album exists..)
               // save the output of this stack to the photos library
                // Create a new album with the entered title.

        var assetCollection: PHAssetCollection?

        var uiImageOutput: UIImage?

        fetchExistingAlbum(stack, &assetCollection)

        if stack.shouldExportToPhotos {
               // Add the asset to the photo library
                // album name may not be entered or used if limited photo library access
            do {
                   uiImageOutput = try metalRender.captureImage()
            }

            catch {
//                Logger(subsystem: LogSubsystem, category: LogCategory).error ("saveToPhotosLibrary metalRender failed at capture image data)
                userSaveErrorAlert(withError: error)
                return
            }

            photoLibPerformJPEGChange(uiImageOutput, assetCollection, stack)

        }


           }

}
// ================ end extension PGLAppStack =========================
