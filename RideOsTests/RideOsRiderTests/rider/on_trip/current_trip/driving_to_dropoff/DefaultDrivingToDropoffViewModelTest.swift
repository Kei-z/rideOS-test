import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxTest
import XCTest

class DefaultDrivingToDropoffViewModelTest: ReactiveTestCase {
    var viewModelUnderTest: DefaultDrivingToDropoffViewModel!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var dialogModelRecorder: TestableObserver<MatchedToVehicleStatusModel>!
    
    let expectedStatusPrefix = "You will arrive by "
    let currentDateProvider: () -> Date = { Date(timeIntervalSinceReferenceDate: 0) }
    
    let passengerStateModels: [RiderTripStateModel] = [
        .drivingToDropoff(
            passengerPickupLocation: GeocodedLocationModel(displayName: "pickup0",
                                                           location: CLLocationCoordinate2D(latitude: 0, longitude: 0)),
            passengerDropoffLocation: GeocodedLocationModel(displayName: "dropoff0",
                                                            location: CLLocationCoordinate2D(latitude: 1, longitude: 1)),
            route: Route(
                coordinates: [
                    CLLocationCoordinate2D(latitude: 0, longitude: 0),
                    CLLocationCoordinate2D(latitude: 1, longitude: 1)
                ],
                travelTime: 60*5,
                travelDistanceMeters: 50
            ),
            vehiclePosition: VehiclePosition(vehicleId: "vehicle0",
                                             position: CLLocationCoordinate2D(latitude: 2, longitude: 2),
                                             heading: 45),
            vehicleInfo: VehicleInfo(licensePlate: "LICENSE0", contactInfo: ContactInfo()),
            waypoints: []
        ),
        .drivingToDropoff(
            passengerPickupLocation: GeocodedLocationModel(displayName: "pickup0",
                                                           location: CLLocationCoordinate2D(latitude: 3, longitude: 3)),
            passengerDropoffLocation: GeocodedLocationModel(displayName: "dropoff0",
                                                            location: CLLocationCoordinate2D(latitude: 4, longitude: 4)),
            route: Route(
                coordinates: [
                    CLLocationCoordinate2D(latitude: 3, longitude: 3),
                    CLLocationCoordinate2D(latitude: 4, longitude: 4)
                ],
                travelTime: 60*10,
                travelDistanceMeters: 500
            ),
            vehiclePosition: VehiclePosition(vehicleId: "vehicle1",
                                             position: CLLocationCoordinate2D(latitude: 5, longitude: 5),
                                             heading: 45),
            vehicleInfo: VehicleInfo(licensePlate: "LICENSE1", contactInfo: ContactInfo()),
            waypoints: [
                PassengerWaypoint(location: CLLocationCoordinate2D(latitude: 6, longitude: 6)),
                PassengerWaypoint(location: CLLocationCoordinate2D(latitude: 7, longitude: 7))
            ]
        ),
    ]
    
    func setUp(initialPassengerState: RiderTripStateModel) {
        super.setUp()
        viewModelUnderTest = DefaultDrivingToDropoffViewModel(initialPassengerState: initialPassengerState,
                                                              currentDateProvider: currentDateProvider)
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest,
                                                            scheduler: scheduler)
        dialogModelRecorder = scheduler.record(viewModelUnderTest.dialogModel)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testViewModelProducesExpectedEventsOnInitialization() {
        setUp(initialPassengerState: passengerStateModels[0])
        guard case RiderTripStateModel.drivingToDropoff(_,
                                                        let dropoff,
                                                        let route,
                                                        let vehiclePosition,
                                                        let vehicleInfo,
                                                        _) = passengerStateModels[0] else {
                                                            fatalError("Unexpected PassengerStateModel case")
        }
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, .fitLatLngBounds(
                LatLngBounds(containingCoordinates: route.coordinates + [dropoff.location, vehiclePosition.position])))
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition)
            ]))
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, [DrawablePath.drivingRouteLine(coordinates: route.coordinates)])
        ])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, MapSettings(shouldShowUserLocation: false))
        ])
        XCTAssertEqual(dialogModelRecorder.events, [
            .next(
                0,
                MatchedToVehicleStatusModel(
                    status: expectedStatusPrefix + String.timeOfDayLabelFrom(startDate: currentDateProvider(),
                                                                             interval: route.travelTime),
                    nextWaypoint: dropoff.displayName,
                    vehicleInfo: vehicleInfo
                )
            )
        ])
    }
    
    func testViewModelProducesExpectedEventsOnSubsequentUpdate() {
        setUp(initialPassengerState: passengerStateModels[0])
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.updatePassengerState(self.passengerStateModels[1])
        })
        
        scheduler.advanceTo(1)
        
        guard case RiderTripStateModel.drivingToDropoff(_,
                                                        let dropoff,
                                                        let route,
                                                        let vehiclePosition,
                                                        let vehicleInfo,
                                                        _) = passengerStateModels[0] else {
                                                            fatalError("Unexpected PassengerStateModel case")
        }
        guard case RiderTripStateModel.drivingToDropoff(_,
                                                        let dropoff1,
                                                        let route1,
                                                        let vehiclePosition1,
                                                        let vehicleInfo1,
                                                        let waypoints1) = passengerStateModels[1] else {
                                                            fatalError("Unexpected PassengerStateModel case")
        }
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, .fitLatLngBounds(
                LatLngBounds(containingCoordinates: route.coordinates + [dropoff.location, vehiclePosition.position]))),
            .next(1, .fitLatLngBounds(
                LatLngBounds(containingCoordinates: route1.coordinates + [dropoff1.location, vehiclePosition1.position])))
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition),
            ])),
            .next(1, Dictionary.init(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff1.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition1)
            ] + CurrentTripMarkers.markersFor(waypoints: waypoints1)))
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, [DrawablePath.drivingRouteLine(coordinates: route.coordinates)]),
            .next(1, [DrawablePath.drivingRouteLine(coordinates: route1.coordinates)])
        ])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, MapSettings(shouldShowUserLocation: false)),
            .next(1, MapSettings(shouldShowUserLocation: false))
        ])
        XCTAssertEqual(dialogModelRecorder.events, [
            .next(
                0,
                MatchedToVehicleStatusModel(
                    status: expectedStatusPrefix + String.timeOfDayLabelFrom(startDate: currentDateProvider(),
                                                                             interval: route.travelTime),
                    nextWaypoint: dropoff.displayName,
                    vehicleInfo: vehicleInfo
                )
            ),
            .next(
                1,
                MatchedToVehicleStatusModel(
                    status: expectedStatusPrefix + String.timeOfDayLabelFrom(startDate: currentDateProvider(),
                                                                             interval: route1.travelTime),
                    nextWaypoint: dropoff1.displayName,
                    vehicleInfo: vehicleInfo1
                )
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
