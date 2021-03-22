//
//  PGLAppStack.swift
//  Glance
//
//  Created by Will on 12/8/18.
//  Copyright © 2018 Will Loew-Blosser. All rights reserved.
//

import Foundation

let  PGLStackChange = NSNotification.Name(rawValue: "PGLStackChange")
let PGLSelectActiveStackRow = NSNotification.Name(rawValue: "PGLSelectActiveStackRow")
 // 2021/02/02 PGLSelectActiveStackRow may not be used.. remove?

class PGLAppStack {
    var outputStack: PGLFilterStack
    var viewerStack = PGLFilterStack()
    var pushedStacks = [PGLFilterStack]()
    lazy var cellFilters = self.flattenFilters()
        // flat array of filters in the stack trees

    var showFilterImage = false

   

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
    
    // MARK: Master Data Object Stacks
    func postStackChange() {
        
        let stackNotification = Notification(name:PGLStackChange)
        NotificationCenter.default.post(stackNotification)

    }

    func postSelectActiveStackRow() {
        let rowChange = Notification(name: PGLSelectActiveStackRow)
        NotificationCenter.default.post(rowChange)
    }

    func resetToTopStack(newStack: PGLFilterStack) {
        // new stack loaded from the data store
        // replace current data
        // clear persistentContext of the old context - so that it reloads from data in saved state

       rollbackStack()
            // removes unsaved changes from the NSManagedObjectContext

        viewerStack = newStack
        outputStack = viewerStack // same as init
        pushedStacks = [PGLFilterStack]()
        postStackChange()
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
        NSLog("PGLAppStack #moveTo(filterIndent: \(filterIndent)")
        NSLog("PGLAppStack #moveTo( viewerStack was \(viewerStack)")

        filterIndent.stack.imageCIContext = viewerStack.imageCIContext
        viewerStack = filterIndent.stack
        NSLog("PGLAppStack #moveTo( viewerStack now \(viewerStack)")
        viewerStack.activeFilterIndex = filterIndent.filterPosition
        // remove from pushedStacks???
        pushedStacks.removeAll(where: { $0 === viewerStack })

    }

    func addChildStackTo(parm: PGLFilterAttribute) {
        // the parm takes the output of a set of filters in a filterStack
        // as the visual input
        let  newStack = PGLFilterStack()
       
//        newStack.setStartupDefault() // Images null filter is starting filter
        newStack.stackName = viewerStack.nextStackName()
//        NSLog("addChildStackTo(parm:) newStack.stackName = \(newStack.stackName)")
        newStack.parentAttribute = parm
//        newStack.parentStack = viewerStack
        pushChildStack(newStack)  // make newStack as the current masterDataStack

        parm.inputStack = newStack
        parm.setImageParmState(newState: ImageParm.inputChildStack)
         // Notice the didSet in inputStack: it hooks output of stack to input of the attribute
//        resetCellFilters() // the flattened filter list needs update for the new stack
        postStackChange() // causes resetCellFilters too
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
//            if pushedStacks.isEmpty {
//                return viewerStack
//            }
//            else {
//                return (pushedStacks.first!)
//                // this fails to pick the actual output of all the stacks
//            }
        }
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
        else { fatalError("row in cellFilter is out of range")}
        return stackFilterIndent?.filterPosition ?? 0


    }

    func stackRowCount() -> Int {
        // number of filters including the filters of child stacks
       return outputStack.stackRowCount() // will traverse all filters and child stacks
    }

    func resetCellFilters() {
        cellFilters = flattenFilters()
    }

    // MARK: Display state
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
    var isImageControllerOpen = true { // set to false when PGLAssetGridController or other controllers in the detail are open
        didSet{
            NSLog ("PGLAppStackl isImageControllerOpen = \(isImageControllerOpen)")
            NSLog ("PGLAppStackl isImageControllerOpen oldValue = \(oldValue)")
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
