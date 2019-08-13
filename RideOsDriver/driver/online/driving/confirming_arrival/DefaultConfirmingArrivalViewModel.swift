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
import RxOptional
import RxSwift
import RxSwiftExt

public class DefaultConfirmingArrivalViewModel: ConfirmingArrivalViewModel {
    private static let geocodeRepeatBehavior = RepeatBehavior.immediate(maxCount: 2)

    public struct Style {
        public let mapZoomLevel: Float
        public let destinationIcon: DrawableMarkerIcon

        public init(mapZoomLevel: Float = 15.0,
                    destinationIcon: DrawableMarkerIcon = DrawableMarkerIcons.dropoffPin()) {
            self.mapZoomLevel = mapZoomLevel
            self.destinationIcon = destinationIcon
        }
    }

    private let destination: CLLocationCoordinate2D
    private let style: Style
    private let geocodeInteractor: GeocodeInteractor
    private let schedulerProvider: SchedulerProvider
    private let logger: Logger

    public init(destination: CLLocationCoordinate2D,
                style: Style = Style(),
                geocodeInteractor: GeocodeInteractor = DriverDependencyRegistry.instance.mapsDependencyFactory.geocodeInteractor,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.destination = destination
        self.style = style
        self.geocodeInteractor = geocodeInteractor
        self.schedulerProvider = schedulerProvider
        self.logger = logger
    }

    public var arrivalDetailText: Observable<String> {
        return reverseGeocodeObservable().map { $0.displayName }
    }

    private func reverseGeocodeObservable() -> Observable<GeocodedLocationModel> {
        return geocodeInteractor.reverseGeocode(location: destination, maxResults: 1)
            .observeOn(schedulerProvider.computation())
            .logErrors(logger: logger)
            .retry(DefaultConfirmingArrivalViewModel.geocodeRepeatBehavior)
            .map { $0.first }
            .filterNil()
            .share(replay: 1)
    }
}

// MARK: MapStateProvider

extension DefaultConfirmingArrivalViewModel: MapStateProvider {
    public func getMapSettings() -> Observable<MapSettings> {
        return Observable.just(MapSettings(shouldShowUserLocation: false))
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return reverseGeocodeObservable().map { [style] in
            CameraUpdate.centerAndZoom(center: $0.location, zoom: style.mapZoomLevel)
        }
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return reverseGeocodeObservable().map { [style] in
            [
                "destination_icon": DrawableMarker(coordinate: $0.location, icon: style.destinationIcon),
            ]
        }
    }
}
