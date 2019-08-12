import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest

class DefaultCurrentTripViewModelTest: ReactiveTestCase {
    static let tripId = "trip_id"
    
    var viewModelUnderTest: DefaultCurrentTripViewModel!
    var riderTripStateModelRecorder: TestableObserver<RiderTripStateModel>!
    var tripInteractor: FixedTripInteractor!
    var currentTripListener: RecordingCurrentTripListener!
    
    static let pickupLocation = GeocodedLocationModel(displayName: "pickup",
                                                      location: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    static let dropoffLocation = GeocodedLocationModel(displayName: "dropoff",
                                                       location: CLLocationCoordinate2D(latitude: 1, longitude: 1))
    
    static let riderTripState = RiderTripStateModel.waitingForAssignment(
        passengerPickupLocation: DefaultCurrentTripViewModelTest.pickupLocation,
        passengerDropoffLocation: DefaultCurrentTripViewModelTest.dropoffLocation
    )
    
    func setUp(tripStateObservable: Observable<RiderTripStateModel>) {
        ResolvedFleet.instance.set(resolvedFleet: FleetInfo.defaultFleetInfo)

        tripInteractor = FixedTripInteractor()
        currentTripListener = RecordingCurrentTripListener()
        viewModelUnderTest = DefaultCurrentTripViewModel(
            userStorageReader: UserDefaultsUserStorageReader(
                userDefaults: TemporaryUserDefaults(stringValues: [CommonUserStorageKeys.userId: "user id"])
            ),
            tripId: DefaultCurrentTripViewModelTest.tripId,
            listener: currentTripListener,
            riderTripStateInteractor: ReplayingTripStateInteractor(tripStateObservable),
            tripInteractor: tripInteractor,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger())
        
        riderTripStateModelRecorder = scheduler.record(viewModelUnderTest.riderTripState)
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testRiderTripStateStartsWithUnknown() {
        setUp(tripStateObservable: scheduler.createColdObservable([
            .next(0, DefaultCurrentTripViewModelTest.riderTripState),
        ]).asObservable())
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(riderTripStateModelRecorder.events, [
            .next(0, RiderTripStateModel.unknown),
            .next(2, DefaultCurrentTripViewModelTest.riderTripState),
        ])
    }
    
    func testViewModelPollsRiderTripStateInteractor() {
        setUp(tripStateObservable: scheduler.createColdObservable([
            .next(0, DefaultCurrentTripViewModelTest.riderTripState),
        ]).asObservable())
        
        scheduler.advanceTo(5)
        
        XCTAssertEqual(riderTripStateModelRecorder.events, [
            .next(0, RiderTripStateModel.unknown),
            .next(2, DefaultCurrentTripViewModelTest.riderTripState),
            .next(3, DefaultCurrentTripViewModelTest.riderTripState),
            .next(4, DefaultCurrentTripViewModelTest.riderTripState),
            .next(5, DefaultCurrentTripViewModelTest.riderTripState),
        ])
    }
    
    func testCancelTripCallsCancelTripOnTripInteractor() {
        setUp(tripStateObservable: scheduler.createColdObservable([
            .next(0, DefaultCurrentTripViewModelTest.riderTripState),
        ]).asObservable())
        
        viewModelUnderTest.cancelTrip()
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(tripInteractor.methodCalls, ["cancelTrip(passengerId:tripId:)"])
    }

    func testEditPickupCallsEditPickupOnListener() {
        setUp(tripStateObservable: Observable.empty())
        viewModelUnderTest.editPickup()
        XCTAssertEqual(currentTripListener.methodCalls, ["editPickup()"])
    }
}

class RecordingCurrentTripListener: MethodCallRecorder, CurrentTripListener {
    func editPickup() {
        recordMethodCall(#function)
    }
}
