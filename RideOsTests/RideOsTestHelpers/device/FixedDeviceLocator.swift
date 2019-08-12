import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public class FixedDeviceLocator: DeviceLocator {
    private let deviceLocation: CLLocation

    public init(deviceLocation: CLLocation) {
        self.deviceLocation = deviceLocation
    }

    public var lastKnownLocation: Single<CLLocation> {
        return Single.just(deviceLocation)
    }

    public func observeCurrentLocation() -> Observable<CLLocation> {
        return Observable.just(deviceLocation)
    }
}
