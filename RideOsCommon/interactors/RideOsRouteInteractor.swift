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
import Polyline
import RideOsApi
import RxSwift

public class RideOsRouteInteractor: RouteInteractor {
    private let pathService: PathPathService

    public init(pathService: PathPathService = PathPathService.serviceWithApiHost()) {
        self.pathService = pathService
    }

    public func getRoute(origin: CLLocationCoordinate2D,
                         destination: CLLocationCoordinate2D) -> Observable<Route> {
        let originWaypoint = PathWaypoint()
        originWaypoint.position = Position(coordinate: origin)

        let destinationWaypoint = PathWaypoint()
        destinationWaypoint.position = Position(coordinate: destination)

        let request = PathPathRequest()
        request.waypointsArray = [originWaypoint, destinationWaypoint]
        request.geometryFormat = .polyline

        return Observable.create { observer in
            let call = self.pathService.rpcToGetPath(with: request) { response, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }

                guard let response = response else {
                    observer.onError(RouteInteractorError.routeNotFound)
                    return
                }

                let result = RideOsRouteInteractor.convertToRoute(pathResponse: response)

                switch result {
                case let .success(route):
                    observer.onNext(route)
                    observer.onCompleted()
                case let .failure(error):
                    observer.onError(error)
                }
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
        // Use share() so that we send only a single route request even if we have multiple subscriptions on this
        // Observable
        .share(replay: 1)
    }

    public static func convertToRoute(pathResponse: PathPathResponse) -> Result<Route, RouteInteractorError> {
        guard let path = pathResponse.pathsArray.firstObject as? PathPath else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let leg = path.legsArray.firstObject as? PathLeg else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let polyline = leg.polyline else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let coordinates = Polyline(encodedPolyline: polyline).coordinates else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard coordinates.count > 1 else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let travelTime = path.travelTime else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        return .success(Route(coordinates: coordinates,
                              polyline: polyline,
                              travelTime: Double(travelTime.seconds) + Double(travelTime.nanos) / 1.0e9,
                              travelDistanceMeters: path.distance))
    }

    // TODO(chrism): Move this to its own utility class
    public static func convertRouteResponseToRoute(response: RouteResponse) -> Result<Route, RouteInteractorError> {
        guard let path = response.path else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let polyline = path.polyline else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let coordinates = Polyline(encodedPolyline: polyline).coordinates else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard coordinates.count > 1 else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        guard let travelTime = path.travelTime else {
            return .failure(RouteInteractorError.routeNotFound)
        }

        return .success(Route(coordinates: coordinates,
                              polyline: polyline,
                              travelTime: Double(travelTime.milliseconds) / 1000.0,
                              travelDistanceMeters: path.distanceMeters))
    }
}
