import ApplicationServices
import AppKit
import Foundation

enum SmokeFailure: Error, CustomStringConvertible {
    case appNotRunning
    case accessibilityNotTrusted
    case windowNotFound
    case expectedTextMissing(String, String)
    case buttonNotFound(String, String)
    case actionFailed(String)

    var description: String {
        switch self {
        case .appNotRunning:
            "HabitBar is not running."
        case .accessibilityNotTrusted:
            "Accessibility permission is required for UI smoke tests."
        case .windowNotFound:
            "Habit Bar UI-testing window was not found."
        case .expectedTextMissing(let text, let dump):
            "Expected UI text '\(text)' was not found.\n\nAccessibility dump:\n\(dump)"
        case .buttonNotFound(let title, let dump):
            "Button '\(title)' was not found.\n\nAccessibility dump:\n\(dump)"
        case .actionFailed(let title):
            "Could not press button '\(title)'."
        }
    }
}

struct AccessibilityNode {
    var role: String
    var title: String
    var value: String
    var description: String
    var element: AXUIElement
    var children: [AccessibilityNode]

    var searchableText: String {
        ([role, title, value, description] + children.map(\.searchableText))
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var dump: String {
        dumpLines(depth: 0).joined(separator: "\n")
    }

    func firstButton(titled title: String) -> AXUIElement? {
        let actionableRoles = ["AXButton", "AXMenuButton", "AXMenuItem"]
        if actionableRoles.contains(role), self.title == title || description == title || value == title {
            return element
        }

        for child in children {
            if let match = child.firstButton(titled: title) {
                return match
            }
        }

        return nil
    }

    func buttons(titled title: String) -> [AXUIElement] {
        let actionableRoles = ["AXButton", "AXMenuButton", "AXMenuItem"]
        let current = actionableRoles.contains(role) && (self.title == title || description == title || value == title)
            ? [element]
            : []
        return current + children.flatMap { $0.buttons(titled: title) }
    }

    func firstElement(role wantedRole: String) -> AXUIElement? {
        if role == wantedRole {
            return element
        }

        for child in children {
            if let match = child.firstElement(role: wantedRole) {
                return match
            }
        }

        return nil
    }

    private func dumpLines(depth: Int) -> [String] {
        let indent = String(repeating: "  ", count: depth)
        let summary = [role, title, value, description]
            .filter { !$0.isEmpty }
            .joined(separator: " | ")
        return [indent + summary] + children.flatMap { $0.dumpLines(depth: depth + 1) }
    }
}

@main
struct HabitBarUITestRunner {
    static func main() {
        do {
            try run()
            print("HabitBar UI smoke test passed.")
        } catch {
            fputs("HabitBar UI smoke test failed: \(error)\n", stderr)
            exit(1)
        }
    }

