import CoreLocation
import Foundation
import RideOsRider
import RxSwift

class FixedStopInteractor: StopInteractor {
    private var stopIndex = 0

    private let stops: [Stop]
    private let expectedFleetId: String

    init(stops: [Stop], expectedFleetId: String) {
        self.stops = stops
        self.expectedFleetId = expectedFleetId
    }

    func getStop(nearLocation location: CLLocationCoordinate2D, forFleet fleetId: String) -> Observable<Stop> {
        if fleetId != expectedFleetId {
            fatalError("fleetId \(fleetId) does not match expected fleetId \(expectedFleetId)")
        }

        if stopIndex >= stops.count {
            fatalError("Too many calls to \(#function)")
        }

        let ret = Observable.just(stops[stopIndex])
        stopIndex += 1
        return ret
    }
}
