// Licensed under GPL-3.0. See LICENSE.
//
//  BoostOverlay.swift
//  LeleleBrowser
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserSettings
import LeleleBrowserTweaks
import LeleleBrowserUI
import LeleleBrowserWeb

/// The Boost panel, drawn in the window over the page's top-right corner. Only the panel takes
/// clicks, so the page stays usable for Zap. In-window like `ExtensionLibraryOverlay`.
struct BoostOverlay: View {
    @EnvironmentObject var browserManager: BrowserManager
    @Environment(BrowserWindowState.self) private var windowState

    private var session: PageSession? { browserManager.tabs.selectedSession(in: windowState) }

    var body: some View {
        content.task(id: windowState.isBoostPanelVisible) { await browserManager.leleleSettings?.waitForBoosts() }
    }

    @ViewBuilder private var content: some View {
        if windowState.isBoostPanelVisible, let settings = browserManager.leleleSettings, settings.boostsLoaded, let session,
           case let host = Boost.normalizeHost(session.url.host ?? ""), !host.isEmpty
        {
            BoostPanel(
                settings: settings,
                host: host,
                onPreview: { draft in
                    guard let webView = session.webView else { return }
                    BoostTweaks.preview(for: session.url, in: webView, settings: settings, draft: draft)
                },
                onZap: {
                    guard let webView = session.webView else { return nil }
                    return await BoostTweaks.pickElement(in: webView)
                },
                onCancelZap: { session.webView.map { BoostTweaks.cancelPick(in: $0) } },
                onFinish: { close(session, settings) }
            )
            // A different site is a different panel, with its own draft.
            .id(host)
            .leleleFloatingSurface(in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
            .padding(LeleleBrowserDesign.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.top, LeleleBrowserDesign.Size.row)
            .transition(.opacity)
            .onChange(of: windowState.selectedItemID) { _, _ in close(session, settings) }
        }
    }

    /// Whatever was not saved goes away: the page shows the saved Boosts again, and the zap list
    /// catches up with them.
    private func close(_ session: PageSession, _ settings: LeleleBrowserSettingsService) {
        if let webView = session.webView {
            BoostTweaks.preview(for: session.url, in: webView, settings: settings)
            BoostTweaks.syncZapList(settings: settings, blocker: browserManager.contentBlockerManager)
        }
        windowState.isBoostPanelVisible = false
    }
}
