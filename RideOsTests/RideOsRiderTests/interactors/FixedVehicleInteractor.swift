import CoreLocation
import Foundation
import RideOsRider
import RxSwift

public class FixedVehicleInteractor: VehicleInteractor {
    private let vehicles: [VehiclePosition]
    
    public init(vehicles: [VehiclePosition]) {
        self.vehicles = vehicles
    }
    
    public func getVehiclesInVicinity(center: CLLocationCoordinate2D, fleetId: String) -> Observable<[VehiclePosition]> {
        return Observable.just(vehicles)
    }
}
