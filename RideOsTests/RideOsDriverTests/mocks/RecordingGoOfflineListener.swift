import RideOsCommon
import RideOsDriver
import RideOsTestHelpers

class RecordingGoOfflineListener: MethodCallRecorder, GoOfflineListener {
    func goOffline() {
        recordMethodCall(#function)
    }
}
