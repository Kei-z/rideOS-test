import CoreLocation
import Foundation
import RideOsCommon
import RideOsTestHelpers
import RideOsRider
import RxSwift

public class FixedTripInteractor: MethodCallRecorder, TripInteractor {
    private let createTripObservable: Observable<String>
    private let cancelTripCompletable: Completable
    private let currentTripSequence: [String?]
    private let editPickupResponse: Observable<String>
    private var currentTripIndex = 0

    public init(createTripObservable: Observable<String> = Observable.empty(),
                cancelTripCompletable: Completable = Completable.never(),
                currentTripSequence: [String?] = [nil],
                editPickupResponse: Observable<String> = Observable.empty()) {
        self.createTripObservable = createTripObservable
        self.cancelTripCompletable = cancelTripCompletable
        self.currentTripSequence = currentTripSequence
        self.editPickupResponse = editPickupResponse
    }
    
    public func createTripForPassenger(passengerId: String,
                                       contactInfo: ContactInfo,
                                       fleetId: String,
                                       numPassengers: UInt32,
                                       pickupLocation: TripLocation,
                                       dropoffLocation: TripLocation,
                                       vehicleId: String?) -> Observable<String> {
        recordMethodCall(#function)
        return createTripObservable
    }
    
    public func cancelTrip(passengerId: String, tripId: String) -> Completable {
        recordMethodCall(#function)
        return cancelTripCompletable
    }
    
    public func getCurrentTrip(forPassenger passengerId: String) -> Observable<String?> {
        recordMethodCall(#function)
        let currentTrip = currentTripSequence[min(currentTripIndex, currentTripSequence.count - 1)]
        currentTripIndex += 1
        return Observable.just(currentTrip)
    }

    public func editPickup(tripId: String, newPickupLocation: TripLocation) -> Observable<String> {
        recordMethodCall(#function)
        return editPickupResponse
    }
}
