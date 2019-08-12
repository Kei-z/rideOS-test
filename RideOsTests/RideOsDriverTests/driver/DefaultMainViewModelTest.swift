import RideOsCommon
import RideOsDriver
import RideOsTestHelpers
import RxTest

class DefaultMainViewModelTest: ReactiveTestCase {
    private var viewModelUnderTest: DefaultMainViewModel!
    private var stateRecorder: TestableObserver<MainViewState>!

    override func setUp() {
        super.setUp()

        // add vehicle info to the temporary user defaults to bypass vehicle registration requirement
        let vehicleInfo = VehicleRegistration(name: "name", phoneNumber: "000-000-0000",
                                                  licensePlate: "ABCD123", riderCapacity: 4)
        let tempDefaults = TemporaryUserDefaults(stringValues: [CommonUserStorageKeys.userId: "user id"])
        let writer = UserDefaultsUserStorageWriter(userDefaults: tempDefaults)
        writer.set(key: DriverSettingsKeys.vehicleInfo, value: vehicleInfo)

        viewModelUnderTest = DefaultMainViewModel(
            userStorageReader: UserDefaultsUserStorageReader(userDefaults: tempDefaults),
            driverVehicleInteractor: FixedDriverVehicleInteractor(),
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler)
        )
        stateRecorder = scheduler.record(viewModelUnderTest.getMainViewState())

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testViewModelReflectsExpectedInitialState() {
        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
        ])
    }

    func testViewModelCanGoOnlineWhenOffline() {
        scheduler.scheduleAt(0) { self.viewModelUnderTest.goOnline() }

        scheduler.advanceTo(1)

        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            next(1, .online),
        ])
    }

    func testViewModelCanGoOfflineWhenOnline() {
        scheduler.scheduleAt(0) { self.viewModelUnderTest.goOnline() }
        scheduler.scheduleAt(1) { self.viewModelUnderTest.goOffline() }

        scheduler.advanceTo(2)

        XCTAssertEqual(stateRecorder.events, [
            next(0, .offline),
            next(1, .online),
            next(2, .offline),
        ])
    }
}
