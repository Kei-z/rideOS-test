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
    private let logger: Logger

    public convenience init(navigationController: UINavigationController,
                            mapViewController: MapViewController,
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                            logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.init(navigationController: navigationController,
                  mapViewController: mapViewController,
                  viewModel: DefaultMainViewModel(schedulerProvider: schedulerProvider, logger: logger),
                  schedulerProvider: schedulerProvider,
                  logger: logger)
    }

    public init(navigationController: UINavigationController,
                mapViewController: MapViewController,
                viewModel: MainViewModel,
                schedulerProvider: SchedulerProvider,
                logger: Logger) {
        self.viewModel = viewModel
        self.mapViewController = mapViewController
        self.schedulerProvider = schedulerProvider
        self.logger = logger

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
                default:
                    self.logger.logError("Unexpected main view state: \(mainViewState)")
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