    private static func run() throws {
        guard AXIsProcessTrusted() else {
            throw SmokeFailure.accessibilityNotTrusted
        }

        let app = try waitForApp()
        app.activate()
        Thread.sleep(forTimeInterval: 0.2)

        let root = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetAttributeValue(root, kAXFrontmostAttribute as CFString, kCFBooleanTrue)

        let window = try waitForWindow(root)
        var tree = buildTree(window, maxDepth: 10)

        for expected in ["Habit Bar", "Today", "Morning Walk", "Add", "Archive", "Open"] {
            guard tree.searchableText.contains(expected) else {
                throw SmokeFailure.expectedTextMissing(expected, tree.dump)
            }
        }

        try pressButton("Undo today", in: tree)
        tree = buildTree(window, maxDepth: 10)
        try pressButton("Complete today", in: tree)
        tree = buildTree(window, maxDepth: 10)
        try pressButton("Incomplete", in: tree)
        tree = buildTree(window, maxDepth: 10)

        try pressButton("Add", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard tree.searchableText.contains("New Habit") || tree.searchableText.contains("Name") else {
            throw SmokeFailure.expectedTextMissing("New Habit", tree.dump)
        }

        try setFirstTextField("Stretch", in: tree)
        tree = buildTree(window, maxDepth: 10)
        try pressButton("Save", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard tree.searchableText.contains("Stretch") else {
            throw SmokeFailure.expectedTextMissing("Stretch", tree.dump)
        }

        try pressButton("Edit", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard tree.searchableText.contains("Edit Habit") || tree.searchableText.contains("Name") else {
            throw SmokeFailure.expectedTextMissing("Edit Habit", tree.dump)
        }

        try setFirstTextField("Evening Stretch", in: tree)
        tree = buildTree(window, maxDepth: 10)
        try pressButton("Save", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard tree.searchableText.contains("Evening Stretch") else {
            throw SmokeFailure.expectedTextMissing("Evening Stretch", tree.dump)
        }

        try pressButton("Delete", in: tree)
        tree = buildTree(root, maxDepth: 12)
        try pressButton("Confirm Delete", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard !tree.searchableText.contains("Evening Stretch") else {
            throw SmokeFailure.expectedTextMissing("Evening Stretch deleted", tree.dump)
        }

        try pressButton("Add", in: tree)
        tree = buildTree(window, maxDepth: 10)
        try setFirstTextField("Archive Me", in: tree)
        tree = buildTree(window, maxDepth: 10)
        try pressButton("Save", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard tree.searchableText.contains("Archive Me") else {
            throw SmokeFailure.expectedTextMissing("Archive Me", tree.dump)
        }

        try pressButton("Archive", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard !tree.searchableText.contains("Archive Me") else {
            throw SmokeFailure.expectedTextMissing("Archive Me archived", tree.dump)
        }

        try pressLastButton("Archive", in: tree)
        tree = buildTree(root, maxDepth: 12)
        try pressButton("Restore Archive Me", in: tree)
        tree = buildTree(window, maxDepth: 10)

        guard tree.searchableText.contains("Archive Me") else {
            throw SmokeFailure.expectedTextMissing("Archive Me restored", tree.dump)
        }
    }

    private static func waitForApp() throws -> NSRunningApplication {
        for _ in 0..<50 {
            if let app = NSRunningApplication
                .runningApplications(withBundleIdentifier: "com.georgetsouvaltzis.HabitBar")
                .first {
                return app
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        throw SmokeFailure.appNotRunning
    }

    private static func waitForWindow(_ app: AXUIElement) throws -> AXUIElement {
        for _ in 0..<50 {
            if let windows = attribute(app, kAXWindowsAttribute) as? [AXUIElement] {
                for window in windows where stringAttribute(window, kAXTitleAttribute) == "Habit Bar" {
                    return window
                }
            }
            Thread.sleep(forTimeInterval: 0.1)
        }

        throw SmokeFailure.windowNotFound
    }

    private static func pressButton(_ title: String, in tree: AccessibilityNode) throws {
        guard let button = tree.firstButton(titled: title) else {
            throw SmokeFailure.buttonNotFound(title, tree.dump)
        }

        AXUIElementSetAttributeValue(button, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
        guard result == .success else {
            throw SmokeFailure.actionFailed(title)
        }

        Thread.sleep(forTimeInterval: 0.4)
    }

    private static func pressLastButton(_ title: String, in tree: AccessibilityNode) throws {
        guard let button = tree.buttons(titled: title).last else {
            throw SmokeFailure.buttonNotFound(title, tree.dump)
        }

        AXUIElementSetAttributeValue(button, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        let result = AXUIElementPerformAction(button, kAXPressAction as CFString)
        guard result == .success else {
            throw SmokeFailure.actionFailed(title)
        }

        Thread.sleep(forTimeInterval: 0.4)
    }

    private static func setFirstTextField(_ value: String, in tree: AccessibilityNode) throws {
        guard let textField = tree.firstElement(role: "AXTextField") else {
            throw SmokeFailure.buttonNotFound("text field", tree.dump)
        }

        let focusResult = AXUIElementSetAttributeValue(textField, kAXFocusedAttribute as CFString, kCFBooleanTrue)
        guard focusResult == .success else {
            throw SmokeFailure.actionFailed("text field")
        }

        clickCenter(of: textField)
        Thread.sleep(forTimeInterval: 0.1)

        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(value, forType: .string)
        selectAllText(in: textField)
        sendKey(virtualKey: 0, modifiers: .maskCommand)
        sendKey(virtualKey: 9, modifiers: .maskCommand)

        Thread.sleep(forTimeInterval: 0.3)
    }

    private static func selectAllText(in textField: AXUIElement) {
        let currentValue = stringAttribute(textField, kAXValueAttribute)
        var range = CFRange(location: 0, length: currentValue.count)
        guard let rangeValue = AXValueCreate(.cfRange, &range) else {
            return
        }
        AXUIElementSetAttributeValue(textField, kAXSelectedTextRangeAttribute as CFString, rangeValue)
    }

    private static func clickCenter(of element: AXUIElement) {
        guard
            let rawPosition = attribute(element, kAXPositionAttribute),
            let rawSize = attribute(element, kAXSizeAttribute)
        else {
            return
        }

        let positionValue = rawPosition as! AXValue
        let sizeValue = rawSize as! AXValue

        var position = CGPoint.zero
        var size = CGSize.zero
        guard
            AXValueGetValue(positionValue, .cgPoint, &position),
            AXValueGetValue(sizeValue, .cgSize, &size)
        else {
            return
        }

        let point = CGPoint(x: position.x + size.width / 2, y: position.y + size.height / 2)
        let source = CGEventSource(stateID: .combinedSessionState)
        let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)
        let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)
        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
    }

    private static func sendKey(virtualKey: CGKeyCode, modifiers: CGEventFlags = []) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: virtualKey, keyDown: false)
        keyDown?.flags = modifiers
        keyUp?.flags = modifiers
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    private static func buildTree(_ element: AXUIElement, maxDepth: Int) -> AccessibilityNode {
        let children: [AccessibilityNode]
        if maxDepth > 0, let rawChildren = attribute(element, kAXChildrenAttribute) as? [AXUIElement] {
            children = rawChildren.map { buildTree($0, maxDepth: maxDepth - 1) }
        } else {
            children = []
        }

        return AccessibilityNode(
            role: stringAttribute(element, kAXRoleAttribute),
            title: stringAttribute(element, kAXTitleAttribute),
            value: stringAttribute(element, kAXValueAttribute),
            description: stringAttribute(element, kAXDescriptionAttribute),
            element: element,
            children: children
        )
    }

    private static func attribute(_ element: AXUIElement, _ key: String) -> AnyObject? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, key as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    private static func stringAttribute(_ element: AXUIElement, _ key: String) -> String {
        attribute(element, key) as? String ?? ""
    }
}
