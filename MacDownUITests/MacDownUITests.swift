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
                               "-MPDisableUpdater", "YES",
                               "-AppleLanguages", "(en)"]
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

    func testUntitledDocumentSurvivesNormalQuitAndRelaunch() throws {
        app.terminate()
        app.launchArguments = ["-ApplePersistenceIgnoreState", "NO",
                               "-NSQuitAlwaysKeepsWindows", "YES",
                               "-editorAutoSave", "YES",
                               "-MPDisableUpdater", "YES"]
        app.launch()
        app.typeKey("n", modifierFlags: .command)
        let documentWindow = app.windows.containing(.textView,
            identifier: "editor-text-view").firstMatch
        let editor = documentWindow.textViews.matching(
            identifier: "editor-text-view").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        XCTAssertEqual(editor.value as? String, "")
        let marker = "Draft recovery " + UUID().uuidString
        editor.click()
        editor.typeText(marker)
        XCTAssertTrue((editor.value as? String ?? "").contains(marker))
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 15),
                      "Normal quit must preserve the draft without a save panel")
        app.launch()
        let recovered = app.textViews.matching(identifier: "editor-text-view")
            .matching(NSPredicate(format: "value CONTAINS %@", marker)).firstMatch
        XCTAssertTrue(recovered.waitForExistence(timeout: 15),
                      "The never-saved document must retain its exact contents")
        // Explicitly close this fixture rather than leave it for later UI tests.
        recovered.click()
        recovered.typeKey("a", modifierFlags: .command)
        recovered.typeKey(XCUIKeyboardKey.delete.rawValue, modifierFlags: [])
        app.typeKey("w", modifierFlags: .command)
    }

    func testSavedDocumentSurvivesNormalQuitWithUnsavedEdits() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory,
                                               withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("existing.md")
        let marker = "Existing recovery " + UUID().uuidString
        try "Saved baseline".write(to: file, atomically: true, encoding: .utf8)
        app.terminate()
        app.launchArguments = ["-ApplePersistenceIgnoreState", "NO",
                               "-NSQuitAlwaysKeepsWindows", "YES",
                               "-editorAutoSave", "YES",
                               "-MPDisableUpdater", "YES"]
        app.launch()
        app.typeKey("o", modifierFlags: .command)
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeText(file.path)
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        let editor = app.textViews.matching(identifier: "editor-text-view").matching(
            NSPredicate(format: "value CONTAINS %@", "Saved baseline")).firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        editor.click()
        editor.typeKey("a", modifierFlags: .command)
        editor.typeText(marker)
        app.typeKey("q", modifierFlags: .command)
        XCTAssertTrue(app.wait(for: .notRunning, timeout: 15))
        app.launch()
        let restored = app.textViews.matching(identifier: "editor-text-view").matching(
            NSPredicate(format: "value CONTAINS %@", marker)).firstMatch
        XCTAssertTrue(restored.waitForExistence(timeout: 15))
    }

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

    func testReaderModeAppliesToEveryNewWindowAndKeepsProgressVisible() throws {
        app.terminate()
        app.launchArguments = ["-ApplePersistenceIgnoreState", "YES",
                               "-MPDisableUpdater", "YES",
                               "-editorStartInPreviewMode", "YES",
                               "-editorShowReadingProgress", "YES"]
        app.launch()
        for _ in 0..<3 {
            app.typeKey("n", modifierFlags: .command)
            let window = app.windows.firstMatch
            XCTAssertTrue(window.webViews.firstMatch.waitForExistence(timeout: 10))
            XCTAssertFalse(window.textViews.matching(identifier: "editor-text-view").firstMatch.isHittable)
            let progress = window.staticTexts["reading-progress"]
            XCTAssertTrue(progress.waitForExistence(timeout: 5))
            XCTAssertEqual(progress.value as? String, "100%")
        }
    }

    func testReadingPositionUpdatesDuringEditorAndPreviewWheelScrolling() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appendingPathComponent("ReadingProgress.md")
        try String(repeating: "Reading progress paragraph.\n\n", count: 300)
            .write(to: file, atomically: true, encoding: .utf8)
        app.terminate()
        app.launchArguments = ["-ApplePersistenceIgnoreState", "YES",
                               "-MPDisableUpdater", "YES",
                               "-editorShowReadingProgress", "YES",
                               "-editorSyncScrolling", "NO",
                               "-editorStartInPreviewMode", "NO",
                               "-AppleLanguages", "(en)"]
        app.launch()
        app.typeKey("o", modifierFlags: .command)
        app.typeKey("g", modifierFlags: [.command, .shift])
        app.typeText(file.path)
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        app.typeKey(XCUIKeyboardKey.return.rawValue, modifierFlags: [])
        let window = app.windows["ReadingProgress.md"]
        let editor = window.textViews.matching(identifier: "editor-text-view").firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 10))
        let progress = window.staticTexts["reading-progress"]
        XCTAssertTrue(progress.waitForExistence(timeout: 5))
        editor.scroll(byDeltaX: 0, deltaY: -100000)
        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "100%"), object: progress)], timeout: 5)
        // With sync disabled the preview is still at its top. Its wheel event
        // must take ownership of the indicator without requiring a click.
        let preview = window.webViews.firstMatch
        preview.scroll(byDeltaX: 0, deltaY: 1000)
        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "0%"), object: progress)], timeout: 5)
        preview.scroll(byDeltaX: 0, deltaY: -100000)
        wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "100%"), object: progress)], timeout: 5)
    }

    func testReaderSettingsCanBeSelectedThroughPreferences() throws {
        app.typeKey(",", modifierFlags: .command)
        let general = app.toolbars.buttons["General"]
        if general.waitForExistence(timeout: 5) { general.click() }
        let appearance = app.popUpButtons["application-appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 5))
        appearance.click()
        app.menuItems["Appearance: Dark"].click()
        XCTAssertEqual(appearance.value as? String, "Appearance: Dark")
        let screenshot = XCTAttachment(screenshot: app.windows.containing(.popUpButton,
            identifier: "application-appearance").firstMatch.screenshot())
        screenshot.name = "Reader settings with forced dark appearance"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        let position = app.checkBoxes["reading-progress-setting"]
        XCTAssertTrue(position.exists)
        if (position.value as? NSNumber)?.intValue != 1 { position.click() }
        XCTAssertEqual((position.value as? NSNumber)?.intValue, 1)
        XCTAssertTrue(app.staticTexts.matching(identifier: "reading-progress").firstMatch.waitForExistence(timeout: 5))
        let rendering = app.toolbars.buttons["Rendering"]
        XCTAssertTrue(rendering.exists)
        rendering.click()
        let wrapping = app.checkBoxes["code-wrap-setting"]
        XCTAssertTrue(wrapping.waitForExistence(timeout: 5))
        let initialWrapping = try XCTUnwrap(wrapping.value as? NSNumber).intValue
        let wrapIndicator = wrapping.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: 0.5))
        wrapIndicator.click()
        XCTAssertEqual((wrapping.value as? NSNumber)?.intValue, 1 - initialWrapping)
        if initialWrapping == 1 { wrapIndicator.click() }
        XCTAssertEqual((wrapping.value as? NSNumber)?.intValue, 1)
        app.terminate()
        app.launch()
        app.typeKey(",", modifierFlags: .command)
        app.toolbars.buttons["General"].click()
        XCTAssertEqual(app.popUpButtons["application-appearance"].value as? String, "Appearance: Dark")
        XCTAssertEqual((app.checkBoxes["reading-progress-setting"].value as? NSNumber)?.intValue, 1)
        app.toolbars.buttons["Rendering"].click()
        XCTAssertEqual((app.checkBoxes["code-wrap-setting"].value as? NSNumber)?.intValue, 1)
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
