// Licensed under GPL-3.0. See LICENSE.
//
//  ImportStage.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 19/02/2026.
//

import LeleleBrowserDesign
import LeleleBrowserSettings
import SwiftUI

enum Browsers {
    case arc
    case chrome
    case safari
    case dia
    case firefox
    case zen
}

struct ImportStage: View {
    @Binding var selectedBrowser: Browsers

    var body: some View {
        VStack(spacing: 24) {
            Text(L("Transition to Lelele Browser"))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
                .shadow(color: Color(hex: "#38BDF8").opacity(0.45), radius: 14, y: 0)

            Text(L("Import bookmarks and history to get started."))
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(.white.opacity(0.68))

            HStack(spacing: 24) {
                browserButton(icon: "globe", name: "Arc", browser: .arc)
                browserButton(icon: "safari", name: "Safari", browser: .safari)
                browserButton(icon: "globe", name: "Dia", browser: .dia)
            }
            .padding(.top, 8)
        }
    }

    @ViewBuilder
    private func browserButton(icon: String, name: String, browser: Browsers) -> some View {
        let isSelected = selectedBrowser == browser

        Button {
            selectedBrowser = browser
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                            .fill(isSelected
                                  ? LinearGradient(colors: [Color(hex: "#38BDF8"), Color(hex: "#2563EB")],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                  : LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.06)],
                                                   startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
                    .overlay {
                        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                            .stroke(isSelected ? Color(hex: "#7DD3FC") : Color.white.opacity(0.18),
                                    lineWidth: isSelected ? 1.6 : 1)
                    }
                    .shadow(color: isSelected ? Color(hex: "#38BDF8").opacity(0.4) : .clear,
                            radius: isSelected ? 16 : 0, y: isSelected ? 4 : 0)

                Text(name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(isSelected ? 1 : 0.72))
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
