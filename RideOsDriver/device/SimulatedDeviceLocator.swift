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
import RideOsCommon
import RxSwift

public class SimulatedDeviceLocator: NSObject, DeviceLocator {
    public static let instance = SimulatedDeviceLocator()
    private static let invalidLocation = CLLocation(latitude: kCLLocationCoordinate2DInvalid.latitude,
                                                    longitude: kCLLocationCoordinate2DInvalid.longitude)

    private let initialLocationSource: DeviceLocator
    private let simulatedLocationSubject = BehaviorSubject<CLLocation>(value: SimulatedDeviceLocator.invalidLocation)
    private let coreLocationSubject = ReplaySubject<CLLocation>.create(bufferSize: 1)

    public init(initialLocationSource: DeviceLocator = CoreLocationDeviceLocator()) {
        self.initialLocationSource = initialLocationSource

        super.init()
    }

    public func updateSimulatedLocation(_ location: CLLocation) {
        simulatedLocationSubject.onNext(location)
    }

    public func observeCurrentLocation() -> Observable<CLLocation> {
        let validSimulatedLocationSubject = simulatedLocationSubject.filter {
            CLLocationCoordinate2DIsValid($0.coordinate)
        }

        let intialLocation = initialLocationSource.observeCurrentLocation().takeUntil(validSimulatedLocationSubject)
        return Observable.concat([intialLocation, validSimulatedLocationSubject])
    }

    public var lastKnownLocation: Single<CLLocation> {
        let simulatedLocation = try? simulatedLocationSubject.value()

        if let simulatedLocation = simulatedLocation, CLLocationCoordinate2DIsValid(simulatedLocation.coordinate) {
            return Single.just(simulatedLocation)
        }

        return initialLocationSource.lastKnownLocation
    }
}
