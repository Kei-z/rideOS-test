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
import Polyline
import RideOsApi
import RideOsCommon
import RxSwift

public class DefaultDriverPlanInteractor: DriverPlanInteractor {
    private let driverVehicleInteractor: DriverVehicleInteractor

    public init(driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor()) {
        self.driverVehicleInteractor = driverVehicleInteractor
    }

    public func getPlanForVehicle(vehicleId: String) -> Observable<VehiclePlan> {
        return driverVehicleInteractor.getVehicleState(vehicleId: vehicleId)
            .map { try DefaultDriverPlanInteractor.vehiclePlan(from: $0) }
            .asObservable()
    }

    private static func vehiclePlan(from vehicleState: RideHailCommonsVehicleState) throws -> VehiclePlan {
        guard let steps = vehicleState.plan.stepArray as? [RideHailCommonsVehicleState_Step] else {
            throw DriverPlanInteractorError.invalidResponse
        }

        var waypoints = [VehiclePlan.Waypoint]()

        var index = 0
        while index < steps.count {
            let step = steps[index]

            switch step.vehicleActionOneOfCase {
            case .driveToLocation:
                guard index + 1 < steps.count else {
                    logError("Received drive to location step without pickup or drop-off step after. Plan: \(steps)")
                    throw DriverPlanInteractorError.invalidResponse
                }

                let nextStep = steps[index + 1]

                guard step.tripId == nextStep.tripId else {
                    logError("Step after drive to location step does not have same trip id. Plan: \(steps)")
                    throw DriverPlanInteractorError.invalidResponse
                }

                if nextStep.vehicleActionOneOfCase == .pickupRider {
                    guard let pickupRiderStep = nextStep.pickupRider else {
                        logError("Expected pickupRider to be non-nil for step: \(nextStep)")
                        throw DriverPlanInteractorError.invalidResponse
                    }

                    waypoints.append(DefaultDriverPlanInteractor.waypoint(from: step,
                                                                          actionType: .driveToPickup,
                                                                          passengerCount: pickupRiderStep.riderCount))
                } else {
                    guard let dropoffRiderStep = nextStep.dropoffRider else {
                        logError("Expected dropoffRider to be non-nil for step: \(nextStep)")
                        throw DriverPlanInteractorError.invalidResponse
                    }

                    waypoints.append(DefaultDriverPlanInteractor.waypoint(from: step,
                                                                          actionType: .driveToDropoff,
                                                                          passengerCount: dropoffRiderStep.riderCount,
                                                                          additionalStepIds: [nextStep.id_p]))
                    // Skip over the drop-off step, since it has been accounted for as part of processing
                    // the drive to location step. This differs from how we handle the pickup step because, currently,
                    // we represent the action of picking up a rider (VehiclePlayAction.ActionType.loadResource), but
                    // do not have a corresponding representation for the action of dropping off a rider
                    // (e.g., something like VehiclePlayAction.ActionType.unloadResource). This representation could
                    // change in the future.
                    index += 1
                }
            case .pickupRider:
                guard let pickupRiderStep = step.pickupRider else {
                    logError("Expected pickupRider to be non-nil for step: \(step)")
                    throw DriverPlanInteractorError.invalidResponse
                }

                waypoints.append(DefaultDriverPlanInteractor.waypoint(from: step,
                                                                      actionType: .loadResource,
                                                                      passengerCount: pickupRiderStep.riderCount))
            case .dropoffRider:
                guard let dropoffRiderStep = step.dropoffRider else {
                    logError("Expected dropoffRider to be non-nil for step: \(step)")
                    throw DriverPlanInteractorError.invalidResponse
                }

                // In the event we receive a drop-off rider without a drive-to-location before it, treat it
                // as a drive to drop-off.
                waypoints.append(DefaultDriverPlanInteractor.waypoint(from: step,
                                                                      actionType: .driveToDropoff,
                                                                      passengerCount: dropoffRiderStep.riderCount))
            default:
                logError("Unexpected vehicle action for step: \(step)")
            }

            index += 1
        }

        return VehiclePlan(waypoints: waypoints)
    }

    private static func waypoint(
        from step: RideHailCommonsVehicleState_Step,
        actionType: VehiclePlanAction.ActionType,
        passengerCount: UInt32,
        additionalStepIds: [String] = []
    ) -> VehiclePlan.Waypoint {
        let uniqueStepIds = Set<String>([step.id_p] + additionalStepIds)
        let tripResourceInfo = TripResourceInfo(numberOfPassengers: Int(passengerCount))

        return VehiclePlan.Waypoint(taskId: step.tripId,
                                    stepIds: uniqueStepIds,
                                    action: VehiclePlanAction(destination: step.position.coordinate(),
                                                              actionType: actionType,
                                                              tripResourceInfo: tripResourceInfo))
    }
}
