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
import GoogleMaps
import GooglePlaces
import RideOsCommon

public class GoogleMapsDependencyFactory: MapsDependencyFactory {
    public init(googleApiKey: String) {
        GMSServices.provideAPIKey(googleApiKey)
        GMSPlacesClient.provideAPIKey(googleApiKey)
    }

    public var mapView: UIMapView {
        return GoogleMapView()
    }

    public var locationAutocompleteInteractor: LocationAutocompleteInteractor {
        return GooglePlacesLocationAutocompleteInteractor()
    }

    public var geocodeInteractor: GeocodeInteractor {
        return GoogleGeocodeInteractor()
    }
}
