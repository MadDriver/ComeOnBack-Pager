//
//  ThemeChanger.swift
//  ComeOnBack Pager
//
//  Created by Calvin Shultz on 12/28/24.
//

import SwiftUI

struct ThemeChangerScreen: View {

    @Environment(\.dismiss) private var dismiss
    @AppStorage("user_theme") private var userTheme: Theme = .dark
    @Namespace private var animation

    @Binding var screenBrightness: Double

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionHeader("Theme")
                    HStack(spacing: 0) {
                        ForEach(Theme.allCases, id: \.rawValue) { theme in
                            Text(theme.rawValue)
                                .fontWeight(.semibold)
                                .padding(.vertical, Spacing.sm)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(userTheme == theme ? Color.white : Color.primary)
                                .background {
                                    if userTheme == theme {
                                        Capsule()
                                            .fill(Color.accentColor)
                                            .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                    }
                                }
                                .contentShape(.capsule)
                                .onTapGesture {
                                    withAnimation(.snappy) { userTheme = theme }
                                }
                        }
                    } // HStack
                    .padding(Spacing.xs)
                    .background(Color.tileFill, in: .capsule)
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SectionHeader("Brightness")
                    Slider(value: $screenBrightness, in: 0.0...1.0)
                }

                Spacer()
            } // VStack
            .padding(Spacing.xl)
            .navigationTitle("Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ThemeChangerScreen(screenBrightness: .constant(1.0))
}

enum Theme: String, CaseIterable {
    
    case light = "Light"
    case dark = "Dark"
    
    func color(_ scheme: ColorScheme) -> Color {
        switch self {
        case .light:
            return .purple
        case .dark:
            return .red
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

