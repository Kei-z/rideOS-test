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
import MapboxDirections
import RideOsCommon
import RxSwift

public class RideOsRouteMapboxDirectionsViewModel: MapboxNavigationViewModel {
    private let mapboxNavigationViewModel: DefaultMapboxNavigationViewModel

    public convenience init(deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        let directionsInteractor = RideOsRouteMapboxDirectionsInteractor(schedulerProvider: schedulerProvider)

        self.init(deviceLocator: deviceLocator,
                  directionsInteractor: directionsInteractor,
                  schedulerProvider: schedulerProvider)
    }

    public init(deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                directionsInteractor: MapboxDirectionsInteractor,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        mapboxNavigationViewModel = DefaultMapboxNavigationViewModel(deviceLocator: deviceLocator,
                                                                     directionsInteractor: directionsInteractor,
                                                                     schedulerProvider: schedulerProvider,
                                                                     logger: logger)
    }

    public var directions: Observable<MapboxDirections.Route> {
        return mapboxNavigationViewModel.directions
    }

    public var shouldHandleReroutes: Bool {
        return true
    }

    public func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        mapboxNavigationViewModel.route(from: origin, to: destination)
    }

    public func route(to destination: CLLocationCoordinate2D) {
        mapboxNavigationViewModel.route(to: destination)
    }
}
