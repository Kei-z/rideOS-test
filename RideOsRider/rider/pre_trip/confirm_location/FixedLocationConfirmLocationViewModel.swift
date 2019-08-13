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

public class FixedLocationConfirmLocationViewModel: ConfirmLocationViewModel {
    private static let unknownLocationDisplayName =
        RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-location.unknown-fixed-location-name")
    private static let initialZoom: Float = 16.0
    private static let geocodeInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)
    private static let stopInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)

    private let disposeBag = DisposeBag()
    private let mapCenterSubject = ReplaySubject<CLLocationCoordinate2D>.create(bufferSize: 1)
    private let reverseGeocodingStatusSubject = ReplaySubject<ReverseGeocodingStatus>.create(bufferSize: 1)

    private let initialLocation: Single<CLLocationCoordinate2D>
    private let desiredAndAssignedLocationObservable: Observable<DesiredAndAssignedLocation>
    private let stopMarker: DrawableMarkerIcon
    private weak var listener: ConfirmLocationListener?
    private let logger: Logger

    public init(initialLocation: Single<CLLocationCoordinate2D>,
                geocodeInteractor: GeocodeInteractor = RiderDependencyRegistry.instance.mapsDependencyFactory.geocodeInteractor,
                stopInteractor: StopInteractor = DefaultStopInteractor(),
                stopMarker: DrawableMarkerIcon,
                listener: ConfirmLocationListener,
                resolvedFleet: ResolvedFleet = ResolvedFleet.instance,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.initialLocation = initialLocation
        desiredAndAssignedLocationObservable = Observable
            .combineLatest(mapCenterSubject, resolvedFleet.resolvedFleet)
            .do(onNext: { [reverseGeocodingStatusSubject] _ in
                reverseGeocodingStatusSubject.onNext(.inProgress)
            })
            .flatMapLatest {
                FixedLocationConfirmLocationViewModel.updateDesiredAndAssignedLocation(
                    mapCenter: $0,
                    fleetId: $1.fleetId,
                    geocodeInteractor: geocodeInteractor,
                    stopInteractor: stopInteractor,
                    logger: logger
                )
            }
            .do(
                onNext: { [reverseGeocodingStatusSubject] _ in
                    reverseGeocodingStatusSubject.onNext(.notInProgress)
                },
                onError: { [reverseGeocodingStatusSubject] _ in
                    reverseGeocodingStatusSubject.onNext(.error)
                }
            )
            .share(replay: 1)
        self.stopMarker = stopMarker
        self.listener = listener
        self.logger = logger

        initialLocation
            .subscribe(onSuccess: {
                self.mapCenterSubject.onNext($0)
            })
            .disposed(by: disposeBag)
    }

    private static func updateDesiredAndAssignedLocation(
        mapCenter: CLLocationCoordinate2D,
        fleetId: String,
        geocodeInteractor: GeocodeInteractor,
        stopInteractor: StopInteractor,
        logger: Logger
    ) -> Observable<DesiredAndAssignedLocation> {
        return Observable
            .zip(
                FixedLocationConfirmLocationViewModel.reverseGeocode(tripLocation: TripLocation(location: mapCenter),
                                                                     geocodeInteractor: geocodeInteractor,
                                                                     logger: logger),
                stopInteractor
                    .getStop(nearLocation: mapCenter, forFleet: fleetId)
                    .logErrors(logger: logger)
                    .retry(FixedLocationConfirmLocationViewModel.stopInteractorRepeatBehavior)
                    .flatMapLatest {
                        FixedLocationConfirmLocationViewModel.reverseGeocode(
                            tripLocation: TripLocation(location: $0.location, locationId: $0.locationId),
                            geocodeInteractor: geocodeInteractor,
                            logger: logger
                        )
                    }
            )
            .map { DesiredAndAssignedLocation(desiredLocation: $0, assignedLocation: $1) }
    }

    private static func reverseGeocode(tripLocation: TripLocation,
                                       geocodeInteractor: GeocodeInteractor,
                                       logger: Logger) -> Observable<NamedTripLocation> {
        return geocodeInteractor
            .reverseGeocode(location: tripLocation.location, maxResults: 1)
            .logErrors(logger: logger)
            .retry(FixedLocationConfirmLocationViewModel.geocodeInteractorRepeatBehavior)
            .map {
                if let first = $0.first {
                    return first.displayName
                } else {
                    return FixedLocationConfirmLocationViewModel.unknownLocationDisplayName
                }
            }
            .map { NamedTripLocation(tripLocation: tripLocation, displayName: $0) }
            .catchErrorJustReturn(
                NamedTripLocation(
                    tripLocation: tripLocation,
                    displayName: FixedLocationConfirmLocationViewModel.unknownLocationDisplayName
                )
            )
    }

    public func confirmLocation() {
        desiredAndAssignedLocationObservable
            .take(1)
            .asSingle()
            .subscribe(onSuccess: { [listener] desiredAndAssignedLocation in
                listener?.confirmLocation(desiredAndAssignedLocation)
            })
            .disposed(by: disposeBag)
    }

    public func cancel() {
        listener?.cancelConfirmLocation()
    }

    public func onCameraMoved(location: CLLocationCoordinate2D) {
        mapCenterSubject.onNext(location)
    }

    public var selectedLocationDisplayName: Observable<String> {
        return desiredAndAssignedLocationObservable.map {
            if let assignedLocation = $0.assignedLocation {
                return assignedLocation.displayName
            } else {
                return ""
            }
        }
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return initialLocation.asObservable().map {
            CameraUpdate.centerAndZoom(center: $0, zoom: FixedLocationConfirmLocationViewModel.initialZoom)
        }
    }

    public func getPaths() -> Observable<[DrawablePath]> {
        return desiredAndAssignedLocationObservable
            .map {
                if let assignedLocation = $0.assignedLocation {
                    return [DrawablePath.walkingRouteLine(coordinates: [$0.desiredLocation.tripLocation.location,
                                                                        assignedLocation.tripLocation.location])]
                } else {
                    return []
                }
            }
    }

    public func getMarkers() -> Observable<[String: DrawableMarker]> {
        return desiredAndAssignedLocationObservable
            .map { [stopMarker] desiredAndAssignedLocation in
                if let assignedLocation = desiredAndAssignedLocation.assignedLocation {
                    return ["stop": DrawableMarker(coordinate: assignedLocation.tripLocation.location,
                                                   icon: stopMarker)]
                } else {
                    return [:]
                }
            }
    }

    public var reverseGeocodingStatus: Observable<ReverseGeocodingStatus> {
        return reverseGeocodingStatusSubject
    }
}
