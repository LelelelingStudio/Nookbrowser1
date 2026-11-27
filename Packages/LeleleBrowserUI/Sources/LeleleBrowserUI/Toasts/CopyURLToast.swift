// Licensed under GPL-3.0. See LICENSE.
//
//  CopyURLToast.swift
//  LeleleBrowser
//
//  Created on 2025-01-XX.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserWeb

public struct CopyURLToast: View {
    @Environment(BrowserWindowState.self) private var windowState: BrowserWindowState?

    private let title: String

    public init(title: String? = nil) {
        self.title = title ?? "Copied Current URL"
    }

    public var body: some View {
        ToastView {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(LeleleBrowserDesign.Font.secondary)
                    .foregroundStyle(.primary)
                    .frame(width: 14, height: 14)
                    .padding(4)
                    .background(LeleleBrowserDesign.Surface.fill)
                    .clipShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.sm))
                    .overlay {
                        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.sm)
                            .stroke(LeleleBrowserDesign.Surface.hairline, lineWidth: 1)
                    }

                Text(title)
                    .font(LeleleBrowserDesign.Font.secondary)
                    .foregroundStyle(.primary)
            }
        }
        .transition(.toast)
        .onAppear {
            // Auto-dismiss after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                windowState?.isShowingCopyURLToast = false
            }
        }
        .onTapGesture {
            windowState?.isShowingCopyURLToast = false
        }
    }
}

