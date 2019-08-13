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

public struct MatchedToVehicleModel: Equatable {
    public let cameraUpdate: CameraUpdate
    public let paths: [DrawablePath]
    public let markers: [String: DrawableMarker]
    public let dialogModel: MatchedToVehicleStatusModel
    public let mapSettings: MapSettings

    public init(cameraUpdate: CameraUpdate,
                paths: [DrawablePath],
                markers: [String: DrawableMarker],
                dialogModel: MatchedToVehicleStatusModel,
                mapSettings: MapSettings = MapSettings(shouldShowUserLocation: true)) {
        self.cameraUpdate = cameraUpdate
        self.paths = paths
        self.markers = markers
        self.dialogModel = dialogModel
        self.mapSettings = mapSettings
    }
}
