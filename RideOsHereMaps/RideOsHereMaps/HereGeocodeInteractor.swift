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
import NMAKit
import RideOsCommon
import RxSwift

public class HereGeocodeInteractor: GeocodeInteractor {
    let nmaGeocoder = NMAGeocoder.sharedInstance()

    public init() {}

    public func reverseGeocode(location: CLLocationCoordinate2D, maxResults: Int) -> Observable<[GeocodedLocationModel]> {
        return Observable.create { observer in
            let request = self.nmaGeocoder.createReverseGeocodeRequest(coordinates: location.nmaGeoCoordinates())
            request.start { _, result, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }

                if let results = result as? [NMAReverseGeocodeResult] {
                    let resultsWithLocations = results.filter { $0.location?.position != nil }
                    let maxIndex = max(0, min(resultsWithLocations.count, maxResults))
                    let geocodedLocationModels = resultsWithLocations[0 ..< maxIndex].map {
                        GeocodedLocationModel(
                            displayName: HereGeocodeInteractor.displayName(forAddress: $0.location?.address),
                            location: $0.location!.position!.clLocationCoordinate2D()
                        )
                    }
                    observer.onNext(geocodedLocationModels)
                } else {
                    observer.onNext([])
                }
                observer.onCompleted()
            }
            return Disposables.create { request.cancel() }
        }
    }

    private static func displayName(forAddress address: NMAAddress?) -> String {
        guard let address = address else {
            return ""
        }

        if let number = address.houseNumber, let street = address.street {
            // TODO(chrism): Unfortunately HERE doesn't provide an equivalent to Google's GMSAddress.thoroughfare, so
            // we have to construct something on our own. I'm not sure how well this scales globally
            return number + " " + street
        }

        if let district = address.district {
            return district
        }

        return ""
    }
}
