// Licensed under GPL-3.0. See LICENSE.
//
//  LeleleBrowserSettingsEnvironment.swift
//  LeleleBrowserUI
//
//  The SwiftUI glue LeleleBrowserSettings cannot carry: the settings service lives in a
//  Foundation-only package, so the environment key lives here, where the shared
//  settings bodies and both platforms' app targets all reach one key.
//

import LeleleBrowserSettings
import SwiftUI

private struct LeleleBrowserSettingsServiceKey: EnvironmentKey {
    // SwiftUI reads the default even where the real service is injected; build it once.
    @MainActor
    static let defaultValue = LeleleBrowserSettingsService()
}

extension EnvironmentValues {
    public var leleleSettings: LeleleBrowserSettingsService {
        get { self[LeleleBrowserSettingsServiceKey.self] }
        set { self[LeleleBrowserSettingsServiceKey.self] = newValue }
    }
}
