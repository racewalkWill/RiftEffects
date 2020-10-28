//
//  PGLDataStoreTests.swift
//  GlanceTests
//
//  Created by Will on 12/5/18.
//  Copyright © 2018 Will. All rights reserved.
//

import XCTest
import CoreData
import CoreImage
import Photos

@testable import Surreality


enum PhotoId: String {
    case selfie = "A2202355-1BD1-4DAA-A20B-BC2D9179F229/L0/001"
    case portrait = "3607572E-9D53-4385-A5D3-43F1C855C04A/L0/001"
    case burstAlbum = "2A70D5E3-D347-4C3F-A83E-192462055B7E/L0/040"
    case timeLapseAlbum = "D29AF982-36F9-429A-9FA2-A07B9A0DAAB3/L0/040"
    case burst1 = "8AEFD6FA-E088-488A-AEBA-910E705A7E22/L0/001"
    case burst2 = "82CF9D33-BE2D-41A3-817F-46E6BB511A59/L0/001"
    case burst3 = "B2BAE7A2-982B-4C3E-8A67-62C030E62B72/L0/001"
    case timeLapse1 = "1CE13129-93CB-4E9A-AADD-92EEB5B546F2/L0/001"
    case timeLapse2 = "0C17C825-263B-4C0F-869E-6979954BC0B4/L0/001"
    case timeLapse3 = "0DBE8E41-09F9-4847-A949-7B8916284B65/L0/001"
    case timeLapse4 = "28AFB02D-2F75-4C39-BA0F-5C5211B88797/L0/001"
}


