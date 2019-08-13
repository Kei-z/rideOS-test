// Copyright 2019 rideOS, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import CoreLocation
import Foundation
import RideOsCommon
import RxSwift

public protocol TripInteractor {
    func createTripForPassenger(passengerId: String,
                                contactInfo: ContactInfo,
                                fleetId: String,
                                numPassengers: UInt32,
                                pickupLocation: TripLocation,
                                dropoffLocation: TripLocation,
                                vehicleId: String?) -> Observable<String>
    func cancelTrip(passengerId: String, tripId: String) -> Completable
    func getCurrentTrip(forPassenger passengerId: String) -> Observable<String?>
    func editPickup(tripId: String, newPickupLocation: TripLocation) -> Observable<String>
}

public enum TripInteractorError: Error {
    case invalidResponse
}
