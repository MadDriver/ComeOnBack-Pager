//
//  EmptyControllerView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/9/23.
//

import SwiftUI

struct EmptyControllerView: View {
    var body: some View {
        VStack {
            Image(systemName: "person.fill.xmark")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
            Text("No Controllers")
                .font(.system(size: 34, weight: .bold))

        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .opacity(0.5)
    }
}

struct EmptyControllerView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyControllerView()
    }
}
