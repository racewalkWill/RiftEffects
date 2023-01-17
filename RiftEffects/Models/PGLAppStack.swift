//
//  PGLAppStack.swift
//  Glance
//
//  Created by Will on 12/8/18.
//  Copyright © 2018 Will Loew-Blosser. All rights reserved.
//

import Foundation
import os
import UIKit
import CoreData


let  PGLStackChange = NSNotification.Name(rawValue: "PGLStackChange")
let PGLSelectActiveStackRow = NSNotification.Name(rawValue: "PGLSelectActiveStackRow")
 // 2021/02/02 PGLSelectActiveStackRow may not be used.. remove?
enum StackDisplayMode: String {
     case All
     case Single
}

class PGLAppStack {
    var outputStack: PGLFilterStack
    var viewerStack = PGLFilterStack()
    var pushedStacks = [PGLFilterStack]()

    lazy var appRenderer: Renderer = Renderer(globalAppStack: self)



    lazy var cellFilters = self.flattenFilters()
        // flat array of filters in the stack trees

        /// display just the current filter if true
    var showFilterImage = false

    lazy var dataProvider: PGLStackProvider = {
        let appDelegate = UIApplication.shared.delegate as? AppDelegate

        let provider = PGLStackProvider(with: appDelegate!.dataWrapper.persistentContainer )
        // set the provider with a background context

         provider.setFetchControllerForBackgroundContext()
            // use background becuase this is for the imageController, filter, parms controllers
        
        return provider
    }()

   

    // controls displaying the current intermediate viewer data stack image or the final output

    init(){
//       viewerStack.setStartupDefault()
        // not needed a stack has a default in the init.. does not work well wthout at least one filter & image
        outputStack = viewerStack
//        let myCenter =  NotificationCenter.default
//        let queue = OperationQueue.main
//        myCenter.addObserver(forName: PGLImageCollectionClose, object: nil , queue: queue) { myUpdate in
//            NSLog("PGLAppStack  notification PGLImageCollectionClose")
//            self.isImageControllerOpen = true
//        }
//        myCenter.addObserver(forName: PGLImageCollectionOpen, object: nil , queue: queue) { myUpdate in
//            NSLog("PGLAppStack  notification PGLImageCollectionOpen")
//            NSLog("PGLImageCollectionMasterController set isImageControllerOpen = FALSE")
//            self.isImageControllerOpen = false
//        }
    }
    // MARK: REFACTOR ParmController
    // this section contains the logic from the PGLSelectParmController
    // to set values into the parm attribute.
    // REFACTOR vars moved from PGLSelectParmController
    var currentFilter: PGLSourceFilter?
    var targetAttribute: PGLFilterAttribute?
    // the imageController viewDidLoad or appear
    // should perform the highlight logic..

    var parmControls = [String : UIView]() // string index by attributeName
        // holds point and textfield input controls
    var parms =  [String : PGLFilterAttribute]() // string index by attributeName

    var isImageControllerOpen = false { // set to false when PGLAssetGridController or other controllers in the detail are open
       // MARK: appStackParmRefactor
       //  make sure this is set correctly in the iphone compact mode where imageController
        // is not visible
        didSet{
//            NSLog ("PGLAppStackl isImageControllerOpen = \(isImageControllerOpen)")
//            NSLog ("PGLAppStackl isImageControllerOpen oldValue = \(oldValue)")
        }
    }

    func setParms(newFilterParms: [PGLFilterAttribute]) {
            // MARK: appStackParmRefactor

        // Sender?
        // set parms with the attributeName as the dictionary key for the filterAttribute
        // what about clearing old  buttons  in updateParmControls?
        parms =  [String : PGLFilterAttribute]()
        for anAttribute in newFilterParms {
            parms[anAttribute.attributeName!] = anAttribute
        }
    }

    // MARK: Master Data Object Stacks
    func postStackChange() {
        
        let stackNotification = Notification(name:PGLStackChange)
        NotificationCenter.default.post(stackNotification)

        postFilterChangeRedraw()
    }

    func postSelectActiveStackRow() {
        let rowChange = Notification(name: PGLSelectActiveStackRow)
        NotificationCenter.default.post(rowChange)
    }

