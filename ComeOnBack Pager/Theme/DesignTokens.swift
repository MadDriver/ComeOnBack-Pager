//
//  DesignTokens.swift
//  ComeOnBack Pager
//
//  The shared "ops console" design language: one spacing scale, one radius scale, the
//  semantic colors, and the single section-header style. Everything visual in the app
//  resolves back to these — no ad-hoc opacities, corner radii, or hand-picked colors.
//  The accent ("scope cyan") lives in Assets → AccentColor and is read via
//  `Color.accentColor`.
//

import SwiftUI

/// Spacing scale — the only gaps/paddings used across the app.
enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

/// Corner-radius scale: `chip` for tiles/chips, `card` for cards/large buttons.
enum Radius {
    static let chip: CGFloat = 8
    static let card: CGFloat = 12
}

extension Color {
    /// Neutral, unselected tile/chip fill.
    static let tileFill = Color.primary.opacity(0.08)
    /// Acknowledged / delivered / success.
    static let ackGreen = Color.green
    /// Pending / plan / unassigned / not-yet-acknowledged.
    static let pendingOrange = Color.orange
    // Destructive / error is `Color.red`, used directly and only for genuine danger.
    /// Text/icons that sit on the accent fill. White in light mode (on #0891B2),
    /// dark ink in dark mode (bright accents in dark mode take dark text) — keeps
    /// selected chips legible in both schemes. System `.borderedProminent` buttons
    /// manage their own tint and don't use this.
    static let onAccent = Color("AccentContent")
}

/// The one section-label style: uppercase, secondary, lightly tracked.
struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(.subheadline.weight(.semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}
