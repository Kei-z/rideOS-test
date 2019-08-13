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
import RideOsCommon
import RxSwift

public class DrivingCoordinator: Coordinator {
    private let drivingViewModel: DrivingViewModel

    private let vehicleNavigationControllerProvider: () -> UIVehicleNavigationController
    private let destination: CLLocationCoordinate2D
    private let drivePendingTitle: String
    private let confirmArrivalTitle: String
    private let mapViewController: MapViewController
    private let schedulerProvider: SchedulerProvider
    private let disposeBag = DisposeBag()

    private convenience init(finishedDrivingListener: @escaping () -> Void,
                             destination: CLLocationCoordinate2D,
                             drivePendingTitle: String,
                             confirmArrivalTitle: String,
                             mapViewController: MapViewController,
                             navigationController: UINavigationController,
                             userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                             schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        let vehicleNavigationControllerProvider: () -> UIVehicleNavigationController = {
            let simulatedDeviceLocator: SimulatedDeviceLocator?

            if userStorageReader.get(DriverDeveloperSettingsKeys.enableSimulatedNavigation) ?? false {
                simulatedDeviceLocator = SimulatedDeviceLocator.instance
            } else {
                simulatedDeviceLocator = nil
            }

            let viewModel = RideOsRouteMapboxDirectionsViewModel(schedulerProvider: schedulerProvider)

            return MapboxNavigationViewController(mapboxNavigationViewModel: viewModel,
                                                  mapViewController: mapViewController,
                                                  simulatedDeviceLocator: simulatedDeviceLocator,
                                                  schedulerProvider: schedulerProvider)
        }

        self.init(vehicleNavigationControllerProvider: vehicleNavigationControllerProvider,
                  finishedDrivingListener: finishedDrivingListener,
                  destination: destination,
                  drivePendingTitle: drivePendingTitle,
                  confirmArrivalTitle: confirmArrivalTitle,
                  mapViewController: mapViewController,
                  navigationController: navigationController,
                  schedulerProvider: schedulerProvider)
    }

    private init(vehicleNavigationControllerProvider: @escaping () -> UIVehicleNavigationController,
                 finishedDrivingListener: @escaping () -> Void,
                 destination: CLLocationCoordinate2D,
                 drivePendingTitle: String,
                 confirmArrivalTitle: String,
                 mapViewController: MapViewController,
                 navigationController: UINavigationController,
                 schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.vehicleNavigationControllerProvider = vehicleNavigationControllerProvider
        self.destination = destination
        self.drivePendingTitle = drivePendingTitle
        self.confirmArrivalTitle = confirmArrivalTitle
        self.mapViewController = mapViewController
        self.schedulerProvider = schedulerProvider
        drivingViewModel = DefaultDrivingViewModel(finishedDrivingListener: finishedDrivingListener,
                                                   destination: destination)

        super.init(navigationController: navigationController)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func activate() {
        drivingViewModel.drivingViewState
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] drivingState in
                switch drivingState.drivingStep {
                case .drivePending:
                    self.showDrivePending()
                case .navigating:
                    self.showNavigation()
                case .confirmingArrival:
                    self.showConfirmingArrival()
                }
            })
            .disposed(by: disposeBag)
    }

    private func showDrivePending() {
        let startNavigationListener = { [drivingViewModel] in drivingViewModel.startNavigation() }

        showChild(viewController: DrivePendingViewController(titleText: drivePendingTitle,
                                                             destination: destination,
                                                             startNavigationListener: startNavigationListener,
                                                             mapViewController: mapViewController))
    }

    private func showNavigation() {
        let controller = vehicleNavigationControllerProvider()
        showChild(viewController: controller)

        controller.navigate(to: destination) { [drivingViewModel] in
            drivingViewModel.finishedNavigation()
        }
    }

    private func showConfirmingArrival() {
        let confirmArrivalListener = { [drivingViewModel] in drivingViewModel.confirmArrival() }

        showChild(viewController: ConfirmingArrivalViewController(titleText: confirmArrivalTitle,
                                                                  destination: destination,
                                                                  confirmArrivalListener: confirmArrivalListener,
                                                                  mapViewController: mapViewController))
    }
}

extension DrivingCoordinator {
    public static func forPickup(
        finishedDrivingListener: @escaping () -> Void,
        destination: CLLocationCoordinate2D,
        mapViewController: MapViewController,
        navigationController: UINavigationController
    ) -> DrivingCoordinator {
        return DrivingCoordinator(
            finishedDrivingListener: finishedDrivingListener,
            destination: destination,
            drivePendingTitle: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.online.drive-to-pickup.title"
            ),
            confirmArrivalTitle: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.online.confirm-pickup-arrival.title"
            ),
            mapViewController: mapViewController,
            navigationController: navigationController
        )
    }

    public static func forDropoff(
        finishedDrivingListener: @escaping () -> Void,
        destination: CLLocationCoordinate2D,
        mapViewController: MapViewController,
        navigationController: UINavigationController
    ) -> DrivingCoordinator {
        return DrivingCoordinator(
            finishedDrivingListener: finishedDrivingListener,
            destination: destination,
            drivePendingTitle: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.online.drive-to-dropoff.title"
            ),
            confirmArrivalTitle: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.online.confirm-dropoff-arrival.title"
            ),
            mapViewController: mapViewController,
            navigationController: navigationController
        )
    }
}
