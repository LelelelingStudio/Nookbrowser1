// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarMenuSearchField.swift
//  LeleleBrowser
//

import SwiftUI
import LeleleBrowserDesign

/// The history and downloads search field: a filled squircle the height of the sidebar's controls.
struct SidebarMenuSearchField: View {
    let prompt: LocalizedStringKey
    @Binding var text: String
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(LeleleBrowserDesign.Font.body)
                .foregroundStyle(.secondary)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .font(LeleleBrowserDesign.Font.secondary)
                .foregroundStyle(.primary)
                .focused($isFocused)

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(LeleleBrowserDesign.Font.secondary)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LeleleBrowserDesign.Spacing.lg)
        .frame(height: LeleleBrowserDesign.Size.chromeControl)
        .frame(maxWidth: .infinity)
        .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
        .onTapGesture { isFocused = true }
        .leleleControlSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
    }
}
