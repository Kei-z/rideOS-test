import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest

class FixedLocationConfirmLocationViewModelTest: ReactiveTestCase {
    private static let cameraLocations = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 2),
    ]

    private static let stops = [
        Stop(location: CLLocationCoordinate2D(latitude: 3, longitude: 3), locationId: "stop 0"),
        Stop(location: CLLocationCoordinate2D(latitude: 4, longitude: 4), locationId: "stop 1"),
        Stop(location: CLLocationCoordinate2D(latitude: 5, longitude: 5), locationId: "stop 2")
    ]

    private static let fleet = FleetInfo(fleetId: "my_fleet",
                                         displayName: "",
                                         center: nil,
                                         isPhantom: false)

    private static let expectedStopMarkerId = "stop"
    private static let stopMarker = DrawableMarkerIcons.pickupPin()

    var viewModelUnderTest: FixedLocationConfirmLocationViewModel!
    var listener: RecordingConfirmLocationListener!
    var selectedLocationDisplayNameRecorder: TestableObserver<String>!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var reverseGeocodingStatusRecorder: TestableObserver<ReverseGeocodingStatus>!

    func setUp(geocodeInteractorDelay: RxTimeInterval) {
        super.setUp()
        ResolvedFleet.instance.set(resolvedFleet: FixedLocationConfirmLocationViewModelTest.fleet)
        listener = RecordingConfirmLocationListener()

        viewModelUnderTest = FixedLocationConfirmLocationViewModel(
            initialLocation: Observable.just(FixedLocationConfirmLocationViewModelTest.cameraLocations[0]).asSingle(),
            geocodeInteractor: EchoGeocodeInteractor(scheduler: scheduler, delayTime: geocodeInteractorDelay),
            stopInteractor: FixedStopInteractor(stops: FixedLocationConfirmLocationViewModelTest.stops,
                                                expectedFleetId: FixedLocationConfirmLocationViewModelTest.fleet.fleetId),
            stopMarker: FixedLocationConfirmLocationViewModelTest.stopMarker,
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
            .next(0, CameraUpdate.centerAndZoom(center: FixedLocationConfirmLocationViewModelTest.cameraLocations[0],
                                                zoom: Float(16))),
            .completed(0),
        ])

        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, [
                DrawablePath.walkingRouteLine(
                    coordinates: [
                        FixedLocationConfirmLocationViewModelTest.cameraLocations[0],
                        FixedLocationConfirmLocationViewModelTest.stops[0].location
                    ]
                )
            ]),
        ])

        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, [
                FixedLocationConfirmLocationViewModelTest.expectedStopMarkerId:
                    DrawableMarker(coordinate: FixedLocationConfirmLocationViewModelTest.stops[0].location,
                                   icon: FixedLocationConfirmLocationViewModelTest.stopMarker)
            ])
        ])

        XCTAssertEqual(reverseGeocodingStatusRecorder.events, [.next(0, .notInProgress)])

        XCTAssertNil(listener.confirmedLocation)
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testViewModelProducesExpectedEventsAfterCameraMovement() {
        setUp(geocodeInteractorDelay: 0.0)
        zip(
            1...FixedLocationConfirmLocationViewModelTest.cameraLocations.count,
            FixedLocationConfirmLocationViewModelTest.cameraLocations[1...]
        )
            .forEach { i, location in
                self.scheduler.scheduleAt(i, action: { self.viewModelUnderTest.onCameraMoved(location: location)})
            }
        scheduler.start()

        XCTAssertRecordedElements(
            selectedLocationDisplayNameRecorder.events,
            (0..<FixedLocationConfirmLocationViewModelTest.stops.count).map { _ in EchoGeocodeInteractor.displayName }
        )

        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, CameraUpdate.centerAndZoom(center: FixedLocationConfirmLocationViewModelTest.cameraLocations[0],
                                                zoom: Float(16))),
            .completed(0),
        ])

        XCTAssertEqual(
            mapStateProviderRecorder.pathRecorder.events,
            zip(
                0..<FixedLocationConfirmLocationViewModelTest.cameraLocations.count,
                zip(FixedLocationConfirmLocationViewModelTest.cameraLocations,
                    FixedLocationConfirmLocationViewModelTest.stops)
            )
                .map { args in
                    Recorded.next(
                        args.0,
                        [DrawablePath.walkingRouteLine(coordinates: [args.1.0, args.1.1.location])]
                    )
                }
        )

        XCTAssertEqual(
            mapStateProviderRecorder.markerRecorder.events,
            zip(
                0..<FixedLocationConfirmLocationViewModelTest.cameraLocations.count,
                FixedLocationConfirmLocationViewModelTest.stops
            )
                .map { i, stop in
                    Recorded.next(
                        i,
                        [
                            FixedLocationConfirmLocationViewModelTest.expectedStopMarkerId:
                                DrawableMarker(coordinate: stop.location,
                                               icon: FixedLocationConfirmLocationViewModelTest.stopMarker)
                        ]
                    )
                }
        )

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
                    tripLocation: TripLocation(location: FixedLocationConfirmLocationViewModelTest.cameraLocations[0]),
                    displayName: EchoGeocodeInteractor.displayName
                ),
                assignedLocation: NamedTripLocation(
                    tripLocation: TripLocation(location: FixedLocationConfirmLocationViewModelTest.stops[0].location,
                                               locationId: FixedLocationConfirmLocationViewModelTest.stops[0].locationId),
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
            .next(0, .inProgress),
            .next(5, .notInProgress),
        ])
    }
}
