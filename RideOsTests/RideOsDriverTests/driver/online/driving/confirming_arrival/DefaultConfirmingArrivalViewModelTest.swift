import CoreLocation
import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultConfirmingArrivalViewModelTest: ReactiveTestCase {
    private static let destination = CLLocationCoordinate2D(latitude: 42, longitude: 42)
    private static let destinationPin = DrawableMarkerIcons.pickupPin()
    private static let style = DefaultConfirmingArrivalViewModel.Style(mapZoomLevel: 10.0,
                                                                       destinationIcon: destinationPin)

    private var echoGeocodeInteractor: EchoGeocodeInteractor!
    private var viewModelUnderTest: DefaultConfirmingArrivalViewModel!
    private var detailTextRecorder: TestableObserver<String>!
    private var mapStateProviderRecorder: MapStateProviderRecorder!

    override func setUp() {
        super.setUp()

        echoGeocodeInteractor = EchoGeocodeInteractor(scheduler: scheduler)

        viewModelUnderTest =
            DefaultConfirmingArrivalViewModel(destination: DefaultConfirmingArrivalViewModelTest.destination,
                                              style: DefaultConfirmingArrivalViewModelTest.style,
                                              geocodeInteractor: echoGeocodeInteractor,
                                              schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
                                              logger: ConsoleLogger())

        detailTextRecorder = scheduler.record(viewModelUnderTest.arrivalDetailText)

        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest, scheduler: scheduler)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelReflectsExpectedDetailText() {
        scheduler.start()

        XCTAssertEqual(detailTextRecorder.events, [
            next(1, EchoGeocodeInteractor.displayName),
            completed(2),
        ])
    }

    func testViewModelDoesNotShowUserLocationOnMap() {
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            next(0, MapSettings(shouldShowUserLocation: false)),
            completed(0),
        ])
    }

    func testViewModelCentersAndZoomsDestinationOnMap() {
        scheduler.start()

        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            next(1, CameraUpdate.centerAndZoom(center: DefaultConfirmingArrivalViewModelTest.destination,
                                               zoom: DefaultConfirmingArrivalViewModelTest.style.mapZoomLevel)),
            completed(2),
        ])
    }

    func testViewModelShowsDestinationMarkerOnMap() {
        scheduler.start()

        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            next(1, [
                "destination_icon": DrawableMarker(coordinate: DefaultConfirmingArrivalViewModelTest.destination,
                                                   icon: DefaultConfirmingArrivalViewModelTest.style.destinationIcon),
            ]),
            completed(2),
        ])
    }
}
