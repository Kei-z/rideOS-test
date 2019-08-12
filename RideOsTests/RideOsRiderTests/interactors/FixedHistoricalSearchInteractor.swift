import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift

class FixedHistoricalSearchInteractor: HistoricalSearchInteractor {
    private let searchOptions: [LocationAutocompleteResult]

    private var storedSearchOptions: [LocationAutocompleteResult] = []

    init(searchOptions: [LocationAutocompleteResult]) {
        self.searchOptions = searchOptions
    }

    var historicalSearchOptions: Observable<[LocationAutocompleteResult]> {
        return Observable.just(searchOptions)
    }

    func store(searchOption: LocationAutocompleteResult) -> Completable {
        storedSearchOptions.append(searchOption)
        return Completable.never()
    }

    var recordedStoredSearchOptions: [LocationAutocompleteResult] {
        return storedSearchOptions
    }
}
