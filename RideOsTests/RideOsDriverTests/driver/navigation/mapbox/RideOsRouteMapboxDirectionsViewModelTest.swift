import CoreLocation
import MapboxDirections
import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxSwift
import RxTest
import XCTest

class RideOsRouteMapboxDirectionsViewModelTest: ReactiveTestCase {
    private static let deviceLocation = CLLocation(latitude: 1, longitude: 1)
    private static let destination = CLLocation(latitude: 2, longitude: 2)
    private static let directions = MapboxDirections.Route(json: ["distance": 1.0,
                                                                  "duration": 1.0],
                                                           waypoints: [Waypoint(coordinate: destination.coordinate)],
                                                           options: RouteOptions(locations: [destination]))

    private var viewModelUnderTest: RideOsRouteMapboxDirectionsViewModel!
    private var recordingDirectionsInteractor: RecordingMapboxDirectionsInteractor!
    private var directionsRecorder: TestableObserver<MapboxDirections.Route>!

    override func setUp() {
        super.setUp()
        recordingDirectionsInteractor =
            RecordingMapboxDirectionsInteractor(directions: RideOsRouteMapboxDirectionsViewModelTest.directions)

        let deviceLocator = FixedDeviceLocator(deviceLocation: RideOsRouteMapboxDirectionsViewModelTest.deviceLocation)
        let schedulerProvider = TestSchedulerProvider(scheduler: scheduler)
        viewModelUnderTest = RideOsRouteMapboxDirectionsViewModel(deviceLocator: deviceLocator,
                                                                  directionsInteractor: recordingDirectionsInteractor,
                                                                  schedulerProvider: schedulerProvider,
                                                                  logger: ConsoleLogger())
        directionsRecorder = scheduler.record(viewModelUnderTest.directions)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelIndicatesItShouldHandleReroutes() {
        XCTAssertTrue(viewModelUnderTest.shouldHandleReroutes)
    }

    func testViewModelUpdatesDirectionsAfterRouteFromOriginToDestinationRequest() {
        scheduler.scheduleAt(0) {
            self.viewModelUnderTest.route(
                from: RideOsRouteMapboxDirectionsViewModelTest.deviceLocation.coordinate,
                to: RideOsRouteMapboxDirectionsViewModelTest.destination.coordinate
            )
        }

        scheduler.start()

        XCTAssertEqual(directionsRecorder.events, [
            next(1, RideOsRouteMapboxDirectionsViewModelTest.directions),
        ])

        XCTAssertEqual(recordingDirectionsInteractor.methodCalls, ["getDirections(from:to:)"])
    }

    func testViewModelUpdatesDirectionsAfterRouteToDestinationRequest() {
        scheduler.scheduleAt(0) {
            self.viewModelUnderTest.route(to: RideOsRouteMapboxDirectionsViewModelTest.destination.coordinate)
        }

        scheduler.start()

        XCTAssertEqual(directionsRecorder.events, [
            next(1, RideOsRouteMapboxDirectionsViewModelTest.directions),
        ])

        XCTAssertEqual(recordingDirectionsInteractor.methodCalls, ["getDirections(from:to:)"])
    }
}
