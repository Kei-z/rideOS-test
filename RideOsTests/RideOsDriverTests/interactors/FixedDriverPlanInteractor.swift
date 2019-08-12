import CoreLocation
import Foundation
import RideOsApi
import RideOsDriver
import RideOsTestHelpers
import RxSwift

public class FixedDriverPlanInteractor: MethodCallRecorder, DriverPlanInteractor {
    private let vehiclePlan: VehiclePlan

    public init(vehiclePlan: VehiclePlan = VehiclePlan(waypoints: [])) {
        self.vehiclePlan = vehiclePlan
    }

    public func getPlanForVehicle(vehicleId _: String) -> Observable<VehiclePlan> {
        recordMethodCall(#function)
        return Observable.just(vehiclePlan)
    }
}
