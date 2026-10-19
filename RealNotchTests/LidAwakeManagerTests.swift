import XCTest
@testable import RealNotch

final class LidAwakeManagerTests: XCTestCase {
    func testSleepDisabledLineSetIsOn() {
        let output = """
        System-wide power settings:
         SleepDisabled\t\t1
        Currently in use:
         standby              1
        """
        XCTAssertTrue(LidAwakeManager.isSleepDisabled(pmsetOutput: output))
    }

    func testSleepDisabledZeroIsOff() {
        XCTAssertFalse(LidAwakeManager.isSleepDisabled(pmsetOutput: " SleepDisabled\t\t0\n"))
    }

    func testMissingLineIsOff() {
        let output = """
        Currently in use:
         Sleep On Power Button 1
         sleep                1 (sleep prevented by caffeinate)
        """
        XCTAssertFalse(LidAwakeManager.isSleepDisabled(pmsetOutput: output))
    }

    func testEmptyOutputIsOff() {
        XCTAssertFalse(LidAwakeManager.isSleepDisabled(pmsetOutput: ""))
    }
}
