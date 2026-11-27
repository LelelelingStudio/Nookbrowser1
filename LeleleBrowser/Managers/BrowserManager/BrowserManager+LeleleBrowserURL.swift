// Licensed under GPL-3.0. See LICENSE.
//
//  BrowserManager+LeleleBrowserURL.swift
//  LeleleBrowser
//

import AppKit
import LeleleBrowserWeb
import OSLog

private let leleleURLLog = Logger(subsystem: "com.leleleling.browser", category: "LeleleBrowserURL")

extension BrowserManager {
    /// Runs a lelele:// link from another app. Dropped unless Settings > Links allows it.
    func handleLeleleBrowserURL(_ link: URL) {
        guard leleleSettings?.allowLeleleBrowserURLs == true else {
            leleleURLLog.info("Dropped lelele:// link: not allowed in Settings")
            return
        }
        guard let command = LeleleBrowserURLCommand.parse(link) else {
            leleleURLLog.info("Ignored lelele:// link: \(link.host ?? "", privacy: .public) is not a valid command")
            return
        }
        if !command.ignored.isEmpty {
            leleleURLLog.info("Ignored lelele:// parameters: \(command.ignored.joined(separator: ","), privacy: .public)")
        }

        var spaceID: UUID?
        if let name = command.space {
            let choices = tabs.orderedSpaces.filter { !$0.isAgent }.map { (id: $0.id, name: $0.name) }
            guard let match = LeleleBrowserURLCommand.match(name, in: choices) else {
                leleleURLLog.info("Ignored lelele:// link: no such space")
                return
            }
            spaceID = match
        }
        guard let window = openBrowserWindow(), !window.isIncognito else { return }
        // A window showing the Agent space opens into the first ordinary one.
        if spaceID == nil, window.spaceID.flatMap({ tabs.space($0) })?.isAgent == true {
            spaceID = tabs.orderedSpaces.first { !$0.isAgent }?.id
        }

        switch command.action {
        case .switchSpace:
            if let spaceID { tabs.setSpace(spaceID, in: window) }
        case .open(let url, let reuse):
            openFromLauncher(url, reuse: reuse, space: spaceID, explicit: command.space != nil, in: window)
        case .search(let query):
            guard let template = leleleSettings?.resolvedSearchEngineTemplate,
                  let url = LeleleBrowserURLCommand.searchURL(for: query, template: template) else { return }
            openFromLauncher(url, reuse: false, space: spaceID, explicit: command.space != nil, in: window)
        }
    }

    private func openFromLauncher(_ url: URL, reuse: Bool, space: UUID?, explicit: Bool, in window: BrowserWindowState) {
        if reuse, let target = space ?? window.spaceID,
           let existing = tabs.items(inSpace: target).first(where: { $0.url.map { LeleleBrowserURLCommand.isSamePage($0, url) } == true }) {
            tabs.select(existing.id, in: window)
            return
        }
        // Air Traffic Control only decides when the link names no space.
        if !explicit, siteRoutingManager.applyRoute(url: url, from: nil) { return }
        tabs.open(url: url, in: window, placement: .newTab, parent: space.map { .tabs(spaceID: $0) })
    }
}
