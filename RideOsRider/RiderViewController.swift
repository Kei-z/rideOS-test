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

import RideOsCommon
import RxSwift
import SideMenu

public class RiderViewController: StartupViewController {
    private let developerSettingsFormViewControllerFactory: DeveloperSettingsFormViewControllerFactory
    private var mainViewController: MainViewController?

    public init(developerSettingsFormViewControllerFactory: @escaping DeveloperSettingsFormViewControllerFactory,
                loginMethods: [LoginMethod],
                user: User = User.currentUser,
                userStorageWriter: UserStorageWriter = UserDefaultsUserStorageWriter()) {
        self.developerSettingsFormViewControllerFactory = developerSettingsFormViewControllerFactory
        super.init(loginMethods: loginMethods, user: user, userStorageWriter: userStorageWriter)
    }

    public required init?(coder _: NSCoder) {
        logFatalError("\(#function) is unimplemented")
        abort()
    }

    public override func createMainViewController(_: String) -> (AuthenticatedUIViewController) {
        let navigationController = UINavigationController(rootViewController: UIViewController())
        navigationController.isNavigationBarHidden = true
        let mainViewController = MainViewController(
            mainNavigationController: navigationController,
            developerSettingsFormViewControllerFactory: developerSettingsFormViewControllerFactory
        )
        self.mainViewController = mainViewController
        return mainViewController
    }

    public func currentCoordinatorEncodedState(_ encoder: JSONEncoder) -> Data? {
        return mainViewController?.applicationCoordinatorEncodedState(encoder)
    }
}

class MainViewController: UIViewController, AuthenticatedViewController, MainSettingsFormViewControllerDelegate {
    private let settingsMenuWidthScreenPercentage: CGFloat = 0.9
    private let disposeBag = DisposeBag()
    private let schedulerProvider = DefaultSchedulerProvider()

    weak var delegate: AuthenticatedViewControllerDelegate?

    private let mainNavigationController: UINavigationController
    private let fleetOptionResolver: FleetOptionResolver
    private let mapViewController: MapViewController
    private let applicationCoordinator: ApplicationCoordinator
    private let mainSettingsFormViewController: MainSettingsFormViewController

    public required init?(coder _: NSCoder) {
        fatalError("MainViewController does not support NSCoder")
    }

    init(mainNavigationController: UINavigationController,
         developerSettingsFormViewControllerFactory: @escaping DeveloperSettingsFormViewControllerFactory) {
        self.mainNavigationController = mainNavigationController
        fleetOptionResolver = DefaultFleetOptionResolver()
        mainSettingsFormViewController = MainSettingsFormViewController(
            developerSettingsFormViewControllerFactory: developerSettingsFormViewControllerFactory
        )
        mapViewController = MapViewController()

        applicationCoordinator = ApplicationCoordinator(
            navigationController: mainNavigationController,
            mapViewController: mapViewController
        )
        super.init(nibName: nil, bundle: nil)

        mainSettingsFormViewController.delegate = self
        let settingsNavigationController = UISideMenuNavigationController(
            rootViewController: mainSettingsFormViewController
        )
        settingsNavigationController.menuWidth = round(view.frame.size.width * settingsMenuWidthScreenPercentage)

        SideMenuManager.default.menuPushStyle = .subMenu
        SideMenuManager.default.menuPresentMode = .menuSlideIn
        SideMenuManager.default.menuLeftNavigationController = settingsNavigationController
        SideMenuManager.default.menuFadeStatusBar = false
        SideMenuManager.default.menuAnimationFadeStrength = 0.5

        resolveFleet()

        mapViewController
            .settingsButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in
                self.present(SideMenuManager.default.menuLeftNavigationController!, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        applicationCoordinator.activate()

        migrateFirstAndLastNameToPreferredName()
    }

    private func resolveFleet() {
        fleetOptionResolver
            .resolve(fleetOption: UserDefaultsUserStorageReader().fleetOption)
            .subscribe(onNext: {
                ResolvedFleet.instance.set(resolvedFleet: $0.fleetInfo)
            })
            .disposed(by: disposeBag)
    }

    override func viewWillAppear(_: Bool) {
        addChild(mainNavigationController)
        view.addSubview(mainNavigationController.view)
        mainNavigationController.didMove(toParent: self)
    }

    func mainSettingsFormViewControllerDidLogOut(_: MainSettingsFormViewController) {
        dismiss(animated: true, completion: nil)
        delegate?.user(didLogout: self)
    }

    func migrateFirstAndLastNameToPreferredName() {
        // For users who had the legacy app installed, read any stored first and last name from user defaults and
        // set their new preferred name
        // TODO(chrism): Remove once most users have upgraded from our legacy apps
        let firstName = UserDefaults.standard.string(forKey: "AccountSettingsFirstNameKey")
        let lastName = UserDefaults.standard.string(forKey: "AccountSettingsLastNameKey")
        if firstName != nil || lastName != nil {
            var nameComponents = PersonNameComponents()
            nameComponents.givenName = firstName
            nameComponents.familyName = lastName
            UserDefaultsUserStorageWriter().set(
                key: CommonUserStorageKeys.preferredName,
                value: PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
            )
        }
    }

    func applicationCoordinatorEncodedState(_ encoder: JSONEncoder) -> Data? {
        return applicationCoordinator.encodedState(encoder)
    }
}
