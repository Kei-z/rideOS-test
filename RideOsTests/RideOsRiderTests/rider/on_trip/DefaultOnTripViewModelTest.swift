import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift
import RxTest
import XCTest

class DefaultOnTripViewModelTest: ReactiveTestCase {
    static let currentTaskId = "current_trip_id"
    static let newTaskId = "new_trip_id"
    static let newPickupLocation = DesiredAndAssignedLocation(
        desiredLocation: NamedTripLocation(
            tripLocation: TripLocation(location: CLLocationCoordinate2D(latitude: 1, longitude: 1)),
            displayName: "new pickup"
        )
    )

    var viewModelUnderTest: DefaultOnTripViewModel!
    var tripInteractor: FixedTripInteractor!
    var displayStateRecorder: TestableObserver<OnTripDisplayState>!
    var tripFinishedListener: RecordingTripFinishedListener!

    func setUp(editPickupResponse: Observable<String>) {
        super.setUp()

        tripInteractor = FixedTripInteractor(editPickupResponse: editPickupResponse)
        tripFinishedListener = RecordingTripFinishedListener()
        viewModelUnderTest = DefaultOnTripViewModel(
            tripId: DefaultOnTripViewModelTest.currentTaskId,
            tripFinishedListener: tripFinishedListener,
            tripInteractor: tripInteractor,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger()
        )

        displayStateRecorder = scheduler.record(viewModelUnderTest.displayState)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testInitialDisplayStateIsCurrentTrip() {
        setUp(editPickupResponse: Observable.empty())
        scheduler.start()

        XCTAssertEqual(displayStateRecorder.events, [.next(0, .currentTrip)])
    }

    func testEditPickupTransitionsDisplayStateToEditingPickup() {
        setUp(editPickupResponse: Observable.empty())
        scheduler.scheduleAt(1) { self.viewModelUnderTest.editPickup() }
        scheduler.start()

        XCTAssertEqual(displayStateRecorder.events, [.next(0, .currentTrip), .next(1, .editingPickup)])
    }

    func testCancelConfirmLocationTransitionsDisplayStateBackToCurrentTrip() {
        setUp(editPickupResponse: Observable.empty())
        scheduler.scheduleAt(1) { self.viewModelUnderTest.editPickup() }
        scheduler.scheduleAt(2) { self.viewModelUnderTest.cancelConfirmLocation() }
        scheduler.start()

        XCTAssertEqual(displayStateRecorder.events, [
            .next(0, .currentTrip),
            .next(1, .editingPickup),
            .next(2, .currentTrip)
        ])
    }

    func testConfirmLocationTransitionsStateToUpdatingPickupAndCallsTaskInteractorEditPickup() {
        setUp(editPickupResponse: Observable.just(DefaultOnTripViewModelTest.newTaskId))
        scheduler.scheduleAt(1) { self.viewModelUnderTest.editPickup() }
        scheduler.scheduleAt(2) {
            self.viewModelUnderTest.confirmLocation(DefaultOnTripViewModelTest.newPickupLocation)
        }
        scheduler.start()

        XCTAssertEqual(displayStateRecorder.events, [
            .next(0, .currentTrip),
            .next(1, .editingPickup),
            .next(2, .updatingPickup(newPickupLocation: DefaultOnTripViewModelTest.newPickupLocation))
        ])

        XCTAssertEqual(tripInteractor.methodCalls, ["editPickup(tripId:newPickupLocation:)"])
    }

    func testTaskInteractorEditPickupErrorTransitionsBackToCurrentTrip() {
        setUp(editPickupResponse: Observable.error(TripInteractorError.invalidResponse))
        scheduler.scheduleAt(1) { self.viewModelUnderTest.editPickup() }
        scheduler.scheduleAt(2) {
            self.viewModelUnderTest.confirmLocation(DefaultOnTripViewModelTest.newPickupLocation)
        }
        scheduler.start()

        XCTAssertEqual(displayStateRecorder.events, [
            .next(0, .currentTrip),
            .next(1, .editingPickup),
            .next(2, .updatingPickup(newPickupLocation: DefaultOnTripViewModelTest.newPickupLocation)),
            .next(3, .currentTrip)
        ])
    }

    func testCallingTripFinishedCallsTripFinishedListener() {
        setUp(editPickupResponse: Observable.empty())
        scheduler.start()

        viewModelUnderTest.tripFinished()

        XCTAssertEqual(tripFinishedListener.methodCalls, ["tripFinished()"])
    }
}

class RecordingTripFinishedListener: MethodCallRecorder, TripFinishedListener {
    func tripFinished() {
        recordMethodCall(#function)
    }
}
