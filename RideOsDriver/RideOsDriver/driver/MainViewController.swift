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
import SideMenu

public class MainViewController: UIViewController, AuthenticatedViewController {
    private static let settingsMenuScreenWidthPercentage: CGFloat = 0.9

    public weak var delegate: AuthenticatedViewControllerDelegate?

    private let fleetInteractor: FleetInteractor
    private let sideMenuManager: SideMenuManager
    private let viewModel: MainViewModel
    private let schedulerProvider: SchedulerProvider
    private let mainNavigationController: UINavigationController
    private let mapViewController: MapViewController
    private let applicationCoordinator: ApplicationCoordinator
    private let fleetOptionResolver: FleetOptionResolver
    private let disposeBag = DisposeBag()

    public init(fleetInteractor: FleetInteractor = DriverDependencyRegistry.instance.driverDependencyFactory.fleetInteractor,
                sideMenuManager: SideMenuManager = SideMenuManager.default,
                viewModel: MainViewModel = DefaultMainViewModel(),
                application: UIApplication = UIApplication.shared,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.sideMenuManager = sideMenuManager
        self.viewModel = viewModel
        self.fleetInteractor = fleetInteractor
        self.schedulerProvider = schedulerProvider
        fleetOptionResolver = DefaultFleetOptionResolver()

        mainNavigationController = UINavigationController(rootViewController: UIViewController())
        mapViewController = MapViewController(schedulerProvider: schedulerProvider)
        applicationCoordinator = ApplicationCoordinator(
            navigationController: mainNavigationController,
            mapViewController: mapViewController
        )

        super.init(nibName: nil, bundle: nil)

        resolveFleet()

        application.isIdleTimerDisabled = true

        mainNavigationController.isNavigationBarHidden = true

        let developerSettingsFormViewControllerFactory = { userStorageReader, userStorageWriter in
            DriverDeveloperSettingsFormViewController(
                userStorageReader: userStorageReader,
                userStorageWriter: userStorageWriter,
                fleetSelectionViewModel: DefaultFleetSelectionViewModel(fleetInteractor: fleetInteractor)
            )
        }

        let settingsForm = MainSettingsFormViewController(
            developerSettingsFormViewControllerFactory: developerSettingsFormViewControllerFactory
        )
        settingsForm.delegate = self

        let settingsNavigationController = UISideMenuNavigationController(rootViewController: settingsForm)
        let sideMenuWidth = round(view.frame.size.width * MainViewController.settingsMenuScreenWidthPercentage)
        settingsNavigationController.menuWidth = sideMenuWidth

        self.sideMenuManager.menuPushStyle = .subMenu
        self.sideMenuManager.menuPresentMode = .menuSlideIn
        self.sideMenuManager.menuLeftNavigationController = settingsNavigationController
        self.sideMenuManager.menuAnimationBackgroundColor = ProfileView.backgroundColor

        mapViewController
            .settingsButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in
                guard let sideMenuNavigationController = self.sideMenuManager.menuLeftNavigationController else {
                    logError("Side menu manager is missing left navigation controller. Not showing side menu.")
                    return
                }
                self.present(sideMenuNavigationController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        applicationCoordinator.activate()
    }

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        addChild(mainNavigationController)
        view.addSubview(mainNavigationController.view)
        mainNavigationController.didMove(toParent: self)
    }

    private func resolveFleet() {
        fleetOptionResolver
            .resolve(fleetOption: UserDefaultsUserStorageReader().fleetOption)
            .subscribe(onNext: {
                ResolvedFleet.instance.set(resolvedFleet: $0.fleetInfo)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: MainSettingsFormViewControllerDelegate

extension MainViewController: MainSettingsFormViewControllerDelegate {
    public func mainSettingsFormViewControllerDidLogOut(_: MainSettingsFormViewController) {
        dismiss(animated: true, completion: nil)
        delegate?.user(didLogout: self)
    }
}
