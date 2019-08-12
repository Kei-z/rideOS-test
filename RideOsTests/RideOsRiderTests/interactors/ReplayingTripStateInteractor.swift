import Foundation
import RideOsRider
import RxSwift

public class ReplayingTripStateInteractor: RiderTripStateInteractor {
    let tripStateObservable: Observable<RiderTripStateModel>
    
    public init(_ tripStateObservable: Observable<RiderTripStateModel>) {
        self.tripStateObservable = tripStateObservable
    }
    
    public func getTripState(tripId: String, fleetId: String) -> Observable<RiderTripStateModel> {
        return tripStateObservable
    }
}
