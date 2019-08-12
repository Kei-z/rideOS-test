import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RxSwift
import RxTest
import XCTest

class DefaultFleetOptionResolverTest: ReactiveTestCase {
    private static let deviceLocation = CLLocation(latitude: 0, longitude: 0)

    private var fleetOptionResolverUnderTest: DefaultFleetOptionResolver!
    private var resolvedFleetRecorder: TestableObserver<FleetInfoResolutionResponse>!

    func setUp(fleets: [FleetInfo], fleetOptionToResolve: FleetOption) {
        super.setUp()

        fleetOptionResolverUnderTest = DefaultFleetOptionResolver(
            fleetInteractor: FixedFleetInteractor(fleets: fleets),
            deviceLocator: FixedDeviceLocator(deviceLocation: DefaultFleetOptionResolverTest.deviceLocation),
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger()
        )

        resolvedFleetRecorder =
            scheduler.record(fleetOptionResolverUnderTest.resolve(fleetOption: fleetOptionToResolve))

        assertNil(fleetOptionResolverUnderTest, after: { self.fleetOptionResolverUnderTest = nil })
    }

    func testResolvingAutomaticFleetOptionReturnsTheClosestFleet() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 0, longitude: 1),
                      isPhantom: false),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                      isPhantom: false),
        ]
        setUp(fleets: fleets, fleetOptionToResolve: .automatic)

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: fleets[0], wasRequestedFleetAvailable: true),
        ])
    }

    func testResolvingManualFleetOptionForAnAvailableFleetReturnsThatFleet() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 0, longitude: 1),
                      isPhantom: false),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                      isPhantom: false),
        ]
        setUp(fleets: fleets, fleetOptionToResolve: .manual(fleetInfo: fleets[1]))

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: fleets[1], wasRequestedFleetAvailable: true),
        ])
    }

    func testResolvingManualFleetOptionForAnUnavailableFleetReturnsTheClosestFleet() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 0, longitude: 1),
                      isPhantom: false),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                      isPhantom: false),
        ]
        setUp(fleets: fleets,
              fleetOptionToResolve: .manual(fleetInfo: FleetInfo(fleetId: "unknown fleet",
                                                                 displayName: "",
                                                                 center: nil,
                                                                 isPhantom: false)))

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: fleets[0], wasRequestedFleetAvailable: false),
        ])
    }

    func testResolvingAutomaticFleetOptionPrefersNonPhantomFleets() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 0, longitude: 1),
                      isPhantom: true),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                      isPhantom: false),
        ]
        setUp(fleets: fleets, fleetOptionToResolve: .automatic)

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: fleets[1], wasRequestedFleetAvailable: true),
        ])
    }

    func testResolvingAutomaticFleetOptionFallsBackToTheClosestPhantomFleetWhenThereAreNoNonPhantomFleets() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 0, longitude: 1),
                      isPhantom: true),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                      isPhantom: true),
        ]
        setUp(fleets: fleets, fleetOptionToResolve: .automatic)

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: fleets[0], wasRequestedFleetAvailable: true),
        ])
    }

    func testResolvingAutomaticFleetOptionFiltersFleetsWithNoCenterSpecified() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: nil,
                      isPhantom: false),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                      isPhantom: false),
        ]
        setUp(fleets: fleets, fleetOptionToResolve: .automatic)

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: fleets[1], wasRequestedFleetAvailable: true),
        ])
    }

    func testResolvingAutomaticFleetOptionReturnsDefaultFleetWhenNoFleetsHaveACenterSpecified() {
        let fleets = [
            FleetInfo(fleetId: "fleet0",
                      displayName: "",
                      center: nil,
                      isPhantom: false),
            FleetInfo(fleetId: "fleet1",
                      displayName: "",
                      center: nil,
                      isPhantom: false),
        ]
        setUp(fleets: fleets, fleetOptionToResolve: .automatic)

        scheduler.start()

        AssertRecordedElementsIgnoringCompletion(resolvedFleetRecorder.events, [
            FleetInfoResolutionResponse(fleetInfo: FleetInfo.defaultFleetInfo, wasRequestedFleetAvailable: true),
        ])
    }
}
