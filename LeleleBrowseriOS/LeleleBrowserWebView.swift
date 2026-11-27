// Licensed under GPL-3.0. See LICENSE.
//
//  LeleleBrowserWebView.swift
//  LeleleBrowseriOS
//

import WebKit
import LeleleBrowserWeb

/// The session's view on iOS. FocusableWKWebView's job on macOS is focus and the context menu;
/// neither exists here, so this only carries the back-reference the package expects.
@MainActor
final class LeleleBrowserWebView: WKWebView, SessionWebView {
    weak var owningSession: PageSession?
    var contextMenuBridge: WebContextMenuBridge?
    func contextMenuPayloadDidUpdate(_ payload: WebContextMenuPayload?) {}
}
