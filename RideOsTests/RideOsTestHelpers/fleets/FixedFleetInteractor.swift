import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public class FixedFleetInteractor: FleetInteractor {
    private let fleets: [FleetInfo]

    public init(fleets: [FleetInfo]) {
        self.fleets = fleets
    }

    public var availableFleets: Observable<[FleetInfo]> {
        return Observable.just(fleets)
    }
}
