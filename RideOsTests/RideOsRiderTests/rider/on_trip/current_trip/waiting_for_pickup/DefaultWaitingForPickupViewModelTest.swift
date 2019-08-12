import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxTest
import XCTest

class DefaultWaitingForPickupViewModelTest: ReactiveTestCase {
    var viewModelUnderTest: DefaultWaitingForPickupViewModel!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var dialogModelRecorder: TestableObserver<MatchedToVehicleStatusModel>!
    
    let expectedStatus = "Your ride has arrived!"
    
    let passengerStateModels: [RiderTripStateModel] = [
        .waitingForPickup(
            passengerPickupLocation: GeocodedLocationModel(displayName: "pickup0",
                                                           location: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
            passengerDropoffLocation: GeocodedLocationModel(displayName: "dropoff0",
                                                            location: CLLocationCoordinate2D(latitude: 1, longitude: 1)),
            vehiclePosition: VehiclePosition(vehicleId: "vehicle0",
                                             position: CLLocationCoordinate2D(latitude: 2, longitude: 2),
                                             heading: 45),
            vehicleInfo: VehicleInfo(licensePlate: "LICENSE0", contactInfo: ContactInfo())
        ),
        .waitingForPickup(
            passengerPickupLocation: GeocodedLocationModel(displayName: "pickup0",
                                                           location: CLLocationCoordinate2D(latitude: 3, longitude: 3)),
            passengerDropoffLocation: GeocodedLocationModel(displayName: "dropoff0",
                                                            location: CLLocationCoordinate2D(latitude: 4, longitude: 4)),
            vehiclePosition: VehiclePosition(vehicleId: "vehicle1",
                                             position: CLLocationCoordinate2D(latitude: 5, longitude: 5),
                                             heading: 45),
            vehicleInfo: VehicleInfo(licensePlate: "LICENSE1", contactInfo: ContactInfo())
        ),
    ]
    
    func setUp(initialPassengerState: RiderTripStateModel) {
        super.setUp()
        viewModelUnderTest = DefaultWaitingForPickupViewModel(initialPassengerState: initialPassengerState)
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest,
                                                            scheduler: scheduler)
        dialogModelRecorder = scheduler.record(viewModelUnderTest.dialogModel)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testViewModelProducesExpectedEventsOnInitialization() {
        setUp(initialPassengerState: passengerStateModels[0])
        guard case RiderTripStateModel.waitingForPickup(let pickup,
                                                       let dropoff,
                                                       let vehiclePosition,
                                                       let vehicleInfo) = passengerStateModels[0] else {
                                                        fatalError("Unexpected PassengerStateModel case")
        }
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [pickup.location, vehiclePosition.position])))
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: pickup.location),
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition)
            ]))
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [.next(0, [])])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, MapSettings(shouldShowUserLocation: true))
        ])
        XCTAssertEqual(dialogModelRecorder.events, [
            .next(0, MatchedToVehicleStatusModel(status: expectedStatus,
                                                 nextWaypoint: pickup.displayName,
                                                 vehicleInfo: vehicleInfo)
            )
        ])
    }
    
    func testViewModelProducesExpectedEventsOnSubsequentUpdate() {
        setUp(initialPassengerState: passengerStateModels[0])
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.updatePassengerState(self.passengerStateModels[1])
        })
        
        scheduler.advanceTo(1)
        
        guard case RiderTripStateModel.waitingForPickup(let pickup,
                                                       let dropoff,
                                                       let vehiclePosition,
                                                       let vehicleInfo) = passengerStateModels[0] else {
                                                        fatalError("Unexpected PassengerStateModel case")
        }
        guard case RiderTripStateModel.waitingForPickup(let pickup1,
                                                       let dropoff1,
                                                       let vehiclePosition1,
                                                       let vehicleInfo1) = passengerStateModels[1] else {
                                                        fatalError("Unexpected PassengerStateModel case")
        }
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [pickup.location, vehiclePosition.position]))),
            .next(1, .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [pickup1.location, vehiclePosition1.position]))),
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: pickup.location),
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition)
            ])),
            .next(1, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: pickup1.location),
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff1.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition1)
            ]))
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, []),
            .next(1, [])
        ])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, MapSettings(shouldShowUserLocation: true)),
            .next(1, MapSettings(shouldShowUserLocation: true))
        ])
        XCTAssertEqual(dialogModelRecorder.events, [
            .next(0, MatchedToVehicleStatusModel(status: expectedStatus,
                                                 nextWaypoint: pickup.displayName,
                                                 vehicleInfo: vehicleInfo)
            ),
            .next(1, MatchedToVehicleStatusModel(status: expectedStatus,
                                                 nextWaypoint: pickup1.displayName,
                                                 vehicleInfo: vehicleInfo1)
            )
        ])
    }
    
    func testPassengerStateNotEqualToDrivingToPickupCausesViewModelToProduceNoEvents() {
        setUp(initialPassengerState: .unknown)
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [])
        XCTAssertEqual(dialogModelRecorder.events, [])
    }
}
