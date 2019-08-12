import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import XCTest

class UserStorageHistoricalSearchInteractorTest: ReactiveTestCase {
    private var userDefaults: TemporaryUserDefaults!
    private var userStorageReader: UserDefaultsUserStorageReader!
    private var userStorageWriter: UserDefaultsUserStorageWriter!
    private var historicalSearchInteractorUnderTest: UserStorageHistoricalSearchInteractor!

    private static let searchOptions = [
        LocationAutocompleteResult.forUnresolvedLocation(id: "0", primaryText: "0", secondaryText: "0"),
        LocationAutocompleteResult.forUnresolvedLocation(id: "1", primaryText: "1", secondaryText: "1"),
        LocationAutocompleteResult.forUnresolvedLocation(id: "2", primaryText: "2", secondaryText: "2"),
        LocationAutocompleteResult.forUnresolvedLocation(id: "3", primaryText: "3", secondaryText: "3"),
        LocationAutocompleteResult.forUnresolvedLocation(id: "4", primaryText: "4", secondaryText: "4"),
        LocationAutocompleteResult.forUnresolvedLocation(id: "5", primaryText: "5", secondaryText: "5"),
    ]

    func setUp(initialStoredSearchOptions: [LocationAutocompleteResult]) {
        super.setUp()

        userDefaults = TemporaryUserDefaults()
        userStorageReader = UserDefaultsUserStorageReader(userDefaults: userDefaults)
        userStorageWriter = UserDefaultsUserStorageWriter(userDefaults: userDefaults)

        historicalSearchInteractorUnderTest = UserStorageHistoricalSearchInteractor(
            userStorageReader: userStorageReader,
            userStorageWriter: userStorageWriter,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            maxSearchOptionCount: 5
        )

        if initialStoredSearchOptions.isNotEmpty {
            userStorageWriter.set(key: UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey,
                                  value: initialStoredSearchOptions)
        }
    }

    func testStoringSearchOptionUpdatesUserStorageCorrectly() {
        setUp(initialStoredSearchOptions: [])

        let recordedCompletable = scheduler.record(
            historicalSearchInteractorUnderTest.store(
                searchOption: UserStorageHistoricalSearchInteractorTest.searchOptions[0]
            ).asObservable()
        )

        scheduler.start()

        XCTAssertEqual(
            userStorageReader.get(UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey),
            [UserStorageHistoricalSearchInteractorTest.searchOptions[0]]
        )
        XCTAssertEqual(recordedCompletable.events, [.completed(1)])
    }

    func testStoringDuplicateSearchOptionDoesNotLeadToDuplicateInUserStorage() {
        setUp(initialStoredSearchOptions: [UserStorageHistoricalSearchInteractorTest.searchOptions[0]])

        let recordedCompletable = scheduler.record(
            historicalSearchInteractorUnderTest.store(
                searchOption: UserStorageHistoricalSearchInteractorTest.searchOptions[0]
            ).asObservable()
        )

        scheduler.start()

        XCTAssertEqual(
            userStorageReader.get(UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey),
            [UserStorageHistoricalSearchInteractorTest.searchOptions[0]]
        )
        XCTAssertEqual(recordedCompletable.events, [.completed(1)])
    }

    func testStoringDuplicateSearchOptionPromotesThatSearchOptionToFrontOfList() {
        setUp(initialStoredSearchOptions: Array(UserStorageHistoricalSearchInteractorTest.searchOptions[0...1]))

        let recordedCompletable = scheduler.record(
            historicalSearchInteractorUnderTest.store(
                searchOption: UserStorageHistoricalSearchInteractorTest.searchOptions[1]
            ).asObservable()
        )

        scheduler.start()

        XCTAssertEqual(
            userStorageReader.get(UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey),
            [UserStorageHistoricalSearchInteractorTest.searchOptions[1],
             UserStorageHistoricalSearchInteractorTest.searchOptions[0]]
        )
        XCTAssertEqual(recordedCompletable.events, [.completed(1)])
    }

    func testStoringSearchOptionWithMaxNumberAlreadyStoredRemovesLastOption() {
        setUp(initialStoredSearchOptions: Array(UserStorageHistoricalSearchInteractorTest.searchOptions[0...4]))

        let recordedCompletable = scheduler.record(
            historicalSearchInteractorUnderTest.store(
                searchOption: UserStorageHistoricalSearchInteractorTest.searchOptions[5]
            ).asObservable()
        )

        scheduler.start()

        XCTAssertEqual(
            userStorageReader.get(UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey),
            [UserStorageHistoricalSearchInteractorTest.searchOptions[5]]
                + Array(UserStorageHistoricalSearchInteractorTest.searchOptions[0...3])
        )
        XCTAssertEqual(recordedCompletable.events, [.completed(1)])
    }

    func testRetrieveHistoricalSearchOptions() {
        setUp(initialStoredSearchOptions: Array(UserStorageHistoricalSearchInteractorTest.searchOptions[0...4]))

        let recorder = scheduler.record(historicalSearchInteractorUnderTest.historicalSearchOptions)

        scheduler.start()

        XCTAssertEqual(recorder.events, [
            .next(0, Array(UserStorageHistoricalSearchInteractorTest.searchOptions[0...4]))
        ])
    }

    func testRetrieveHistoricalSearchOptionsWithNothingStored() {
        setUp(initialStoredSearchOptions: [])

        let recorder = scheduler.record(historicalSearchInteractorUnderTest.historicalSearchOptions)

        scheduler.start()

        XCTAssertEqual(recorder.events, [.next(0, [])])
    }
}
