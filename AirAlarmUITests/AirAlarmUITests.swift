import XCTest

final class AirAlarmUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper

    /// Launch the app skipping onboarding
    private func launchSkippingOnboarding() {
        app.launchArguments += ["-hasSeenOnboarding", "YES"]
        app.launch()
    }

    // MARK: - Launch

    @MainActor
    func testAppLaunchSucceeds() throws {
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5))
    }

    // MARK: - Onboarding

    @MainActor
    func testOnboardingFlowCompletion() throws {
        // Reset onboarding state
        app.launchArguments += ["-hasSeenOnboarding", "NO"]
        app.launch()

        // Should show welcome/onboarding screen
        // Swipe through pages or tap Next
        let nextButton = app.buttons["onboardingNext"]
        if nextButton.waitForExistence(timeout: 3) {
            nextButton.tap()
            // Wait and tap next again for page 2
            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
            }
            // Final page should have Get Started
            let getStarted = app.buttons["onboardingGetStarted"]
            if getStarted.waitForExistence(timeout: 2) {
                getStarted.tap()
            }
        }
    }

    // MARK: - Main Screen Elements

    @MainActor
    func testMainScreenElementsExist() throws {
        launchSkippingOnboarding()

        // Settings button
        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5), "Settings button should exist")

        // Volume slider
        let volume = app.sliders["volumeSlider"]
        XCTAssertTrue(volume.exists, "Volume slider should exist")

        // At least one noise type button
        let rainButton = app.buttons["noise_Rain"]
        XCTAssertTrue(rainButton.exists, "Rain noise button should exist")
    }

    // MARK: - Noise Selection

    @MainActor
    func testNoiseTypeSelection() throws {
        launchSkippingOnboarding()

        let oceanButton = app.buttons["noise_Ocean"]
        XCTAssertTrue(oceanButton.waitForExistence(timeout: 5))
        oceanButton.tap()

        let forestButton = app.buttons["noise_Forest"]
        XCTAssertTrue(forestButton.exists)
        forestButton.tap()

        let fanButton = app.buttons["noise_Fan"]
        XCTAssertTrue(fanButton.exists)
        fanButton.tap()
    }

    // MARK: - Settings

    @MainActor
    func testSettingsNavigation() throws {
        launchSkippingOnboarding()

        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 5))
        settings.tap()

        // Settings sheet should appear with close button
        let close = app.buttons["settingsClose"]
        XCTAssertTrue(close.waitForExistence(timeout: 3), "Settings close button should appear")
        close.tap()

        // After dismissing, settings button should be visible again
        XCTAssertTrue(settings.waitForExistence(timeout: 3))
    }

    @MainActor
    func testSettingsContent() throws {
        launchSkippingOnboarding()

        app.buttons["settingsButton"].tap()

        // Verify bedtime toggle exists
        let bedtimeToggle = app.switches["bedtimeToggle"]
        XCTAssertTrue(bedtimeToggle.waitForExistence(timeout: 3), "Bedtime toggle should exist")

        // Verify history link exists
        let historyLink = app.buttons["historyLink"]
        XCTAssertTrue(historyLink.exists, "History link should exist")
    }

    // MARK: - Volume

    @MainActor
    func testVolumeSliderInteraction() throws {
        launchSkippingOnboarding()

        let slider = app.sliders["volumeSlider"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))

        // Adjust slider
        slider.adjust(toNormalizedSliderPosition: 0.3)
        slider.adjust(toNormalizedSliderPosition: 0.8)
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
