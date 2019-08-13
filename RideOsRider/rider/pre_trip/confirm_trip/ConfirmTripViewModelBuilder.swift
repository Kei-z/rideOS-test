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

public class ConfirmTripViewModelBuilder {
    private let userStorageReader: UserStorageReader

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader()) {
        self.userStorageReader = userStorageReader
    }

    public func buildViewModel(
        pickupLocation: CLLocationCoordinate2D,
        dropoffLocation: CLLocationCoordinate2D,
        pickupIcon: DrawableMarkerIcon,
        dropoffIcon: DrawableMarkerIcon,
        listener: ConfirmTripListener,
        routeInteractor _: RouteInteractor = RiderDependencyRegistry.instance.riderDependencyFactory.routeInteractor,
        routeDisplayStringFormatter: @escaping (Route) -> NSAttributedString
    ) -> ConfirmTripViewModel {
        if userStorageReader.get(RiderDeveloperSettingsKeys.enableManualVehicleSelection) ?? false {
            return VehicleSelectionConfirmTripViewModel(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                pickupIcon: pickupIcon,
                dropoffIcon: dropoffIcon,
                listener: listener,
                routeDisplayStringFormatter: routeDisplayStringFormatter
            )
        } else {
            return DefaultConfirmTripViewModel(
                pickupLocation: pickupLocation,
                dropoffLocation: dropoffLocation,
                pickupIcon: pickupIcon,
                dropoffIcon: dropoffIcon,
                listener: listener,
                routeDisplayStringFormatter: routeDisplayStringFormatter
            )
        }
    }
}
