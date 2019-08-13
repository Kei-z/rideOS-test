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

public class DefaultStartScreenViewModel: StartScreenViewModel {
    private static let vehiclePollInterval: RxTimeInterval = 1.0
    private static let defaultZoomLevel: Float = 15.0

    private let mapCenterSubject: PublishSubject<CLLocationCoordinate2D> = PublishSubject()

    private weak var listener: StartScreenListener?
    private let vehicleInteractor: VehicleInteractor
    private let schedulerProvider: SchedulerProvider
    private let deviceLocator: DeviceLocator
    private let resolvedFleet: ResolvedFleet
    private let logger: Logger

    public init(listener: StartScreenListener,
                vehicleInteractor: VehicleInteractor = DefaultVehicleInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                resolvedFleet: ResolvedFleet = ResolvedFleet.instance,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.listener = listener
        self.vehicleInteractor = vehicleInteractor
        self.schedulerProvider = schedulerProvider
        self.deviceLocator = deviceLocator
        self.resolvedFleet = resolvedFleet
        self.logger = logger
    }

    public func startLocationSearch() {
        listener?.startLocationSearch()
    }
}

// MARK: MapStateProvider

extension DefaultStartScreenViewModel: MapStateProvider {
    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return Observable
            .combineLatest(
                Observable<Int>.interval(DefaultStartScreenViewModel.vehiclePollInterval,
                                         scheduler: schedulerProvider.computation()),
                mapCenterSubject,
                resolvedFleet.resolvedFleet
            )
            .map { _, mapCenter, fleet in (mapCenter, fleet) }
            .flatMapLatest { [vehicleInteractor, logger] mapCenter, fleet in
                vehicleInteractor
                    .getVehiclesInVicinity(center: mapCenter, fleetId: fleet.fleetId)
                    .logErrors(logger: logger)
                    .catchErrorJustComplete()
            }
            .map(DefaultStartScreenViewModel.toDrawableMarkers)
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return deviceLocator.observeCurrentLocation()
            .map { location in
                CameraUpdate.centerAndZoom(center: location.coordinate, zoom: DefaultStartScreenViewModel.defaultZoomLevel)
            }
    }

    private static func toDrawableMarkers(vehiclePositions: [VehiclePosition]) -> [String: DrawableMarker] {
        return Dictionary(uniqueKeysWithValues: vehiclePositions.map {
            ($0.vehicleId, DefaultStartScreenViewModel.toDrawableMarker(vehiclePosition: $0))
        })
    }

    private static func toDrawableMarker(vehiclePosition: VehiclePosition) -> DrawableMarker {
        return DrawableMarker(coordinate: vehiclePosition.position,
                              heading: vehiclePosition.heading,
                              icon: DrawableMarkerIcons.car())
    }
}

// MARK: MapCenterListener

extension DefaultStartScreenViewModel: MapCenterListener {
    public func mapCenterDidMove(to coordinate: CLLocationCoordinate2D) {
        mapCenterSubject.onNext(coordinate)
    }
}
