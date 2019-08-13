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

public class DefaultWaitingForPickupViewModel: DefaultMatchedToVehicleViewModel {
    private static let status =
        RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.on-trip.waiting-for-pickup.header")

    public init(initialPassengerState: RiderTripStateModel) {
        super.init(modelProvider: DefaultWaitingForPickupViewModel.computeMatchedToVehicleModel,
                   initialPassengerState: initialPassengerState)
    }

    private static func computeMatchedToVehicleModel(_ state: RiderTripStateModel) -> MatchedToVehicleModel? {
        guard case let RiderTripStateModel.waitingForPickup(pickup,
                                                            dropoff,
                                                            vehiclePosition,
                                                            vehicleInfo) = state else {
            return nil
        }

        return MatchedToVehicleModel(
            cameraUpdate: .fitLatLngBounds(
                LatLngBounds(containingCoordinates: [pickup.location, vehiclePosition.position])
            ),
            paths: [],
            markers: Dictionary(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: pickup.location),
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition),
            ]),
            dialogModel: MatchedToVehicleStatusModel(
                status: DefaultWaitingForPickupViewModel.status,
                nextWaypoint: pickup.displayName,
                vehicleInfo: vehicleInfo
            )
        )
    }
}
