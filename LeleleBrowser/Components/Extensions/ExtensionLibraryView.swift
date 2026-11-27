// Licensed under GPL-3.0. See LICENSE.
//
//  ExtensionLibraryView.swift
//  LeleleBrowser
//

import AppKit
import os
import SwiftUI
import WebKit

import LeleleBrowserBlocker
import LeleleBrowserDesign
import LeleleBrowserSettings
import LeleleBrowserWeb
import LeleleBrowserUI

struct ExtensionLibraryView: View {
    let browserManager: BrowserManager
    let windowState: BrowserWindowState
    let settings: LeleleBrowserSettingsService
    let onDismiss: () -> Void
    let onShowMoreMenu: () -> Void


    private let logger = Logger(subsystem: "com.lelele.browser", category: "ExtensionLibrary")

    private var currentTab: PageSession? {
        browserManager.tabs.selectedSession(in: windowState)
    }

    private var currentHost: String? {
        currentTab?.url.host
    }

    /// Only web pages can be Boosted.
    private var boostHost: String? {
        guard let url = currentTab?.url, url.scheme == "http" || url.scheme == "https" else { return nil }
        let host = Boost.normalizeHost(url.host ?? "")
        return host.isEmpty ? nil : host
    }

    private let width: CGFloat = 300
    private let columns = Array(repeating: GridItem(.flexible(), spacing: LeleleBrowserDesign.Spacing.sm), count: 4)

