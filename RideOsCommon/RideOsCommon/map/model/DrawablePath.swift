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

public struct DrawablePath: Equatable {
    public static let defaultWidth: Float = 4
    public static let defaultColor: UIColor = .gray
    public static let defaultIsDashed = false

    public let coordinates: [CLLocationCoordinate2D]
    public let width: Float
    public let color: UIColor

    // TODO(chrism): If we ever support styles other than solid and dashed lines, we should make this an enum
    public let isDashed: Bool

    public init(coordinates: [CLLocationCoordinate2D],
                width: Float = DrawablePath.defaultWidth,
                color: UIColor = DrawablePath.defaultColor,
                isDashed: Bool = DrawablePath.defaultIsDashed) {
        self.coordinates = coordinates
        self.width = width
        self.color = color
        self.isDashed = isDashed
    }
}

// MARK: Route line

extension DrawablePath {
    private static let routeLineWidth: Float = 3.0

    public static func previewDrivingRouteLine(coordinates: [CLLocationCoordinate2D]) -> DrawablePath {
        return DrawablePath(
            coordinates: coordinates,
            width: DrawablePath.routeLineWidth,
            color: RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.route-line.driving.preview-color"),
            isDashed: false
        )
    }

    public static func drivingRouteLine(coordinates: [CLLocationCoordinate2D]) -> DrawablePath {
        return DrawablePath(
            coordinates: coordinates,
            width: DrawablePath.routeLineWidth,
            color: RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.route-line.driving.color"),
            isDashed: false
        )
    }

    public static func walkingRouteLine(coordinates: [CLLocationCoordinate2D]) -> DrawablePath {
        return DrawablePath(
            coordinates: coordinates,
            width: DrawablePath.routeLineWidth,
            color: RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.route-line.walking.color"),
            isDashed: true
        )
    }
}
