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
import RxSwift

public class DefaultDrivingToPickupViewModel: DefaultMatchedToVehicleViewModel {
    public init(initialPassengerState: RiderTripStateModel) {
        super.init(modelProvider: DefaultDrivingToPickupViewModel.computeMatchedToVehicleModel,
                   initialPassengerState: initialPassengerState)
    }

    private static func computeMatchedToVehicleModel(_ state: RiderTripStateModel) -> MatchedToVehicleModel? {
        guard case let RiderTripStateModel.drivingToPickup(pickup,
                                                           dropoff,
                                                           route,
                                                           vehiclePosition,
                                                           vehicleInfo,
                                                           waypoints) = state else {
            return nil
        }

        return MatchedToVehicleModel(
            cameraUpdate: .fitLatLngBounds(
                LatLngBounds(containingCoordinates: route.coordinates + [pickup.location, vehiclePosition.position])
            ),
            paths: [DrawablePath.drivingRouteLine(coordinates: route.coordinates)],
            markers: Dictionary(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: pickup.location),
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition),
            ] + CurrentTripMarkers.markersFor(waypoints: waypoints)),
            dialogModel: MatchedToVehicleStatusModel(
                status: DefaultDrivingToPickupViewModel.statusStringFor(travelTime: route.travelTime,
                                                                        waypointCount: waypoints.count),
                nextWaypoint: pickup.displayName,
                vehicleInfo: vehicleInfo
            )
        )
    }

    private static func statusStringFor(travelTime: CFTimeInterval, waypointCount: Int) -> String {
        let prefix: String
        if waypointCount > 1 {
            prefix = String(waypointCount)
                + RideOsRiderResourceLoader.instance
                .getString("ai.rideos.rider.on-trip.driving-to-pickup.header.multiple-stops-prefix")
        } else if waypointCount == 1 {
            prefix = RideOsRiderResourceLoader.instance
                .getString("ai.rideos.rider.on-trip.driving-to-pickup.header.one-stop-prefix")
        } else {
            prefix = ""
        }

        return prefix
            + RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.on-trip.driving-to-pickup.header.eta")
            + String.minutesLabelWith(timeInterval: travelTime)
    }
}
