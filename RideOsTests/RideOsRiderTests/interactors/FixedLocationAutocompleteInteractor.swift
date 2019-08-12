import CoreLocation
import Foundation
import RideOsCommon
import RideOsRider
import RxSwift

public class FixedLocationAutocompleteInteractor: LocationAutocompleteInteractor {
    public static let location = CLLocationCoordinate2D(latitude: 37, longitude: -122)
    
    public static func autoCompleteResult(forSearchText searchText: String) -> LocationAutocompleteResult {
        return LocationAutocompleteResult.forUnresolvedLocation(id: searchText,
                                                                primaryText: searchText,
                                                                secondaryText: searchText)
    }
    
    public func getAutocompleteResults(searchText: String,
                                       bounds: LatLngBounds) -> Observable<[LocationAutocompleteResult]> {
        return Observable.just([FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: searchText)])
    }
    
    public func getLocationFromAutocompleteResult(_ result: LocationAutocompleteResult) -> Observable<GeocodedLocationModel> {
        return Observable.just(GeocodedLocationModel(displayName: result.primaryText,
                                                     location: FixedLocationAutocompleteInteractor.location))
    }
}
