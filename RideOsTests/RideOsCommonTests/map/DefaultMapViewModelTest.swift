import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RxSwift
import RxTest

class DefaultMapViewModelTest: ReactiveTestCase {
    private static let goodCameraUpdate = CameraUpdate.centerAndZoom(
        center: CLLocationCoordinate2D(latitude: 1, longitude: 2),
        zoom: 12.0
    )
    private static let badCameraUpdate = CameraUpdate.centerAndZoom(
        center: CLLocationCoordinate2D(latitude: 3, longitude: 4),
        zoom: -1.0
    )

    var viewModelUnderTest: DefaultMapViewModel!
    var cameraUpdateRecorder: TestableObserver<CameraUpdate>!

    var shouldAllowRecenteringRecorder: TestableObserver<Bool>!

    override func setUp() {
        super.setUp()
        viewModelUnderTest = DefaultMapViewModel()
        cameraUpdateRecorder = scheduler.record(viewModelUnderTest.cameraUpdatesToPerform)
        shouldAllowRecenteringRecorder = scheduler.record(viewModelUnderTest.shouldAllowRecentering)
    }

    func testCameraUpdatesWhileMapIsCenteredAreForwarded() {
        scheduler.scheduleAt(0, action: { self.viewModelUnderTest.recenterMap() })
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })
        scheduler.scheduleAt(2, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })

        scheduler.start()

        XCTAssertEqual(cameraUpdateRecorder.events, [
            next(1, DefaultMapViewModelTest.goodCameraUpdate),
            next(2, DefaultMapViewModelTest.goodCameraUpdate),
        ])
    }

    func testCameraUpdatesWhileMapIsNotCenteredAreNotForwarded() {
        scheduler.scheduleAt(0, action: { self.viewModelUnderTest.recenterMap() })
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.mapWasDragged() })
        scheduler.scheduleAt(3, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })
        scheduler.scheduleAt(4, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })

        scheduler.start()

        XCTAssertEqual(cameraUpdateRecorder.events, [
            next(1, DefaultMapViewModelTest.goodCameraUpdate),
        ])
    }

    func testForcedCameraUpdatesWhileMapIsNotCenteredAreForwarded() {
        scheduler.scheduleAt(0, action: { self.viewModelUnderTest.recenterMap() })
        scheduler.scheduleAt(1, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })
        scheduler.scheduleAt(2, action: { self.viewModelUnderTest.mapWasDragged() })
        scheduler.scheduleAt(3, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: false)
        })
        scheduler.scheduleAt(4, action: {
            self.viewModelUnderTest.requestCameraUpdate(DefaultMapViewModelTest.goodCameraUpdate, forced: true)
        })

        scheduler.start()

        XCTAssertEqual(cameraUpdateRecorder.events, [
            next(1, DefaultMapViewModelTest.goodCameraUpdate),
            next(4, DefaultMapViewModelTest.goodCameraUpdate),
        ])
    }

    func testDraggingAndRecenteringTheMapTriggersTheCorrectShouldAllowRecenteringEvents() {
        scheduler.scheduleAt(0) { self.viewModelUnderTest.recenterMap() }
        scheduler.scheduleAt(1) { self.viewModelUnderTest.mapWasDragged() }
        scheduler.scheduleAt(2) { self.viewModelUnderTest.recenterMap() }

        scheduler.start()

        XCTAssertEqual(shouldAllowRecenteringRecorder.events, [
            next(0, false),
            next(1, true),
            next(2, false),
        ])
    }
}