class PGLDataStoreTests: XCTestCase {
    let ciTestFilterName = "CIDiscBlur"
    var fdsAppDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataContainer: NSPersistentContainer?
    var appStack: PGLAppStack!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
        appStack = myAppDelegate.appStack
    }

    override func tearDown() {

            // Put teardown code here. This method is called after the invocation of each test method in the class.
    //        let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
    //               myAppDelegate.saveContext() // checks if context has changes

            let newStack = PGLFilterStack()
            newStack.setStartupDefault() // not sent in the init.. need a starting point
            self.appStack.resetToTopStack(newStack: newStack)
            super.tearDown()


    }

    // MARK: StoredFilter tests
    func testFilterSave() {

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let newRadiusValue: CGFloat = 4.0
        let moContext = fdsAppDelegate.persistentContainer.viewContext
        let newFilter = NSEntityDescription.insertNewObject(forEntityName: "CDStoredFilter", into: moContext) as! CDStoredFilter
        newFilter.ciFilter = CIFilter(name: ciTestFilterName)
        newFilter.ciFilterName = ciTestFilterName
        XCTAssert( newRadiusValue != newFilter.ciFilter!.value(forKey: kCIInputRadiusKey) as? CGFloat )
        newFilter.ciFilter?.setValue(newRadiusValue , forKey: kCIInputRadiusKey)
        newFilter.ciFilter?.setValue(defaultCIImage(), forKey: kCIInputImageKey)
        if moContext.hasChanges {
            do { try moContext.save()
            } catch { fatalError() }
        }


        XCTAssert( newRadiusValue == newFilter.ciFilter!.value(forKey: kCIInputRadiusKey) as? CGFloat )

        if moContext.hasChanges {
            NSLog("FilterDataStoreTests #testExample saving radius input change")
            do { try moContext.save()
            } catch { fatalError() }
        }
    }

    func testFilterRead() {

        // Use XCTAssert and related functions to verify your tests produce the correct results.
        let newRadiusValue: CGFloat = 4.0
        let moContext = fdsAppDelegate.persistentContainer.viewContext
        let request =  NSFetchRequest<CDStoredFilter>(entityName: "CDStoredFilter")

        var readResults: [CDStoredFilter]!
        do {  readResults = try moContext.fetch(request) }
        catch { fatalError("testFilterRead error")}
        XCTAssert(!readResults.isEmpty)
        NSLog("testFilterRead has readResults.count = \(readResults.count)")

        let filter1 = readResults.last
        //        XCTAssert(filter1?.name == ciTestFilterName)
        NSLog("testFilterRead filter1.name = \(String(describing: filter1?.ciFilterName))")

        let theFilter = filter1?.ciFilter
        let theAttributes = theFilter?.attributes

        NSLog("testFilterRead = \(String(describing: theAttributes))")
        var inputRadius: CGFloat = 0.0
        inputRadius = (theFilter?.value(forKey: kCIInputRadiusKey) as? CGFloat)!
        XCTAssert(inputRadius == newRadiusValue )
        let filterInput = (theFilter?.value(forKey: kCIInputImageKey)) as? CIImage
        XCTAssertNotNil(filterInput)
    }

    func testFilterImageInput() {
        // how does the data store handle a parm that is a ciImage?
        // 1. get an image from the PhotoLibrary


        let testImage = defaultCIImage()
        let newRadiusValue: CGFloat = 4.0
        let moContext = fdsAppDelegate.persistentContainer.viewContext
        let newFilter = NSEntityDescription.insertNewObject(forEntityName: "CDStoredFilter", into: moContext) as! CDStoredFilter
        newFilter.ciFilter = CIFilter(name:ciTestFilterName )
        newFilter.ciFilterName = ciTestFilterName
        XCTAssert( newRadiusValue != newFilter.ciFilter!.value(forKey: kCIInputRadiusKey) as? CGFloat )
        newFilter.ciFilter?.setValue(newRadiusValue , forKey: kCIInputRadiusKey)
        newFilter.ciFilter?.setValue(testImage , forKey: kCIInputImageKey)
        if moContext.hasChanges {
            do { try moContext.save()
            } catch { fatalError("moContext.save error") }
        }

        let theFilter = newFilter.ciFilter
        XCTAssertNotNil(theFilter!.value(forKey: kCIInputImageKey))
        let storedRadius = theFilter!.value(forKey: kCIInputRadiusKey) as? CGFloat
        XCTAssert( storedRadius == newRadiusValue)



    }

    // MARK: PGLImageList tests

    func testCycleStack() {
        // setup - get photo assets


        // create a Cycle stack
        let myCycleStack = PGLDataStoreTests.imageListTestObject()

        XCTAssert(myCycleStack.imageAssets.count == 6)
        _ = myCycleStack.first()
        XCTAssertNotNil(myCycleStack.firstImage)

    }



    // MARK: TestSupport

   static func imageListTestObject() -> PGLImageList {
        let assetIDs = [PhotoId.burst1.rawValue, PhotoId.burst2.rawValue , PhotoId.timeLapse1.rawValue, PhotoId.timeLapse2.rawValue, PhotoId.timeLapse3.rawValue, PhotoId.timeLapse4.rawValue]
        // create a Cycle stack
    let albumIDs = [PhotoId.burstAlbum.rawValue, PhotoId.burstAlbum.rawValue,PhotoId.burstAlbum.rawValue,PhotoId.timeLapseAlbum.rawValue,PhotoId.timeLapseAlbum.rawValue,PhotoId.timeLapseAlbum.rawValue,]
// matching assetId and albumId arrays
        return PGLImageList(localAssetIDs: assetIDs, albumIds: albumIDs)
    }

    func defaultCIImage() -> CIImage {
        let aPhotoId = [PhotoId.selfie.rawValue]
        var resizeImage: CIImage?
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.isSynchronous = true

        let photoFetchResult = PHAsset.fetchAssets(withLocalIdentifiers: aPhotoId, options: nil)
        let photoAsset = photoFetchResult.firstObject
        let targetSize = CGSize(width: 640.0, height: 480.0)
        PHImageManager.default().requestImage(for: photoAsset!, targetSize: targetSize, contentMode: .aspectFit, options: options, resultHandler: { image, _ in
            guard let theImage = image else { return  }
            if let convertedImage = CoreImage.CIImage(image: theImage ) {
                let theOrientation = CGImagePropertyOrientation.up
                let pickedCIImage = convertedImage.oriented(theOrientation)
                resizeImage = self.scaleToFrame(ciImage: pickedCIImage, newSize: targetSize)
            }
        })
        return resizeImage!
    }
    fileprivate func scaleToFrame(ciImage: CIImage, newSize: CGSize) -> CIImage {
        // make all the images scale to the same size
        let sourceExtent = ciImage.extent
        let xScale = newSize.width / sourceExtent.width
        let yScale =  newSize.height / sourceExtent.height
        let scaleTransform = CGAffineTransform.init(scaleX: xScale, y: yScale)
        return ciImage.transformed(by: scaleTransform)
    }


    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
