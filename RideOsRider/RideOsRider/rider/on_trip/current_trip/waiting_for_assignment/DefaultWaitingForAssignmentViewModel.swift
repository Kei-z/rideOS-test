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

public class DefaultWaitingForAssignmentViewModel {
    private let pickupDropoffSubject = ReplaySubject<GeocodedPickupDropoff>.create(bufferSize: 1)

    private let routeObservable: Observable<Route>
    private let logger: Logger

    public init(initialPassengerState: RiderTripStateModel,
                routeInteractor: RouteInteractor = RiderDependencyRegistry.instance.riderDependencyFactory.routeInteractor,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.logger = logger
        routeObservable = pickupDropoffSubject
            .flatMapLatest { pickupDropoff in
                routeInteractor
                    .getRoute(origin: pickupDropoff.pickup.location,
                              destination: pickupDropoff.dropoff.location)
                    .logErrorsRetryAndDefault(to: Route(coordinates: [], travelTime: 0, travelDistanceMeters: 0),
                                              logger: logger)
            }
        updatePassengerState(initialPassengerState)
    }
}

extension DefaultWaitingForAssignmentViewModel: WaitingForAssignmentViewModel {
    public var pickupDropoff: Observable<GeocodedPickupDropoff> {
        return pickupDropoffSubject
    }
}

// MARK: PassengerStateObserver

extension DefaultWaitingForAssignmentViewModel: PassengerStateObserver {
    public func updatePassengerState(_ state: RiderTripStateModel) {
        guard case let RiderTripStateModel.waitingForAssignment(pickup, dropoff) = state else {
            return
        }
        pickupDropoffSubject.onNext(GeocodedPickupDropoff(pickup: pickup, dropoff: dropoff))
    }
}

// MARK: MapStateProvider

extension DefaultWaitingForAssignmentViewModel: MapStateProvider {
    public func getPaths() -> Observable<[DrawablePath]> {
        return routeObservable.map { [DrawablePath.drivingRouteLine(coordinates: $0.coordinates)] }
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return routeObservable.map { CameraUpdate.fitLatLngBounds(LatLngBounds(containingCoordinates: $0.coordinates)) }
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return pickupDropoffSubject.map { pickupDropoff in
            Dictionary(uniqueKeysWithValues: [
                CurrentTripMarkers.markerFor(pickupLocation: pickupDropoff.pickup.location),
                CurrentTripMarkers.markerFor(dropoffLocation: pickupDropoff.dropoff.location),
            ])
        }
    }
}
