import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultIdleViewModelTest: ReactiveTestCase {
    private var viewModelUnderTest: DefaultIdleViewModel!
    private var recordingDriverVehicleInteractor: FixedDriverVehicleInteractor!
    private var stateRecorder: TestableObserver<IdleViewState>!
    
    func setUp(markVehicleNotReadyError: Error?) {
        super.setUp()
        
        recordingDriverVehicleInteractor = FixedDriverVehicleInteractor(
            markVehicleNotReadyError: markVehicleNotReadyError
        )
        
        viewModelUnderTest = DefaultIdleViewModel(
            userStorageReader: UserDefaultsUserStorageReader(
                userDefaults:TemporaryUserDefaults(stringValues: [CommonUserStorageKeys.userId: "user id"])
            ),
            driverVehicleInteractor: recordingDriverVehicleInteractor,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger())
        
        stateRecorder = scheduler.record(viewModelUnderTest.idleViewState)
    }
    
    func testViewModelReflectsExpectedInitialState() {
        setUp(markVehicleNotReadyError: nil)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .online),
            ])
    }
    
    func testViewModelReflectsGoingOfflineAfterGoOfflineIsCalled() {
        setUp(markVehicleNotReadyError: nil)
        
        viewModelUnderTest.goOffline()
        
        scheduler.advanceTo(1)
        
        XCTAssertEqual(recordingDriverVehicleInteractor.methodCalls, ["markVehicleNotReady(vehicleId:)"])
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .online),
            next(1, .goingOffline),
            ])
    }
    
    func testViewModelReflectsBeingOfflineAfterGoOfflineSucceeds() {
        setUp(markVehicleNotReadyError: nil)
        
        viewModelUnderTest.goOffline()
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .online),
            next(1, .goingOffline),
            next(2, .offline),
            ])
    }
    
    func testViewModelReflectsFailingToGoOfflineAfterGoOfflineFails() {
        setUp(markVehicleNotReadyError: NSError(domain: "", code: 0, userInfo: nil))
        
        viewModelUnderTest.goOffline()
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .online),
            next(1, .goingOffline),
            next(2, .failedToGoOffline),
            ])
    }
    
    
    func testViewModelDoesNotTryToGoOfflineAgainIfAlreadyOffline() {
        setUp(markVehicleNotReadyError: nil)
        
        viewModelUnderTest.goOffline()
        
        scheduler.advanceTo(2)
        
        viewModelUnderTest.goOffline()
        
        scheduler.advanceTo(3)
        
        XCTAssertEqual(stateRecorder.events, [
            next(0, .online),
            next(1, .goingOffline),
            next(2, .offline),
            ])
    }
}
