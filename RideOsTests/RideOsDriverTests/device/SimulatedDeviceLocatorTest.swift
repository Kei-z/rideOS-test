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

    func testDeviceLocatorStartsWithLastKnownLocationFromInitialSourceBeforeReceivingUpdate() {
        lastKnownLocationRecorder = scheduler.record(deviceLocatorUnderTest.lastKnownLocation)

        scheduler.start()

        XCTAssertEqual(lastKnownLocationRecorder.events, [
            next(0, SimulatedDeviceLocatorTest.initialLocation),
            completed(0),
        ])
    }

    func testDeviceLocatorStartsWithObservedLocationFromInitialSourceBeforeReceivingUpdate() {
        observeLocationRecorder = scheduler.record(deviceLocatorUnderTest.observeCurrentLocation())

        scheduler.start()

        XCTAssertEqual(observeLocationRecorder.events, [
            next(0, SimulatedDeviceLocatorTest.initialLocation),
        ])
    }

    func testDeviceLocatorProvidesSimulatedLastKnownLocationAfterUpdate() {
        deviceLocatorUnderTest.updateSimulatedLocation(SimulatedDeviceLocatorTest.simulatedLocation)

        lastKnownLocationRecorder = scheduler.record(deviceLocatorUnderTest.lastKnownLocation)

        scheduler.start()

        XCTAssertEqual(lastKnownLocationRecorder.events, [
            next(0, SimulatedDeviceLocatorTest.simulatedLocation),
            completed(0),
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
