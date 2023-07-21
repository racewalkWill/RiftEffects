//
//  PGLStackTypeList.swift
//  RiftEffects
//
//  Created by Will on 7/19/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import SwiftUI

struct PGLStackTypeName: Identifiable {
    var id = UUID()
    var name: String

}

var listElements = [
        "14may23",
      "DemoApr23",
      "Jul23",
      "May23",
      "Page test1",
      "Random Filters",
      "Sept22",
      "dark",
      "demo",
      "demo 2023",
      "demo May23",
     "demo segmentation ",
     "demo2",
     "demoApr23",
     "feb27-2023",
     "input",
     "jul23",
     "jun23",
     "line morphology",
     "mar22",
     "mar23",
     "may23",
     "promo",
     "test",
     "type",
     "unusual",
     "unusual "  ] .map({PGLStackTypeName(name: $0)})

struct PGLStackTypeList: View {
    @State private var singleSelection: UUID?

    var stackTypeNames: [PGLStackTypeName]
    

    var body: some View {
        List(selection: $singleSelection) { ForEach(stackTypeNames) { name in
            Text(name.name)
        }}

        }
}


struct PGLStackTypeList_Previews: PreviewProvider {
    static var previews: some View {
        PGLStackTypeList(stackTypeNames: listElements)
    }
}
