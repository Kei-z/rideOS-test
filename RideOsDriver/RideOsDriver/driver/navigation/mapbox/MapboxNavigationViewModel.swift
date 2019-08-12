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
import MapboxDirections
import RideOsCommon
import RxSwift
import RxSwiftExt

public protocol MapboxNavigationViewModel {
    var directions: Observable<MapboxDirections.Route> { get }
    var shouldHandleReroutes: Bool { get }

    func route(from origin: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D)
    func route(to destination: CLLocationCoordinate2D)
}
