// Licensed under GPL-3.0. See LICENSE.
// LeleleBrowserDesign is built as a module beside the binary, then linked in:
//
//   D=Packages/LeleleBrowserDesign/Sources/LeleleBrowserDesign; mkdir -p /tmp/x-lib
//   swiftc -swift-version 5 -parse-as-library -emit-module -emit-library -module-name LeleleBrowserDesign \
//          -module-link-name LeleleBrowserDesign $D/*.swift -emit-module-path /tmp/x-lib/LeleleBrowserDesign.swiftmodule \
//          -o /tmp/x-lib/libLeleleBrowserDesign.dylib && \
//   swiftc -swift-version 5 -I /tmp/x-lib -L /tmp/x-lib -lLeleleBrowserDesign -Xlinker -rpath -Xlinker /tmp/x-lib \
//          Packages/LeleleBrowserUI/Sources/LeleleBrowserUI/Spaces/SpaceIconPicker.swift Packages/LeleleBrowserUI/Checks/SpaceIconCheck.swift -o /tmp/x && /tmp/x
@main
struct SpaceIconCheck {
    static func main() {
        for placeholder in ["", "square.grid.2x2", "house", "person.fill"] {
            precondition(SpaceIcon.isDot(placeholder), placeholder)
        }
        precondition(!SpaceIcon.isDot("star"))
        precondition(!SpaceIcon.isDot("🚀"))
        precondition(!SpaceIcon.isDot("lelele.agent:0F0F0F0F-0000-0000-0000-000000000000"))
        precondition(SpaceIcon.isEmoji("🚀") && !SpaceIcon.isEmoji("star"))
        print("ok")
    }
}
