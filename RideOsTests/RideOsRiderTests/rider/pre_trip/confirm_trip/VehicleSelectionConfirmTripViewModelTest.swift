import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxTest
import XCTest

class VehicleSelectionConfirmTripViewModelTest: ReactiveTestCase {
    private static let vehicles = [
        AvailableVehicle(vehicleId: "vehicle0", displayName: "B"),
        AvailableVehicle(vehicleId: "vehicle1", displayName: "A"),
    ]

    var viewModelUnderTest: VehicleSelectionConfirmTripViewModel!
    var vehicleSelectionOptionsRecorder: TestableObserver<[VehicleSelectionOption]>!

    override func setUp() {
        super.setUp()

        ResolvedFleet.instance.set(resolvedFleet: FleetInfo.defaultFleetInfo)

        viewModelUnderTest = VehicleSelectionConfirmTripViewModel(
            pickupLocation: DefaultConfirmTripViewModelTest.pickupLocation,
            dropoffLocation: DefaultConfirmTripViewModelTest.dropoffLocation,
            pickupIcon: DefaultConfirmTripViewModelTest.pickupIcon,
            dropoffIcon: DefaultConfirmTripViewModelTest.dropoffIcon,
            listener: RecordingConfirmTripListener(),
            routeInteractor: PointToPointRouteInteractor(scheduler: scheduler),
            routeDisplayStringFormatter: VehicleSelectionConfirmTripViewModelTest.routeInfoDisplayString,
            availableVehicleInteractor: FixedAvailableVehicleInteractor(vehicles: VehicleSelectionConfirmTripViewModelTest.vehicles),
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger()
        )
        vehicleSelectionOptionsRecorder = scheduler.record(viewModelUnderTest.vehicleSelectionOptions)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testEnableManualVehicleSelectionIsTrue() {
        XCTAssertTrue(viewModelUnderTest.enableManualVehicleSelection)
    }

    func testVehicleSelectionOptionsMatchExpected() {
        let manualVehicleOptions = VehicleSelectionConfirmTripViewModelTest
            .vehicles
            .sorted { $0.displayName < $1.displayName }
            .map { VehicleSelectionOption.manual(vehicle: $0) }
        scheduler.start()
        XCTAssertEqual(vehicleSelectionOptionsRecorder.events, [
            .next(2, [.automatic] + manualVehicleOptions)
        ])
    }

    private static func routeInfoDisplayString(route: Route) -> NSAttributedString {
        return NSAttributedString(string: "")
    }
}
