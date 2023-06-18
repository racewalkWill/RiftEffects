//
//  PGLStackItem.swift
//  RiftEffects
//
//  Created by Will on 6/15/23.
//  Copyright © 2023 Will Loew-Blosser. All rights reserved.
//

import SwiftUI

struct PGLStackItem: View {
    var cdStackItem: CDFilterStack

//    @EnvironmentObject var stacks: [CDFilterStack] = PGLStackDataUIProvider.
    var body: some View {
        cdStackItem.thumbnail
            .resizable()
            .aspectRatio(3 / 2, contentMode: .fit)
            .overlay {
                PGLTextOverlay(cdStackItem: cdStackItem)
            }
    }
}

struct PGLTextOverlay: View {
    var cdStackItem: CDFilterStack


    var gradient: LinearGradient {
        .linearGradient(
            Gradient(colors: [.black.opacity(0.6), .black.opacity(0)]),
            startPoint: .bottom,
            endPoint: .center)
    }


    var body: some View {
        ZStack(alignment: .bottomLeading) {
            gradient
            VStack(alignment: .leading) {
                Text(cdStackItem.title ?? "")
                    .font(.title)
                    .bold()
                Text("\(cdStackItem.modified)")
            }
            .padding()
        }
        .foregroundColor(.white)
    }
}

struct PGLStackItem_Previews: PreviewProvider {
    static var previews: some View {
        if let firstStack: CDFilterStack = PGLStackDataUIProvider().firstStack() {

        }

    }
}
