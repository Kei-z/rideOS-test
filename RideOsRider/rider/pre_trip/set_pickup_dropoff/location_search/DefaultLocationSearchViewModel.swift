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

public class DefaultLocationSearchViewModel: LocationSearchViewModel {
    private static let locationAutoCompleteInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)

    private let disposeBag = DisposeBag()

    private let locationOptions: BehaviorSubject<[String]> = BehaviorSubject(value: [])

    private let pickupTextSubject: PublishSubject<String> = PublishSubject()
    private let dropoffTextSubject: PublishSubject<String> = PublishSubject()
    private let selectionSubject: PublishSubject<LocationSearchOption> = PublishSubject()

    private let selectedPickup: BehaviorSubject<LocationSearchOption?>
    private let selectedDropoff: BehaviorSubject<LocationSearchOption?>

    // TODO(chrism): this needs to be consistent with text field that the view activates initially
    private let focusSubject: BehaviorSubject<LocationSearchFocusType> = BehaviorSubject(value: .dropoff)

    private let schedulerProvider: SchedulerProvider
    private weak var listener: LocationSearchListener?
    private let locationAutocompleteInteractor: LocationAutocompleteInteractor
    private let deviceLocator: DeviceLocator
    private let historicalSearchInteractor: HistoricalSearchInteractor
    private let doneActionEnabled: Bool
    private let initialPickupString: String
    private let initialDropoffString: String
    private let searchBounds: LatLngBounds
    private let logger: Logger

    public init(schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                listener: LocationSearchListener,
                initialPickup: GeocodedLocationModel?,
                initialDropoff: GeocodedLocationModel?,
                searchBounds: LatLngBounds,
                locationAutocompleteInteractor: LocationAutocompleteInteractor = RiderDependencyRegistry.instance.mapsDependencyFactory.locationAutocompleteInteractor,
                deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                historicalSearchInteractor: HistoricalSearchInteractor = UserStorageHistoricalSearchInteractor(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.schedulerProvider = schedulerProvider
        self.listener = listener
        self.searchBounds = searchBounds
        self.locationAutocompleteInteractor = locationAutocompleteInteractor
        self.deviceLocator = deviceLocator
        self.historicalSearchInteractor = historicalSearchInteractor
        self.logger = logger

        if initialPickup != nil {
            selectedPickup = BehaviorSubject(value: nil)
        } else {
            selectedPickup = BehaviorSubject(value: .currentLocation)
        }
        selectedDropoff = BehaviorSubject(value: nil)
        doneActionEnabled = initialPickup != nil && initialDropoff != nil
        initialPickupString = initialPickup?.displayName ?? ""
        initialDropoffString = initialDropoff?.displayName ?? ""

        selectionSubject
            .map { [focusSubject] selection in try (selection, focusSubject.value()) }
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [listener, selectedPickup, selectedDropoff] selection, focus in
                if focus == .pickup {
                    switch selection {
                    case .selectOnMap:
                        listener.setPickupOnMap()
                    default:
                        selectedPickup.onNext(selection)
                    }
                } else if focus == .dropoff {
                    switch selection {
                    case .selectOnMap:
                        listener.setDropoffOnMap()
                    default:
                        selectedDropoff.onNext(selection)
                    }
                }
            })
            .disposed(by: disposeBag)

        geocodedLocationFromSelectedLocation(selectedPickup)
            .subscribeOn(schedulerProvider.io())
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: self.listener?.selectPickup)
            .disposed(by: disposeBag)

        geocodedLocationFromSelectedLocation(selectedDropoff)
            .subscribeOn(schedulerProvider.io())
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: self.listener?.selectDropoff)
            .disposed(by: disposeBag)

        selectedDropoff
            .subscribeOn(schedulerProvider.io())
            .filterNil()
            .map { (selectedSearchOption: LocationSearchOption) -> LocationAutocompleteResult? in
                switch selectedSearchOption {
                case let .autocompleteLocation(location), let .historical(location):
                    return location
                default:
                    return nil
                }
            }
            .filterNil()
            .flatMap { historicalSearchInteractor.store(searchOption: $0).asObservable() }
            .subscribe()
            .disposed(by: disposeBag)
    }

    private func geocodedLocationFromSelectedLocation(_ locationSearchOption: Observable<LocationSearchOption?>)
        -> Observable<GeocodedLocationModel> {
        return locationSearchOption
            .filterNil()
            .flatMapLatest { [unowned self] (selection: LocationSearchOption) -> Observable<GeocodedLocationModel> in
                switch selection {
                case let .autocompleteLocation(autocompleteLocation), let .historical(autocompleteLocation):
                    return self.locationAutocompleteInteractor
                        .getLocationFromAutocompleteResult(autocompleteLocation)
                        .logErrors(logger: self.logger)
                        .retry(DefaultLocationSearchViewModel.locationAutoCompleteInteractorRepeatBehavior)
                case .currentLocation:
                    return self.getCurrentLocation()
                default:
                    fatalError("Invalid LocationSearchOption type")
                }
            }
    }

    public func setPickupText(_ text: String) {
        pickupTextSubject.onNext(text)
    }

    public func setDropoffText(_ text: String) {
        dropoffTextSubject.onNext(text)
    }

    public func setFocus(_ focus: LocationSearchFocusType) {
        focusSubject.onNext(focus)
    }

    public func makeSelection(_ selectedLocation: LocationSearchOption) {
        selectionSubject.onNext(selectedLocation)
    }

    public func done() {
        listener?.doneSearching()
    }

    public func cancel() {
        listener?.cancelLocationSearch()
    }

    public func getLocationOptions() -> Observable<[LocationSearchOption]> {
        let autocompleteOptions = Observable
            .combineLatest(
                pickupTextSubject.startWith(""),
                dropoffTextSubject.startWith(""),
                focusSubject
            )
            .distinctUntilChanged { $0 == $1 }
            .flatMap { [unowned self] (pickup: String, dropoff: String, focus: LocationSearchFocusType) -> Observable<[LocationSearchOption]> in
                if focus == .dropoff {
                    return self.getLocationSearchOptionsFromAutoCompleteResults(text: dropoff)
                } else {
                    return self.getLocationSearchOptionsFromAutoCompleteResults(text: pickup)
                }
            }
            .subscribeOn(schedulerProvider.computation())

        return Observable
            .combineLatest(
                historicalSearchInteractor.historicalSearchOptions
                    .subscribeOn(schedulerProvider.io())
                    .startWith([])
                    .map { historicalSearchOptions in
                        historicalSearchOptions.map { LocationSearchOption.historical($0) }
                    },
                autocompleteOptions,
                focusSubject
            )
            .map { historicalOptions, autocompleteOptions, focus in
                if autocompleteOptions.isNotEmpty {
                    return autocompleteOptions
                }

                if focus == .dropoff {
                    return historicalOptions + [LocationSearchOption.selectOnMap]
                } else {
                    return [LocationSearchOption.currentLocation, LocationSearchOption.selectOnMap] + historicalOptions
                }
            }
    }

    public func getSelectedPickup() -> Observable<String> {
        return selectedPickup
            .filterNil()
            .map { $0.displayName() }
            .startWith(initialPickupString)
    }

    public func getSelectedDropOff() -> Observable<String> {
        return selectedDropoff
            .filterNil()
            .map { $0.displayName() }
            .startWith(initialDropoffString)
    }

    public func isDoneActionEnabled() -> Observable<Bool> {
        return Observable.just(doneActionEnabled)
    }

    private func getLocationSearchOptionsFromAutoCompleteResults(text: String) -> Observable<[LocationSearchOption]> {
        if text.isEmpty {
            return Observable.just([])
        }
        return locationAutocompleteInteractor
            .getAutocompleteResults(searchText: text, bounds: searchBounds)
            .logErrors(logger: logger)
            .retry(DefaultLocationSearchViewModel.locationAutoCompleteInteractorRepeatBehavior)
            .map(convertToLocationSearchOptions)
    }

    private func convertToLocationSearchOptions(_ predictions: [LocationAutocompleteResult]) -> [LocationSearchOption] {
        return predictions.map(LocationSearchOption.autocompleteLocation)
    }

    private func getCurrentLocation() -> Observable<GeocodedLocationModel> {
        return deviceLocator
            .observeCurrentLocation()
            .map { location in
                GeocodedLocationModel(displayName: LocationSearchOption.currentLocation.displayName(),
                                      location: location.coordinate)
            }
    }
}
