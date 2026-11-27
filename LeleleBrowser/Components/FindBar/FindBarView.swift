// Licensed under GPL-3.0. See LICENSE.
//
//  FindBarView.swift
//  LeleleBrowser
//
//  Created by Jonathan Caudill on 28/12/2024.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserUI

struct FindBarView: View {
    @ObservedObject var findManager: FindManager
    @FocusState private var isTextFieldFocused: Bool

    // Hover states for buttons
    @State private var isUpButtonHovered = false
    @State private var isDownButtonHovered = false
    @State private var isCloseButtonHovered = false

    var body: some View {
        // Transparent background for tap-outside-to-dismiss
        ZStack {
            // Use a GeometryReader to place tap area only around the findbar
            Color.clear
                .allowsHitTesting(false)

            VStack {
                HStack {
                    Spacer()
                    HStack(spacing: 8) {
                        // Search icon + text field - integrated without sub-box
                        HStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(LeleleBrowserDesign.Font.body)

                            TextField("Find in page", text: $findManager.searchText)
                                .textFieldStyle(.plain)
                                .font(LeleleBrowserDesign.Font.body)
                                .frame(width: 160)
                                .focused($isTextFieldFocused)
                                .onSubmit {
                                    findManager.findNext()
                                }
                                .onChange(of: findManager.searchText) { _, newValue in
                                    findManager.search(for: newValue, in: findManager.currentSession)
                                }
                        }

                        // Match count - always present to maintain consistent width
                        Group {
                            if findManager.matchCount > 0 {
                                Text("\(findManager.currentMatchIndex) of \(findManager.matchCount)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if !findManager.searchText.isEmpty {
                                Text("0/0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                // Placeholder to maintain width when empty
                                Text("0/0")
                                    .font(.caption)
                                    .foregroundColor(.clear)
                            }
                        }
                        .frame(minWidth: 40)

                        Divider()
                            .frame(height: 16)

                        // Navigation buttons - with hover reactivity
                        HStack(spacing: 2) {
                            Button(action: {
                                findManager.findPrevious()
                            }) {
                                Image(systemName: "chevron.up")
                                    .font(LeleleBrowserDesign.Font.caption)
                                    .frame(width: 22, height: 22)
                                    .background(isUpButtonHovered ? Color.secondary.opacity(0.2) : Color.clear)
                                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xs))
                            }
                            .buttonStyle(.plain)
                            .disabled(findManager.searchText.isEmpty)
                            .onHoverTracking { hovering in
                                withAnimation(LeleleBrowserDesign.Motion.hover(hovering)) {
                                    isUpButtonHovered = hovering
                                }
                            }

                            Button(action: {
                                findManager.findNext()
                            }) {
                                Image(systemName: "chevron.down")
                                    .font(LeleleBrowserDesign.Font.caption)
                                    .frame(width: 22, height: 22)
                                    .background(isDownButtonHovered ? Color.secondary.opacity(0.2) : Color.clear)
                                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xs))
                            }
                            .buttonStyle(.plain)
                            .disabled(findManager.searchText.isEmpty)
                            .onHoverTracking { hovering in
                                withAnimation(LeleleBrowserDesign.Motion.hover(hovering)) {
                                    isDownButtonHovered = hovering
                                }
                            }
                        }

                        Divider()
                            .frame(height: 16)

                        // Close button - with hover reactivity
                        Button(action: {
                            findManager.hideFindBar()
                        }) {
                            Image(systemName: "xmark")
                                .font(LeleleBrowserDesign.Font.caption)
                                .frame(width: 22, height: 22)
                                .background(isCloseButtonHovered ? Color.secondary.opacity(0.2) : Color.clear)
                                .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xs))
                        }
                        .buttonStyle(.plain)
                        .onHoverTracking { hovering in
                            withAnimation(LeleleBrowserDesign.Motion.hover(hovering)) {
                                isCloseButtonHovered = hovering
                            }
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .leleleFloatingSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xl))
                    .padding(.trailing, 16)
                }
                .padding(.top, 12)

                Spacer()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        findManager.hideFindBar()
                    }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Fade and blur out on hide
        .opacity(findManager.isFindBarVisible ? 1 : 0)
        .blur(radius: findManager.isFindBarVisible ? 0 : 8)
        .allowsHitTesting(findManager.isFindBarVisible)
        .animation(LeleleBrowserDesign.Motion.standard, value: findManager.isFindBarVisible)
        // Focus management
        .onChange(of: findManager.isFindBarVisible) { _, isVisible in
            if isVisible {
                DispatchQueue.main.async {
                    isTextFieldFocused = true
                }
            } else {
                isTextFieldFocused = false
            }
        }
    }
}
