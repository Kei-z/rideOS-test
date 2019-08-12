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

public struct FleetInfo: Equatable, Codable {
    public static let defaultFleetInfo = FleetInfo(fleetId: "",
                                                   displayName: "",
                                                   center: nil,
                                                   isPhantom: false)

    public let fleetId: String
    public let displayName: String
    public let center: CLLocationCoordinate2D?
    public let isPhantom: Bool

    public init(fleetId: String,
                displayName: String,
                center: CLLocationCoordinate2D?,
                isPhantom: Bool) {
        self.fleetId = fleetId
        self.displayName = displayName
        self.center = center
        self.isPhantom = isPhantom
    }
}
