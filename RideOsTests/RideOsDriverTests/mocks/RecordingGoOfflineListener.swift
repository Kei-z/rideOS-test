import RideOsCommon
import RideOsDriver
import RideOsTestHelpers

class RecordingGoOfflineListener: MethodCallRecorder, GoOfflineListener {
    func didGoOffline() {
        recordMethodCall(#function)
    }
}
