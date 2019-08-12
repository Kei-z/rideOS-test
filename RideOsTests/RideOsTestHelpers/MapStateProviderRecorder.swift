import CoreLocation
import Foundation
import RideOsCommon
import RxSwift
import RxTest

public class MapStateProviderRecorder {
    public let mapSettingsRecorder: TestableObserver<MapSettings>!
    public let cameraUpdateRecorder: TestableObserver<CameraUpdate>!
    public let pathRecorder: TestableObserver<[DrawablePath]>!
    public let markerRecorder: TestableObserver<[String: DrawableMarker]>!

    public init(mapStateProvider: MapStateProvider, scheduler: TestScheduler) {
        mapSettingsRecorder = scheduler.record(mapStateProvider.getMapSettings())
        cameraUpdateRecorder = scheduler.record(mapStateProvider.getCameraUpdates())
        pathRecorder = scheduler.record(mapStateProvider.getPaths())
        markerRecorder = scheduler.record(mapStateProvider.getMarkers())
    }
}
