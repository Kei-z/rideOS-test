import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest
import RxCocoa

class DefaultLocationSearchViewModelTest: ReactiveTestCase {
    private static let deviceLocation = CLLocation(latitude: 42, longitude: 42)
    private static let currentLocationString = "Current location"
    private static let expectedGeocodedCurrentLocation = GeocodedLocationModel(
        displayName: DefaultLocationSearchViewModelTest.currentLocationString,
        location: DefaultLocationSearchViewModelTest.deviceLocation.coordinate
    )
    private static let searchBounds = LatLngBounds(southWestCorner: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                                                   northEastCorner: CLLocationCoordinate2D(latitude: 2, longitude: 2))
    
    var viewModelUnderTest: DefaultLocationSearchViewModel!
    var locationOptionsRecorder: TestableObserver<[LocationSearchOption]>!
    var selectedPickupRecorder: TestableObserver<String>!
    var selectedDropoffRecorder: TestableObserver<String>!
    var isDoneActionEnabledRecorder: TestableObserver<Bool>!
    var listener: RecordingLocationSearchListener!
    var fixedHistoricalSearchInteractor: FixedHistoricalSearchInteractor!
    
    func setUp(initialPickup: GeocodedLocationModel?,
               initialDropoff: GeocodedLocationModel?,
               historicalSearchResults: [LocationAutocompleteResult] = []) {
        super.setUp()
        listener = RecordingLocationSearchListener()
        fixedHistoricalSearchInteractor = FixedHistoricalSearchInteractor(searchOptions: historicalSearchResults)
        viewModelUnderTest = DefaultLocationSearchViewModel(
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            listener: listener,
            initialPickup: initialPickup,
            initialDropoff: initialDropoff,
            searchBounds: DefaultLocationSearchViewModelTest.searchBounds,
            locationAutocompleteInteractor: FixedLocationAutocompleteInteractor(),
            deviceLocator: FixedDeviceLocator(deviceLocation: DefaultLocationSearchViewModelTest.deviceLocation),
            historicalSearchInteractor: fixedHistoricalSearchInteractor,
            logger: ConsoleLogger()
        )
        
        locationOptionsRecorder = scheduler.createObserver(Array.self)
        viewModelUnderTest.getLocationOptions()
            .asDriver(onErrorJustReturn: [])
            .drive(locationOptionsRecorder)
            .disposed(by: disposeBag)
        
        selectedPickupRecorder = scheduler.createObserver(String.self)
        viewModelUnderTest.getSelectedPickup()
            .asDriver(onErrorJustReturn: "ERROR")
            .drive(selectedPickupRecorder)
            .disposed(by: disposeBag)
        
        selectedDropoffRecorder = scheduler.createObserver(String.self)
        viewModelUnderTest.getSelectedDropOff()
            .asDriver(onErrorJustReturn: "ERROR")
            .drive(selectedDropoffRecorder)
            .disposed(by: disposeBag)
        
        isDoneActionEnabledRecorder = scheduler.createObserver(Bool.self)
        viewModelUnderTest.isDoneActionEnabled()
            .asDriver(onErrorJustReturn: false)
            .drive(isDoneActionEnabledRecorder)
            .disposed(by: disposeBag)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testStateMatchesExpectationBeforeInteractionsWithNoInitialPickupOrDropoff() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.start()
        AssertRecordedElementsIgnoringCompletion(locationOptionsRecorder.events, [[LocationSearchOption.selectOnMap]])
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])

    }
    
    func testStateMatchesExpectationBeforeInteractionsWithInitialPickupButNoInitialDropoff() {
        setUp(initialPickup: GeocodedLocationModel(displayName: "pickup location",
                                                   location: CLLocationCoordinate2D(latitude: 1, longitude: 2)),
              initialDropoff: nil)
        scheduler.start()
        AssertRecordedElementsIgnoringCompletion(locationOptionsRecorder.events, [[LocationSearchOption.selectOnMap]])
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["pickup location"])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, [])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])
    }
    
    func testStateMatchesExpectationBeforeInteractionsWithInitialDropoffButNoInitialPickup() {
        setUp(initialPickup: nil,
              initialDropoff: GeocodedLocationModel(displayName: "dropoff location",
                                                    location: CLLocationCoordinate2D(latitude: 3, longitude: 4)))
        scheduler.start()
        AssertRecordedElementsIgnoringCompletion(locationOptionsRecorder.events, [[LocationSearchOption.selectOnMap]])
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, ["dropoff location"])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])
    }
    
    func testSetDropoffTextProducesExpectedEvents() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setDropoffText("d") })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.setDropoffText("dr") })
        scheduler.start()

        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, [LocationSearchOption.selectOnMap]),
            next(1, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "d")),
            ]),
            next(2, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "dr")),
            ]),
        ])

        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])
    }

    func testSetDuplicateDropoffTextProducesExpectedEvents() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setDropoffText("dr") })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.setDropoffText("dr") }) // duplicate. make sure we dedupe
        scheduler.start()
        
        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, [LocationSearchOption.selectOnMap]),
            next(1, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "dr")),
            ]),
        ])
        
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])
    }

    
    func testSetDropoffTextThenPickupTextProducesExpectedEvents() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setDropoffText("d") })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.setFocus(.pickup) })
        scheduler.scheduleAt(3, action: { self.viewModelUnderTest.setPickupText("p") })
        scheduler.start()

        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, [LocationSearchOption.selectOnMap]),
            next(1, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "d")),
            ]),
            next(2, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "d")),
            ]),
            next(2, [
                LocationSearchOption.currentLocation,
                LocationSearchOption.selectOnMap
            ]),
            next(3, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "p"))
            ]),
        ])

        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])
    }

    func testSetDropoffTextThenSelectDropoffProducesExpectedEvents() {
        let expectedAutocompleteResult = FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "d")

        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setDropoffText("d") })
        scheduler.scheduleAt(2, action: {
            self.viewModelUnderTest.makeSelection(.autocompleteLocation(expectedAutocompleteResult))
        })
        scheduler.start()

        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, [LocationSearchOption.selectOnMap]),
            next(1, [
                .autocompleteLocation(expectedAutocompleteResult),
            ])
        ])

        XCTAssertEqual(selectedDropoffRecorder.events, [next(0, ""), next(3, "d")])
        XCTAssertEqual(selectedPickupRecorder.events, [next(0, ""), next(0, DefaultLocationSearchViewModelTest.currentLocationString),])

        XCTAssertEqual(isDoneActionEnabledRecorder.events, [next(0, false), completed(0)])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertEqual(listener.dropoff, GeocodedLocationModel(displayName: "d",
                                                               location: FixedLocationAutocompleteInteractor.location))
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)", "selectDropoff(_:)"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [expectedAutocompleteResult])
    }

    func testCancelInvokesCancelLocationSearchOnListener() {
        setUp(initialPickup: nil, initialDropoff: nil)
        viewModelUnderTest.cancel()
        XCTAssertEqual(listener.methodCalls, ["cancelLocationSearch()"])
    }
    
    func testDoneInvokesDoneSearchingOnListener() {
        setUp(initialPickup: GeocodedLocationModel(displayName: "pickup location",
                                                   location: CLLocationCoordinate2D(latitude: 1, longitude: 2)),
              initialDropoff: GeocodedLocationModel(displayName: "dropoff location",
                                                    location: CLLocationCoordinate2D(latitude: 3, longitude: 4)))
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.done() })
        scheduler.start()
        AssertRecordedElementsIgnoringCompletion(locationOptionsRecorder.events, [[LocationSearchOption.selectOnMap]])
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["pickup location"])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, ["dropoff location"])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [true])
        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["doneSearching()"])
    }
    
    func testSelectDropoffOnMapInvokesSetDropoffOnMapOnListener() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.makeSelection(LocationSearchOption.selectOnMap) })
        scheduler.start()
        AssertRecordedElementsIgnoringCompletion(locationOptionsRecorder.events, [[LocationSearchOption.selectOnMap]])
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)", "setDropoffOnMap()"])
    }
    
    func testSelectPickupOnMapInvokesSetPickupOnMapOnListenerButDoesNotStoreAutocompleteResult() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setFocus(.pickup) })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.makeSelection(LocationSearchOption.selectOnMap) })
        scheduler.start()
        
        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, [LocationSearchOption.selectOnMap]),
            next(1, [LocationSearchOption.currentLocation, LocationSearchOption.selectOnMap]),
            next(1, [LocationSearchOption.currentLocation, LocationSearchOption.selectOnMap]),
        ])
        
        AssertRecordedElementsIgnoringCompletion(selectedPickupRecorder.events, ["", DefaultLocationSearchViewModelTest.currentLocationString])
        AssertRecordedElementsIgnoringCompletion(selectedDropoffRecorder.events, [""])
        AssertRecordedElementsIgnoringCompletion(isDoneActionEnabledRecorder.events, [false])
        XCTAssertEqual(listener.pickup, DefaultLocationSearchViewModelTest.expectedGeocodedCurrentLocation)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["selectPickup(_:)", "setPickupOnMap()"])
        XCTAssertEqual(fixedHistoricalSearchInteractor.recordedStoredSearchOptions, [])
    }

    func testSetDropoffTextWithHistoricalLocationsProducesExpectedLocationOptions() {
        let historicalSearchResults = [
            LocationAutocompleteResult.forUnresolvedLocation(id: "0", primaryText: "0", secondaryText: "0"),
            LocationAutocompleteResult.forUnresolvedLocation(id: "1", primaryText: "1", secondaryText: "1")
        ]
        let expectedHistoricalOptions = historicalSearchResults.map { LocationSearchOption.historical($0) }
        setUp(initialPickup: nil, initialDropoff: nil, historicalSearchResults: historicalSearchResults)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setDropoffText("d") })
        scheduler.start()

        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, expectedHistoricalOptions + [LocationSearchOption.selectOnMap]),
            next(1, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "d")),
            ]),
        ])
    }

    func testSetPickupTextWithHistoricalLocationsProducesExpectedLocationOptions() {
        let historicalSearchResults = [
            LocationAutocompleteResult.forUnresolvedLocation(id: "0", primaryText: "0", secondaryText: "0"),
            LocationAutocompleteResult.forUnresolvedLocation(id: "1", primaryText: "1", secondaryText: "1")
        ]
        let expectedHistoricalOptions = historicalSearchResults.map { LocationSearchOption.historical($0) }
        setUp(initialPickup: nil, initialDropoff: nil, historicalSearchResults: historicalSearchResults)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.setFocus(.pickup) })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.setPickupText("p") })
        scheduler.start()

        XCTAssertEqual(locationOptionsRecorder.events, [
            next(1, expectedHistoricalOptions + [LocationSearchOption.selectOnMap]),
            next(1,
                 [LocationSearchOption.currentLocation, LocationSearchOption.selectOnMap] + expectedHistoricalOptions),
            next(1,
                 [LocationSearchOption.currentLocation, LocationSearchOption.selectOnMap] + expectedHistoricalOptions),
            next(2, [
                .autocompleteLocation(FixedLocationAutocompleteInteractor.autoCompleteResult(forSearchText: "p"))
            ]),
        ])
    }
}

class RecordingLocationSearchListener: MethodCallRecorder, LocationSearchListener {
    var pickup: GeocodedLocationModel?
    var dropoff: GeocodedLocationModel?
    
    func selectPickup(_ pickup: GeocodedLocationModel) {
        self.pickup = pickup
        recordMethodCall(#function)
    }
    
    func selectDropoff(_ dropoff: GeocodedLocationModel) {
        self.dropoff = dropoff
        recordMethodCall(#function)
    }
    
    func setPickupOnMap() {
        recordMethodCall(#function)
    }
    
    func setDropoffOnMap() {
        recordMethodCall(#function)
    }
    
    func cancelLocationSearch() {
        recordMethodCall(#function)
    }
    
    func doneSearching() {
        recordMethodCall(#function)
    }
}
