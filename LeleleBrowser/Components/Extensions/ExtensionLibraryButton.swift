// Licensed under GPL-3.0. See LICENSE.
//
//  ExtensionLibraryButton.swift
//  LeleleBrowser
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserWeb
import LeleleBrowserUI

struct ExtensionLibraryButton: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState

    var body: some View {
        // Arc's site controls button; the panel springs out of it.
        Button("Site Controls", systemImage: "slider.horizontal.3") {
            withAnimation(.interpolatingSpring(Spring(response: 0.3, dampingRatio: 0.86))) {
                windowState.isExtensionLibraryVisible.toggle()
            }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(LeleleBrowserIconButtonStyle(size: LeleleBrowserDesign.Size.iconButton, radius: LeleleBrowserDesign.Radius.sm))
        .foregroundStyle(Color.primary)
        // The overlay in WindowView hangs off this frame.
        .anchorPreference(key: ExtensionLibraryAnchorKey.self, value: .bounds) { $0 }
    }
}
