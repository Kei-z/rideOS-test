import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public class PointToPointRouteInteractor: RouteInteractor {
    public static let travelTime = CFTimeInterval(42.0)
    public static let travelDistanceMeters = 84.0

    private let scheduler: SchedulerType
    private let delayTime: RxTimeInterval

    public init(scheduler: SchedulerType,
                delayTime: RxTimeInterval = 0.0) {
        self.scheduler = scheduler
        self.delayTime = delayTime
    }

    public static func route(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Route {
        return Route(coordinates: [origin, destination],
                     travelTime: PointToPointRouteInteractor.travelTime,
                     travelDistanceMeters: PointToPointRouteInteractor.travelDistanceMeters)
    }

    public func getRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Observable<Route> {
        // NOTE: we only apply a .delay() if delayTime is > 0.0 because applying a .delay() of 0.0 still causes the
        // Observable to emit the event on the next tick
        if delayTime > 0.0 {
            return Observable
                .just(PointToPointRouteInteractor.route(origin: origin, destination: destination))
                .delay(delayTime, scheduler: scheduler)
        } else {
            return Observable.just(PointToPointRouteInteractor.route(origin: origin, destination: destination))
        }
    }
}
