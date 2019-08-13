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
import RxSwift

public class DefaultMapViewModel: MapViewModel {
    private let cameraUpdateSubject = ReplaySubject<CameraUpdate>.create(bufferSize: 1)
    private let isMapCenteredSubject = ReplaySubject<Bool>.create(bufferSize: 1)

    public init() {}

    public func mapWasDragged() {
        isMapCenteredSubject.onNext(false)
    }

    public func recenterMap() {
        isMapCenteredSubject.onNext(true)
    }

    public func requestCameraUpdate(_ cameraUpdate: CameraUpdate, forced: Bool) {
        cameraUpdateSubject.onNext(cameraUpdate)
        if forced {
            recenterMap()
        }
    }

    public var cameraUpdatesToPerform: Observable<CameraUpdate> {
        return Observable.combineLatest(cameraUpdateSubject, isMapCenteredSubject)
            .filter { $0.1 }
            .map { $0.0 }
    }

    public var shouldAllowRecentering: Observable<Bool> {
        return isMapCenteredSubject.map { !$0 }
    }
}
