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

public protocol MapCenterListener {
    func mapCenterDidMove(to coordinate: CLLocationCoordinate2D)
}

public protocol MapDragListener {
    func mapWasDragged()
}

public protocol MapView {
    func setMapSettings(_ mapSettings: MapSettings)

    func moveCamera(_ cameraUpdate: CameraUpdate)

    func showMarkers(_ markers: [String: DrawableMarker])

    func showPaths(_ paths: [DrawablePath])

    func setMapCenterListener(_ mapCenterListener: MapCenterListener?)

    func setMapDragListener(_ mapCenterListener: MapDragListener?)

    // Set this to account for things like views that overlap the map. ex: if the bottom of the map is covered by a
    // view of height 50, you'd set this to: UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    var mapInsets: UIEdgeInsets { get set }

    var visibleRegion: LatLngBounds { get }
}
