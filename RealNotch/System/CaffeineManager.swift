import Foundation
import IOKit.pwr_mgt
import Observation

/// "Keep Awake" — holds a power-management assertion so the display doesn't sleep.
/// Released automatically when toggled off or the app quits.
@Observable
final class CaffeineManager {
    private(set) var isActive = false
    private var assertionID: IOPMAssertionID = IOPMAssertionID(0)

    func toggle() {
        isActive ? deactivate() : activate()
    }

    func activate() {
        guard !isActive else { return }
        var id = IOPMAssertionID(0)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "RealNotch Keep Awake" as CFString,
            &id
        )
        if result == kIOReturnSuccess {
            assertionID = id
            isActive = true
        }
    }

    func deactivate() {
        guard isActive else { return }
        IOPMAssertionRelease(assertionID)
        assertionID = IOPMAssertionID(0)
        isActive = false
    }

    deinit {
        if isActive { IOPMAssertionRelease(assertionID) }
    }
}
