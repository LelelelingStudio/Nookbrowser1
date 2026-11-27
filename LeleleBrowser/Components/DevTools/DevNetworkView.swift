// Licensed under GPL-3.0. See LICENSE.
//
//  DevNetworkView.swift
//  LeleleBrowser
//
//  Network tab: fetch and XHR with headers and bodies, everything else from Resource Timing.
//

import AppKit
import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserWeb
import LeleleBrowserUI

struct DevNetworkView: View {
    let capture: DevCapture?
    let session: PageSession?
    @EnvironmentObject var browserManager: BrowserManager

    @State private var search = ""
    @State private var selectedID: Int?

    var body: some View {
        if let capture {
            VStack(spacing: 0) {
                HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
                    TextField("Filter", text: $search)
                        .textFieldStyle(.plain)
                        .font(LeleleBrowserDesign.Font.secondary)
                        .padding(.horizontal, LeleleBrowserDesign.Spacing.sm)
                        .frame(height: LeleleBrowserDesign.Size.iconButton)
                        .leleleControlSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
                }
                .padding(LeleleBrowserDesign.Spacing.md)

                List(visible(capture), selection: $selectedID) { entry in
                    DevNetworkRow(entry: entry).tag(entry.id)
                        .contextMenu {
                            Button("Send to Agent") {
                                browserManager.handOff(DevPick(markdown: DevHandoff.markdown(network: entry, pageURL: session?.url.absoluteString)), from: session)
                            }
                        }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                if let id = selectedID, let entry = capture.network.items.first(where: { $0.id == id }) {
                    Divider()
                    DevNetworkDetail(entry: entry)
                        .frame(maxHeight: LeleleBrowserDesign.Size.sheetSmallHeight)
                }
            }
        } else {
            DevPanelEmpty()
        }
    }

    private func visible(_ capture: DevCapture) -> [DevNetworkEntry] {
        let term = search.lowercased()
        guard !term.isEmpty else { return capture.network.items }
        return capture.network.items.filter { $0.url.lowercased().contains(term) || $0.kind.contains(term) }
    }
}

private struct DevNetworkRow: View {
    let entry: DevNetworkEntry

    private var statusText: String {
        switch entry.state {
        case .pending: return "…"
        case .failed: return "✕"
        case .done: return entry.status.map(String.init) ?? "–"
        }
    }

    private var failed: Bool { entry.state == .failed || (entry.status ?? 0) >= 400 }

    var body: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Text(statusText)
                .font(LeleleBrowserDesign.Font.caption.monospacedDigit())
                .foregroundStyle(failed ? .red : .secondary)
                .frame(width: LeleleBrowserDesign.Size.iconButton, alignment: .leading)
            VStack(alignment: .leading, spacing: 0) {
                Text(entry.name)
                    .font(LeleleBrowserDesign.Font.secondary)
                    .foregroundStyle(failed ? .red : .primary)
                    .lineLimit(1)
                Text("\(entry.method) · \(entry.kind)")
                    .font(LeleleBrowserDesign.Font.caption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
            if let ms = entry.duration {
                Text("\(Int(ms.rounded())) ms")
                    .font(LeleleBrowserDesign.Font.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DevNetworkDetail: View {
    let entry: DevNetworkEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.md) {
                Text(entry.url)
                    .font(LeleleBrowserDesign.Font.secondary.monospaced())
                    .textSelection(.enabled)
                if let error = entry.error {
                    Text(error).font(LeleleBrowserDesign.Font.secondary).foregroundStyle(.red)
                }
                if entry.hasDetail {
                    Button("Copy as cURL") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(entry.curl, forType: .string)
                    }
                    .buttonStyle(RectNavButtonStyle())
                    headers("Request Headers", entry.requestHeaders)
                    body("Request Body", entry.requestBody)
                    headers("Response Headers", entry.responseHeaders)
                    body("Response Body", entry.responseBody)
                } else {
                    Text("Loads started by the page's HTML carry no headers here. Use Web Inspector.")
                        .font(LeleleBrowserDesign.Font.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LeleleBrowserDesign.Spacing.md)
        }
    }

    @ViewBuilder
    private func headers(_ title: String, _ values: [String: String]) -> some View {
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.xxs) {
                Text(title).font(LeleleBrowserDesign.Font.captionStrong).foregroundStyle(.secondary)
                ForEach(values.sorted(by: { $0.key < $1.key }), id: \.key) { name, value in
                    Text("\(name): \(value)")
                        .font(LeleleBrowserDesign.Font.caption.monospaced())
                        .textSelection(.enabled)
                }
            }
        }
    }

    @ViewBuilder
    private func body(_ title: String, _ text: String?) -> some View {
        if let text, !text.isEmpty {
            VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.xxs) {
                Text(title).font(LeleleBrowserDesign.Font.captionStrong).foregroundStyle(.secondary)
                Text(text)
                    .font(LeleleBrowserDesign.Font.caption.monospaced())
                    .lineLimit(40)
                    .textSelection(.enabled)
            }
        }
    }
}
