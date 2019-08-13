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
    private let userStorageReader: UserStorageReader
    private let viewModel: MainViewModel
    private let schedulerProvider: SchedulerProvider
    private let lowConnectivityMonitor = LowConnectivityMonitor()

    public init(navigationController: UINavigationController,
                mapViewController: MapViewController,
                userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                viewModel: MainViewModel = DefaultMainViewModel(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.viewModel = viewModel
        self.mapViewController = mapViewController
        self.userStorageReader = userStorageReader
        self.schedulerProvider = schedulerProvider
        super.init(navigationController: navigationController)
    }

    public override func activate() {
        viewModel
            .getMainViewState()
            .distinctUntilChanged()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] mainViewState in
                switch mainViewState {
                case .startScreen:
                    self.showStartScreen()
                case .preTrip:
                    self.showPreTrip()
                case let .onTrip(tripId):
                    self.showOnTrip(tripId: tripId)
                }
            })
            .disposed(by: disposeBag)
        lowConnectivityMonitor.beginMonitoringNetworkConnectivity(parentViewController: navigationController)
    }

    private func showStartScreen() {
        showChild(viewController: StartScreenViewController(
            viewModel: DefaultStartScreenViewModel(listener: viewModel),
            mapViewController: mapViewController
        ))
    }

    private func showPreTrip() {
        showChild(coordinator: PreTripCoordinator(listener: viewModel,
                                                  mapViewController: mapViewController,
                                                  navigationController: navigationController))
    }

    private func showOnTrip(tripId: String) {
        showChild(coordinator: OnTripCoordinator(tripId: tripId,
                                                 tripFinishedListener: viewModel,
                                                 mapViewController: mapViewController,
                                                 navigationController: navigationController))
    }
}
