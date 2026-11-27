// Licensed under GPL-3.0. See LICENSE.
//
//  BrowserConfig.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 31/07/2025.
//

import SwiftUI
import WebKit
import LeleleBrowserBlocker

public class BrowserConfiguration {
    public static let shared = BrowserConfiguration()
    
    private init() {}
    
    public lazy var webViewConfiguration: WKWebViewConfiguration = {
        let config = WKWebViewConfiguration()
        #if os(macOS)
        BrowserConfiguration.applyProcessPool(to: config)
        #endif

        // Use default website data store for normal browsing
        // Extensions use their own separate persistent storage managed by Apple
        config.websiteDataStore = WKWebsiteDataStore.default()

        // Configure JavaScript preferences for extension support
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        config.defaultWebpagePreferences = preferences

        // Core WebKit preferences for extensions
        config.preferences.javaScriptCanOpenWindowsAutomatically = false

        // Media settings — use macOS default (no restrictions, matching Safari behavior).
        // [.audio] blocks programmatic play() for media with audio tracks, which breaks
        // YouTube autoplay since SPA navigations call play() outside user-gesture context.
        config.mediaTypesRequiringUserActionForPlayback = []
        
        // "mediaDevicesEnabled" stays unset: it crashes WebContent (sandbox-denied AudioComponentRegistrar).
        // Pages still get mic and camera from the Info.plist usage strings and device entitlements.

        // CRITICAL: Enable HTML5 Fullscreen API
        config.preferences.isElementFullscreenEnabled = true

        // Enable background media playback
        config.allowsAirPlayForMediaPlayback = true
        
        // User agent for better compatibility with Client Hints support
        #if os(macOS)
        config.applicationNameForUserAgent = "Chrome/142.0.0.0 Safari/537.36"
        #else
        config.applicationNameForUserAgent = "Version/\(PlatformUserAgent.safariVersion) Mobile/15E148 Safari/604.1"
        #endif

        #if os(macOS)
        // Google sign-in rejects bare WKWebView clients. Match the network UA with the JS-visible
        // identity and client hints so accounts.google.com treats the page as a supported browser.
        if let agent = PlatformUserAgent.custom {
            config.userContentController.addUserScript(
                WKUserScript(
                    source: Self.chromeIdentityScript(userAgent: agent),
                    injectionTime: .atDocumentStart,
                    forMainFrameOnly: false
                )
            )
        }
        #endif

        // Clipboard, picture-in-picture, inline playback and the inspector are spelled differently
        // per platform; see BrowserConfig+macOS.swift and BrowserConfig+iOS.swift.
        BrowserConfiguration.applyPlatformPreferences(to: config)

        // Note: webExtensionController will be set by ExtensionManager during initialization

        // MARK: Passkeys
        // Do not override WebAuthn feature detection. Sites need the real capability result so
        // Google and others can offer passkeys when WebKit/AuthenticationServices support them.
        // Full platform authenticator support in a third-party browser still requires Apple's
        // com.apple.developer.web-browser.public-key-credential entitlement in a signed build.
        return config
    }()

    /// Optional hook for ContentBlockerManager to apply rule lists to new controllers.
    public var contentRuleListApplicator: ((WKUserContentController) -> Void)?

    // MARK: - Fresh User Content Controller
    // Creates a fresh WKUserContentController but preserves LeleleBrowser's own shared
    // user scripts. This avoids cross-tab handler conflicts while keeping
    // scripts that must be present on every tab.
    //
    // Only LeleleBrowser-owned scripts are copied. WKWebExtensionController injects its
    // content scripts into every new controller itself, so copying them here as
    // well would hand each new tab two of each. See WKUserScript+LeleleBrowserOwned.
    public func freshUserContentController() -> WKUserContentController {
        let controller = WKUserContentController()
        for script in webViewConfiguration.userContentController.userScripts.leleleOwned {
            controller.addUserScript(script)
        }
        // Apply content blocker rule lists if available
        contentRuleListApplicator?(controller)
        return controller
    }

    // MARK: - Cache-Optimized Configuration
    // Derives from shared config to preserve process pool + extension controller
    public func cacheOptimizedWebViewConfiguration() -> WKWebViewConfiguration {
        let config = webViewConfiguration.copy() as! WKWebViewConfiguration
        config.userContentController = freshUserContentController()
        return config
    }

    // MARK: - Profile-Aware Configurations
    // Derive from the shared config so extension controller + process pool are inherited
    @MainActor
    /// `base` is the configuration of the page's extension set; nil is the shared one.
    public func webViewConfiguration(for profile: Profile, base: WKWebViewConfiguration? = nil) -> WKWebViewConfiguration {
        let config = (base ?? webViewConfiguration).copy() as! WKWebViewConfiguration

        // Fresh UCC per tab to avoid cross-tab handler conflicts (preserves shared scripts)
        config.userContentController = freshUserContentController()

        // Use the profile's website data store for isolation
        // Private pages keep the controller; WebKit runs only extensions with
        // `hasAccessToPrivateData` in a non-persistent store's pages.
        config.websiteDataStore = profile.dataStore

        return config
    }

    // MARK: - Chrome Web Store Integration
    
    /// Get the Web Store injector script
    public static func webStoreInjectorScript() -> WKUserScript? {
        guard let scriptPath = Bundle.main.path(forResource: "WebStoreInjector", ofType: "js"),
              let scriptSource = try? String(contentsOfFile: scriptPath, encoding: .utf8) else {
            return nil
        }
        
        return WKUserScript(
            source: scriptSource,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
    }

    private static func chromeIdentityScript(userAgent: String) -> String {
        let ua = javaScriptLiteral(userAgent)
        return """
        (function() {
          try {
            Object.defineProperty(navigator, 'userAgent', {
              configurable: true,
              get: function() { return \(ua); }
            });
          } catch (e) {}

          try {
            if (!window.chrome) window.chrome = {};
            if (!window.chrome.runtime) window.chrome.runtime = {};
            if (!window.chrome.loadTimes) window.chrome.loadTimes = function() { return {}; };
            if (!window.chrome.csi) window.chrome.csi = function() { return {}; };
          } catch (e) {}

          try {
            var brands = [
              {brand: 'Not A;Brand', version: '99'},
              {brand: 'Chromium', version: '142'},
              {brand: 'Google Chrome', version: '142'}
            ];
            Object.defineProperty(navigator, 'userAgentData', {
              configurable: true,
              value: {
                brands: brands,
                mobile: false,
                platform: 'macOS',
                getHighEntropyValues: function() {
                  return Promise.resolve({
                    architecture: 'arm',
                    bitness: '64',
                    model: '',
                    platformVersion: '15.5.0',
                    fullVersionList: brands,
                    wow64: false
                  });
                }
              }
            });
          } catch (e) {}
        })();
        """
    }

    private static func javaScriptLiteral(_ value: String) -> String {
        guard let data = try? JSONEncoder().encode(value),
              let literal = String(data: data, encoding: .utf8) else { return "\"\"" }
        return literal
    }
}
