// Licensed under GPL-3.0. See LICENSE.
//
//  LeleleBrowserURLCommandCheck.swift
//  LeleleBrowser
//
//  swiftc Packages/LeleleBrowserWeb/Sources/LeleleBrowserWeb/LeleleBrowserURLCommand.swift \
//         Packages/LeleleBrowserWeb/Checks/LeleleBrowserURLCommandCheck.swift -o /tmp/leleleurl-check && /tmp/leleleurl-check
//

import Foundation

@main
struct LeleleBrowserURLCommandCheck {
    static func parse(_ s: String) -> LeleleBrowserURLCommand? { LeleleBrowserURLCommand.parse(URL(string: s)!) }

    static func main() {
        let open = parse("lelele://open?url=https%3A%2F%2Fexample.com%2Fa%3Fb%3D1%23x&space=Work&reuse=1&junk=2")
        precondition(open?.action == .open(URL(string: "https://example.com/a?b=1#x")!, reuse: true))
        precondition(open?.space == "Work" && open?.ignored == ["junk"])
        precondition(parse("lelele://open?url=http://a.com")?.action == .open(URL(string: "http://a.com")!, reuse: false))
        precondition(parse("LELELE://OPEN?url=https://a.com") != nil)
        precondition(parse("lelele://search?q=hello%20world&space=a")?.action == .search("hello world"))
        precondition(parse("lelele://space?name=Work")?.space == "Work")
        precondition(parse("lelele://open?url=https://a.com&space=") == nil && parse("lelele://open?url=https://a.com&space=%20") == nil)
        precondition(parse("lelele://search?q=a&space=" + String(repeating: "x", count: 9000)) == nil)

        // Hostile or malformed
        for bad in [
            "lelele://open", "lelele://open?url=", "lelele://open?url=file:///etc/passwd",
            "lelele://open?url=javascript:alert(1)", "lelele://open?url=data:text/html,hi",
            "lelele://open?url=lelele://open?url=https://a.com", "lelele://open?url=https://",
            "lelele://open?url=ftp://a.com", "lelele://search", "lelele://search?q=%20", "lelele://space",
            "lelele://quit", "lelele://delete?url=https://a.com", "lelele:///open?url=https://a.com",
            "https://open?url=https://a.com", "lelele://open?url=" + String(repeating: "a", count: 9000),
        ] {
            precondition(parse(bad) == nil, bad)
        }
        // First duplicate wins; reuse only for exactly 1.
        precondition(parse("lelele://open?url=https://a.com&url=file:///x")?.action == .open(URL(string: "https://a.com")!, reuse: false))
        precondition(parse("lelele://open?url=https://a.com&reuse=true")?.action == .open(URL(string: "https://a.com")!, reuse: false))

        // Search URL
        let t = "https://www.google.com/search?q=%@"
        precondition(LeleleBrowserURLCommand.searchURL(for: "a&b c+d", template: t)?.absoluteString == "https://www.google.com/search?q=a%26b%20c%2Bd")
        precondition(LeleleBrowserURLCommand.searchURL(for: "x", template: "javascript:%@") == nil)

        // Space match
        let a = UUID(), b = UUID()
        let spaces = [(id: a, name: "Work"), (id: b, name: "Home")]
        precondition(LeleleBrowserURLCommand.match("work", in: spaces) == a)
        precondition(LeleleBrowserURLCommand.match(b.uuidString.lowercased(), in: spaces) == b)
        precondition(LeleleBrowserURLCommand.match("Wor", in: spaces) == nil)
        precondition(LeleleBrowserURLCommand.match(UUID().uuidString, in: spaces) == nil)

        // Same page
        func same(_ x: String, _ y: String) -> Bool { LeleleBrowserURLCommand.isSamePage(URL(string: x)!, URL(string: y)!) }
        precondition(same("https://A.com/p/#top", "https://a.com/p"))
        precondition(same("https://a.com", "https://a.com/"))
        precondition(!same("https://a.com/p?x=1", "https://a.com/p?x=2"))
        precondition(!same("http://a.com", "https://a.com"))
        print("LeleleBrowserURLCommandCheck passed")
    }
}
