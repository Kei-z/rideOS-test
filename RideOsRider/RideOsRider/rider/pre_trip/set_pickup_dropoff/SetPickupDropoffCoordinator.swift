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

public class SetPickupDropoffCoordinator: Coordinator {
    private let disposeBag = DisposeBag()

    private let viewModel: SetPickupDropoffViewModel
    private let mapViewController: MapViewController
    private let deviceLocator: DeviceLocator
    private let schedulerProvider: SchedulerProvider

    public convenience init(listener: SetPickupDropoffListener,
                            mapViewController: MapViewController,
                            navigationController: UINavigationController,
                            initialPickup: PreTripLocation? = nil,
                            initialDropoff: PreTripLocation? = nil,
                            deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.init(viewModel: DefaultSetPickupDropoffViewModel(listener: listener,
                                                              initialPickup: initialPickup,
                                                              initialDropoff: initialDropoff),
                  mapViewController: mapViewController,
                  navigationController: navigationController,
                  deviceLocator: deviceLocator,
                  schedulerProvider: schedulerProvider)
    }

    public init(viewModel: SetPickupDropoffViewModel,
                mapViewController: MapViewController,
                navigationController: UINavigationController,
                deviceLocator: DeviceLocator,
                schedulerProvider: SchedulerProvider) {
        self.viewModel = viewModel
        self.mapViewController = mapViewController
        self.deviceLocator = deviceLocator
        self.schedulerProvider = schedulerProvider
        super.init(navigationController: navigationController)
    }

    public override func activate() {
        viewModel.getDisplayState()
            .observeOn(schedulerProvider.mainThread())
            // Only emit events when the step changes
            .distinctUntilChanged { $0.step == $1.step }
            .subscribe(onNext: { [unowned self] displayState in
                switch displayState.step {
                case .searchingForPickupDropoff:
                    self.showLocationSearch(pickup: displayState.pickup?.desiredLocation.geocodedLocation,
                                            dropoff: displayState.dropoff?.desiredLocation.geocodedLocation)
                case .settingPickupOnMap:
                    self.showSettingPickupOnMap()
                case .settingDropoffOnMap:
                    self.showSettingDropoffOnMap()
                }
            })
            .disposed(by: disposeBag)
    }

    public func showLocationSearch(pickup: GeocodedLocationModel?, dropoff: GeocodedLocationModel?) {
        showChild(
            viewController: LocationSearchViewController(
                DefaultLocationSearchViewModel(listener: viewModel,
                                               initialPickup: pickup,
                                               initialDropoff: dropoff,
                                               searchBounds: mapViewController.visibleRegion)
            )
        )
    }

    public func showSettingPickupOnMap() {
        showChild(viewController: ConfirmLocationViewController.buildForSetPickup(
            mapViewController: mapViewController,
            initialLocation: deviceLocator.observeCurrentLocation().map { $0.coordinate }.take(1).asSingle(),
            listener: viewModel
        ))
    }

    public func showSettingDropoffOnMap() {
        showChild(viewController: ConfirmLocationViewController.buildForSetDropoff(
            mapViewController: mapViewController,
            initialLocation: deviceLocator.observeCurrentLocation().map { $0.coordinate }.take(1).asSingle(),
            listener: viewModel
        ))
    }
}
