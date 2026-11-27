// Licensed under GPL-3.0. See LICENSE.
//
//  SearchUtilsCheck.swift
//  LeleleBrowser
//
//  What the URL bar treats as an address and what it searches. LeleleBrowserWeb has no test target, so
//  this compiles the shipped source directly:
//
//    swiftc Packages/LeleleBrowserWeb/Sources/LeleleBrowserWeb/SearchUtils.swift \
//           Packages/LeleleBrowserWeb/Checks/SearchUtilsCheck.swift -o /tmp/search-utils-check && /tmp/search-utils-check
//

import Foundation

@main
struct SearchUtilsCheck {
    static func main() {
        let template = "https://search.example/?q=%@"
        let addresses = [
            "example.com", "example.de", "sub.example.co.uk/path?q=1", "example.com#top", "nas.local:8080",
            "b\u{FC}cher.de", "localhost:3000", "192.168.1.140/Dashboard", "https://x.test/a b",
        ]
        for input in addresses {
            precondition(isLikelyURL(input), "\(input) should be an address")
            precondition(!normalizeURL(input, queryTemplate: template).hasPrefix("https://search.example"), "\(input) should navigate")
        }
        for input in ["3.14", "what.", "asp.net core", "me@example.com", "v1.2", "swift", "a.b"] {
            precondition(!isLikelyURL(input), "\(input) should be a search")
            precondition(normalizeURL(input, queryTemplate: template).hasPrefix("https://search.example"), "\(input) should search")
        }
        precondition(normalizeURL("192.168.1.140", queryTemplate: template) == "http://192.168.1.140")
        precondition(normalizeURL("example.de", queryTemplate: template) == "https://example.de")

        // An open tab goes above the typed row only when what was typed starts its host or title.
        let pull = URL(string: "https://github.com/lelele-browser/LeleleBrowser/pull/429")!
        for typed in ["git", " GitHub ", "github.com", "www.git", "lelele"] {
            precondition(typedStartsTab(typed, title: "lelele-browser/Lelele Browser: open tabs in the palette", url: pull), "\(typed) should lead to the tab")
        }
        precondition(typedStartsTab("you", title: "Video", url: URL(string: "https://www.youtube.com/watch?v=1")!))
        precondition(typedStartsTab("caf", title: "Caf\u{E9} Gratitude", url: URL(string: "https://example.com")!))
        for typed in ["github.com/lelele", "open tabs", "pull", "", "   "] {
            precondition(!typedStartsTab(typed, title: "lelele-browser/Lelele Browser: open tabs in the palette", url: pull), "\(typed) should stay below the typed row")
        }
        print("SearchUtilsCheck passed")
    }
}
