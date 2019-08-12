import CoreLocation
import RideOsDriver
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultDrivingModelTest: ReactiveTestCase {
    private static let destination = CLLocationCoordinate2D(latitude: 42, longitude: 42)

    private var viewModelUnderTest: DrivingViewModel!
    private var recordingFinishedDrivingListener: RecordingFinishedDrivingListener!
    private var stateRecorder: TestableObserver<DrivingViewState>!

    func setUp(withInitialStep step: DrivingViewState.Step) {
        super.setUp()
        recordingFinishedDrivingListener = RecordingFinishedDrivingListener()

        let finishedDrivingListener = recordingFinishedDrivingListener.finishedDriving
        viewModelUnderTest = DefaultDrivingViewModel(finishedDrivingListener: finishedDrivingListener,
                                                     destination: DefaultDrivingModelTest.destination,
                                                     initialStep: step,
                                                     schedulerProvider: TestSchedulerProvider(scheduler: scheduler))
        stateRecorder = scheduler.record(viewModelUnderTest.drivingViewState)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelReflectsExpectedInitialState() {
        let expectedInitialStep: DrivingViewState.Step = .drivePending
        setUp(withInitialStep: expectedInitialStep)

        scheduler.start()

        XCTAssertEqual(stateRecorder.events, [
            next(0, DrivingViewState(drivingStep: expectedInitialStep,
                                     destination: DefaultDrivingModelTest.destination)),
        ])
    }

    func testViewModelWithDrivePendingTransitionsToNavigatingOnStartNavigation() {
        setUp(withInitialStep: .drivePending)

        scheduler.scheduleAt(0) { self.viewModelUnderTest.startNavigation() }

        scheduler.start()

        XCTAssertEqual(stateRecorder.events, [
            next(0, DrivingViewState(drivingStep: .drivePending,
                                     destination: DefaultDrivingModelTest.destination)),
            next(1, DrivingViewState(drivingStep: .navigating,
                                     destination: DefaultDrivingModelTest.destination)),
        ])
    }

    func testViewModelThatIsNavigatingTransitionsToConfirmingArrivalOnFinishNavigation() {
        setUp(withInitialStep: .navigating)

        scheduler.scheduleAt(0) { self.viewModelUnderTest.finishedNavigation() }

        scheduler.start()

        XCTAssertEqual(stateRecorder.events, [
            next(0, DrivingViewState(drivingStep: .navigating,
                                     destination: DefaultDrivingModelTest.destination)),
            next(1, DrivingViewState(drivingStep: .confirmingArrival,
                                     destination: DefaultDrivingModelTest.destination)),
        ])
    }

    func testViewModelWaitingToConfirmArrivalMaintainsSameStateAfterConfirmingArrival() {
        setUp(withInitialStep: .confirmingArrival)

        scheduler.scheduleAt(0) { self.viewModelUnderTest.confirmArrival() }

        scheduler.start()

        XCTAssertEqual(stateRecorder.events, [
            next(0, DrivingViewState(drivingStep: .confirmingArrival,
                                     destination: DefaultDrivingModelTest.destination)),
        ])
    }

    func testViewModelCallsFinishedDrivingListenerAfterConfirmingArrival() {
        setUp(withInitialStep: .confirmingArrival)

        scheduler.scheduleAt(0) { self.viewModelUnderTest.confirmArrival() }

        scheduler.start()

        XCTAssertEqual(recordingFinishedDrivingListener.methodCalls, ["finishedDriving()"])
    }
}

class RecordingFinishedDrivingListener: MethodCallRecorder {
    func finishedDriving() {
        recordMethodCall(#function)
    }
}
