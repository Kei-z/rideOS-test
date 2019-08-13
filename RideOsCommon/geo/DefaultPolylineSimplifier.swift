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
import SwiftSimplify

public class DefaultPolylineSimplifier: PolylineSimplifier {
    // 0.00009 degrees of latitude is approximately 10 meters
    public static let defaultSimplificationThresholdDegrees: Float = 0.00009

    private let toleranceDegrees: Float

    public init(toleranceDegrees: Float = DefaultPolylineSimplifier.defaultSimplificationThresholdDegrees) {
        self.toleranceDegrees = toleranceDegrees
    }

    public func simplify(polyline: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        // Note that this treats latitude/longitude as Cartesian coordinates, which is *grossly* incorrect. However,
        // it seems to work ok for our purposes for now. At some point, we should consider implementing proper
        // simplification of coordinates by a) using the correct distance metric or b) projecting the coordinates to a
        // local tangent plane and doing the simplification in that plane
        return SwiftSimplify.simplify(polyline, tolerance: toleranceDegrees)
    }
}
