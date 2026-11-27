// Licensed under GPL-3.0. See LICENSE.
//
//  TidyDownloadToast.swift
//  LeleleBrowser
//
//  Shown when Tidy Downloads renames a file: the new name, the old one struck through, undo.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserUI

struct TidyDownloadToast: View {
    let download: Download
    let downloads: DownloadManager

    private let visibleFor: Duration = .seconds(6)
    private let maxWidth: CGFloat = 300

    var body: some View {
        HStack(alignment: .top, spacing: LeleleBrowserDesign.Spacing.md) {
            VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.xxs) {
                Text("Download renamed to:")
                    .font(LeleleBrowserDesign.Font.caption)
                    .foregroundStyle(.secondary)
                Text(download.displayName)
                    .font(LeleleBrowserDesign.Font.secondary)
                    .lineLimit(1)
                if let old = download.renamedFrom {
                    Text(old)
                        .font(LeleleBrowserDesign.Font.caption)
                        .foregroundStyle(.tertiary)
                        .strikethrough()
                        .lineLimit(1)
                }
            }
            HStack(spacing: LeleleBrowserDesign.Spacing.xxs) {
                Button("Undo", systemImage: "arrow.uturn.backward") { downloads.undoTidy(download) }
                    .help("Undo")
                Button("Close", systemImage: "xmark") { downloads.dismissTidyToast() }
                    .help("Close")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(LeleleBrowserIconButtonStyle(size: LeleleBrowserDesign.Size.rowButton))
            .foregroundStyle(.secondary)
        }
        .padding(LeleleBrowserDesign.Spacing.lg)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .leleleFloatingSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.xl))
        .task(id: download.id) {
            try? await Task.sleep(for: visibleFor)
            if downloads.lastTidied === download { downloads.dismissTidyToast() }
        }
    }
}
