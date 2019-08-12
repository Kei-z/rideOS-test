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
import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import RideOsCommon
import RxSwift

public class DefaultMapboxDirectionsInteractor: MapboxDirectionsInteractor {
    private static var mapboxApiToken: String {
        // swiftlint:disable force_cast
        return Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as! String
        // swiftlint:enable force_cast
    }

    private let directionsInteractor: Directions
    private let schedulerProvider: SchedulerProvider

    public init(schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        directionsInteractor = Directions(accessToken: DefaultMapboxDirectionsInteractor.mapboxApiToken)
        self.schedulerProvider = schedulerProvider
    }

    public func getDirections(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Single<MapboxDirections.Route> {
        let routeOptions = NavigationRouteOptions(coordinates: [origin, destination])
        routeOptions.includesSteps = true

        return Single.create { [directionsInteractor] single in
            let task = directionsInteractor.calculate(routeOptions) { _, routes, error in
                guard error == nil else {
                    single(.error(error!))
                    return
                }

                guard let routes = routes, let route = routes.first else {
                    single(.error(MapboxDirectionsInteractorError.invalidRouteResponse))
                    return
                }

                single(.success(route))
            }

            task.resume()

            return Disposables.create {
                task.cancel()
            }
        }
        .subscribeOn(schedulerProvider.io())
    }
}
