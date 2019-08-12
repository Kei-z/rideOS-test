import CoreLocation
import MapboxDirections
import RideOsDriver
import RideOsTestHelpers
import RxSwift

class RecordingMapboxDirectionsInteractor: MethodCallRecorder, MapboxDirectionsInteractor {
    private let directions: MapboxDirections.Route

    init(directions: MapboxDirections.Route) {
        self.directions = directions
    }

    func getDirections(from _: CLLocationCoordinate2D,
                       to _: CLLocationCoordinate2D) -> Single<MapboxDirections.Route> {
        recordMethodCall(#function)
        return Single.just(directions)
    }
}