    var body: some View {
        VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.lg) {
            actionTiles
            extensionsSection
            settingsSection
            Rectangle().fill(LeleleBrowserDesign.Surface.hairline).frame(height: 1)
            footer
        }
        .padding(LeleleBrowserDesign.Spacing.lg)
        .frame(width: width)
    }

    // MARK: - Actions

    /// Arc's top row: share, Boost, capture, sound.
    private var actionTiles: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.sm) {
            Menu {
                Button("Copy Link", systemImage: "link") {
                    guard let url = currentTab?.url.absoluteString else { return }
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url, forType: .string)
                    onDismiss()
                }
                if let url = currentTab?.url {
                    ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") }
                }
            } label: {
                ActionTileLabel(systemImage: "square.and.arrow.up")
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
            .buttonStyle(ActionTileStyle())
            .help("Share")
            .disabled(currentTab == nil)

            Button {
                browserManager.openBoostPanel(in: windowState)
                onDismiss()
            } label: {
                ActionTileLabel(systemImage: "paintbrush.pointed")
            }
            .buttonStyle(ActionTileStyle())
            .help("Boost")
            .disabled(boostHost == nil)

            Button {
                onDismiss()
                withAnimation(LeleleBrowserDesign.Motion.spring) { windowState.isPortraitCaptureVisible = true }
            } label: {
                ActionTileLabel(systemImage: "camera")
            }
            .buttonStyle(ActionTileStyle())
            .help("Capture")
            .disabled(currentTab == nil)

            MuteButton(tab: currentTab)
        }
    }

    // MARK: - Extensions

    private var extensionsSection: some View {
        VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.sm) {
            Text("Extensions")
                .font(LeleleBrowserDesign.Font.title)

            let extensions = browserManager.extensionManager(for: windowState)?.installedExtensions.filter { $0.isEnabled } ?? []
            LazyVGrid(columns: columns, spacing: LeleleBrowserDesign.Spacing.sm) {
                ForEach(extensions, id: \.id) { ext in
                    ExtensionGridItem(
                        ext: ext,
                        isPinned: settings.pinnedExtensionIDs.contains(ext.id),
                        browserManager: browserManager,
                        windowState: windowState,
                        settings: settings
                    )
                }
                Button(action: openWebStore) {
                    ActionTileLabel(systemImage: "plus", compact: true)
                }
                .buttonStyle(ActionTileStyle())
                .help("Add Extension…")
            }
        }
    }

    // MARK: - Settings

    @State private var contentBlockerEnabled: Bool = true

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.xs) {
            Text("Settings")
                .font(LeleleBrowserDesign.Font.title)
                .padding(.bottom, LeleleBrowserDesign.Spacing.xxs)

            if let host = currentHost {
                SiteSettingRow(
                    icon: "shield.lefthalf.filled",
                    title: "Content Blocker",
                    subtitle: contentBlockerEnabled ? "On" : "Off for this site",
                    isOn: contentBlockerEnabled
                ) {
                    contentBlockerEnabled.toggle()
                    browserManager.contentBlockerManager.allowDomain(host, allowed: !contentBlockerEnabled)
                }
                .onAppear { contentBlockerEnabled = !browserManager.contentBlockerManager.isDomainAllowed(host) }
                .onChange(of: currentHost) { _, newHost in
                    if let newHost { contentBlockerEnabled = !browserManager.contentBlockerManager.isDomainAllowed(newHost) }
                }

                if let tab = currentTab, tab.enhancedFingerprintingProtectionApplies {
                    SiteSettingRow(
                        icon: "hand.raised.fill",
                        title: "Fingerprinting Protection",
                        subtitle: tab.usesEnhancedFingerprintingProtection ? "Enhanced" : "Standard until you leave this site",
                        isOn: tab.usesEnhancedFingerprintingProtection
                    ) {
                        if tab.usesEnhancedFingerprintingProtection {
                            tab.reloadWithoutEnhancedFingerprintingProtection()
                        } else {
                            tab.reloadWithEnhancedFingerprintingProtection()
                        }
                    }
                }

                let developer = settings.isDeveloperSite(host)
                SiteSettingRow(
                    icon: "hammer.fill",
                    title: "Developer Mode",
                    subtitle: developer ? "On" : "Off",
                    isOn: developer
                ) {
                    withAnimation(LeleleBrowserDesign.Motion.spring) { settings.setDeveloperSite(host, on: !developer) }
                }
            }

            SiteSettingRow(
                icon: "pip",
                title: "Automatic Picture-in-Picture",
                subtitle: settings.autoPictureInPicture ? "Allowed" : "Off",
                isOn: settings.autoPictureInPicture
            ) {
                settings.autoPictureInPicture.toggle()
            }

            if currentTab != nil {
                SiteSettingRow(
                    icon: "plus.magnifyingglass",
                    title: "Zoom",
                    subtitle: "\(browserManager.zoomManager.currentZoomPercentage)%",
                    isOn: browserManager.zoomManager.currentZoomPercentage != 100,
                    action: nil
                ) {
                    HStack(spacing: LeleleBrowserDesign.Spacing.xxs) {
                        Button("Zoom Out", systemImage: "minus", action: zoomOut)
                        Button("Zoom In", systemImage: "plus", action: zoomIn)
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(LeleleBrowserIconButtonStyle(size: LeleleBrowserDesign.Size.rowButton + LeleleBrowserDesign.Spacing.xs))
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        let secure = currentTab?.url.scheme == "https"
        return HStack {
            Label(secure ? "Secure" : "Not Secure", systemImage: secure ? "lock.fill" : "lock.open.fill")
                .font(LeleleBrowserDesign.Font.body)
                .padding(.horizontal, LeleleBrowserDesign.Spacing.md)
                .frame(height: LeleleBrowserDesign.Size.row)
                .background(LeleleBrowserDesign.Surface.fill, in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
                .help(currentHost ?? "")

            Spacer()

            Menu {
                Button("Clear Cache") { clear(cache: true) }
                    .disabled(currentHost == nil)
                Button("Clear Cookies") { clear(cache: false) }
                    .disabled(currentHost == nil)
                Divider()
                Button("Manage Boosts…") {
                    browserManager.openSettings(tab: .tweaks)
                    onDismiss()
                }
                Button("New Boost…") {
                    browserManager.openBoostPanel(in: windowState)
                    onDismiss()
                }
                .disabled(boostHost == nil)
                Divider()
                Button("Manage Extensions…") {
                    browserManager.openSettings(tab: .extensions)
                    onDismiss()
                }
                Button("Add Extension…", action: openWebStore)
                Divider()
                Button("All Site Settings…", action: onShowMoreMenu)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: LeleleBrowserDesign.Size.spaceIcon, weight: .semibold))
                    .frame(width: LeleleBrowserDesign.Size.iconButton + LeleleBrowserDesign.Spacing.xs,
                           height: LeleleBrowserDesign.Size.iconButton + LeleleBrowserDesign.Spacing.xs)
                    .background(LeleleBrowserDesign.Surface.fillPressed, in: Circle())
                    .contentShape(Circle())
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .fixedSize()
            .help("More")
        }
    }

    /// Extensions come from the Chrome Web Store, whose pages get LeleleBrowser's install button.
    private func openWebStore() {
        browserManager.tabs.open(url: ExtensionStore.chromeWebStoreURL, in: windowState, placement: .newTab)
        onDismiss()
    }

    private func clear(cache: Bool) {
        guard let host = currentHost else { return }
        Task {
            if cache {
                await browserManager.cacheManager.clearCacheForDomain(host)
            } else {
                await browserManager.cookieManager.deleteCookiesForDomain(host)
            }
        }
        onDismiss()
    }

    // MARK: - Zoom Helpers

    private func zoomIn() {
        guard let tab = currentTab, let webView = tab.webView else { return }
        browserManager.zoomManager.zoomIn(for: webView)
    }

    private func zoomOut() {
        guard let tab = currentTab, let webView = tab.webView else { return }
        browserManager.zoomManager.zoomOut(for: webView)
    }
}

// MARK: - Tiles

/// Arc's square action tile: a raised dark key with a soft top light, pressing in a touch.
private struct ActionTileStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? AnyShapeStyle(.primary) : AnyShapeStyle(.tertiary))
            .background {
                LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                    .fill(configuration.isPressed ? LeleleBrowserDesign.Surface.fillPressed
                          : isHovering && isEnabled ? LeleleBrowserDesign.Surface.fillPressed : LeleleBrowserDesign.Surface.fill)
                    .overlay(alignment: .top) {
                        // The light catching the key's top edge.
                        LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.12), .clear], startPoint: .top, endPoint: .center))
                    }
            }
            .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.lg))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(LeleleBrowserDesign.Motion.quick, value: configuration.isPressed)
            .animation(LeleleBrowserDesign.Motion.hover(isHovering), value: isHovering)
            .onHoverTracking { isHovering = $0 }
    }
}

