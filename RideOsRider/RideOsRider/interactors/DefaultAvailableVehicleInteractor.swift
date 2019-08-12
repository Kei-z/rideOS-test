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

import Foundation
import RideOsApi
import RxSwift

public class DefaultAvailableVehicleInteractor: AvailableVehicleInteractor {
    private static let maxVehicles: Int32 = INT32_MAX

    private let rideHailOperationsService: RideHailOperationsRideHailOperationsService
    public init(rideHailOperationsService: RideHailOperationsRideHailOperationsService = RideHailOperationsRideHailOperationsService.serviceWithApiHost()) {
        self.rideHailOperationsService = rideHailOperationsService
    }

    public func getAvailableVehicles(inFleet fleetId: String) -> Observable<[AvailableVehicle]> {
        return Observable.create { observer in
            let request = RideHailOperationsGetVehiclesRequest()
            request.fleetId = fleetId

            let call = self.rideHailOperationsService.rpcToGetVehicles(with: request) { response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let response = response else {
                    observer.onError(AvailableVehicleInteractorError.invalidResponse)
                    return
                }

                guard let vehicles = response.vehicleArray as NSArray as? [RideHailCommonsVehicle] else {
                    observer.onError(AvailableVehicleInteractorError.invalidResponse)
                    return
                }

                observer.onNext(
                    vehicles
                        .filter { $0.state.readiness }
                        .map {
                            AvailableVehicle(vehicleId: $0.id_p,
                                             displayName: DefaultAvailableVehicleInteractor.displayName(for: $0))
                        }
                )
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }

    private static func displayName(for vehicle: RideHailCommonsVehicle) -> String {
        if vehicle.info.licensePlate.isEmpty {
            return vehicle.id_p
        }
        return vehicle.info.licensePlate
    }
}