     func resetOutputAppStack(_ userPickedStack: PGLFilterStack) {
        viewerStack = userPickedStack
        outputStack = viewerStack // same as init
        pushedStacks = [PGLFilterStack]()
        postStackChange()
    }

    func resetToTopStack(newStackId: NSManagedObjectID) {
        // new stack loaded from the data store
        // replace current data
        // clear persistentContext of the old context - so that it reloads from data in saved state
        var cdStack: CDFilterStack!
        releaseTopStack()
        let userPickedStack = PGLFilterStack.init()
        guard let currentBackgroundContext = dataProvider.providerManagedObjectContext
        else { return }
        do {  cdStack =  try currentBackgroundContext.existingObject(with: newStackId) as? CDFilterStack

        } catch {
            Logger(subsystem: LogSubsystem, category: LogCategory).error("resetToTopStack error  \(error.localizedDescription)")
            DispatchQueue.main.async {
                // put back on the main UI loop for the user alert
                let alert = UIAlertController(title: "Data Error", message: "PGLFilterStack resetToTopStack() \(error.localizedDescription). ", preferredStyle: .alert)

                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .default, handler: { _ in

                }))

                let myAppDelegate =  UIApplication.shared.delegate as! AppDelegate
                myAppDelegate.displayUser(alert: alert)

            }
            return // on error
        }
        userPickedStack.on(cdStack: cdStack)
        
        resetOutputAppStack(userPickedStack)
    }

    func releaseTopStack() {
        rollbackStack()
             // removes unsaved changes from the NSManagedObjectContext
         // disconnect the cdStack from the old selected stack..
         //  release the old pglStack
 //        outputStack.storedStack = nil
         // 2022-07-23  the line to set to nil did not fix memory
         outputStack.releaseVars()
        dataProvider.reset()
        resetNeedsRedraw()

             // nil out refs so the memory is released
    }

    func resetNeedsRedraw() {
        let updateNotification = Notification(name:PGLResetNeedsRedraw)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: nil)
    }
    
    func removeDefaultEmptyFilter() {
        if outputStack.isEmptyDefaultStack() {
          _ = outputStack.removeDefaultFilter()
            }
    }

    func resetViewStack() {
        viewerStack = outputStack
        // when showing stacks the user can choose
        // any filter - parent or child.
        
    }
    func moveTo(filterIndent: PGLFilterIndent) {
        Logger(subsystem: LogSubsystem, category: LogCategory).info("PGLAppStack #moveTo(filterIndent: \(filterIndent.filterPosition)")


        filterIndent.stack.imageCIContext = viewerStack.imageCIContext
        viewerStack = filterIndent.stack
//        NSLog("PGLAppStack #moveTo( viewerStack now \(viewerStack)")
        viewerStack.activeFilterIndex = filterIndent.filterPosition
        // remove from pushedStacks???
        pushedStacks.removeAll(where: { $0 === viewerStack })
        postFilterChangeRedraw()


    }

    func postFilterChangeRedraw() {
        let updateNotification = Notification(name:PGLRedrawFilterChange)
        NotificationCenter.default.post(name: updateNotification.name, object: nil, userInfo: ["filterHasChanged" : true as AnyObject])
    }

    func addChildSequenceStackTo(parm: PGLFilterAttribute) {
        // same as addChildStackTo(parm: PGLFilterAttribute)
        // but with different stack class

        // see also for loading sequence from coredata
        // PGLFilterAttributeImage sets up the sequenceStack
        // in #readCDParmImage(..) with the #setUpStack(onParentImageParm:..)
        let newSequenceStack = PGLSequenceStack()
        newSequenceStack.setStartupDefault()  // puts in the 'Images' empty filter as first child filter
        if let ciFilterSequence = parm.myFilter as? PGLCISequenced {
            ciFilterSequence.myFilterSequence = newSequenceStack

            addChildStackBasic(newSequenceStack, parm)
        }
    }
    
    fileprivate func addChildStackBasic(_ newStack: PGLFilterStack, _ parm: PGLFilterAttribute) {
            //        newStack.setStartupDefault() // Images null filter is starting filter
        newStack.stackName = viewerStack.nextStackName()
        newStack.stackType = "input"
            //        NSLog("addChildStackTo(parm:) newStack.stackName = \(newStack.stackName)")
        newStack.parentAttribute = parm
            //        newStack.parentStack = viewerStack
        pushChildStack(newStack)  // make newStack as the current masterDataStack

        parm.inputStack = newStack
        parm.setImageParmState(newState: ImageParm.inputChildStack)
            // Notice the didSet in inputStack: it hooks output of stack to input of the attribute
            //        resetCellFilters() // the flattened filter list needs update for the new stack
        postStackChange() // causes imageController view.isHidden = true
            // hides the visual output.
    }

    func addChildStackTo(parm: PGLFilterAttribute) {
        // the parm takes the output of a set of filters in a filterStack
        // as the visual input
        let  newStack = PGLFilterStack()
       
        addChildStackBasic(newStack, parm) // causes resetCellFilters too
    }

    func pushChildStack(_ child: PGLFilterStack) {
        child.imageCIContext = viewerStack.imageCIContext

        pushedStacks.append(viewerStack)
        viewerStack = child
        postStackChange()
    }

    func popToParentStack() {
        if pushedStacks.count > 0 {
            viewerStack = pushedStacks.removeLast()
            postStackChange()
        }
    }
    func popToParentStack(upTo: Int) {
            // usually upTo is negative.. going back up the stack
        let counter = abs(upTo)
        if upTo == 0 { return }
            for _ in 1 ... counter {
                if pushedStacks.count > 0 {
                    viewerStack = pushedStacks.removeLast()
                }
            }
            postStackChange()
    }



    func hasParentStack() -> Bool {
//        NSLog("PGLAppStack #hasParentStack pushedStacks.count = \(pushedStacks.count)")
        return pushedStacks.count > 0
    }

    func getViewerStack() -> PGLFilterStack {
           // see also similar getOutputStack()
            // the return value should not be stored by a caller
            // this value will change to other instances of PGLFilterStack
            // only send messages to the viewStack

           return viewerStack
       }

    func outputFilterStack() -> PGLFilterStack {
        // either the masterDataStack (the current one)
        // or the stack for the output image (another stack!)
        if showFilterImage {
            // looking at the current stack's filter output image
            return viewerStack
        }
        else { // show the final output
            return outputStack

        }
    }

    func setFilterChangeModeToAdd() {
        viewerStack.stackMode = FilterChangeMode.add
    }

    func setFilterChangeModeToReplace() {
        viewerStack.stackMode = FilterChangeMode.replace
    }

    // MARK: Child Stack push/pop

    func moveActiveAhead() {
        // called before the postSelectActiveStackRow
        let startingActiveRow = activeFilterCellRow()
            // viewerStackRow in cellFilters
        let endRow = flatRowCount() - 1 // zero based array
        if startingActiveRow  == endRow {
            return  // don't change now at the end of all the filters
        }
        let  nextRowCell = cellFilters[startingActiveRow + 1 ]

        moveTo(filterIndent: nextRowCell)
    }

    func moveActiveBack() {
        // called before the postSelectActiveStackRow
        let startingActiveRow = activeFilterCellRow()
//        let endRow = flatRowCount() - 1 // zero based array
        if startingActiveRow  == 0 {
            return  // don't change now at start
        }
        let  nextRowCell = cellFilters[startingActiveRow - 1 ]

        moveTo(filterIndent: nextRowCell)
    }

    // MARK: flattened Filters
    // cache the flattenFilters.. reset on filter change.
    func flattenFilters() -> [PGLFilterIndent] {
        // make sure to travers the appStack in the same order
        // adds/deletes of filters require the whole flatten array to regenerate.

        var flatAnswer = [PGLFilterIndent]() // empty
        var level = 0
        var stackIndex = 0
        for aFilter in outputStack.activeFilters {
            flatAnswer.append(PGLFilterIndent(level, aFilter, inStack: outputStack,index: stackIndex))
            level += 1
            aFilter.addChildFilters(level, into: &flatAnswer)
            level -= 1
            stackIndex += 1
        }
        return flatAnswer
    }

    func filterAt(indexPath: IndexPath) -> PGLFilterIndent {
        // each child stack adds one indent
        // 
        return cellFilters[indexPath.row]
    }

    func moveFilter(fromSourceRow: IndexPath, destinationRow: IndexPath ) {

        // empty or just one element}
        // fromSourceRow and destinationRow are indexes to flattenFilter array

        let sourceIndentCell = filterAt(indexPath: fromSourceRow)
        let targetIndentCell = filterAt(indexPath:  destinationRow)

        let sourceStack = sourceIndentCell.stack
        let targetStack = targetIndentCell.stack
            // may be different stacks
            // could be a move from or to a child stack from a parent stack

        let sourceFilter = sourceStack.activeFilters.remove(at: sourceIndentCell.filterPosition)
        targetStack.activeFilters.insert(sourceFilter, at: targetIndentCell.filterPosition)

        // reset the imageInput chain
        // does first filter need inputs set? priorFilter is no longer valid
        // could have inputCollection or a childStack as working input
        if targetIndentCell.filterPosition == 0 {
            if let inputImageAttribute = targetStack.activeFilters[0].getInputImageAttribute(){
                    if inputImageAttribute.imageParmState == ImageParm.inputPriorFilter {
                        inputImageAttribute.setImageParmState(newState: ImageParm.missingInput)
                    }
                }
        }

        for index in 1 ..< targetStack.activeFilters.count {
            let priorFilter = targetStack.activeFilters[index - 1 ]
            let aFilter = targetStack.activeFilters[index]
            aFilter.setInput(image: priorFilter.outputImage(),source: targetStack.stackFilterName(priorFilter, index: index))

            aFilter.setInputImageParmState(newState: ImageParm.inputPriorFilter)
            }


    }

    func activeFilterCellRow() -> Int {
        // answer the cellFilter index for the appStack viewerStack.activeIndex

        let viewerActiveIndex = viewerStack.activeFilterIndex
        return cellFilters.firstIndex(where: {$0.stack === viewerStack && $0.filterPosition == viewerActiveIndex}) ?? 0
    }

    func mapCellRowToStackIndex(index: IndexPath) -> Int {
        // a row click on the filterStack needs to be mapped to the
        // indexRow of the parent or child stack
        // the reverse of activeFilterCellRow
        var stackFilterIndent: PGLFilterIndent?
        if cellFilters.count > index.row - 1 {
             stackFilterIndent = cellFilters[index.row] }
        else { return 0 }
        return stackFilterIndent?.filterPosition ?? 0


    }

    func stackRowCount() -> Int {
        // number of filters including the filters of child stacks
       return outputStack.stackRowCount() // will traverse all filters and child stacks
    }

    func flatRowCount() -> Int {
        // rows including all the rows of childStacks
        return cellFilters.count
    }
    func resetCellFilters() {
        cellFilters = flattenFilters()
    }

    // MARK: Display state
    func resetDrawableSize() {
        for aCellIndent in cellFilters {
            aCellIndent.filter.resetDrawableSize()
        }
    }

    func toggleShowFilterImage() {
        showFilterImage = !showFilterImage
        // if the current filter is a child then update the
        // viewer stack too
    }

    func hasAnimation() -> Bool {
        // return true if any filter in any stack has animation (dissolves, motion.. etc)
        if viewerStack.hasAnimationFilter() { return true}
        else {
            return  pushedStacks.contains { ( aStack: PGLFilterStack) -> Bool in
                aStack.hasAnimationFilter() }
            }
        }


}

class PGLFilterIndent {
    // supports PGLStackController creation of cells in the tableView
    // indent a filter under it's parent

    var level: Int
    var filter: PGLSourceFilter
    var stack: PGLFilterStack
    var filterPosition: Int

    init(_ indent: Int, _ onFilter: PGLSourceFilter, inStack: PGLFilterStack, index: Int) {
        level = indent
        filter = onFilter
        stack = inStack
        filterPosition = index
    }

    var descriptorDisplayName: String {

        if let thisName = filter.descriptorDisplayName  {
            return thisName
        }
        else {
            return filter.localizedName()
        }

    }
}