private struct ActionTileLabel: View {
    let systemImage: String
    var compact = false

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: compact ? LeleleBrowserDesign.Size.spaceIcon : LeleleBrowserDesign.Size.spaceIcon + 4, weight: .regular))
            .contentTransition(.symbolEffect(.replace))
            .frame(maxWidth: .infinity)
            .frame(height: LeleleBrowserDesign.Size.essentialsTile)
    }
}

// MARK: - Mute Button (reactive to tab state)

private struct MuteButton: View {
    let tab: PageSession?

    var body: some View {
        let muted = tab?.isAudioMuted ?? false
        Button {
            tab?.toggleMute()
        } label: {
            ActionTileLabel(systemImage: muted ? "speaker.slash" : "speaker.wave.2")
        }
        .buttonStyle(ActionTileStyle())
        .help(muted ? "Unmute" : "Mute")
        .disabled(tab == nil)
    }
}

// MARK: - Extension Grid Item

private struct ExtensionGridItem: View {
    let ext: InstalledExtension
    let isPinned: Bool
    let browserManager: BrowserManager
    let windowState: BrowserWindowState
    let settings: LeleleBrowserSettingsService

    @State private var isHovering = false
    @State private var badgeText: String?

    private var currentTab: PageSession? {
        browserManager.tabs.selectedSession(in: windowState)
    }

