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
import RxSwiftExt

public class VehicleSelectionConfirmTripViewModel: DefaultConfirmTripViewModel {
    private let availableVehicleInteractor: AvailableVehicleInteractor
    private let resolvedFleet: ResolvedFleet
    private let schedulerProvider: SchedulerProvider
    private let logger: Logger

    public init(pickupLocation: CLLocationCoordinate2D,
                dropoffLocation: CLLocationCoordinate2D,
                pickupIcon: DrawableMarkerIcon,
                dropoffIcon: DrawableMarkerIcon,
                listener: ConfirmTripListener,
                routeInteractor: RouteInteractor = RiderDependencyRegistry.instance.riderDependencyFactory.routeInteractor,
                routeDisplayStringFormatter: @escaping (Route) -> NSAttributedString,
                availableVehicleInteractor: AvailableVehicleInteractor = DefaultAvailableVehicleInteractor(),
                resolvedFleet: ResolvedFleet = ResolvedFleet.instance,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.availableVehicleInteractor = availableVehicleInteractor
        self.resolvedFleet = resolvedFleet
        self.schedulerProvider = schedulerProvider
        self.logger = logger

        super.init(pickupLocation: pickupLocation,
                   dropoffLocation: dropoffLocation,
                   pickupIcon: pickupIcon,
                   dropoffIcon: dropoffIcon,
                   listener: listener,
                   routeInteractor: routeInteractor,
                   routeDisplayStringFormatter: routeDisplayStringFormatter,
                   logger: logger)
    }

    public override var enableManualVehicleSelection: Bool { return true }

    public override var vehicleSelectionOptions: Observable<[VehicleSelectionOption]> {
        return resolvedFleet.resolvedFleet
            .observeOn(schedulerProvider.io())
            .flatMapLatest { [availableVehicleInteractor, logger] in
                availableVehicleInteractor
                    .getAvailableVehicles(inFleet: $0.fleetId)
                    .logErrorsRetryAndDefault(to: [], logger: logger)
            }
            .observeOn(schedulerProvider.computation())
            .map { vehicles in
                [VehicleSelectionOption.automatic]
                    + vehicles
                    .sorted { $0.displayName < $1.displayName }
                    .map { VehicleSelectionOption.manual(vehicle: $0) }
            }
    }
}
