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
import RxSwift

public class FollowCurrentLocationMapStateProvider: MapStateProvider {
    private static let defaultZoomLevel: Float = 15.0

    private let deviceLocator: DeviceLocator
    private let icon: DrawableMarkerIcon

    public init(deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                icon: DrawableMarkerIcon) {
        self.deviceLocator = deviceLocator
        self.icon = icon
    }

    public func getMapSettings() -> Observable<MapSettings> {
        return Observable.just(MapSettings(shouldShowUserLocation: false))
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return deviceLocator.observeCurrentLocation().map {
            CameraUpdate.centerAndZoom(center: $0.coordinate,
                                       zoom: FollowCurrentLocationMapStateProvider.defaultZoomLevel)
        }
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return deviceLocator.observeCurrentLocation().map { [icon] in [
            "current_location_icon": DrawableMarker(coordinate: $0.coordinate, icon: icon),
        ]
        }
    }
}
