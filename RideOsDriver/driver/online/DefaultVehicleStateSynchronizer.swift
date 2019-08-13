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
import RideOsCommon
import RxSwift

public class DefaultVehicleStateSynchronizer: VehicleStateSynchronizer {
    private typealias LegDefinitionRoutePair = (
        Single<RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition>,
        Single<Route>
    )

    private let driverVehicleInteractor: DriverVehicleInteractor
    private let routeInteractor: RouteInteractor

    public init(driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor(),
                routeInteractor: RouteInteractor = RideOsRouteInteractor()) {
        self.driverVehicleInteractor = driverVehicleInteractor
        self.routeInteractor = routeInteractor
    }

    public func synchronizeVehicleState(vehicleId: String,
                                        vehicleCoordinate: CLLocationCoordinate2D,
                                        vehicleHeading: CLLocationDirection) -> Completable {
        return driverVehicleInteractor.getVehicleState(vehicleId: vehicleId)
            .flatMapCompletable { vehicleState in
                Completable.merge(self.driverVehicleInteractor.updateVehiclePose(vehicleId: vehicleId,
                                                                                 vehicleCoordinate: vehicleCoordinate,
                                                                                 vehicleHeading: vehicleHeading),
                                  self.updateVehicleRouteLegs(vehicleId: vehicleId,
                                                              vehicleCoordinate: vehicleCoordinate,
                                                              vehicleState: vehicleState))
            }
    }

    private func updateVehicleRouteLegs(vehicleId: String,
                                        vehicleCoordinate: CLLocationCoordinate2D,
                                        vehicleState: RideHailCommonsVehicleState) -> Completable {
        do {
            let legDefinitionsToUpdate = try legDefinitions(from: vehicleState, using: vehicleCoordinate)

            return Single.zip(legDefinitionsToUpdate).flatMapCompletable {
                self.driverVehicleInteractor.updateVehicleRouteLegs(vehicleId: vehicleId, legs: $0)
            }
        } catch {
            return Completable.error(error)
        }
    }

    private func legDefinitions(
        from vehicleState: RideHailCommonsVehicleState,
        using vehicleCoordinate: CLLocationCoordinate2D
    ) throws -> [Single<RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition>] {
        guard let vehiclePlanSteps = vehicleState.plan.stepArray as? [RideHailCommonsVehicleState_Step] else {
            throw DriverPlanInteractorError.invalidResponse
        }

        var legDefintionsAndRoutesToSet = [LegDefinitionRoutePair]()

        for index in 0 ..< vehiclePlanSteps.count {
            var previousStep: RideHailCommonsVehicleState_Step?
            if index > 0 {
                previousStep = vehiclePlanSteps[index - 1]
            }

            let currentStep = vehiclePlanSteps[index]

            if case .driveToLocation = currentStep.vehicleActionOneOfCase {
                let previousStepCoordinate: CLLocationCoordinate2D
                let fromStepId: String
                let fromTripId: String

                if let previousStep = previousStep {
                    previousStepCoordinate = previousStep.position.coordinate()
                    fromStepId = previousStep.id_p
                    fromTripId = previousStep.tripId
                } else {
                    previousStepCoordinate = vehicleCoordinate
                    fromStepId = ""
                    fromTripId = ""
                }

                let route = routeInteractor.getRoute(origin: previousStepCoordinate,
                                                     destination: currentStep.position.coordinate())

                let routeLegDefinition = RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition()
                routeLegDefinition.fromStepId = fromStepId
                routeLegDefinition.fromTripId = fromTripId
                routeLegDefinition.toStepId = currentStep.id_p
                routeLegDefinition.toTripId = currentStep.tripId

                legDefintionsAndRoutesToSet.append((Single.just(routeLegDefinition), route.asSingle()))
            }
        }

        return DefaultVehicleStateSynchronizer.setRouteLegs(for: legDefintionsAndRoutesToSet)
    }

    private static func setRouteLegs(for legRoutePairs: [LegDefinitionRoutePair]) ->
        [Single<RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition>] {
        return legRoutePairs.map { legAndRouteSingle ->
            Single<RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition> in

            Single.zip(legAndRouteSingle.0, legAndRouteSingle.1)
                .map { legDefintionAndRoute -> RideHailDriverUpdateVehicleStateRequest_SetRouteLegs_LegDefinition in
                    let legDefinition = legDefintionAndRoute.0
                    let route = legDefintionAndRoute.1

                    let routeLeg = RideHailCommonsVehicleState_Step_RouteLeg()
                    routeLeg.distanceInMeters = route.travelDistanceMeters
                    routeLeg.travelTimeInSeconds = route.travelTime
                    routeLeg.polyline = route.polyline

                    legDefinition.routeLeg = routeLeg

                    return legDefinition
                }
        }
    }
}
