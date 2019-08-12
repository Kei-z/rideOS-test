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

import Foundation
import RideOsCommon
import RxSwift

public class ApplicationCoordinator: Coordinator {
    private let disposeBag = DisposeBag()

    private let mapViewController: MapViewController
    private let viewModel: MainViewModel
    private let schedulerProvider: SchedulerProvider

    public init(navigationController: UINavigationController,
                mapViewController: MapViewController,
                viewModel: MainViewModel = DefaultMainViewModel(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.viewModel = viewModel
        self.mapViewController = mapViewController
        self.schedulerProvider = schedulerProvider
        super.init(navigationController: navigationController)
    }

    public override func activate() {
        viewModel.getMainViewState()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] mainViewState in
                switch mainViewState {
                case .vehicleUnregistered:
                    self.showVehicleUnregistered()
                case .offline:
                    self.showOffline()
                case .online:
                    self.showOnline()
                }
            })
            .disposed(by: disposeBag)
    }

    private func showOffline() {
        showChild(viewController: OfflineViewController(goOnlineListener: viewModel,
                                                        mapViewController: mapViewController))
    }

    private func showOnline() {
        showChild(coordinator: OnlineCoordinator(goOfflineListener: viewModel,
                                                 mapViewController: mapViewController,
                                                 navigationController: navigationController))
    }

    private func showVehicleUnregistered() {
        showChild(coordinator: VehicleUnregisteredCoordinator(registerVehicleFinishedListener: viewModel,
                                                              mapViewController: mapViewController,
                                                              navigationController: navigationController))
    }
}
