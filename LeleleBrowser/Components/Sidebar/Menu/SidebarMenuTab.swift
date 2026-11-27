// Licensed under GPL-3.0. See LICENSE.
//
//  SidebarMenuTab.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 23/09/2025.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserWeb
import LeleleBrowserUI

struct SidebarMenuTab: View {
    var image: String
    var activeImage: String
    var title: String
    var isActive: Bool = true
    let action: () -> Void
    @State private var isHovering: Bool = false
    @State private var shouldWiggle: Bool = false

    private let height: CGFloat = 80

    var body: some View {
        Button {
            action()
            shouldWiggle.toggle()
        } label: {
            label
        }
        .buttonStyle(.plain)
        .onHoverTracking { state in
            isHovering = state
        }
    }

    private var label: some View {
        VStack(spacing: LeleleBrowserDesign.Spacing.md) {
            Image(systemName: isActive ? activeImage : image)
                .font(LeleleBrowserDesign.Font.titleLarge)
                .foregroundStyle(isActive ? .green : .primary)
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.wiggle, value: shouldWiggle)
                .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))

            Text(title)
                .font(LeleleBrowserDesign.Font.secondary)
                .foregroundStyle(.primary)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
        // The chosen tab takes the selected sidebar row's surface, so it takes no hover fill.
        .background(!isActive && isHovering ? LeleleBrowserDesign.Surface.fill : .clear, in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xl))
        .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xl))
        .leleleRowSelection(isActive, radius: LeleleBrowserDesign.Radius.xl)
        .animation(LeleleBrowserDesign.Motion.hover(isHovering), value: isHovering)
        .animation(LeleleBrowserDesign.Motion.standard, value: isActive)
    }
}
