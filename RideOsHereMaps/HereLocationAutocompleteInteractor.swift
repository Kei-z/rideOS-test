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

public class HereLocationAutocompleteInteractor: LocationAutocompleteInteractor {
    public init() {}

    public func getAutocompleteResults(searchText: String,
                                       bounds: LatLngBounds) -> Observable<[LocationAutocompleteResult]> {
        return Observable.create { observer in
            let location = bounds.northEastCorner.nmaGeoCoordinates()
            guard let request = NMAPlaces.sharedInstance()?.createAutoSuggestionRequest(location: location,
                                                                                        partialTerm: searchText) else {
                fatalError("No NMAPlaces instance")
            }

            request.start { _, result, error in
                guard HereLocationAutocompleteInteractor.isErrorNilNotFoundOrNone(error) else {
                    observer.onError(error!)
                    return
                }

                if let results = result as? [NMAAutoSuggest] {
                    observer.onNext(
                        results
                            .map(HereLocationAutocompleteInteractor.toLocationAutocompleteResult)
                            .filter { $0 != nil }
                            .map { $0! }
                    )
                } else {
                    observer.onNext([])
                }
                observer.onCompleted()
            }

            return Disposables.create { request.cancel() }
        }
    }

    public func getLocationFromAutocompleteResult(
        _ result: LocationAutocompleteResult
    ) -> Observable<GeocodedLocationModel> {
        guard let location = result.resolvedLocation else {
            fatalError("LocationAutocompleteResult for \(result.primaryText) does not contain a resolved location")
        }
        return Observable.just(GeocodedLocationModel(displayName: result.primaryText, location: location))
    }

    private static func isErrorNilNotFoundOrNone(_ error: Error?) -> Bool {
        if let error = error as NSError? {
            return error.code == NMARequestError.notFound.rawValue || error.code == NMARequestError.none.rawValue
        }
        return true
    }

    private static func toLocationAutocompleteResult(_ autoSuggest: NMAAutoSuggest) -> LocationAutocompleteResult? {
        if let place = autoSuggest as? NMAAutoSuggestPlace,
            let location = place.position,
            let primaryText = autoSuggest.title {
            return LocationAutocompleteResult.forResolvedLocation(
                location.clLocationCoordinate2D(),
                primaryText: primaryText,
                secondaryText: HereLocationAutocompleteInteractor.secondaryTextFrom(
                    vicinityDescription: place.vicinityDescription
                )
            )
        }
        return nil
    }

    // TODO(chrism): HERE's vicinityDescription may contain multiple lines of text, with HTML <br/> tags in between.
    // So our approach here is to parse the HTML into an NSAttributedString and extract only the last line. I don't
    // know how well this will scale globally, so we may eventually want to consider other approaches, including
    // allowing multiple lines of secondary text in the UI
    //
    // publicly visible for testing
    public static func secondaryTextFrom(vicinityDescription: String?) -> String {
        guard let vicinityDescription = vicinityDescription else {
            return ""
        }

        guard let vicinityDescriptionData = vicinityDescription.data(using: String.Encoding.unicode) else {
            return ""
        }

        do {
            let vicinityDescriptionAttributedString = try NSAttributedString(
                data: vicinityDescriptionData,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
            )
            return vicinityDescriptionAttributedString.string.components(separatedBy: "\n").last ?? ""
        } catch {
            return ""
        }
    }
}
