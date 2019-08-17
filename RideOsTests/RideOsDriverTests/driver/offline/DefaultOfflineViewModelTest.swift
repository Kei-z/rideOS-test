import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultOfflineViewModelTest: ReactiveTestCase {
    private var viewModelUnderTest: DefaultOfflineViewModel!
    private var recordingDriverVehicleInteractor: FixedDriverVehicleInteractor!
    private var stateRecorder: TestableObserver<OfflineViewState>!
    
    func setUp(markVehicleReadyError: Error?) {
        super.setUp()
        
        recordingDriverVehicleInteractor = FixedDriverVehicleInteractor(
            markVehicleReadyError: markVehicleReadyError
        )
        
        viewModelUnderTest = DefaultOfflineViewModel(
            userStorageReader: UserDefaultsUserStorageReader(
                userDefaults:TemporaryUserDefaults(stringValues: [CommonUserStorageKeys.userId: "user id"])
            ),
            driverVehicleInteractor: recordingDriverVehicleInteractor,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger())

        stateRecorder = scheduler.record(viewModelUnderTest.offlineViewState)
    }

    func testViewModelReflectsExpectedInitialState() {
        setUp(markVehicleReadyError: nil)

        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            ])
    }

    func testViewModelReflectsGoingOnlineAfterGoOnlineIsCalled() {
        setUp(markVehicleReadyError: nil)
        
        viewModelUnderTest.goOnline()
        
        scheduler.advanceTo(1)
        
        XCTAssertEqual(recordingDriverVehicleInteractor.methodCalls, ["markVehicleReady(vehicleId:)"])
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            next(1, .goingOnline),
            ])
    }

    func testViewModelReflectsBeingOnlineAfterGoingOnlineSucceeds() {
        setUp(markVehicleReadyError: nil)
        
        viewModelUnderTest.goOnline()
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            next(1, .goingOnline),
            next(2, .online),
            ])
    }
    
    func testViewModelReflectsFailingToGoOnlineAfterGoingOnlineFails() {
        setUp(markVehicleReadyError: NSError(domain: "", code: 0, userInfo: nil))
        
        viewModelUnderTest.goOnline()
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            next(1, .goingOnline),
            next(2, .failedToGoOnline),
            ])
    }
    
    func testViewModelDoesNotTryToGoOnlineAgainIfAlreadyOnline() {
        setUp(markVehicleReadyError: nil)
        
        viewModelUnderTest.goOnline()
        
        scheduler.advanceTo(2)
        
        viewModelUnderTest.goOnline()
        
        scheduler.advanceTo(3)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            next(1, .goingOnline),
            next(2, .online),
            ])
    }
}
