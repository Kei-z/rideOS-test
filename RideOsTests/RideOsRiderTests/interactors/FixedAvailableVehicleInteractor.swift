import CoreLocation
import Foundation
import RideOsRider
import RxSwift

public class FixedAvailableVehicleInteractor: AvailableVehicleInteractor {
    private let vehicles: [AvailableVehicle]

    public init(vehicles: [AvailableVehicle]) {
        self.vehicles = vehicles
    }

    public func getAvailableVehicles(inFleet fleetId: String) -> Observable<[AvailableVehicle]> {
        return Observable.just(vehicles)
    }
}
