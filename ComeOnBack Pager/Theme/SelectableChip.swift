//
//  SelectableChip.swift
//  ComeOnBack Pager
//
//  The one selectable tile used by every picker — canned messages recipients, teams,
//  controllers, positions, and minute presets. Neutral when unselected; accent
//  ("scope cyan") fill + white text when selected. `role` tints the *unselected* fill
//  for a non-neutral slot (e.g. orange for an occupied/unavailable position) — never
//  red for a neutral choice.
//

import SwiftUI

struct SelectableChip: View {
    let label: String
    var icon: String? = nil
    var selected: Bool
    var role: Color? = nil
    var minHeight: CGFloat = 50

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon { Image(systemName: icon) }
            Text(label).fontWeight(.semibold)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity)
        .frame(minHeight: minHeight)
        .padding(.horizontal, Spacing.sm)
        .foregroundStyle(selected ? Color.white : Color.primary)
        .background(fill)
        .clipShape(RoundedRectangle(cornerRadius: Radius.chip, style: .continuous))
        .contentShape(Rectangle())
    }

    private var fill: Color {
        if selected { return .accentColor }
        if let role { return role.opacity(0.18) }
        return .tileFill
    }
}

struct SelectableChip_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            SelectableChip(label: "LC2", selected: false)
            SelectableChip(label: "LC2", selected: true)
            SelectableChip(label: "GC", icon: "phone.fill", selected: false, role: .orange)
        }
        .padding()
    }
}
