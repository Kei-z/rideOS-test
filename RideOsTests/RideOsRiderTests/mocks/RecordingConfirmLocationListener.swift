import RideOsCommon
import RideOsTestHelpers
import RideOsRider

class RecordingConfirmLocationListener: MethodCallRecorder, ConfirmLocationListener {
    var confirmedLocation: DesiredAndAssignedLocation?

    func confirmLocation(_ location: DesiredAndAssignedLocation) {
        confirmedLocation = location
        recordMethodCall(#function)
    }

    func cancelConfirmLocation() {
        recordMethodCall(#function)
    }
}
