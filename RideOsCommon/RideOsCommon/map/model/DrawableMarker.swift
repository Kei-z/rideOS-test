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

public struct DrawableMarker: Equatable {
    public let coordinate: CLLocationCoordinate2D
    public let heading: CLLocationDirection
    public let icon: DrawableMarkerIcon

    public init(coordinate: CLLocationCoordinate2D, heading: CLLocationDirection = 0.0, icon: DrawableMarkerIcon) {
        self.coordinate = coordinate
        self.icon = icon
        self.heading = heading
    }
}

public struct DrawableMarkerIcon: Equatable {
    public let image: UIImage
    public let groundAnchor: CGPoint

    public init(image: UIImage, groundAnchor: CGPoint) {
        self.image = image
        self.groundAnchor = groundAnchor
    }
}
