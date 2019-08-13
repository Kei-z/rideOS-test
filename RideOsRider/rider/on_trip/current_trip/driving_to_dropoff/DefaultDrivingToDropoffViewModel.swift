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

public class DefaultDrivingToDropoffViewModel: DefaultMatchedToVehicleViewModel {
    private static let statusPrefix =
        RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.on-trip.driving-to-dropoff.eta-prefix")

    public init(initialPassengerState: RiderTripStateModel,
                currentDateProvider: @escaping () -> Date) {
        super.init(
            modelProvider: {
                DefaultDrivingToDropoffViewModel.computeMatchedToVehicleModel(
                    $0,
                    currentDateProvider: currentDateProvider
                )
            },
            initialPassengerState: initialPassengerState
        )
    }

    private static func computeMatchedToVehicleModel(_ state: RiderTripStateModel,
                                                     currentDateProvider: () -> Date) -> MatchedToVehicleModel? {
        guard case let RiderTripStateModel.drivingToDropoff(pickup,
                                                            dropoff,
                                                            route,
                                                            vehiclePosition,
                                                            vehicleInfo,
                                                            waypoints) = state else {
            return nil
        }

        return MatchedToVehicleModel(
            cameraUpdate: .fitLatLngBounds(
                LatLngBounds(containingCoordinates: route.coordinates + [dropoff.location, vehiclePosition.position])
            ),
            paths: [DrawablePath.drivingRouteLine(coordinates: route.coordinates)],
            markers: Dictionary(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(dropoffLocation: dropoff.location),
                CurrentTripMarkers.markerFor(vehiclePosition: vehiclePosition),
            ] + CurrentTripMarkers.markersFor(waypoints: waypoints)),
            dialogModel: MatchedToVehicleStatusModel(
                status: DefaultDrivingToDropoffViewModel.statusPrefix
                    + String.timeOfDayLabelFrom(startDate: currentDateProvider(), interval: route.travelTime),
                nextWaypoint: dropoff.displayName,
                vehicleInfo: vehicleInfo
            ),
            mapSettings: MapSettings(shouldShowUserLocation: false)
        )
    }
}
