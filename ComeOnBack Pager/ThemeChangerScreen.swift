//
//  ThemeChanger.swift
//  ComeOnBack Pager
//
//  Created by Calvin Shultz on 12/28/24.
//

import SwiftUI

struct ThemeChangerScreen: View {
    
    @Environment(\.colorScheme) private var scheme
    @AppStorage("user_theme") private var userTheme: Theme = .dark
    @AppStorage("user_brightness_setting") private var userBrightness: Double = 1.0
    @Namespace private var animation
    
    @Binding var screenBrightness: Double
        
    var body: some View {
        VStack(spacing: 15) {
            
            Text("Choose a Style")
                .font(.title2.bold())
                .padding(.top, 25)
                .foregroundStyle(Color.black)
                .bold()
            
            HStack(spacing: 0) {
                ForEach(Theme.allCases, id: \.rawValue) { theme in
                    Text(theme.rawValue)
                        .padding(.vertical, 10)
                        .frame(width: 100)
                        .foregroundStyle(Color.black)
                        .background {
                            ZStack {
                                if userTheme == theme {
                                    Capsule()
                                        .fill(.white)
                                        .matchedGeometryEffect(id: "ACTIVETAB", in: animation)
                                }
                            }
                            .animation(.snappy, value: userTheme)
                        }
                        .contentShape(.rect)
                        .onTapGesture {
                            userTheme = theme
                        }
                }
            } // HStack
            .padding(3)
            .background(.gray.opacity(0.2), in: .capsule)
            .padding(.top, 20)
            
            VStack(spacing: -5) {
                Text("Brightness")
                    .font(.title2.bold())
                    .foregroundStyle(Color.black)
                Slider(value: $screenBrightness, in: 0.0...1.0)
                    .frame(width: 300)
                    .padding()
            }
            .padding(.top, 20)
            
            
            
        } // VStack
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: 500)
        .background(Color.white)
        .clipShape(.rect(cornerRadius: 30))

        
        
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

