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

public enum LocationSearchOption: Equatable {
    case autocompleteLocation(_ autocompleteLocation: LocationAutocompleteResult)
    case currentLocation
    case selectOnMap
    case historical(_ autocompleteLocation: LocationAutocompleteResult)

    public func displayName() -> String {
        switch self {
        case let .autocompleteLocation(autocompleteLocation), let .historical(autocompleteLocation):
            return autocompleteLocation.primaryText
        case .currentLocation:
            return RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.location-search.current-location-option")
        case .selectOnMap:
            return RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.location-search.set-on-map-option")
        }
    }
}
