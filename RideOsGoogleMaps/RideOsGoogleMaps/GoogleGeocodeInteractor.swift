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
import GoogleMaps
import RideOsCommon
import RxSwift

public class GoogleGeocodeInteractor: GeocodeInteractor {
    let gmsGeocoder = GMSGeocoder()

    public init() {}

    public func reverseGeocode(
        location: CLLocationCoordinate2D,
        maxResults: Int
    ) -> Observable<[GeocodedLocationModel]> {
        return Observable.create { observer in
            self.gmsGeocoder.reverseGeocodeCoordinate(location) { response, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }

                if let results = response?.results() {
                    // construct a GeocodedLocationModel for each GMSAddress result, where the displayName is the
                    // GMSAddress's "thoroughfare" (i.e. the street number and name)
                    let geocodedLocationModels = results[0 ..< max(0, min(results.count, maxResults))]
                        .map { GeocodedLocationModel(displayName: $0.thoroughfare ?? "", location: $0.coordinate) }
                    observer.onNext(geocodedLocationModels)
                } else {
                    observer.onNext([])
                }
                observer.onCompleted()
            }
            return Disposables.create()
        }
    }
}
