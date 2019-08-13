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
import RxSwiftExt

public class DefaultMapboxNavigationViewModel: MapboxNavigationViewModel {
    private let deviceLocator: DeviceLocator
    private let directionsInteractor: MapboxDirectionsInteractor
    private let schedulerProvider: SchedulerProvider
    private let directionsToDisplay = ReplaySubject<MapboxDirections.Route>.create(bufferSize: 1)
    private let originDestinationToRoute = PublishSubject<(CLLocationCoordinate2D, CLLocationCoordinate2D)>()
    private let disposeBag = DisposeBag()

    public init(deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                directionsInteractor: MapboxDirectionsInteractor = DefaultMapboxDirectionsInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.deviceLocator = deviceLocator
        self.directionsInteractor = directionsInteractor
        self.schedulerProvider = schedulerProvider

        originDestinationToRoute
            .observeOn(schedulerProvider.computation())
            .flatMap { [directionsInteractor] originAndDestination -> Observable<MapboxDirections.Route> in
                let origin = originAndDestination.0
                let destination = originAndDestination.1

                return directionsInteractor.getDirections(from: origin, to: destination)
                    .asObservable()
                    .logErrorsAndRetry(logger: logger)
            }
            .subscribe(onNext: { [directionsToDisplay] in directionsToDisplay.onNext($0) })
            .disposed(by: disposeBag)
    }

    public var directions: Observable<MapboxDirections.Route> {
        return directionsToDisplay
    }

    public var shouldHandleReroutes: Bool {
        return false
    }

    public func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D) {
        originDestinationToRoute.onNext((origin, destination))
    }

    public func route(to destination: CLLocationCoordinate2D) {
        deviceLocator.lastKnownLocation.zip(with: Single.just(destination)) { ($0.coordinate, $1) }
            .subscribe(onNext: { [originDestinationToRoute] in originDestinationToRoute.onNext($0) })
            .disposed(by: disposeBag)
    }
}
