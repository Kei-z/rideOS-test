import CoreLocation
import Foundation
import RideOsApi
import RideOsDriver
import RideOsTestHelpers
import RxSwift

public class FixedDriverVehicleInteractor: MethodCallRecorder, DriverVehicleInteractor {
    private let vehicleState: RideHailCommonsVehicleState

    public init(vehicleState: RideHailCommonsVehicleState = RideHailCommonsVehicleState()) {
        self.vehicleState = vehicleState
    }

    public func createVehicle(vehicleId _: String,
                              fleetId: String,
                              vehicleInfo: VehicleRegistration) -> Completable {
        recordMethodCall(#function)
        return Completable.empty()
    }

    public func markVehicleReady(vehicleId _: String) -> Completable {
        recordMethodCall(#function)
        return Completable.empty()
    }

    public func markVehicleNotReady(vehicleId _: String) -> Completable {
        recordMethodCall(#function)
        return Completable.empty()
    }

    public func finishSteps(vehicleId _: String, taskId _: String, stepIds _: [String]) -> Completable {
        recordMethodCall(#function)
        return Completable.empty()
    }

    public func getVehicleState(vehicleId _: String) -> Single<RideHailCommonsVehicleState> {
        recordMethodCall(#function)
        return Single.just(vehicleState)
    }

    public func updateVehiclePose(vehicleId _: String,
                                  vehicleCoordinate _: CLLocationCoordinate2D,
                                  vehicleHeading _: CLLocationDirection) -> Completable {
        recordMethodCall(#function)
        return Completable.empty()
    }

    public func updateVehicleRouteLegs(
        vehicleId _: String,
        legs _: [RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition]
    ) -> Completable {
        recordMethodCall(#function)
        return Completable.empty()
    }
}
