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

public class RideOsRouteMapboxDirectionsInteractor: MapboxDirectionsInteractor {
    private static var mapboxApiToken: String {
        // swiftlint:disable force_cast
        return Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as! String
        // swiftlint:enable force_cast
    }

    private static let mapboxMatchingCoordinateLimit = 500

    private let polylineSimplifier: PolylineSimplifier
    private let directionsInteractor: Directions
    private let routeInteractor: RouteInteractor
    private let schedulerProvider: SchedulerProvider

    public init(routeInteractor: RouteInteractor = RideOsRouteInteractor(),
                polylineSimplifier: PolylineSimplifier = DefaultPolylineSimplifier(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        directionsInteractor = Directions(accessToken: RideOsRouteMapboxDirectionsInteractor.mapboxApiToken)
        self.routeInteractor = routeInteractor
        self.polylineSimplifier = polylineSimplifier
        self.schedulerProvider = schedulerProvider
    }

    public func getDirections(
        from origin: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) -> Single<MapboxDirections.Route> {
        return routeInteractor.getRoute(origin: origin, destination: destination)
            .observeOn(schedulerProvider.computation())
            .flatMap { self.getDirections(along: $0.coordinates) }
            .asSingle()
    }

    private func getDirections(along coordinates: [CLLocationCoordinate2D]) -> Single<MapboxDirections.Route> {
        var simplifiedCoordinates = coordinates

        if coordinates.count >= RideOsRouteMapboxDirectionsInteractor.mapboxMatchingCoordinateLimit {
            simplifiedCoordinates = polylineSimplifier.simplify(polyline: coordinates)
        }

        let matchOptions = NavigationMatchOptions(coordinates: simplifiedCoordinates)
        guard let firstWaypoint = matchOptions.waypoints.first,
            let lastWaypoint = matchOptions.waypoints.last else {
            return Single.error(MapboxDirectionsInteractorError.invalidRouteRequest)
        }

        // Only mark the first and last waypoints as the significant ones in the route so that intermediate waypoints
        // do not generate instructions indicating the user has arrived at an intermediate stop.
        matchOptions.waypoints = matchOptions.waypoints.map { waypoint in
            let isSignificantWaypoint = waypoint == firstWaypoint || waypoint == lastWaypoint
            waypoint.separatesLegs = isSignificantWaypoint

            return waypoint
        }

        matchOptions.includesSteps = true
        matchOptions.resamplesTraces = true

        return Single.create { [directionsInteractor] single in
            let task = directionsInteractor.calculateRoutes(matching: matchOptions) { _, routes, error in
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
