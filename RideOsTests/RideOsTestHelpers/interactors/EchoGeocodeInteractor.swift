import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public class EchoGeocodeInteractor: GeocodeInteractor {
    public static let displayName = "Geocoded Location"

    private let scheduler: SchedulerType
    private let delayTime: RxTimeInterval

    public init(scheduler: SchedulerType,
                delayTime: RxTimeInterval = 0.0) {
        self.scheduler = scheduler
        self.delayTime = delayTime
    }

    public func reverseGeocode(location: CLLocationCoordinate2D,
                               maxResults _: Int) -> Observable<[GeocodedLocationModel]> {
        // NOTE: we only apply a .delay() if delayTime is > 0.0 because applying a .delay() of 0.0 still causes the
        // Observable to emit the event on the next tick
        if delayTime > 0.0 {
            return Observable
                .just([GeocodedLocationModel(displayName: EchoGeocodeInteractor.displayName,
                                             location: location)])
                .delay(delayTime, scheduler: scheduler)
        } else {
            return Observable
                .just([GeocodedLocationModel(displayName: EchoGeocodeInteractor.displayName,
                                             location: location)])
        }
    }
}
