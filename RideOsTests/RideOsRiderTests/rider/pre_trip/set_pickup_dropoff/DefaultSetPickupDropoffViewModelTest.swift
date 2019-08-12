import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxTest
import XCTest

class DefaultSetPickupDropoffViewModelTest: ReactiveTestCase {
    private static let pickup = PreTripLocation(
        desiredAndAssignedLocation: DesiredAndAssignedLocation(
            desiredLocation: NamedTripLocation(
                tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 1, longitude: 2)),
                displayName: "pickup"
            )
        ),
        wasSetOnMap: false
    )

    private static let dropoff = PreTripLocation(
        desiredAndAssignedLocation: DesiredAndAssignedLocation(
            desiredLocation: NamedTripLocation(
                tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 3, longitude: 4)),
                displayName: "dropoff"
            )
        ),
        wasSetOnMap: false
    )

    var viewModelUnderTest: DefaultSetPickupDropoffViewModel!
    var listener: RecordingSetPickupDropoffListener!
    var recorder: TestableObserver<SetPickupDropOffDisplayState>!
    
    func setUp(initialPickup: PreTripLocation?, initialDropoff: PreTripLocation?) {
        super.setUp()
        listener = RecordingSetPickupDropoffListener()
        viewModelUnderTest = DefaultSetPickupDropoffViewModel(listener: listener,
                                                     initialPickup: initialPickup,
                                                     initialDropoff: initialDropoff,
                                                     schedulerProvider: TestSchedulerProvider(scheduler: scheduler))
        recorder = scheduler.createObserver(SetPickupDropOffDisplayState.self)
        
        viewModelUnderTest.getDisplayState()
            .asDriver(onErrorJustReturn: SetPickupDropOffDisplayState(step: .searchingForPickupDropoff,
                                                                      pickup: nil,
                                                                      dropoff: nil))
            .drive(recorder)
            .disposed(by: disposeBag)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testInitialSetPickupDropOffDisplayStateWithNoInitialPickupOrDropoffMatchesExpectedState() {
        setUp(initialPickup: nil, initialDropoff: nil)

        scheduler.start()

        XCTAssertEqual(recorder.events, [
            next(0, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff, pickup: nil, dropoff: nil))
        ])

        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, [])
    }

    func testInitialSetPickupDropOffDisplayStateWithInitialPickupAndDropoffMatchesExpectedState() {
        setUp(initialPickup: DefaultSetPickupDropoffViewModelTest.pickup,
              initialDropoff: DefaultSetPickupDropoffViewModelTest.dropoff)

        scheduler.start()

        XCTAssertEqual(recorder.events, [
            next(0,
                 SetPickupDropOffDisplayState(
                    step: .searchingForPickupDropoff,
                    pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                    dropoff: DefaultSetPickupDropoffViewModelTest.dropoff.desiredAndAssignedLocation
                )
            )
        ])

        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, [])
    }
    
    func testSettingPickupTransitionsToExpectedSetPickupDropoffDisplayState() {
        setUp(initialPickup: nil, initialDropoff: nil)
        
        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.selectPickup(
                DefaultSetPickupDropoffViewModelTest
                    .pickup
                    .desiredAndAssignedLocation
                    .namedTripLocation
                    .geocodedLocation
            )
        }
        scheduler.start()
        
        XCTAssertEqual(recorder.events, [
            next(0, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff, pickup: nil, dropoff: nil)),
            next(2, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: nil))
        ])

        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, [])
    }
    
    func testSettingDropoffTransitionsToExpectedSetPickupDropoffDisplayState() {
        setUp(initialPickup: nil, initialDropoff: nil)
        
        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.selectDropoff(
                DefaultSetPickupDropoffViewModelTest
                    .dropoff
                    .desiredAndAssignedLocation
                    .namedTripLocation
                    .geocodedLocation
            )
        }
        scheduler.start()
        
        XCTAssertEqual(recorder.events, [
            next(0, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff, pickup: nil, dropoff: nil)),
            next(2, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff,
                                                 pickup: nil,
                                                 dropoff: DefaultSetPickupDropoffViewModelTest.dropoff.desiredAndAssignedLocation))
            ])
        
        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, [])
    }
    
    func testSettingPickupOnMapConfirmingAndThenSelectingDropoffTransitionsToExpectedSetPickupDropoffDisplayState() {
        setUp(initialPickup: nil, initialDropoff: nil)
        
        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.setPickupOnMap()
        }
        scheduler.scheduleAt(2) {
            self.viewModelUnderTest
                .confirmLocation(DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation)
        }

        scheduler.scheduleAt(3) {
            self.viewModelUnderTest.selectDropoff(
                DefaultSetPickupDropoffViewModelTest
                    .dropoff
                    .desiredAndAssignedLocation
                    .namedTripLocation
                    .geocodedLocation
            )
        }

        scheduler.start()
        
        XCTAssertEqual(recorder.events, [
            next(0, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff, pickup: nil, dropoff: nil)),
            next(1, SetPickupDropOffDisplayState(step: .settingPickupOnMap, pickup: nil, dropoff: nil)),
            next(3, SetPickupDropOffDisplayState(step: .settingPickupOnMap,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: nil)),
            next(4, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: nil)),
            next(4, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: DefaultSetPickupDropoffViewModelTest.dropoff.desiredAndAssignedLocation)),
        ])
        
        XCTAssertEqual(
            listener.pickup,
            PreTripLocation(
                desiredAndAssignedLocation: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                wasSetOnMap: true
            )
        )
        XCTAssertEqual(listener.dropoff, DefaultSetPickupDropoffViewModelTest.dropoff)
        XCTAssertEqual(listener.methodCalls, ["set(pickup:dropoff:)"])
    }
    
    func testSettingDropoffOnMapAndThenConfirmingTransitionsToExpectedSetPickupDropoffDisplayStateAndNotifiesListener() {
        setUp(initialPickup: DefaultSetPickupDropoffViewModelTest.pickup, initialDropoff: nil)
        
        scheduler.scheduleAt(1) { self.viewModelUnderTest.setDropoffOnMap() }
        scheduler.scheduleAt(2) {
            self.viewModelUnderTest
                .confirmLocation(DefaultSetPickupDropoffViewModelTest.dropoff.desiredAndAssignedLocation)
        }
        scheduler.start()
        
        XCTAssertEqual(recorder.events, [
            next(0, SetPickupDropOffDisplayState(step: .searchingForPickupDropoff,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: nil)),
            next(1, SetPickupDropOffDisplayState(step: .settingDropoffOnMap,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: nil)),
            next(3, SetPickupDropOffDisplayState(step: .settingDropoffOnMap,
                                                 pickup: DefaultSetPickupDropoffViewModelTest.pickup.desiredAndAssignedLocation,
                                                 dropoff: DefaultSetPickupDropoffViewModelTest.dropoff.desiredAndAssignedLocation)),
        ])
        
        XCTAssertEqual(listener.pickup, DefaultSetPickupDropoffViewModelTest.pickup)
        XCTAssertEqual(
            listener.dropoff,
            PreTripLocation(
                desiredAndAssignedLocation: DefaultSetPickupDropoffViewModelTest.dropoff.desiredAndAssignedLocation,
                wasSetOnMap: true
            )
        )
        XCTAssertEqual(listener.methodCalls, ["set(pickup:dropoff:)"])
    }
    
    func testCancellingLocationSearchCallsCancelSetPickupDropoffOnListener() {
        setUp(initialPickup: nil, initialDropoff: nil)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.cancelLocationSearch() })
        scheduler.start()
        
        XCTAssertNil(listener.pickup)
        XCTAssertNil(listener.dropoff)
        XCTAssertEqual(listener.methodCalls, ["cancelSetPickupDropoff()"])
    }
    
    func testDoneSearchingCallsSetPickupDropoffOnListener() {
        setUp(initialPickup: DefaultSetPickupDropoffViewModelTest.pickup,
              initialDropoff: DefaultSetPickupDropoffViewModelTest.dropoff)
        scheduler.scheduleAt(1, action: { self.viewModelUnderTest.doneSearching() })
        scheduler.start()
        
        XCTAssertEqual(listener.pickup, DefaultSetPickupDropoffViewModelTest.pickup)
        XCTAssertEqual(listener.dropoff, DefaultSetPickupDropoffViewModelTest.dropoff)
        XCTAssertEqual(listener.methodCalls, ["set(pickup:dropoff:)"])
    }
}

class RecordingSetPickupDropoffListener: MethodCallRecorder, SetPickupDropoffListener {
    var pickup: PreTripLocation?
    var dropoff: PreTripLocation?
    
    func set(pickup: PreTripLocation, dropoff: PreTripLocation) {
        self.pickup = pickup
        self.dropoff = dropoff
        recordMethodCall(#function)
    }
    
    func cancelSetPickupDropoff() {
        recordMethodCall(#function)
    }
}
