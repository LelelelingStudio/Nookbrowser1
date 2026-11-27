// Licensed under GPL-3.0. See LICENSE.
//
//  ShortcutConflictToast.swift
//  LeleleBrowser
//
//  Created by AI Assistant on 2025.
//
//  Toast notification shown when a keyboard shortcut conflicts between
//  LeleleBrowser and a website. Informs users they can press again for LeleleBrowser action.
//

import SwiftUI
import LeleleBrowserDesign

// MARK: - Shortcut Conflict Toast View

public struct ShortcutConflictToast: View {
    /// The shortcut as the user typed it, e.g. "⌘K".
    let shortcut: String
    let websiteName: String
    let leleleActionName: String
    
    public init(
        shortcut: String,
        websiteName: String,
        leleleActionName: String
    ) {
        self.shortcut = shortcut
        self.websiteName = websiteName
        self.leleleActionName = leleleActionName
    }

    public var body: some View {
        ToastView {
            HStack(spacing: 10) {
                // Keyboard icon
                Image(systemName: "keyboard")
                    .font(LeleleBrowserDesign.Font.body)
                    .foregroundStyle(.primary)
                    .frame(width: 18, height: 18)
                    .padding(5)
                    .background(LeleleBrowserDesign.Surface.fill)
                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
                    .overlay {
                        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md)
                            .stroke(LeleleBrowserDesign.Surface.hairline, lineWidth: 1)
                    }
                
                VStack(alignment: .leading, spacing: 2) {
                    // Title: shortcut key used by website
                    HStack(spacing: 4) {
                        Text(shortcut)
                            .font(LeleleBrowserDesign.Font.secondary)
                            .foregroundStyle(.primary)
                        Text("used by")
                            .font(LeleleBrowserDesign.Font.caption)
                            .foregroundStyle(.secondary)
                        Text(websiteName)
                            .font(LeleleBrowserDesign.Font.secondary)
                            .foregroundStyle(.primary)
                    }
                    
                    // Subtitle: press again for LeleleBrowser
                    HStack(spacing: 4) {
                        Text("Press again for")
                            .font(LeleleBrowserDesign.Font.caption)
                            .foregroundStyle(.secondary)
                        Text(leleleActionName)
                            .font(LeleleBrowserDesign.Font.caption)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .transition(.toast)
    }
}

// MARK: - Preview

#Preview {
    ShortcutConflictToast(
        shortcut: "⌘K",
        websiteName: "Figma",
        leleleActionName: "Command Palette"
    )
    .padding()
    .background(Color.gray.opacity(0.3))
}