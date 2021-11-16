//
//  GlanceUITests.swift
//  GlanceUITests
//
//  Created by Will on 10/11/17.
//  Copyright © 2017 Will. All rights reserved.
//

import XCTest

class GlanceUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func example() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.



        let app = XCUIApplication()
        let moreButton = app.tabBars.buttons["More"]
        moreButton.tap()

        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["DefaultInput"]/*[[".cells.staticTexts[\"DefaultInput\"]",".staticTexts[\"DefaultInput\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Portrait"]/*[[".cells.staticTexts[\"Portrait\"]",".staticTexts[\"Portrait\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let saleFurnitureStaticText = tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Sale Furniture"]/*[[".cells.staticTexts[\"Sale Furniture\"]",".staticTexts[\"Sale Furniture\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        saleFurnitureStaticText.tap()

        let collectionViewsQuery = app.collectionViews
        collectionViewsQuery.children(matching: .cell).element(boundBy: 0).otherElements.children(matching: .image).element.tap()

        let acceptButton = app.navigationBars["Image"].buttons["Accept"]
        acceptButton.tap()

        let acceptButton2 = app.navigationBars["Sale Furniture"].buttons["Accept"]
        acceptButton2.tap()
        moreButton.tap()
        moreButton.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Default background"]/*[[".cells.staticTexts[\"Default background\"]",".staticTexts[\"Default background\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Screenshots"]/*[[".cells.staticTexts[\"Screenshots\"]",".staticTexts[\"Screenshots\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        saleFurnitureStaticText.tap()
        collectionViewsQuery.children(matching: .cell).element(boundBy: 3).otherElements.children(matching: .image).element.tap()
        acceptButton.tap()
        acceptButton2.tap()

    }

    func testDissolveTwoAlbums() {
           let app = XCUIApplication()

        let tablesQuery = app.tables
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Images"]/*[[".cells.staticTexts[\"Images\"]",".staticTexts[\"Images\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Dissolve"]/*[[".cells.staticTexts[\"Dissolve\"]",".staticTexts[\"Dissolve\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        app.navigationBars["S1"].buttons["Back"].tap()

        tablesQuery/*@START_MENU_TOKEN@*/.buttons["More Info"]/*[[".cells.buttons[\"More Info\"]",".buttons[\"More Info\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["inputImage"]/*[[".cells.staticTexts[\"inputImage\"]",".staticTexts[\"inputImage\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()


        tablesQuery/*@START_MENU_TOKEN@*/.staticTexts["Bursts"]/*[[".cells.staticTexts[\"Bursts\"]",".staticTexts[\"Bursts\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let burstsNavigationBar = app.navigationBars["Bursts"]
        burstsNavigationBar.buttons["All"].tap()
//        burstsNavigationBar.buttons["Accept"].tap()

      app.tables/*@START_MENU_TOKEN@*/.staticTexts["Time-lapse"]/*[[".cells.staticTexts[\"Time-lapse\"]",".staticTexts[\"Time-lapse\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        let verticalScrollBar2PagesCollectionViewsQuery = app.collectionViews.containing(.other, identifier:"Vertical scroll bar, 2 pages")
        verticalScrollBar2PagesCollectionViewsQuery.children(matching: .cell).element(boundBy: 15).children(matching: .other).element.tap()
        verticalScrollBar2PagesCollectionViewsQuery.children(matching: .cell).element(boundBy: 16).children(matching: .other).element.tap()
        app.navigationBars["Bursts"].buttons["Accept"].tap()
        app.navigationBars["S1"].buttons["Back"].tap()

        // assert here that dissolve is running with  two albums and more than 4 images/parm
        // can you get to the model objects for assert tests?
        
    }

    
}
