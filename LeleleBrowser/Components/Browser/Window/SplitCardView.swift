// Licensed under GPL-3.0. See LICENSE.
//
//  SplitCardView.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 09/12/2025.
//

import SwiftUI
import LeleleBrowserDesign

struct SplitCardView: View {
    var icon: String
    var text: String
    var isTabHovered: Bool
    var accentColor: Color = .blue
    
    private var currentTextColor: Color {
        isTabHovered ? accentColor : .white
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(LeleleBrowserDesign.Font.heading)
                    .foregroundStyle(currentTextColor)
                Text(text)
                    .font(LeleleBrowserDesign.Font.secondary)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(currentTextColor)
                    .frame(maxWidth: .infinity)
            }
            .opacity(0.6)
            
            LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                .strokeBorder(currentTextColor, style: StrokeStyle(lineWidth: 2, dash: [7,10]))
                .opacity(0.3)
        }
        .frame(width: 237, height: 394)
        .padding(8)
        .background(
            Color(currentTextColor)
                .opacity(0.1)
        )
        .leleleFloatingSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
        .animation(LeleleBrowserDesign.Motion.standard, value: currentTextColor)
    }
}
