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

public class DefaultMatchedToVehicleViewModel: MatchedToVehicleViewModel {
    private let cameraUpdateSubject = ReplaySubject<CameraUpdate>.create(bufferSize: 1)
    private let pathsSubject = ReplaySubject<[DrawablePath]>.create(bufferSize: 1)
    private let markersSubject = ReplaySubject<[String: DrawableMarker]>.create(bufferSize: 1)
    private let dialogModelSubject = ReplaySubject<MatchedToVehicleStatusModel>.create(bufferSize: 1)
    private let mapSettingsSubject = ReplaySubject<MapSettings>.create(bufferSize: 1)

    private let modelProvider: (RiderTripStateModel) -> MatchedToVehicleModel?

    public init(modelProvider: @escaping (RiderTripStateModel) -> MatchedToVehicleModel?,
                initialPassengerState: RiderTripStateModel) {
        self.modelProvider = modelProvider
        updatePassengerState(initialPassengerState)
    }

    public var dialogModel: Observable<MatchedToVehicleStatusModel> {
        return dialogModelSubject
    }

    public func updatePassengerState(_ state: RiderTripStateModel) {
        if let model = modelProvider(state) {
            cameraUpdateSubject.onNext(model.cameraUpdate)
            pathsSubject.onNext(model.paths)
            markersSubject.onNext(model.markers)
            mapSettingsSubject.onNext(model.mapSettings)
            dialogModelSubject.onNext(model.dialogModel)
        }
    }
}

// MARK: MapStateProvider

extension DefaultMatchedToVehicleViewModel: MapStateProvider {
    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return cameraUpdateSubject
    }

    public func getPaths() -> Observable<[DrawablePath]> {
        return pathsSubject
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return markersSubject
    }

    public func getMapSettings() -> Observable<MapSettings> {
        return mapSettingsSubject
    }
}
