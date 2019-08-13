import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest

class DefaultMainViewModelTest: ReactiveTestCase {
    private var viewModelUnderTest: DefaultMainViewModel!
    private var stateRecorder: TestableObserver<MainViewState>!
    
    func setUp(vehicleStatus: VehicleStatus) {
        super.setUp()
        
        viewModelUnderTest = DefaultMainViewModel(
            userStorageReader: UserDefaultsUserStorageReader(
                userDefaults: TemporaryUserDefaults(stringValues: [CommonUserStorageKeys.userId: "a_test_user_id"])
            ),
            driverVehicleInteractor: FixedDriverVehicleInteractor(vehicleStatus: vehicleStatus),
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger()
        )
        stateRecorder = scheduler.record(viewModelUnderTest.getMainViewState())
        
        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }
    
    func testViewModelReflectsOfflineInitialStateWhenVehicleIsNotReady() {
        setUp(vehicleStatus: .notReady)
        
        scheduler.advanceTo(1)
        
        XCTAssertEqual(stateRecorder.events, [
            next(1, .offline),
            ])
    }
    
    func testViewModelReflectsOnlineInitialStateWhenVehicleIsReady() {
        setUp(vehicleStatus: .ready)
        
        scheduler.advanceTo(1)
        
        XCTAssertEqual(stateRecorder.events, [
            next(1, .online),
            ])
    }
    
    func testViewModelReflectsUnregisteredInitialStateWhenVehicleIsUnregistered() {
        setUp(vehicleStatus: .unregistered)
        
        scheduler.advanceTo(1)
        
        XCTAssertEqual(stateRecorder.events, [
            next(1, .vehicleUnregistered),
            ])
    }
    
    func testViewModelCanGoOnlineWhenOffline() {
        setUp(vehicleStatus: .notReady)
        
        scheduler.scheduleAt(0) { self.viewModelUnderTest.goOnline() }
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(stateRecorder.events, [
            next(1, .offline),
            next(2, .online),
            ])
    }
    
    func testViewModelCanGoOfflineWhenOnline() {
        setUp(vehicleStatus: .notReady)
        
        scheduler.scheduleAt(0) { self.viewModelUnderTest.goOnline() }
        scheduler.scheduleAt(1) { self.viewModelUnderTest.goOffline() }
        
        scheduler.advanceTo(3)
        
        XCTAssertEqual(stateRecorder.events, [
            next(1, .offline),
            next(2, .online),
            next(3, .offline),
            ])
    }
    
    func testViewModelGoesOfflineAfterFinishingVehicleRegistration() {
        setUp(vehicleStatus: .unregistered)
        
        scheduler.scheduleAt(0) { self.viewModelUnderTest.vehicleRegistrationFinished() }
        
        scheduler.advanceTo(2)
        
        XCTAssertEqual(stateRecorder.events, [
            next(1, .vehicleUnregistered),
            next(2, .offline),
            ])
    }
}
