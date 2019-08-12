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
import RideOsCommon
import RxSwift

public class ConfirmLocationViewModelBuilder {
    public static func buildViewModelForPickup(initialLocation: Single<CLLocationCoordinate2D>,
                                               listener: ConfirmLocationListener) -> ConfirmLocationViewModel {
        if shouldUseFixedPudols() {
            return FixedLocationConfirmLocationViewModel(initialLocation: initialLocation,
                                                         stopMarker: DrawableMarkerIcons.pickupPin(),
                                                         listener: listener)
        } else {
            return DefaultConfirmLocationViewModel(initialLocation: initialLocation, listener: listener)
        }
    }

    public static func buildViewModelForDropoff(initialLocation: Single<CLLocationCoordinate2D>,
                                                listener: ConfirmLocationListener) -> ConfirmLocationViewModel {
        if shouldUseFixedPudols() {
            return FixedLocationConfirmLocationViewModel(initialLocation: initialLocation,
                                                         stopMarker: DrawableMarkerIcons.dropoffPin(),
                                                         listener: listener)
        } else {
            return DefaultConfirmLocationViewModel(initialLocation: initialLocation, listener: listener)
        }
    }

    private static func shouldUseFixedPudols() -> Bool {
        guard let info = Bundle.main.infoDictionary else {
            fatalError("Can't load Info.plist")
        }

        guard let useFixedPudols = info["RequiresFixedPickupAndDropoffLocations"] as? Bool else {
            return false
        }

        return useFixedPudols
    }
}
