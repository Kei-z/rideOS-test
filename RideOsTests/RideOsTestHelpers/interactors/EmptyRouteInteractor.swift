import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public class EmptyRouteInteractor: RouteInteractor {
    public init() {}

    public func getRoute(origin _: CLLocationCoordinate2D, destination _: CLLocationCoordinate2D) -> Observable<Route> {
        return Observable.empty()
    }
}
