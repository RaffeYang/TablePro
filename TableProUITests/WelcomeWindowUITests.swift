import TableProPluginKit
import XCTest

final class WelcomeWindowUITests: UITestCase {
    func testAFreshLaunchOpensOnTheWelcomeWindowWithNoTour() throws {
        let app = try launchApp()
        let welcome = app.windows["welcome"]
        XCTAssertTrue(welcome.waitToExist(timeout: 10))

        XCTAssertTrue(
            welcome.buttons["Open Sample Database"].waitToExist(timeout: 10),
            "An empty store must offer the sample database where the list would be"
        )
        XCTAssertFalse(welcome.links["Skip"].exists, "The first launch must not open on a tour")
    }

    func testAFirstLaunchShowsTheWelcomeSheetUntilContinue() throws {
        let app = try launchApp(environment: ["TABLEPRO_UI_TEST_SHOW_WELCOME_SHEET": "1"])
        let welcome = app.windows["welcome"]
        XCTAssertTrue(welcome.waitToExist(timeout: 10))

        let continueButton = welcome.descendants(matching: .button)["welcome-sheet-continue"]
        XCTAssertTrue(continueButton.waitToExist(timeout: 10), "A first launch must show the welcome sheet")
        XCTAssertTrue(waitUntilHittable(continueButton, timeout: 5))
        continueButton.click()

        XCTAssertTrue(waitForPredicate(timeout: 5) { !continueButton.exists }, "Continue must close the sheet")
        XCTAssertTrue(welcome.buttons["Open Sample Database"].waitToExist(timeout: 5))
    }

    func testHelpMenuShowsTheWelcomeSheetAgain() throws {
        let app = try launchApp()
        let welcome = app.windows["welcome"]
        XCTAssertTrue(welcome.waitToExist(timeout: 10))
        XCTAssertFalse(welcome.descendants(matching: .button)["welcome-sheet-continue"].exists)

        let item = app.menuBars.menuItems["Getting Started"]
        XCTAssertTrue(item.waitToExist(timeout: 10), "Help must offer the welcome sheet")
        item.click()

        XCTAssertTrue(
            welcome.descendants(matching: .button)["welcome-sheet-continue"].waitToExist(timeout: 10),
            "Help > Getting Started must show the sheet again"
        )
    }

    func testOpenSampleDatabaseFromTheEmptyListOpensTheSample() throws {
        let app = try launchApp()
        let open = app.windows["welcome"].buttons["Open Sample Database"]
        XCTAssertTrue(open.waitToExist(timeout: 10))
        XCTAssertTrue(waitUntilHittable(open, timeout: 5))

        open.click()

        XCTAssertTrue(waitForSampleDatabaseWindow(in: app), "Open Sample Database must open the sample")
    }

    func testTheWelcomeWindowShowsTheVersionAndTheUpdateCheck() throws {
        let app = try launchApp()
        let welcome = app.windows["welcome"]
        XCTAssertTrue(welcome.waitToExist(timeout: 10))

        XCTAssertTrue(
            welcome.links["Check for Updates…"].waitToExist(timeout: 10),
            "The welcome window must offer the update check by default"
        )
        let versionLine = welcome.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Version"))
            .firstMatch
        XCTAssertTrue(versionLine.waitToExist(timeout: 10), "The welcome window must show the app version")
    }

    /// The setting is seeded straight into the suite the app reads rather than clicked in Settings,
    /// because the toggle sits far enough down the General pane that the runner's screen needs the
    /// pane scrolled to reach it.
    func testTurningTheSettingOffHidesTheVersionAndTheUpdateCheck() throws {
        let seeded = try XCTUnwrap(UserDefaults(suiteName: PluginHostStorage.sandboxSuiteName))
        seeded.set(
            Data(#"{"startupBehavior":"showWelcome","showWelcomeVersionInfo":false}"#.utf8),
            forKey: "com.TablePro.settings.general"
        )

        let app = try launchApp()
        let welcome = app.windows["welcome"]
        XCTAssertTrue(welcome.waitToExist(timeout: 10))
        // The panel must have mounted before an absence means anything.
        XCTAssertTrue(welcome.buttons["New Connection…"].waitToExist(timeout: 10))

        let versionLine = welcome.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH %@", "Version"))
            .firstMatch
        let updateCheck = welcome.links["Check for Updates…"]
        XCTAssertTrue(
            waitForPredicate(timeout: 5) { !versionLine.exists && !updateCheck.exists },
            "A welcome window with the version info off must show neither the app version nor the update check"
        )
    }
}
