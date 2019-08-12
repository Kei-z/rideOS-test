import CoreLocation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import XCTest

class DefaultStartScreenViewModelTest: ReactiveTestCase {
    private static let deviceLocation = CLLocation(latitude: 42, longitude: 42)
    private let vehicles = [
        VehiclePosition(vehicleId: "vehicle 0",
                        position: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                        heading: 1),
        VehiclePosition(vehicleId: "vehicle 1",
                        position: CLLocationCoordinate2D(latitude: 2, longitude: 2),
                        heading: 2),
    ]
    var viewModelUnderTest: DefaultStartScreenViewModel!
    var listener: RecordingStartScreenListener!
    var mapStateProviderRecorder: MapStateProviderRecorder!
    
    override func setUp() {
        super.setUp()
        ResolvedFleet.instance.set(resolvedFleet: FleetInfo.defaultFleetInfo)
        listener = RecordingStartScreenListener()
        viewModelUnderTest = DefaultStartScreenViewModel(
            listener: listener,
            vehicleInteractor: FixedVehicleInteractor(vehicles: vehicles),
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            deviceLocator: FixedDeviceLocator(deviceLocation: DefaultStartScreenViewModelTest.deviceLocation),
            logger: ConsoleLogger()
        )
        mapStateProviderRecorder = MapStateProviderRecorder(mapStateProvider: viewModelUnderTest, scheduler: scheduler)
        
        viewModelUnderTest.mapCenterDidMove(to: CLLocationCoordinate2D(latitude: 0, longitude: 0))
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testStartLocationSearchCallsListener() {
        viewModelUnderTest.startLocationSearch()
        XCTAssertEqual(listener.methodCalls, ["startLocationSearch()"])
    }
    
    func testProvidesExpectedMapState() {
        let expectedMarkers = Dictionary(uniqueKeysWithValues: vehicles.map {
            ($0.vehicleId, DrawableMarker(coordinate: $0.position,
                                          heading: $0.heading,
                                          icon: DrawableMarkerIcons.car()))
        })
        
        // Allow 3 ticks to pass
        scheduler.advanceTo(3)
        
        XCTAssertEqual(mapStateProviderRecorder.cameraUpdateRecorder.events, [
            .next(0, CameraUpdate.centerAndZoom(center: DefaultStartScreenViewModelTest.deviceLocation.coordinate,
                                                zoom: 15.0)),
            .completed(0),
        ])
        XCTAssertEqual(mapStateProviderRecorder.pathRecorder.events, [.next(0, []), .completed(0)])
        XCTAssertEqual(mapStateProviderRecorder.markerRecorder.events, [
            // We expect 3 next events - one per tick
            .next(1, expectedMarkers),
            .next(2, expectedMarkers),
            .next(3, expectedMarkers),
        ])
    }
}

class RecordingStartScreenListener: MethodCallRecorder, StartScreenListener {
    func startLocationSearch() {
        recordMethodCall(#function)
    }
}
