import CoreLocation
import Foundation
import RideOsDriver
import RideOsTestHelpers
import RxSwift

class RecordingVehicleStateSynchronizer: MethodCallRecorder, VehicleStateSynchronizer {
    private let synchronizeVehicleStateCompletable: Completable

    public init(synchronizeVehicleStateCompletable: Completable = Completable.empty()) {
        self.synchronizeVehicleStateCompletable = synchronizeVehicleStateCompletable
    }

    func synchronizeVehicleState(vehicleId _: String,
                                 vehicleCoordinate _: CLLocationCoordinate2D,
                                 vehicleHeading _: CLLocationDirection) -> Completable {
        recordMethodCall(#function)
        return synchronizeVehicleStateCompletable
    }
}
