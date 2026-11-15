import XCTest

final class FluxUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testNavigationAndMotionScreens() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Studio"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Settings"].tap()
        let animate = app.switches["Animate wallpaper previews"]
        XCTAssertTrue(animate.waitForExistence(timeout: 5))
        if animate.value as? String == "1" { animate.tap() }
        capture("Settings", app: app)
        app.tabBars.buttons["Studio"].tap()
        XCTAssertTrue(app.buttons["Customize Aurora wallpaper"].waitForExistence(timeout: 5))
        capture("Studio", app: app)
        app.tabBars.buttons["Wallpapers"].tap()
        XCTAssertTrue(app.buttons["Open Aurora"].waitForExistence(timeout: 5))
        capture("Wallpapers", app: app)
        app.tabBars.buttons["Motion"].tap()
        let open = app.buttons["Open animated card"]
        XCTAssertTrue(open.waitForExistence(timeout: 5))
        open.tap()
        XCTAssertTrue(app.buttons["Close animated card"].waitForExistence(timeout: 5))
        capture("Motion", app: app)
    }

    @MainActor
    func testSaveLivePhotoFromEditor() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Studio"].waitForExistence(timeout: 15))
        app.tabBars.buttons["Studio"].tap()
        let editor = app.buttons["Customize Aurora wallpaper"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        XCTAssertTrue(app.navigationBars["Aurora"].waitForExistence(timeout: 5))
        capture("Wallpaper editor", app: app)
        let save = app.buttons["wallpaper.saveLivePhoto"]
        for _ in 0..<6 {
            if save.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(save.isHittable)
        save.tap()
        let result = app.alerts["Export"]
        XCTAssertTrue(result.waitForExistence(timeout: 100))
        XCTAssertTrue(result.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Saved to Photos.")).firstMatch.exists,
                      "Expected a saved Live Photo. Received: " + result.debugDescription)
        capture("Live Photo saved", app: app)
        result.buttons["OK"].tap()
    }

    @MainActor
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
