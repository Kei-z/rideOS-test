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

import Eureka
import Foundation
import RxSwift
import UIKit

public class MainSettingsFormViewController: FormViewController, UINavigationControllerDelegate {
    private static let signOutButtonTitle =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.settings.signout")
    private static let signOutButtonHeight: CGFloat = 48.0
    private static let signOutButtonBottomOffset: CGFloat = 24.0
    private static let profileViewHeight: CGFloat = 177.0

    static let editProfileString =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.settings.developer.edit-profile")
    static let developerSettingsString =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.settings.developer")

    private let disposeBag = DisposeBag()
    private let profileView = ProfileView()
    private let signOutButton =
        StackedActionButtonContainerView(title: MainSettingsFormViewController.signOutButtonTitle)

    public weak var delegate: MainSettingsFormViewControllerDelegate?

    private let userStorageReader: UserStorageReader
    private let userStorageWriter: UserStorageWriter
    private let user: User
    private let developerSettingsFormViewControllerFactory: DeveloperSettingsFormViewControllerFactory?

    private var userEmailAddress: String?

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                userStorageWriter: UserStorageWriter = UserDefaultsUserStorageWriter(),
                user: User = User.currentUser,
                developerSettingsFormViewControllerFactory: DeveloperSettingsFormViewControllerFactory?) {
        self.userStorageReader = userStorageReader
        self.userStorageWriter = userStorageWriter
        self.developerSettingsFormViewControllerFactory = developerSettingsFormViewControllerFactory
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("MainSettingsFormViewController does not support NSCoder")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        user.fetchProfile { profile in
            guard let profile = profile else {
                logError("No user profile")
                return
            }
            DispatchQueue.main.async {
                self.userEmailAddress = profile.email
                self.profileView.set(pictureURL: profile.pictureURL)
                self.profileView.set(email: self.userEmailAddress)
            }
        }

        userStorageReader.observe(CommonUserStorageKeys.preferredName)
            .subscribe(onNext: { [profileView] preferredName in
                profileView.set(preferredName: preferredName)
            })
            .disposed(by: disposeBag)

        tableView.backgroundColor = .white

        navigationController?.navigationBar.isHidden = true
        navigationController?.delegate = self

        // Set this so that the top section's header (the ProfileView) extends to the very top of the screen
        tableView.contentInsetAdjustmentBehavior = .never

        tableView.isScrollEnabled = false

        tableView.addSubview(signOutButton)
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.bottomAnchor.constraint(
            equalTo: tableView.safeAreaLayoutGuide.bottomAnchor,
            constant: -MainSettingsFormViewController.signOutButtonBottomOffset
        ).isActive = true
        signOutButton.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        signOutButton.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        signOutButton
            .heightAnchor
            .constraint(equalToConstant: MainSettingsFormViewController.signOutButtonHeight)
            .isActive = true

        signOutButton.tapEvents
            .subscribe(onNext: { [unowned self] in
                self.delegate?.mainSettingsFormViewControllerDidLogOut(self)
            })
            .disposed(by: disposeBag)

        setupForm()
    }

    private func setupForm() {
        form +++ Section { section in
            section.header = { [unowned self] in
                var header = HeaderFooterView<UIView>(.callback {
                    self.profileView
                })
                header.height = { self.profileViewHeight }
                return header
            }()
        }

        let section = Section()
        form +++ section
            <<< ButtonRow { row in
                row.title = MainSettingsFormViewController.editProfileString
                row.presentationMode = .show(controllerProvider: ControllerProvider.callback(builder: {
                    AccountSettingsFormViewController(userStorageReader: self.userStorageReader,
                                                      userStorageWriter: self.userStorageWriter,
                                                      userEmailAddress: self.userEmailAddress)
                }), onDismiss: nil)
            }
            .cellSetup { cell, _ in
                cell.imageView?.image = CommonImages.person()
            }

        if let developerSettingsFormViewControllerFactory = developerSettingsFormViewControllerFactory {
            section <<< ButtonRow { row in
                row.title = MainSettingsFormViewController.developerSettingsString
                row.presentationMode = .show(controllerProvider: ControllerProvider.callback(builder: {
                    developerSettingsFormViewControllerFactory(self.userStorageReader, self.userStorageWriter)
                }), onDismiss: nil)
            }
            .cellSetup { cell, _ in
                cell.imageView?.image = CommonImages.gear()
            }
        }
    }

    private var profileViewHeight: CGFloat {
        return MainSettingsFormViewController.profileViewHeight + view.safeAreaInsets.top
    }

    public func navigationController(_ navigationController: UINavigationController,
                                     willShow viewController: UIViewController,
                                     animated: Bool) {
        if viewController == self {
            // If the navigation controller is showing this view controller, hide the navigation bar so that the
            // ProfileView is at the very top of the screen
            navigationController.setNavigationBarHidden(true, animated: animated)
        } else {
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }
}

public protocol MainSettingsFormViewControllerDelegate: NSObjectProtocol {
    func mainSettingsFormViewControllerDidLogOut(_ mainSettingsFormViewController: MainSettingsFormViewController)
}
