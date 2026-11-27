// Licensed under GPL-3.0. See LICENSE.
//
//  LeleleBrowseriOSApp.swift
//  LeleleBrowseriOS
//

import SwiftUI
import LeleleBrowserUI

@main
struct LeleleBrowseriOSApp: App {
    @StateObject private var model = BrowserModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .leleleEnvironment(model)
        }
    }
}

extension View {
    /// Everything the shared rows, menus and settings bodies read. Sheets do not
    /// inherit these, so the sheet contents apply the same modifier.
    func leleleEnvironment(_ model: BrowserModel) -> some View {
        self
            .environmentObject(model)
            .environment(model.tabs)
            .environment(model.window)
            .environment(model.windowRegistry)
            .environment(model.settings)
            .environment(\.leleleSettings, model.settings)
            .environment(\.tabActions, model)
            .environment(\.contentBlocker, model.blocker)
            .environment(\.siteRouting, model.siteRouting)
    }
}
