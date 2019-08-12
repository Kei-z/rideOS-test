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

import Foundation
import RideOsCommon

public struct NamedTripLocation: Equatable {
    public let tripLocation: TripLocation
    public let displayName: String

    public init(geocodedLocation: GeocodedLocationModel) {
        self.init(tripLocation: TripLocation(location: geocodedLocation.location),
                  displayName: geocodedLocation.displayName)
    }

    public init(tripLocation: TripLocation, displayName: String) {
        self.tripLocation = tripLocation
        self.displayName = displayName
    }

    public var geocodedLocation: GeocodedLocationModel {
        return GeocodedLocationModel(displayName: displayName, location: tripLocation.location)
    }
}
