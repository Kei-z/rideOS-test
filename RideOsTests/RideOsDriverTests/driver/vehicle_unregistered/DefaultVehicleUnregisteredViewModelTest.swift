import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultVehicleUnregisteredViewModelTest: ReactiveTestCase {
    private var viewModelUnderTest: DefaultVehicleUnregisteredViewModel!
    private var stateRecorder: TestableObserver<VehicleUnregisteredViewState>!
    private var recordingRegisterVehicleFinishedListener: RecordingRegisterVehicleFinishedListener!

    override func setUp() {
        super.setUp()
        recordingRegisterVehicleFinishedListener = RecordingRegisterVehicleFinishedListener()

        viewModelUnderTest = DefaultVehicleUnregisteredViewModel(
            registerVehicleFinishedListener: recordingRegisterVehicleFinishedListener,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger()
        )
        stateRecorder = scheduler.record(viewModelUnderTest.getVehicleUnregisteredViewState())

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelReflectsExpectedInitialState() {
        XCTAssertEqual(stateRecorder.events, [
            next(0, .preRegistration),
        ])
    }

    func testViewModelCanStartRegistrationWhenOnStartScreen() {
        scheduler.scheduleAt(0) { self.viewModelUnderTest.startVehicleRegistration() }

        scheduler.advanceTo(1)

        XCTAssertEqual(stateRecorder.events, [
            next(0, .preRegistration),
            next(1, .registering),
        ])
    }

    func testViewModelCanCancelRegistration() {
        scheduler.scheduleAt(0) { self.viewModelUnderTest.startVehicleRegistration() }
        scheduler.scheduleAt(1) { self.viewModelUnderTest.cancelVehicleRegistration() }

        scheduler.advanceTo(2)

        XCTAssertEqual(stateRecorder.events, [
            next(0, .preRegistration),
            next(1, .registering),
            next(2, .preRegistration),
        ])
    }

    func testViewModelCallsRegisterVehicleListener() {
        scheduler.scheduleAt(0) { self.viewModelUnderTest.startVehicleRegistration() }
        scheduler.scheduleAt(1) { self.viewModelUnderTest.finishVehicleRegistration() }

        scheduler.start()

        XCTAssertEqual(recordingRegisterVehicleFinishedListener.methodCalls, ["vehicleRegistrationFinished()"])
    }
}

class RecordingRegisterVehicleFinishedListener: MethodCallRecorder, RegisterVehicleFinishedListener {
    func vehicleRegistrationFinished() {
        recordMethodCall(#function)
    }
}
