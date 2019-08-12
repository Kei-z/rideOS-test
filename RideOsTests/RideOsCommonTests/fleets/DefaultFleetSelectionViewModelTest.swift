import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RxTest
import XCTest

class DefaultFleetSelectionViewModelTest: ReactiveTestCase {
    private static let manualFleets = [
        FleetInfo(fleetId: "fleet0",
                  displayName: "Fleet 0",
                  center: CLLocationCoordinate2D(latitude: 1, longitude: 2),
                  isPhantom: false),
        FleetInfo(fleetId: "fleet1",
                  displayName: "Fleet 2",
                  center: CLLocationCoordinate2D(latitude: 3, longitude: 4),
                  isPhantom: false),
    ]
    private static let automaticallyResolvedFleet = FleetInfo(fleetId: "automatic fleet",
                                                              displayName: "Fleet 2",
                                                              center: CLLocationCoordinate2D(latitude: 5, longitude: 6),
                                                              isPhantom: false)

    var viewModelUnderTest: DefaultFleetSelectionViewModel!
    var availableFleetsRecorder: TestableObserver<[FleetOption]>!
    var resolvedFleetRecorder: TestableObserver<FleetInfo>!
    var userStorageReader: UserStorageReader!

    override func setUp() {
        super.setUp()

        let temporaryUserDefaults = TemporaryUserDefaults()
        userStorageReader = UserDefaultsUserStorageReader(userDefaults: temporaryUserDefaults)
        viewModelUnderTest = DefaultFleetSelectionViewModel(
            fleetInteractor: FixedFleetInteractor(fleets: DefaultFleetSelectionViewModelTest.manualFleets),
            fleetOptionResolver: FixedFleetOptionResolver(
                manualFleets: DefaultFleetSelectionViewModelTest.manualFleets,
                automaticallyResolvedFleet: DefaultFleetSelectionViewModelTest.automaticallyResolvedFleet
            ),
            userStorageWriter: UserDefaultsUserStorageWriter(userDefaults: temporaryUserDefaults),
            userStorageReader: userStorageReader,
            schedulerProvider: TestSchedulerProvider(scheduler: scheduler),
            logger: ConsoleLogger()
        )

        availableFleetsRecorder = scheduler.record(viewModelUnderTest.availableFleets)
        resolvedFleetRecorder = scheduler.record(viewModelUnderTest.resolvedFleet)

        assertNil(viewModelUnderTest, after: { self.viewModelUnderTest = nil })
    }

    func testAvailableFleetsReturnsCorrectFleets() {
        scheduler.start()

        let expectedAvailableFleets = [FleetOption.automatic]
            + DefaultFleetSelectionViewModelTest.manualFleets.map { FleetOption.manual(fleetInfo: $0) }
        XCTAssertEqual(availableFleetsRecorder.events, [.next(2, expectedAvailableFleets), .completed(3)])
    }

    func testResolvedFleetMatchesExpectedOnInitialization() {
        scheduler.start()

        XCTAssertEqual(resolvedFleetRecorder.events, [
            .next(0, DefaultFleetSelectionViewModelTest.automaticallyResolvedFleet),
        ])
    }

    func testResolvedFleetMatchesExpectedAfterSelection() {
        let selectedFleetInfo = DefaultFleetSelectionViewModelTest.manualFleets[1]

        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.select(fleetOption: .manual(fleetInfo: selectedFleetInfo))
            XCTAssertEqual(self.userStorageReader.fleetOption, .manual(fleetInfo: selectedFleetInfo))
        }
        scheduler.start()

        XCTAssertEqual(resolvedFleetRecorder.events, [
            .next(0, DefaultFleetSelectionViewModelTest.automaticallyResolvedFleet),
            .next(1, selectedFleetInfo),
        ])
    }

    func testStoredFleetOptionMatchesExpectedWhenSelectedFleetIsNotValid() {
        let validFleetInfo = DefaultFleetSelectionViewModelTest.manualFleets[0]
        let invalidFleetInfo = FleetInfo(fleetId: "invalid fleet",
                                         displayName: "",
                                         center: CLLocationCoordinate2D(latitude: 1, longitude: 1),
                                         isPhantom: true)
        scheduler.scheduleAt(1) {
            self.viewModelUnderTest.select(fleetOption: .manual(fleetInfo: validFleetInfo))
            XCTAssertEqual(self.userStorageReader.fleetOption, .manual(fleetInfo: validFleetInfo))
        }

        scheduler.scheduleAt(2) {
            self.viewModelUnderTest.select(fleetOption: .manual(fleetInfo: invalidFleetInfo))
        }

        scheduler.start()

        XCTAssertEqual(resolvedFleetRecorder.events, [
            .next(0, DefaultFleetSelectionViewModelTest.automaticallyResolvedFleet),
            .next(1, validFleetInfo),
            .next(2, DefaultFleetSelectionViewModelTest.automaticallyResolvedFleet),
        ])

        XCTAssertEqual(userStorageReader.fleetOption, .automatic)
    }
}
