import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxTest
import XCTest

class DefaultWaitingForAssignmentViewModelTest: ReactiveTestCase {
    var viewModelUnderTest: DefaultWaitingForAssignmentViewModel!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var pickupDropoffRecorder: TestableObserver<GeocodedPickupDropoff>!
    
    let passengerStateModels: [RiderTripStateModel] = [
        .waitingForAssignment(
            passengerPickupLocation: GeocodedLocationModel(displayName: "pickup0",
                                                           location: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
            passengerDropoffLocation: GeocodedLocationModel(displayName: "dropoff0",
                                                            location: CLLocationCoordinate2D(latitude: 1, longitude: 1))
        ),
        .waitingForAssignment(
            passengerPickupLocation: GeocodedLocationModel(displayName: "pickup1",
                                                           location: CLLocationCoordinate2D(latitude: 2, longitude: 2)),
            passengerDropoffLocation: GeocodedLocationModel(displayName: "dropoff1",
                                                            location: CLLocationCoordinate2D(latitude: 3, longitude: 3))
        ),
    ]
    
    func setUp(initialPassengerState: RiderTripStateModel) {
        super.setUp()
        viewModelUnderTest = DefaultWaitingForAssignmentViewModel(
            initialPassengerState: initialPassengerState,
            routeInteractor: PointToPointRouteInteractor(scheduler: scheduler),
            logger: ConsoleLogger()
        )
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest,
                                                            scheduler: scheduler)
        pickupDropoffRecorder = scheduler.record(viewModelUnderTest.pickupDropoff)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testViewModelProducesExpectedEventsOnInitialization() {
        setUp(initialPassengerState: passengerStateModels[0])
        let route = PointToPointRouteInteractor.route(
            origin: passengerStateModels[0].pickupLocation.location,
            destination: passengerStateModels[0].dropoffLocation.location
        )
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, .fitLatLngBounds(LatLngBounds(containingCoordinates: route.coordinates)))
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: passengerStateModels[0].pickupLocation.location),
                CurrentTripMarkers.markerFor(dropoffLocation: passengerStateModels[0].dropoffLocation.location),
            ]))
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, [DrawablePath.drivingRouteLine(coordinates: route.coordinates)])
        ])
        XCTAssertEqual(pickupDropoffRecorder.events, [
            .next(0, GeocodedPickupDropoff(pickup: passengerStateModels[0].pickupLocation,
                                           dropoff: passengerStateModels[0].dropoffLocation))
        ])
    }
    
    func testViewModelProducesExpectedEventsOnSubsequentUpdate() {
        setUp(initialPassengerState: passengerStateModels[0])
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.updatePassengerState(self.passengerStateModels[1])
        })

        scheduler.advanceTo(1)
        
        let route0 = PointToPointRouteInteractor.route(
            origin: passengerStateModels[0].pickupLocation.location,
            destination: passengerStateModels[0].dropoffLocation.location
        )
        let route1 = PointToPointRouteInteractor.route(
            origin: passengerStateModels[1].pickupLocation.location,
            destination: passengerStateModels[1].dropoffLocation.location
        )
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, .fitLatLngBounds(LatLngBounds(containingCoordinates: route0.coordinates))),
            .next(1, .fitLatLngBounds(LatLngBounds(containingCoordinates: route1.coordinates)))
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: passengerStateModels[0].pickupLocation.location),
                CurrentTripMarkers.markerFor(dropoffLocation: passengerStateModels[0].dropoffLocation.location),
            ])),
            .next(1, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: passengerStateModels[1].pickupLocation.location),
                CurrentTripMarkers.markerFor(dropoffLocation: passengerStateModels[1].dropoffLocation.location),
            ]))
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, [DrawablePath.drivingRouteLine(coordinates: route0.coordinates)]),
            .next(1, [DrawablePath.drivingRouteLine(coordinates: route1.coordinates)])
        ])
        XCTAssertEqual(pickupDropoffRecorder.events, [
            .next(0, GeocodedPickupDropoff(pickup: passengerStateModels[0].pickupLocation,
                                           dropoff: passengerStateModels[0].dropoffLocation)),
            .next(1, GeocodedPickupDropoff(pickup: passengerStateModels[1].pickupLocation,
                                           dropoff: passengerStateModels[1].dropoffLocation))
        ])
    }
    
    func testPassengerStateNotEqualToWaitingForAssignmentCausesViewModelToProduceNoAdditionalEvents() {
        setUp(initialPassengerState: .unknown)
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [])
        XCTAssertEqual(pickupDropoffRecorder.events, [])
    }
}
