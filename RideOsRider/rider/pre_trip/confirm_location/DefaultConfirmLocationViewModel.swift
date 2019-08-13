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

public class DefaultConfirmLocationViewModel: ConfirmLocationViewModel {
    private static let initialZoom: Float = 16.0
    private static let geocodeInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)

    private let disposeBag = DisposeBag()
    private let mapCenterSubject = ReplaySubject<CLLocationCoordinate2D>.create(bufferSize: 1)
    private let reverseGeocodingStatusSubject = ReplaySubject<ReverseGeocodingStatus>.create(bufferSize: 1)

    private let initialLocation: Single<CLLocationCoordinate2D>
    private let reverseGeocodedLocationObservable: Observable<GeocodedLocationModel>
    private weak var listener: ConfirmLocationListener?

    public init(initialLocation: Single<CLLocationCoordinate2D>,
                geocodeInteractor: GeocodeInteractor = RiderDependencyRegistry.instance.mapsDependencyFactory.geocodeInteractor,
                listener: ConfirmLocationListener,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.initialLocation = initialLocation
        reverseGeocodedLocationObservable = mapCenterSubject
            .do(onNext: { [reverseGeocodingStatusSubject] _ in
                reverseGeocodingStatusSubject.onNext(.inProgress)
            })
            .flatMapLatest { location in
                geocodeInteractor
                    .reverseGeocode(location: location, maxResults: 1)
                    .logErrors(logger: logger)
                    .retry(DefaultConfirmLocationViewModel.geocodeInteractorRepeatBehavior)
            }
            .map { locationsArray in locationsArray.first! }
            .do(
                onNext: { [reverseGeocodingStatusSubject] _ in
                    reverseGeocodingStatusSubject.onNext(.notInProgress)
                },
                onError: { [reverseGeocodingStatusSubject] _ in
                    reverseGeocodingStatusSubject.onNext(.error)
                }
            )
            .share(replay: 1)
        self.listener = listener

        initialLocation
            .subscribe(onSuccess: {
                self.mapCenterSubject.onNext($0)
            })
            .disposed(by: disposeBag)
    }

    public func confirmLocation() {
        reverseGeocodedLocationObservable
            .take(1)
            .asSingle()
            .subscribe(onSuccess: { [listener] geocodedLocationModel in
                listener?.confirmLocation(
                    DesiredAndAssignedLocation(
                        desiredLocation: NamedTripLocation(geocodedLocation: geocodedLocationModel)
                    )
                )
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
        return reverseGeocodedLocationObservable.map { $0.displayName }
    }

    public func getCameraUpdates() -> Observable<CameraUpdate> {
        return initialLocation.asObservable().map {
            CameraUpdate.centerAndZoom(center: $0, zoom: DefaultConfirmLocationViewModel.initialZoom)
        }
    }

    public var reverseGeocodingStatus: Observable<ReverseGeocodingStatus> {
        return reverseGeocodingStatusSubject
    }

    public func getMapSettings() -> Observable<MapSettings> {
        return Observable.just(MapSettings(keepCenterWhileZooming: true))
    }
}
