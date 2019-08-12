import Foundation
import RideOsTestHelpers
import RideOsRider

class RecordingConfirmTripListener: MethodCallRecorder, ConfirmTripListener {
    var selectedVehicle: VehicleSelectionOption?

    func confirmTrip(selectedVehicle: VehicleSelectionOption) {
        self.selectedVehicle = selectedVehicle
        recordMethodCall(#function)
    }

    func cancelConfirmTrip() {
        recordMethodCall(#function)
    }
}
