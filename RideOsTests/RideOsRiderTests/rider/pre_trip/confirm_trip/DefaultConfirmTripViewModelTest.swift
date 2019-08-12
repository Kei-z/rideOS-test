import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest

class DefaultConfirmTripViewModelTest: ReactiveTestCase {
    static let pickupLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    static let dropoffLocation = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    static let pickupIcon = DrawableMarkerIcon(image: UIImage(), groundAnchor: CGPoint(x: 0, y: 0))
    static let dropoffIcon = DrawableMarkerIcon(image: UIImage(), groundAnchor: CGPoint(x: 1, y: 1))
    
    var viewModelUnderTest: DefaultConfirmTripViewModel!
    var listener: RecordingConfirmTripListener!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var routeInformationRecorder: TestableObserver<NSAttributedString>!
    var fetchingRouteStatusRecorder: TestableObserver<FetchingRouteStatus>!
    
    override func setUp() {
        super.setUp()
        setUp(routeInteractor: PointToPointRouteInteractor(scheduler: scheduler))
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    private func setUp(routeInteractor: RouteInteractor) {
        listener = RecordingConfirmTripListener()
        viewModelUnderTest = DefaultConfirmTripViewModel(
            pickupLocation: DefaultConfirmTripViewModelTest.pickupLocation,
            dropoffLocation: DefaultConfirmTripViewModelTest.dropoffLocation,
            pickupIcon: DefaultConfirmTripViewModelTest.pickupIcon,
            dropoffIcon: DefaultConfirmTripViewModelTest.dropoffIcon,
            listener: listener,
            routeInteractor: routeInteractor,
            routeDisplayStringFormatter: DefaultConfirmTripViewModelTest.routeInfoDisplayString,
            logger: ConsoleLogger())
        
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest, scheduler: scheduler)
        
        routeInformationRecorder = scheduler.createObserver(NSAttributedString.self)
        viewModelUnderTest.getRouteInformation()
            .asDriver(onErrorJustReturn: NSAttributedString(string: ""))
            .drive(routeInformationRecorder)
            .disposed(by: disposeBag)

        fetchingRouteStatusRecorder = scheduler.createObserver(FetchingRouteStatus.self)
        viewModelUnderTest.fetchingRouteStatus
            .asDriver(onErrorJustReturn: .error)
            .drive(fetchingRouteStatusRecorder)
            .disposed(by: disposeBag)
    }
    
    func testStateMatchesExpectedBeforeConfirmation() {
        scheduler.start()
        assertRouteDerivedInfoMatchesExpectedAfterRouteIsFound()
        XCTAssertEqual(fetchingRouteStatusRecorder.events, [.next(0, .done)])
        XCTAssertEqual(listener.methodCalls, [])
    }
    
    func testStateMatchesExpectedAfterConfirmation() {
        viewModelUnderTest.confirmTrip(selectedVehicle: .automatic)
        scheduler.start()
        assertRouteDerivedInfoMatchesExpectedAfterRouteIsFound()
        XCTAssertEqual(fetchingRouteStatusRecorder.events, [.next(0, .done)])
        XCTAssertEqual(listener.selectedVehicle, .automatic)
        XCTAssertEqual(listener.methodCalls, ["confirmTrip(selectedVehicle:)"])
    }
    
    func testCancelCallsCancelConfirmTripOnListener() {
        scheduler.start()
        assertRouteDerivedInfoMatchesExpectedAfterRouteIsFound()
        XCTAssertEqual(fetchingRouteStatusRecorder.events, [.next(0, .done)])
        viewModelUnderTest.cancel()
        XCTAssertEqual(listener.methodCalls, ["cancelConfirmTrip()"])
    }
    
    func testStateMatchesExpectedBeforeRouteIsFound() {
        setUp(routeInteractor: EmptyRouteInteractor())
        scheduler.start()
        AssertRecordedElementsIgnoringCompletion(mapStateProviderRecorder.cameraUpdateRecorder.events, [])
        AssertRecordedElementsIgnoringCompletion(mapStateProviderRecorder.pathRecorder.events, [])
        AssertRecordedElementsIgnoringCompletion(mapStateProviderRecorder.markerRecorder.events, [
            [
                "pickup": DrawableMarker(coordinate: DefaultConfirmTripViewModelTest.pickupLocation,
                                         icon: DefaultConfirmTripViewModelTest.pickupIcon),
                "dropoff": DrawableMarker(coordinate: DefaultConfirmTripViewModelTest.dropoffLocation,
                                          icon: DefaultConfirmTripViewModelTest.dropoffIcon),
                ]
        ])
        AssertRecordedElementsIgnoringCompletion(routeInformationRecorder.events, [])
        XCTAssertEqual(fetchingRouteStatusRecorder.events, [.next(0, .inProgress)])
    }

    func testDelayingRouteResponseDelaysFlippingIsFetchingRouteToFalse() {
        setUp(routeInteractor: PointToPointRouteInteractor(scheduler: scheduler, delayTime: 5.0))
        scheduler.start()
        XCTAssertEqual(fetchingRouteStatusRecorder.events, [.next(0, .inProgress), .next(5, .done)])
    }

    func testMapSettingsMatchExpected() {
        scheduler.start()
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, MapSettings(shouldShowUserLocation: false, keepCenterWhileZooming: false)),
            .completed(0)
        ])
    }
    
    private func assertRouteDerivedInfoMatchesExpectedAfterRouteIsFound() {
        AssertRecordedElementsIgnoringCompletion(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .fitLatLngBounds(LatLngBounds(containingCoordinates: [
                DefaultConfirmTripViewModelTest.pickupLocation,
                DefaultConfirmTripViewModelTest.dropoffLocation
                ]))
        ])
        
        AssertRecordedElementsIgnoringCompletion(mapStateProviderRecorder.pathRecorder.events, [
            [DrawablePath.previewDrivingRouteLine(coordinates: [DefaultConfirmTripViewModelTest.pickupLocation,
                                                                DefaultConfirmTripViewModelTest.dropoffLocation])],
        ])
        
        AssertRecordedElementsIgnoringCompletion(mapStateProviderRecorder.markerRecorder.events, [
            [
                "pickup": DrawableMarker(coordinate: DefaultConfirmTripViewModelTest.pickupLocation,
                                         icon: DefaultConfirmTripViewModelTest.pickupIcon),
                "dropoff": DrawableMarker(coordinate: DefaultConfirmTripViewModelTest.dropoffLocation,
                                          icon: DefaultConfirmTripViewModelTest.dropoffIcon),
                ]
        ])
        
        AssertRecordedElementsIgnoringCompletion(routeInformationRecorder.events, [
            DefaultConfirmTripViewModelTest.routeInfoDisplayString(
                route: PointToPointRouteInteractor.route(
                    origin: DefaultConfirmTripViewModelTest.pickupLocation,
                    destination: DefaultConfirmTripViewModelTest.dropoffLocation))
        ])
    }

    func testEnableManualVehicleSelectionIsFalse() {
        XCTAssertFalse(viewModelUnderTest.enableManualVehicleSelection)
    }
    
    private static func routeInfoDisplayString(route: Route) -> NSAttributedString {
        return NSAttributedString(string: String(format: "%.1f, %.1f", route.travelDistanceMeters, route.travelTime))
    }
}