    var body: some View {
        Button {
            triggerExtensionAction()
        } label: {
            Group {
                if let iconPath = ext.iconPath, let nsImage = NSImage(contentsOfFile: iconPath) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: LeleleBrowserDesign.Size.essentialsFavicon + 2, height: LeleleBrowserDesign.Size.essentialsFavicon + 2)
                } else {
                    Image(systemName: "puzzlepiece.extension")
                        .font(LeleleBrowserDesign.Font.title)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: LeleleBrowserDesign.Size.essentialsTile)
            .overlay(alignment: .topTrailing) {
                if let badge = badgeText, !badge.isEmpty {
                    Text(badge)
                        .font(LeleleBrowserDesign.Font.micro)
                        .foregroundStyle(.white)
                        .padding(.horizontal, LeleleBrowserDesign.Spacing.xs)
                        .padding(.vertical, 1)
                        .background(Color.red, in: Capsule())
                        .padding(LeleleBrowserDesign.Spacing.xs)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isPinned {
                    Image(systemName: "pin.fill")
                        .font(LeleleBrowserDesign.Font.micro)
                        .foregroundStyle(.secondary)
                        .padding(LeleleBrowserDesign.Spacing.xs)
                }
            }
        }
        .buttonStyle(ActionTileStyle())
        .help(ext.name)
        .onHoverTracking { isHovering = $0 }
        .onAppear { refreshBadge() }
        .contextMenu {
            if isPinned {
                Button("Unpin from URL Bar") {
                    settings.pinnedExtensionIDs.removeAll { $0 == ext.id }
                }
            } else {
                Button("Pin to URL Bar") {
                    settings.pinnedExtensionIDs.append(ext.id)
                }
            }
        }
        .accessibilityLabel(ext.name)
        .accessibilityHint("Extension. Double-tap to activate.")
        .accessibilityAddTraits(.isButton)
    }

    private func triggerExtensionAction() {
        guard let ctx = ExtensionSetRegistry.shared.manager(for: windowState).getExtensionContext(for: ext.id) else { return }

        if ctx.webExtension.hasBackgroundContent {
            ctx.loadBackgroundContent { error in
                if let error { Logger(subsystem: "com.lelele.browser", category: "ExtensionLibrary").error("Background wake failed: \(error.localizedDescription, privacy: .public)") }
            }
        }

        let adapter = ExtensionSetRegistry.shared.manager(for: windowState).actionAdapter(in: windowState)
        ExtensionSetRegistry.shared.manager(for: windowState).performAction(ctx, for: adapter)
    }

    private func refreshBadge() {
        guard let ctx = ExtensionSetRegistry.shared.manager(for: windowState).getExtensionContext(for: ext.id) else {
            badgeText = nil
            return
        }
        let adapter = ExtensionSetRegistry.shared.manager(for: windowState).actionAdapter(in: windowState)
        badgeText = ctx.action(for: adapter)?.badgeText
    }
}

// MARK: - Site Setting Row

/// Arc's settings row: a round icon, white when the setting is on, a title and its state.
/// Tapping the row flips it; a row with its own controls passes `action: nil`.
private struct SiteSettingRow<Trailing: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    let isOn: Bool
    let action: (() -> Void)?
    @ViewBuilder let trailing: () -> Trailing

    @State private var isHovering = false
    private let iconSize: CGFloat = 32

    var body: some View {
        HStack(spacing: LeleleBrowserDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: LeleleBrowserDesign.Size.spaceIcon, weight: .semibold))
                // On reads as a filled key in either appearance: primary fill, glyph knocked out.
                .foregroundStyle(isOn ? AnyShapeStyle(.background) : AnyShapeStyle(.primary))
                .frame(width: iconSize, height: iconSize)
                .background(isOn ? Color.primary : Color.primary.opacity(0.16), in: Circle())
                .contentTransition(.symbolEffect(.replace))
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(LeleleBrowserDesign.Font.label)
                    .lineLimit(1)
                Text(subtitle)
                    .font(LeleleBrowserDesign.Font.secondary)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
            }
            Spacer(minLength: 0)
            trailing()
        }
        .padding(.horizontal, LeleleBrowserDesign.Spacing.xs)
        .padding(.vertical, LeleleBrowserDesign.Spacing.xs)
        .background(isHovering && action != nil ? LeleleBrowserDesign.Surface.fill : .clear, in: LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
        .contentShape(LeleleBrowserDesign.Radius.shape(LeleleBrowserDesign.Radius.md))
        .onHoverTracking { isHovering = $0 }
        .onTapGesture { withAnimation(LeleleBrowserDesign.Motion.quick) { action?() } }
        .animation(LeleleBrowserDesign.Motion.quick, value: isOn)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(action == nil ? [] : .isButton)
    }
}

extension SiteSettingRow where Trailing == EmptyView {
    init(icon: String, title: String, subtitle: String, isOn: Bool, action: @escaping () -> Void) {
        self.init(icon: icon, title: title, subtitle: subtitle, isOn: isOn, action: action) { EmptyView() }
    }
}
