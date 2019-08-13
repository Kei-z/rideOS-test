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
import GooglePlaces
import RideOsCommon
import RxSwift

public class GooglePlacesLocationAutocompleteInteractor: LocationAutocompleteInteractor {
    // The place fields to fetch for selected autocomplete results
    private static let placeFields: GMSPlaceField = GMSPlaceField(rawValue: GMSPlaceField.name.rawValue | GMSPlaceField.coordinate.rawValue)!

    // TODO(chrism): make sure that it's ok to use the same session token for multiple requests
    private let sessionToken = GMSAutocompleteSessionToken()

    private let filter: GMSAutocompleteFilter
    private let placesClient: GMSPlacesClient

    public init() {
        filter = GMSAutocompleteFilter()
        filter.type = .noFilter
        placesClient = GMSPlacesClient()
    }

    public func getAutocompleteResults(searchText: String,
                                       bounds: LatLngBounds) -> Observable<[LocationAutocompleteResult]> {
        return Observable.create { observer in
            self.placesClient.findAutocompletePredictions(fromQuery: searchText,
                                                          bounds: GMSCoordinateBounds(coordinate: bounds.northEastCorner,
                                                                                      coordinate: bounds.southWestCorner),
                                                          boundsMode: GMSAutocompleteBoundsMode.bias,
                                                          filter: self.filter,
                                                          sessionToken: self.sessionToken) { results, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }
                if let results = results {
                    observer.onNext(results.map {
                        LocationAutocompleteResult.forUnresolvedLocation(
                            id: $0.placeID,
                            primaryText: $0.attributedPrimaryText.string,
                            secondaryText: $0.attributedSecondaryText?.string ?? ""
                        )
                    })
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    public func getLocationFromAutocompleteResult(_ result: LocationAutocompleteResult) -> Observable<GeocodedLocationModel> {
        guard let placeId = result.id else {
            fatalError("No locationId set")
        }

        return Observable<GMSPlace>
            .create { observer in
                self.placesClient.fetchPlace(
                    fromPlaceID: placeId,
                    placeFields: GooglePlacesLocationAutocompleteInteractor.placeFields,
                    sessionToken: self.sessionToken,
                    callback: { result, error in
                        if let error = error {
                            observer.onError(error)
                            return
                        } else if let result = result {
                            observer.onNext(result)
                        }
                        observer.onCompleted()
                    }
                )
                return Disposables.create()
            }
            .map { GeocodedLocationModel(displayName: $0.name ?? "", location: $0.coordinate) }
    }
}
