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
import grpc
import RideOsApi
import RideOsCommon
import RxSwift

public class DefaultTripInteractor: TripInteractor {
    private let riderService: RideHailRiderRideHailRiderService
    private let tripIdProvider: () -> String

    public init(riderService: RideHailRiderRideHailRiderService = RideHailRiderRideHailRiderService.serviceWithApiHost(),
                tripIdProvider: @escaping () -> String = { UUID().uuidString }) {
        self.riderService = riderService
        self.tripIdProvider = tripIdProvider
    }

    public func createTripForPassenger(passengerId: String,
                                       contactInfo: ContactInfo,
                                       fleetId: String,
                                       numPassengers: UInt32,
                                       pickupLocation: TripLocation,
                                       dropoffLocation: TripLocation,
                                       vehicleId: String?) -> Observable<String> {
        let tripId = tripIdProvider()

        let request = RideHailRiderRequestTripRequest()
        request.id_p = tripId
        request.riderId = passengerId
        request.fleetId = fleetId

        request.definition = RideHailCommonsTripDefinition()
        request.definition.pickupDropoff = RideHailCommonsPickupDropoff()
        request.definition.pickupDropoff.riderCount = numPassengers
        request.definition.pickupDropoff.pickup = DefaultTripInteractor.stop(for: pickupLocation)
        request.definition.pickupDropoff.dropoff = DefaultTripInteractor.stop(for: dropoffLocation)

        request.info = RideHailCommonsTripInfo()
        request.info.riderInfo = RideHailCommonsRiderInfo()
        request.info.riderInfo.contactInfo = DefaultTripInteractor.rideHailContactInfo(for: contactInfo)

        if let vehicleId = vehicleId {
            request.dispatchParameters = RideHailRiderDispatchParameters()
            let vehicleFilter = RideHailCommonsVehicleFilter()
            vehicleFilter.vehicleId = vehicleId
            request.dispatchParameters.vehicleFilterArray = [vehicleFilter]
        }

        return Observable.create { observer in
            let call = self.riderService.rpcToRequestTrip(with: request) { response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard response != nil else {
                    observer.onError(TripInteractorError.invalidResponse)
                    return
                }

                observer.onNext(tripId)
                observer.onCompleted()
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }

    public func cancelTrip(passengerId _: String, tripId: String) -> Completable {
        let request = RideHailRiderCancelTripRequest()
        request.id_p = tripId

        return Completable.create { completable in
            let call = self.riderService.rpcToCancelTrip(with: request) { response, error in
                if let error = error {
                    completable(.error(error))
                    return
                }

                guard response != nil else {
                    completable(.error(TripInteractorError.invalidResponse))
                    return
                }

                completable(.completed)
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }

    public func getCurrentTrip(forPassenger passengerId: String) -> Observable<String?> {
        let request = RideHailRiderGetActiveTripIdRequest()
        request.riderId = passengerId

        return Observable.create { observer in
            let call = self.riderService.rpcToGetActiveTripId(with: request) { response, error in
                if let error = error as NSError? {
                    observer.onError(error)
                    return
                }

                guard let response = response else {
                    observer.onError(TripInteractorError.invalidResponse)
                    return
                }

                if response.typeOneOfCase == .activeTrip {
                    observer.onNext(response.activeTrip.id_p)
                } else {
                    observer.onNext(nil)
                }
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }

    public func editPickup(tripId: String, newPickupLocation: TripLocation) -> Observable<String> {
        let newTripId = tripIdProvider()

        let request = RideHailRiderChangeTripDefinitionRequest()
        request.tripId = tripId
        request.replacementTripId = newTripId

        request.changePickup = RideHailRiderChangeTripDefinitionRequest_ChangePickup()
        request.changePickup.newPickup = DefaultTripInteractor.stop(for: newPickupLocation)

        return Observable.create { observer in
            let call = self.riderService.rpcToChangeTripDefinition(with: request) { _, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                observer.onNext(newTripId)
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }

    private static func stop(for tripLocation: TripLocation) -> RideHailCommonsStop {
        let stop = RideHailCommonsStop()
        if let stopId = tripLocation.locationId {
            stop.predefinedStopId = stopId
        } else {
            stop.position = Position(coordinate: tripLocation.location)
        }
        return stop
    }

    private static func rideHailContactInfo(for contactInfo: ContactInfo) -> RideHailCommonsContactInfo {
        let rideHailContactInfo = RideHailCommonsContactInfo()
        if let name = contactInfo.name {
            rideHailContactInfo.name = name
        }
        if let contactUrl = contactInfo.url {
            rideHailContactInfo.contactURL = contactUrl.absoluteString
        }
        return rideHailContactInfo
    }
}
