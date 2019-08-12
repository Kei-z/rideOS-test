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

public class DefaultConfirmTripViewModel: ConfirmTripViewModel {
    private static let routeInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)

    private let fetchingRouteStatusSubject = ReplaySubject<FetchingRouteStatus>.create(bufferSize: 1)

    let pickupLocation: CLLocationCoordinate2D
    private let dropoffLocation: CLLocationCoordinate2D
    private let pickupIcon: DrawableMarkerIcon
    private let dropoffIcon: DrawableMarkerIcon
    let listener: ConfirmTripListener
    private let routeInteractor: RouteInteractor
    private let routeObservable: Observable<Route>
    private let routeDisplayStringFormatter: (Route) -> NSAttributedString

    public init(pickupLocation: CLLocationCoordinate2D,
                dropoffLocation: CLLocationCoordinate2D,
                pickupIcon: DrawableMarkerIcon,
                dropoffIcon: DrawableMarkerIcon,
                listener: ConfirmTripListener,
                routeInteractor: RouteInteractor = RiderDependencyRegistry.instance.riderDependencyFactory.routeInteractor,
                routeDisplayStringFormatter: @escaping (Route) -> NSAttributedString,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        fetchingRouteStatusSubject.onNext(.inProgress)
        self.pickupLocation = pickupLocation
        self.dropoffLocation = dropoffLocation
        self.pickupIcon = pickupIcon
        self.dropoffIcon = dropoffIcon
        self.listener = listener
        self.routeInteractor = routeInteractor
        routeObservable = routeInteractor
            .getRoute(origin: pickupLocation, destination: dropoffLocation)
            .logErrors(logger: logger)
            .retry(DefaultConfirmTripViewModel.routeInteractorRepeatBehavior)
            .do(
                onNext: { [fetchingRouteStatusSubject] _ in
                    fetchingRouteStatusSubject.onNext(.done)
                },
                onError: { [fetchingRouteStatusSubject] _ in
                    fetchingRouteStatusSubject.onNext(.error)
                }
            )
            .share(replay: 1)

        self.routeDisplayStringFormatter = routeDisplayStringFormatter
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return routeObservable.map { route in
            CameraUpdate.fitLatLngBounds(LatLngBounds(containingCoordinates: route.coordinates))
        }
    }

    public func getMapSettings() -> Observable<MapSettings> {
        return Observable.just(MapSettings(shouldShowUserLocation: false))
    }

    public func getPaths() -> Observable<[DrawablePath]> {
        return routeObservable.map { route in
            [DrawablePath.previewDrivingRouteLine(coordinates: route.coordinates)]
        }
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return Observable.just([
            "pickup": DrawableMarker(coordinate: pickupLocation, icon: pickupIcon),
            "dropoff": DrawableMarker(coordinate: dropoffLocation, icon: dropoffIcon),
        ])
    }

    public func getRouteInformation() -> Observable<NSAttributedString> {
        return routeObservable.map { self.routeDisplayStringFormatter($0) }
    }

    public func confirmTrip(selectedVehicle: VehicleSelectionOption) {
        listener.confirmTrip(selectedVehicle: selectedVehicle)
    }

    public func cancel() {
        listener.cancelConfirmTrip()
    }

    public var fetchingRouteStatus: Observable<FetchingRouteStatus> {
        return fetchingRouteStatusSubject
    }

    public var enableManualVehicleSelection: Bool { return false }

    public var vehicleSelectionOptions: Observable<[VehicleSelectionOption]> {
        fatalError("DefaultConfirmTripViewModel does not support manual vehicle selection")
    }
}
