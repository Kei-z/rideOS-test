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

public class DefaultDrivePendingViewModel: DrivePendingViewModel {
    public typealias RouteDetailTextProvider = (CLLocationDistance, TimeInterval) -> String

    public struct Style {
        public static let defaultRouteDetailTextProvider: RouteDetailTextProvider = {
            NSAttributedString.milesAndMinutesLabelWith(meters: $0, timeInterval: $1).string
        }

        public let routeDetailTextProvider: RouteDetailTextProvider
        public let drawablePathWidth: Float
        public let drawablePathColor: UIColor
        public let destinationIcon: DrawableMarkerIcon
        public let vehicleIcon: DrawableMarkerIcon

        public init(routeDetailTextProvider: @escaping RouteDetailTextProvider = Style.defaultRouteDetailTextProvider,
                    drawablePathWidth: Float = 4.0,
                    drawablePathColor: UIColor = .gray,
                    destinationIcon: DrawableMarkerIcon = DrawableMarkerIcons.dropoffPin(),
                    vehicleIcon: DrawableMarkerIcon = DrawableMarkerIcons.car()) {
            self.routeDetailTextProvider = routeDetailTextProvider
            self.drawablePathWidth = drawablePathWidth
            self.drawablePathColor = drawablePathColor
            self.destinationIcon = destinationIcon
            self.vehicleIcon = vehicleIcon
        }
    }

    private let disposeBag = DisposeBag()

    private let destination: CLLocationCoordinate2D
    private let style: Style
    private let deviceLocator: DeviceLocator
    private let routeInteractor: RouteInteractor
    private let schedulerProvider: SchedulerProvider

    public init(destination: CLLocationCoordinate2D,
                style: Style = Style(),
                deviceLocator: DeviceLocator = PotentiallySimulatedDeviceLocator(),
                routeInteractor: RouteInteractor = RideOsRouteInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.destination = destination
        self.style = style
        self.deviceLocator = deviceLocator
        self.routeInteractor = routeInteractor
        self.schedulerProvider = schedulerProvider
    }

    public var routeDetailText: Observable<String> {
        return routeFromCurrentLocationToDestination()
            .observeOn(schedulerProvider.computation())
            .map { [unowned self] in self.detailTextForRouteInfo($0) }
    }

    private func detailTextForRouteInfo(_ routeInfo: RouteInfoModel) -> String {
        return style.routeDetailTextProvider(routeInfo.travelDistanceInMeters, routeInfo.travelTimeInSeconds)
    }

    private func routeFromCurrentLocationToDestination() -> Observable<RouteInfoModel> {
        return deviceLocator
            .observeCurrentLocation()
            .observeOn(schedulerProvider.io())
            .take(1)
            .flatMap { [routeInteractor, destination] in
                routeInteractor.getRoute(origin: $0.coordinate, destination: destination)
            }
            .observeOn(schedulerProvider.computation())
            .map {
                RouteInfoModel(route: $0.coordinates,
                               travelTimeInSeconds: $0.travelTime,
                               travelDistanceInMeters: $0.travelDistanceMeters)
            }
            .share(replay: 1)
    }
}

// MARK: MapStateProvider

extension DefaultDrivePendingViewModel: MapStateProvider {
    public func getMapSettings() -> Observable<MapSettings> {
        return Observable.just(MapSettings(shouldShowUserLocation: false))
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return routeFromCurrentLocationToDestination().map {
            CameraUpdate.fitLatLngBounds(LatLngBounds(containingCoordinates: $0.route))
        }
    }

    public func getPaths() -> Observable<[DrawablePath]> {
        return routeFromCurrentLocationToDestination().map { [style] in
            [DrawablePath(coordinates: $0.route, width: style.drawablePathWidth, color: style.drawablePathColor)]
        }
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return Observable.combineLatest(deviceLocator.observeCurrentLocation(), routeFromCurrentLocationToDestination())
            .map { [style] currentLocation, routeInfo in
                guard let destination = routeInfo.route.last else {
                    logError("Route to pending drive destintation has no coordinate.")
                    return [String: DrawableMarker]()
                }

                return [
                    "vehicle": DrawableMarker(coordinate: currentLocation.coordinate,
                                              heading: currentLocation.course,
                                              icon: style.vehicleIcon),
                    "destination": DrawableMarker(coordinate: destination, icon: style.destinationIcon),
                ]
            }
    }
}
