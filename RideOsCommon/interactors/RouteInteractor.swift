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
import RxSwift

public protocol RouteInteractor {
    func getRoute(origin: CLLocationCoordinate2D, destination: CLLocationCoordinate2D) -> Observable<Route>
}

public struct Route: Equatable, Codable {
    public let coordinates: [CLLocationCoordinate2D]
    public let polyline: String
    public let travelTime: CFTimeInterval
    public let travelDistanceMeters: Double

    public init(coordinates: [CLLocationCoordinate2D],
                travelTime: CFTimeInterval,
                travelDistanceMeters: Double) {
        let polyline: String
        if coordinates.count > 0 {
            polyline = Polyline(coordinates: coordinates).encodedPolyline
        } else {
            polyline = ""
        }

        self.init(coordinates: coordinates,
                  polyline: polyline,
                  travelTime: travelTime,
                  travelDistanceMeters: travelDistanceMeters)
    }

    public init(coordinates: [CLLocationCoordinate2D],
                polyline: String,
                travelTime: CFTimeInterval,
                travelDistanceMeters: Double) {
        self.coordinates = coordinates
        self.polyline = polyline
        self.travelTime = travelTime
        self.travelDistanceMeters = travelDistanceMeters
    }
}

public enum RouteInteractorError: Error {
    case routeNotFound
}
