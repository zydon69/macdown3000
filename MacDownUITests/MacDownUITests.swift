import XCTest
import AppKit

/// UI acceptance smoke tests for MacDown 3000.
///
/// This is intentionally a small, deterministic core that exercises the
/// app launch path, the editor, and the preview pane through XCUITest.
/// It complements (not replaces) the unit test suite.
final class MacDownUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        if let home = ProcessInfo.processInfo.environment["CFFIXED_USER_HOME"] {
            app.launchEnvironment["CFFIXED_USER_HOME"] = home
        }
        // Disable state restoration to get consistent initial state
        app.launchArguments = ["-ApplePersistenceIgnoreState", "YES",
                               "-MPDisableUpdater", "YES"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    // MARK: - Helper Methods

    /// Waits for the editor in the frontmost window.
    private func waitForEditor(timeout: TimeInterval = 5) -> XCUIElement? {
        let editor = app.textViews.matching(identifier: "editor-text-view").firstMatch
        guard editor.waitForExistence(timeout: timeout) else {
            return nil
        }
        return editor
    }

    // MARK: - Smoke Tests

    func testFindFromPreviewOpensRenderedTextSearch() throws {
        let pasteboard = NSPasteboard(name: .find)
        let originalItems = (pasteboard.pasteboardItems ?? []).map { item in
            let copy = NSPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) { copy.setData(data, forType: type) }
            }
            return copy
        }
        defer {
            pasteboard.clearContents()
            if !originalItems.isEmpty { pasteboard.writeObjects(originalItems) }
        }
        let window = app.windows.containing(.textView,
            identifier: "editor-text-view").firstMatch
        let editor = window.textViews.matching(identifier: "editor-text-view").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.click()
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText("# Preview target\n\nSearch **rendered text** here.")
        let preview = window.webViews.firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        preview.click()
        app.typeKey("f", modifierFlags: .command)
        let field = app.searchFields["preview-find-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("rendered text")
        field.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        app.typeKey("g", modifierFlags: .command)
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeKey(XCUIKeyboardKey.escape.rawValue, modifierFlags: [])
        let hidden = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == false"), object: field)
        wait(for: [hidden], timeout: 5)
        editor.click()
        XCTAssertTrue((editor.value as? String ?? "").contains("**rendered text**"))
        app.typeKey("f", modifierFlags: .command)
        XCTAssertFalse(app.searchFields["preview-find-field"].isHittable,
                       "Source Find must retain its native editor interface")
    }

    /// Smoke test: App launches and shows at least one window.
    func testAppLaunchesWithWindow() throws {
        let firstWindow = app.windows.firstMatch
        XCTAssertTrue(firstWindow.waitForExistence(timeout: 5), "App should show at least one window after launch")
    }

    /// Smoke test: Editor text view is accessible.
    func testEditorTextViewExists() throws {
        let editor = app.textViews.matching(identifier: "editor-text-view").firstMatch
        let editorExists = editor.waitForExistence(timeout: 5)
        XCTAssertTrue(editorExists, "Editor text view should exist with accessibility identifier 'editor-text-view'")
    }

    /// Test: Can type text in the editor.
    func testCanTypeInEditor() throws {
        guard let editor = waitForEditor() else {
            XCTFail("Editor not found")
            return
        }

        editor.click()
        let testText = "# Hello World"
        editor.typeText(testText)

        let editorValue = editor.value as? String ?? ""
        XCTAssertTrue(editorValue.contains("Hello World"), "Editor should contain typed text")
    }

    /// Test: Preview pane exists after typing markdown content.
    func testPreviewPaneExists() throws {
        guard let editor = waitForEditor() else {
            XCTFail("Editor not found")
            return
        }

        editor.click()
        editor.typeText("# Hello World")

        let webView = app.webViews.firstMatch
        XCTAssertTrue(webView.waitForExistence(timeout: 5), "Preview pane web view should exist")
    }
}
