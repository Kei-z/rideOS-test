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
import NMAKit
import RideOsCommon

public class HereMapsDependencyFactory: MapsDependencyFactory {
    public init(hereAppId: String, hereAppCode: String, hereLicenseKey: String) {
        NMAApplicationContext.setAppId(hereAppId, appCode: hereAppCode, licenseKey: hereLicenseKey)
    }

    public var mapView: UIMapView {
        return HereMapView()
    }

    public var locationAutocompleteInteractor: LocationAutocompleteInteractor {
        return HereLocationAutocompleteInteractor()
    }

    public var geocodeInteractor: GeocodeInteractor {
        return HereGeocodeInteractor()
    }
}
