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

public protocol DriverVehicleInteractor {
    func createVehicle(vehicleId: String, fleetId: String, vehicleInfo: VehicleRegistration) -> Completable
    func markVehicleReady(vehicleId: String) -> Completable
    func markVehicleNotReady(vehicleId: String) -> Completable
    func finishSteps(vehicleId: String, taskId: String, stepIds: [String]) -> Completable
    func getVehicleStatus(vehicleId: String) -> Single<VehicleStatus>
    func getVehicleState(vehicleId: String) -> Single<RideHailCommonsVehicleState>
    func updateVehiclePose(
        vehicleId: String,
        vehicleCoordinate: CLLocationCoordinate2D,
        vehicleHeading: CLLocationDirection
    ) -> Completable
    func updateVehicleRouteLegs(
        vehicleId: String,
        legs: [RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition]
    ) -> Completable
}

public enum DriverVehicleInteractorError: Error {
    case invalidRequest
    case invalidResponse
}
