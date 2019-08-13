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

public class CurrentTripMarkers {
    public static func markerFor(pickupLocation: CLLocationCoordinate2D) -> (String, DrawableMarker) {
        return ("pickup", DrawableMarker(coordinate: pickupLocation, icon: DrawableMarkerIcons.pickupPin()))
    }

    public static func markerFor(dropoffLocation: CLLocationCoordinate2D) -> (String, DrawableMarker) {
        return ("dropoff", DrawableMarker(coordinate: dropoffLocation, icon: DrawableMarkerIcons.dropoffPin()))
    }

    public static func markerFor(vehiclePosition: VehiclePosition) -> (String, DrawableMarker) {
        return (vehiclePosition.vehicleId, DrawableMarker(coordinate: vehiclePosition.position,
                                                          heading: vehiclePosition.heading,
                                                          icon: DrawableMarkerIcons.car()))
    }

    public static func markersFor(waypoints: [PassengerWaypoint]) -> [(String, DrawableMarker)] {
        return zip(0 ..< waypoints.count, waypoints).map {
            ("waypoint_" + String($0), DrawableMarker(coordinate: $1.location,
                                                      icon: RiderDrawableMarkerIcons.waypoint()))
        }
    }
}
