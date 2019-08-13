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

public struct LatLngBounds: Equatable {
    public let southWestCorner: CLLocationCoordinate2D
    public let northEastCorner: CLLocationCoordinate2D

    public init(containingCoordinates coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            southWestCorner = kCLLocationCoordinate2DInvalid
            northEastCorner = kCLLocationCoordinate2DInvalid
            return
        }

        // TODO: correctly handle situations where the coordinates span the international date line
        southWestCorner = CLLocationCoordinate2D(
            latitude: coordinates.map { $0.latitude }.min()!,
            longitude: coordinates.map { $0.longitude }.min()!
        )
        northEastCorner = CLLocationCoordinate2D(
            latitude: coordinates.map { $0.latitude }.max()!,
            longitude: coordinates.map { $0.longitude }.max()!
        )
    }

    public init(southWestCorner: CLLocationCoordinate2D, northEastCorner: CLLocationCoordinate2D) {
        self.southWestCorner = southWestCorner
        self.northEastCorner = northEastCorner
    }
}
