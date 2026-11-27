// Licensed under GPL-3.0. See LICENSE.
//
//  TabClosureToast.swift
//  LeleleBrowser
//
//  Created by Jonathan Caudill on 02/10/2025.
//

import SwiftUI
import LeleleBrowserDesign

public struct TabClosureToast: View {
    @Environment(\.tabActions) private var actions

    private var count: Int { actions?.tabClosureToastCount ?? 0 }

    public init() {}

    public var body: some View {
        ToastView {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
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

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count) tab\(count > 1 ? "s" : "") closed")
                        .font(LeleleBrowserDesign.Font.secondary)
                        .foregroundStyle(.primary)

                    Text("Press ⌘Z to undo")
                        .font(LeleleBrowserDesign.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .transition(.toast)
        .onAppear {
            // Auto-dismiss after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                actions?.hideTabClosureToast()
            }
        }
        .onTapGesture {
            actions?.hideTabClosureToast()
        }
    }
}
