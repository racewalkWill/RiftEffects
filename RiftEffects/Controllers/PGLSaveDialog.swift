//
//  PGLSaveDialog.swift
//  RiftEffects
//
//  Created by Will on 7/21/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import SwiftUI

struct PGLSaveDialog: View {
    @ObservedObject var saveData: PGLStackSaveData

    var body: some View {
        PGLSaveStackForm(saveData: saveData)
//        NavigationStack {
//
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    Text("Library Save")
//                }
//                
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button {
//                            //                        config.cancel()
//                    } label: {
//                        Text("Cancel")
//                    }
//                }
//
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button {
//                            //                        config.done()
//                    } label: {
//                        Text("Save")
//                    }
//                }
//            }
//
//        }
    }
}

struct PGLSaveDialog_Previews: PreviewProvider {
   static private var demoName = "Demo"
    static private var demoStack = "Jul23"
    @State static private var demoStackData = PGLStackSaveData()
    static var previews: some View {
        PGLSaveDialog(saveData: demoStackData)
    }
}
