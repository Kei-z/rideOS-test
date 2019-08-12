import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxTest
import XCTest

class DefaultMatchedToVehicleViewModelTest: ReactiveTestCase {
    var viewModelUnderTest: DefaultMatchedToVehicleViewModel!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    var dialogModelRecorder: TestableObserver<MatchedToVehicleStatusModel>!
    
    static let pickupLocation = GeocodedLocationModel(displayName: "pickup",
                                                      location: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    static let dropoffLocation = GeocodedLocationModel(displayName: "dropoff",
                                                       location: CLLocationCoordinate2D(latitude: 1, longitude: 1))
    
    static let passengerStateModels: [RiderTripStateModel] = [
        .waitingForAssignment(passengerPickupLocation: DefaultCurrentTripViewModelTest.pickupLocation,
                              passengerDropoffLocation: DefaultCurrentTripViewModelTest.dropoffLocation),
        .unknown,
        .completed(passengerPickupLocation: DefaultCurrentTripViewModelTest.pickupLocation,
                   passengerDropoffLocation: DefaultCurrentTripViewModelTest.dropoffLocation)
    ]
    
    static let expectedMatchedToVehicleModels: [MatchedToVehicleModel] = [
        MatchedToVehicleModel(
            cameraUpdate: .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [DefaultMatchedToVehicleViewModelTest.pickupLocation.location])
            ),
            paths: [],
            markers: [:], 
            dialogModel: MatchedToVehicleStatusModel(status: "status0",
                                                     nextWaypoint: "waypoint0",
                                                     vehicleInfo: VehicleInfo(licensePlate: "vehicleLicensePlate0",
                                                                              contactInfo: ContactInfo())),
            mapSettings: MapSettings(shouldShowUserLocation: true)
        ),
        MatchedToVehicleModel(
            cameraUpdate: .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [DefaultMatchedToVehicleViewModelTest.dropoffLocation.location])
            ),
            paths: [],
            markers: [:],
            dialogModel: MatchedToVehicleStatusModel(status: "status1",
                                                     nextWaypoint: "waypoint1",
                                                     vehicleInfo: VehicleInfo(licensePlate: "vehicleLicensePlate1",
                                                                              contactInfo: ContactInfo())),
            mapSettings: MapSettings(shouldShowUserLocation: false)
        ),
        MatchedToVehicleModel(
            cameraUpdate: .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [DefaultMatchedToVehicleViewModelTest.pickupLocation.location])
            ),
            paths: [],
            markers: [:],
            dialogModel: MatchedToVehicleStatusModel(status: "status2",
                                                     nextWaypoint: "waypoint2",
                                                     vehicleInfo: VehicleInfo(licensePlate: "vehicleLicensePlate2",
                                                                              contactInfo: ContactInfo())),
            mapSettings: MapSettings(shouldShowUserLocation: true)
        )
    ]
    
    func setUp(modelProvider: @escaping (RiderTripStateModel) -> MatchedToVehicleModel?) {
        super.setUp()
        viewModelUnderTest = DefaultMatchedToVehicleViewModel(
            modelProvider: modelProvider,
            initialPassengerState: DefaultMatchedToVehicleViewModelTest.passengerStateModels[0]
        )
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest,
                                                            scheduler: scheduler)
        dialogModelRecorder = scheduler.record(viewModelUnderTest.dialogModel)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testViewModelProducesExpectedElementsWhenModelProviderReturnsNil() {
        setUp(modelProvider: { _ in return nil })
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [])
        XCTAssertEqual(dialogModelRecorder.events, [])
    }
    
    func testViewModelProducesExpectedEventsOnInitialization() {
        setUp(modelProvider: provideMatchedToVehicleModel)
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].cameraUpdate)
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].markers)
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].paths)
        ])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].mapSettings)
        ])
        XCTAssertEqual(dialogModelRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].dialogModel)
        ])
    }
    
    func testViewModelProducesExpectedEventsOnSubsequentUpdate() {
        setUp(modelProvider: provideMatchedToVehicleModel)
        
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.updatePassengerState(DefaultMatchedToVehicleViewModelTest.passengerStateModels[1])
        })
        
        scheduler.advanceTo(1)
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].cameraUpdate),
            .next(1, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[1].cameraUpdate)
        ])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].markers),
            .next(1, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[1].markers)
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].paths),
            .next(1, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[1].paths)
        ])
        XCTAssertEqual(mapStateProviderRecorder.mapSettingsRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].mapSettings),
            .next(1, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[1].mapSettings)
        ])
        XCTAssertEqual(dialogModelRecorder.events, [
            .next(0, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[0].dialogModel),
            .next(1, DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[1].dialogModel)
        ])
    }
    
    func provideMatchedToVehicleModel(_ passengerStateModel: RiderTripStateModel) -> MatchedToVehicleModel? {
        guard let index = DefaultMatchedToVehicleViewModelTest.passengerStateModels.firstIndex(of: passengerStateModel) else {
            fatalError("Invalid PassengerStateModel")
        }
        return DefaultMatchedToVehicleViewModelTest.expectedMatchedToVehicleModels[index]
    }
}
