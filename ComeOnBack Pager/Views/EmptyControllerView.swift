//
//  EmptyControllerView.swift
//  ComeOnBack
//
//  Created by Calvin Shultz on 7/9/23.
//
//  A one-line empty state that sits at the top of its column, where the first row
//  would be — not a full-column placeholder that dominates the board.
//

import SwiftUI

struct EmptyControllerView: View {
    var message = "No controllers"

    var body: some View {
        Label(message, systemImage: "person.fill.xmark")
            .font(.body.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: BoardColumns.rowHeight)
            .background(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(Color.tileFill, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.xs)
            .frame(maxHeight: .infinity, alignment: .top)
    }
}

struct EmptyControllerView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyControllerView(message: "No one on position")
    }
}
