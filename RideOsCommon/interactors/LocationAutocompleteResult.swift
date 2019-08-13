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

public struct LocationAutocompleteResult: Equatable, Codable {
    public let primaryText: String
    public let secondaryText: String

    // TODO(chrism): These fields are here to support different LocationAutocompleteInteractors. This is a bit of a
    // hack. At some point, we should remove them and rethink the inputs and outputs used in
    // LocationAutocompleteInteractor's methods
    public let id: String?
    public let resolvedLocation: CLLocationCoordinate2D?

    public static func forResolvedLocation(_ location: CLLocationCoordinate2D,
                                           primaryText: String,
                                           secondaryText: String) -> LocationAutocompleteResult {
        return LocationAutocompleteResult(primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          id: nil,
                                          resolvedLocation: location)
    }

    public static func forUnresolvedLocation(id: String,
                                             primaryText: String,
                                             secondaryText: String) -> LocationAutocompleteResult {
        return LocationAutocompleteResult(primaryText: primaryText,
                                          secondaryText: secondaryText,
                                          id: id,
                                          resolvedLocation: nil)
    }

    private init(primaryText: String,
                 secondaryText: String,
                 id: String?,
                 resolvedLocation: CLLocationCoordinate2D?) {
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.id = id
        self.resolvedLocation = resolvedLocation
    }
}
