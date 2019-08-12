import CoreLocation
import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultDrivePendingViewModelTest: ReactiveTestCase {
    private static let destination = CLLocationCoordinate2D(latitude: 42, longitude: 42)
    private static let deviceLocation = CLLocation(latitude: 1, longitude: 1)

    private static let detailTextProvider: DefaultDrivePendingViewModel.RouteDetailTextProvider = {
        "distance: \($0), travel_time: \($1)"
    }

    private static let style = DefaultDrivePendingViewModel.Style(routeDetailTextProvider: detailTextProvider,
                                                                  drawablePathWidth: 2.0,
                                                                  drawablePathColor: .green,
                                                                  destinationIcon: DrawableMarkerIcons.pickupPin())

    private var viewModelUnderTest: DefaultDrivePendingViewModel!
    private var routeDetailTextRecorder: TestableObserver<String>!
    private var mapStateProviderRecorder: MapStateProviderRecorder!

    override func setUp() {
        super.setUp()

        let destination = DefaultDrivePendingViewModelTest.destination
        let deviceLocator = FixedDeviceLocator(deviceLocation: DefaultDrivePendingViewModelTest.deviceLocation)
        let style = DefaultDrivePendingViewModelTest.style
        let routeInteractor = PointToPointRouteInteractor(scheduler: scheduler)
        let schedulerProvider = TestSchedulerProvider(scheduler: scheduler)

        viewModelUnderTest = DefaultDrivePendingViewModel(destination: destination,
                                                          style: style,
                                                          deviceLocator: deviceLocator,
                                                          routeInteractor: routeInteractor,
                                                          schedulerProvider: schedulerProvider)

        routeDetailTextRecorder = scheduler.record(viewModelUnderTest.routeDetailText)

        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest, scheduler: scheduler)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelReflectsExpectedRouteDetailText() {
        let expectedRouteDetailText =
            DefaultDrivePendingViewModelTest.detailTextProvider(PointToPointRouteInteractor.travelDistanceMeters,
                                                                PointToPointRouteInteractor.travelTime)

        scheduler.start()

        XCTAssertEqual(routeDetailTextRecorder.events, [
            next(3, expectedRouteDetailText),
            completed(4),
        ])
    }

    func testViewModelDoesNotShowUserLocationOnMap() {
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            next(0, MapSettings(shouldShowUserLocation: false)),
            completed(0),
        ])
    }

    func testViewModelShowsRouteFromDeviceLocationToDestinationBoundsOnMap() {
        let expectedRoute = [
            DefaultDrivePendingViewModelTest.deviceLocation.coordinate,
            DefaultDrivePendingViewModelTest.destination,
        ]

        scheduler.start()

        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            next(2, CameraUpdate.fitLatLngBounds(LatLngBounds(containingCoordinates: expectedRoute))),
            completed(3),
        ])
    }

    func testViewModelShowsPathForRouteFromDeviceLocationToDestinationOnMap() {
        let expectedRoute = [
            DefaultDrivePendingViewModelTest.deviceLocation.coordinate,
            DefaultDrivePendingViewModelTest.destination,
        ]

        scheduler.start()

        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(2, [DrawablePath(coordinates: expectedRoute,
                                   width: DefaultDrivePendingViewModelTest.style.drawablePathWidth,
                                   color: DefaultDrivePendingViewModelTest.style.drawablePathColor)]),
            .completed(3),
        ])
    }

    func testViewModelShowsDestinationMarkerOnMap() {
        scheduler.start()

        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(2, [
                "vehicle": DrawableMarker(coordinate: DefaultDrivePendingViewModelTest.deviceLocation.coordinate,
                                          heading: DefaultDrivePendingViewModelTest.deviceLocation.course,
                                          icon: DefaultDrivePendingViewModelTest.style.vehicleIcon),
                "destination": DrawableMarker(coordinate: DefaultDrivePendingViewModelTest.destination,
                                              icon: DefaultDrivePendingViewModelTest.style.destinationIcon),
            ]),
            .completed(3),
        ])
    }
}
