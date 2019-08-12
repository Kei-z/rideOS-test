import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public class FixedFleetOptionResolver: FleetOptionResolver {
    private let manualFleets: [FleetInfo]
    private let automaticallyResolvedFleet: FleetInfo

    public init(manualFleets: [FleetInfo], automaticallyResolvedFleet: FleetInfo) {
        self.manualFleets = manualFleets
        self.automaticallyResolvedFleet = automaticallyResolvedFleet
    }

    public func resolve(fleetOption: FleetOption) -> Observable<FleetInfoResolutionResponse> {
        switch fleetOption {
        case .automatic:
            return Observable.just(FleetInfoResolutionResponse(fleetInfo: automaticallyResolvedFleet,
                                                               wasRequestedFleetAvailable: true))
        case let .manual(fleetInfo):
            if let index = manualFleets.firstIndex(where: { $0.fleetId == fleetInfo.fleetId }) {
                return Observable.just(FleetInfoResolutionResponse(fleetInfo: manualFleets[index],
                                                                   wasRequestedFleetAvailable: true))
            }
            return Observable.just(FleetInfoResolutionResponse(fleetInfo: automaticallyResolvedFleet,
                                                               wasRequestedFleetAvailable: false))
        }
    }
}
