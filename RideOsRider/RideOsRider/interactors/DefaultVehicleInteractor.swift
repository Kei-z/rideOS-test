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
import RideOsApi
import RxSwift

public class DefaultVehicleInteractor: VehicleInteractor {
    private let riderService: RideHailRiderRideHailRiderService

    public init(riderService: RideHailRiderRideHailRiderService = RideHailRiderRideHailRiderService.serviceWithApiHost()) {
        self.riderService = riderService
    }

    public func getVehiclesInVicinity(center: CLLocationCoordinate2D, fleetId: String) -> Observable<[VehiclePosition]> {
        return Observable.create { observer in
            let request = RideHailRiderGetVehiclesInVicinityRequest()
            request.queryPosition = Position(coordinate: center)
            request.fleetId = fleetId

            let call = self.riderService.rpcToGetVehiclesInVicinity(with: request) { response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let response = response else {
                    observer.onError(VehicleInteractorError.invalidResponse)
                    return
                }

                observer.onNext(
                    response.vehicleArray
                        .compactMap { $0 as? RideHailRiderVicinityVehicle }
                        .map(DefaultVehicleInteractor.toVehiclePosition)
                )
            }
            call.start()
            return Disposables.create { call.cancel() }
        }
    }

    private static func toVehiclePosition(_ vehicle: RideHailRiderVicinityVehicle) -> VehiclePosition {
        return VehiclePosition(vehicleId: vehicle.id_p,
                               position: vehicle.position.coordinate(),
                               heading: vehicle.heading != nil ? CLLocationDirection(vehicle.heading!.value) : 0.0)
    }
}
