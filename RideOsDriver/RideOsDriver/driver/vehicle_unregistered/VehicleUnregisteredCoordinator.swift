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

public class VehicleUnregisteredCoordinator: Coordinator {
    private let disposeBag = DisposeBag()

    private let vehicleUnregisteredViewModel: VehicleUnregisteredViewModel
    private let mapViewController: MapViewController
    private let schedulerProvider: SchedulerProvider

    public convenience init(registerVehicleFinishedListener: RegisterVehicleFinishedListener,
                            mapViewController: MapViewController,
                            navigationController: UINavigationController) {
        self.init(mapViewController: mapViewController,
                  vehicleUnregisteredViewModel: DefaultVehicleUnregisteredViewModel(
                      registerVehicleFinishedListener: registerVehicleFinishedListener
                  ),
                  navigationController: navigationController,
                  schedulerProvider: DefaultSchedulerProvider())
    }

    public init(mapViewController: MapViewController,
                vehicleUnregisteredViewModel: VehicleUnregisteredViewModel,
                navigationController: UINavigationController,
                schedulerProvider: SchedulerProvider) {
        self.mapViewController = mapViewController
        self.vehicleUnregisteredViewModel = vehicleUnregisteredViewModel
        self.schedulerProvider = schedulerProvider

        super.init(navigationController: navigationController)
    }

    public override func activate() {
        vehicleUnregisteredViewModel.getVehicleUnregisteredViewState()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] vehicleUnregisteredViewState in
                switch vehicleUnregisteredViewState {
                case .preRegistration:
                    self.showPreRegistration()
                case .registering:
                    self.showRegistering()
                }
            })
            .disposed(by: disposeBag)
    }

    private func showPreRegistration() {
        showChild(viewController: PreRegistrationViewController(startVehicleRegistrationListener: vehicleUnregisteredViewModel,
                                                                mapViewController: mapViewController))
    }

    private func showRegistering() {
        showChild(viewController: VehicleRegistrationViewController(vehicleRegistrationViewModel:
            DefaultVehicleRegistrationViewModel(registerVehicleListener: vehicleUnregisteredViewModel)))
    }
}
