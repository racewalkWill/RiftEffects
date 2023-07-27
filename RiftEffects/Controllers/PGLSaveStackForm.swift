//
//  PGLSaveStackForm.swift
//  RiftEffects
//
//  Created by Will on 7/26/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import SwiftUI

struct PGLSaveStackForm: View {
    @ObservedObject var saveData: PGLStackSaveData
    @State var title = "Library"
    var body: some View {

        Form  {
            TextField("Name", text: $saveData.stackName)
            TextField("Album", text: $saveData.stackType)
            Toggle("Photos Library", isOn: $saveData.storeToPhoto)
            Button("Save", action: saveStack)
        }
    }
}

func saveStack() {

}


struct PGLSaveStackForm_Previews: PreviewProvider {
    @State static var myData = PGLStackSaveData()


    static var previews: some View {

        PGLSaveStackForm(saveData: myData)
    }
}
