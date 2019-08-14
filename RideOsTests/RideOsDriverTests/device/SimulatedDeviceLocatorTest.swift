import CoreLocation
import Foundation
import RideOsDriver
import RideOsTestHelpers
import RxSwift
import RxTest
import XCTest

class SimulatedDeviceLocatorTest: ReactiveTestCase {
    private static let initialLocation = CLLocation(latitude: 42, longitude: 42)
    private static let simulatedLocation = CLLocation(latitude: 1, longitude: 1)

    private var deviceLocatorUnderTest: SimulatedDeviceLocator!
    private var lastKnownLocationRecorder: TestableObserver<CLLocation>!
    private var observeLocationRecorder: TestableObserver<CLLocation>!

    override func setUp() {
        super.setUp()
        deviceLocatorUnderTest = SimulatedDeviceLocator(
            initialLocationSource: FixedDeviceLocator(deviceLocation: SimulatedDeviceLocatorTest.initialLocation)
        )

        assertNil(deviceLocatorUnderTest, after: { self.deviceLocatorUnderTest = nil })
    }

    func testDeviceLocatorStartsWithObservedLocationFromInitialSourceBeforeReceivingUpdate() {
        observeLocationRecorder = scheduler.record(deviceLocatorUnderTest.observeCurrentLocation())

        scheduler.start()

        XCTAssertEqual(observeLocationRecorder.events, [
            next(0, SimulatedDeviceLocatorTest.initialLocation),
        ])
    }

    func testDeviceLocatorProvidesSimulatedObservedLocationAfterUpdate() {
        observeLocationRecorder = scheduler.record(deviceLocatorUnderTest.observeCurrentLocation())

        scheduler.scheduleAt(1) {
            self.deviceLocatorUnderTest.updateSimulatedLocation(SimulatedDeviceLocatorTest.simulatedLocation)
        }

        scheduler.start()

        XCTAssertEqual(observeLocationRecorder.events, [
            next(0, SimulatedDeviceLocatorTest.initialLocation),
            next(1, SimulatedDeviceLocatorTest.simulatedLocation),
        ])
    }
}
