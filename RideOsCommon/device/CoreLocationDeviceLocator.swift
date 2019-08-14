// Copyright 2019 rideOS, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import CoreLocation
import Foundation
import RxSwift

public class CoreLocationDeviceLocator: NSObject, DeviceLocator, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let locationSubject = ReplaySubject<CLLocation>.create(bufferSize: 1)

    public override init() {
        super.init()

        guard CLLocationManager.locationServicesEnabled() else {
            locationSubject.onError(DeviceLocatorError.notAvailable)
            return
        }

        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    public func observeCurrentLocation() -> Observable<CLLocation> {
        return locationSubject
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Force unwrap without checking since locations is guaranteed to always have at least 1 location:
        // https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate/1423615-locationmanager
        locationSubject.onNext(locations.last!)
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        logError("CoreLocation generated error '\(error.humanReadableDescription)'")
    }
}
