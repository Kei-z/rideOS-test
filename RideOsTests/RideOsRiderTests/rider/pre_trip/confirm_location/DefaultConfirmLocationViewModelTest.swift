import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest

class DefaultConfirmLocationViewModelTest: ReactiveTestCase {
    private static let cameraLocations = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 2),
    ]

    var viewModelUnderTest: DefaultConfirmLocationViewModel!
    var listener: RecordingConfirmLocationListener!
    var selectedLocationDisplayNameRecorder: TestableObserver<String>!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var reverseGeocodingStatusRecorder: TestableObserver<ReverseGeocodingStatus>!

    func setUp(geocodeInteractorDelay: RxTimeInterval) {
        super.setUp()
        listener = RecordingConfirmLocationListener()
        
        viewModelUnderTest = DefaultConfirmLocationViewModel(
            initialLocation: Observable.just(DefaultConfirmLocationViewModelTest.cameraLocations[0]).asSingle(),
            geocodeInteractor: EchoGeocodeInteractor(scheduler: scheduler, delayTime: geocodeInteractorDelay),
            listener: listener,
            logger: ConsoleLogger()
        )

        selectedLocationDisplayNameRecorder = scheduler.record(viewModelUnderTest.selectedLocationDisplayName)
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest, scheduler: scheduler)

        reverseGeocodingStatusRecorder = scheduler.createObserver(ReverseGeocodingStatus.self)
        viewModelUnderTest.reverseGeocodingStatus
            .asDriver(onErrorJustReturn: .error)
            .drive(reverseGeocodingStatusRecorder)
            .disposed(by: disposeBag)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelProducesExpectedEventsOnInitialization() {
        setUp(geocodeInteractorDelay: 0.0)
        scheduler.start()

        XCTAssertRecordedElements(selectedLocationDisplayNameRecorder.events, [EchoGeocodeInteractor.displayName])

        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, CameraUpdate.centerAndZoom(center: DefaultConfirmLocationViewModelTest.cameraLocations[0],
                                                zoom: Float(16))),
            .completed(0),
        ])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, MapSettings(keepCenterWhileZooming: true)),
            .completed(0),
        ])

        XCTAssertEqual(reverseGeocodingStatusRecorder.events, [.next(0, .notInProgress)])

        XCTAssertNil(listener.confirmedLocation)
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testViewModelProducesExpectedEventsAfterCameraMovement() {
        setUp(geocodeInteractorDelay: 0.0)
        zip(
            1...DefaultConfirmLocationViewModelTest.cameraLocations.count,
            DefaultConfirmLocationViewModelTest.cameraLocations[1...]
        )
            .forEach { i, location in
                self.scheduler.scheduleAt(i) { self.viewModelUnderTest.onCameraMoved(location: location)}
            }

        scheduler.start()

        XCTAssertEqual(
            selectedLocationDisplayNameRecorder.events,
            (0..<DefaultConfirmLocationViewModelTest.cameraLocations.count).map { i in
                Recorded.next(
                    i,
                    EchoGeocodeInteractor.displayName
                )
            }
        )

        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, CameraUpdate.centerAndZoom(center: DefaultConfirmLocationViewModelTest.cameraLocations[0],
                                                zoom: Float(16))),
            .completed(0),
        ])

        // Each camera update should cause reverseGeocodingStatus to flip to inProgress and then immediately back to
        // notInProgress as the GeocodeInteractor immediately emits a response
        XCTAssertEqual(reverseGeocodingStatusRecorder.events, [
            .next(0, .notInProgress),
            .next(1, .inProgress),
            .next(1, .notInProgress),
            .next(2, .inProgress),
            .next(2, .notInProgress),
        ])

        XCTAssertNil(listener.confirmedLocation)
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testCallingConfirmLocationOnViewModelCallsConfirmedLocationOnListener() {
        setUp(geocodeInteractorDelay: 0.0)
        viewModelUnderTest.confirmLocation()
        scheduler.start()

        XCTAssertEqual(
            listener.confirmedLocation,
            DesiredAndAssignedLocation(
                desiredLocation: NamedTripLocation(
                    tripLocation: TripLocation(location: DefaultConfirmLocationViewModelTest.cameraLocations[0]),
                    displayName: EchoGeocodeInteractor.displayName
                )
            )
        )
        XCTAssertEqual(listener.methodCalls, ["confirmLocation(_:)"])
    }

    func testDelayInReverseGeocodingLeadsToDelayInIsReverseGeocodingInProgressFlippingBackToFalse() {
        setUp(geocodeInteractorDelay: 5.0)
        scheduler.start()

        XCTAssertEqual(reverseGeocodingStatusRecorder.events, [
            .next(0, ReverseGeocodingStatus.inProgress),
            .next(5, ReverseGeocodingStatus.notInProgress),
        ])
    }
}
