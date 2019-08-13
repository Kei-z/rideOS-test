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

public class StartScreenViewController: BackgroundMapViewController, UITextFieldDelegate {
    private static let startLocationSearchButtonHeight: CGFloat = 48.0
    private static let menuButtonStartLocationSearchButtonVerticalSpacing: CGFloat = 16.0

    private let disposeBag = DisposeBag()

    private let startLocationSearchButton = StartScreenViewController.startLocationSearchButton()

    private let viewModel: StartScreenViewModel

    private let settingsViewController = UIViewController()

    public init(viewModel: StartScreenViewModel,
                mapViewController: MapViewController,
                schedulerProvider _: SchedulerProvider = DefaultSchedulerProvider()) {
        self.viewModel = viewModel
        super.init(mapViewController: mapViewController)
    }

    public required init?(coder _: NSCoder) {
        fatalError("StartScreenViewController does not support NSCoder")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        view.addSubview(startLocationSearchButton)
        startLocationSearchButton.translatesAutoresizingMaskIntoConstraints = false
        startLocationSearchButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true
        startLocationSearchButton.topAnchor.constraint(
            equalTo: mapViewController.topAnchor,
            constant: StartScreenViewController.menuButtonStartLocationSearchButtonVerticalSpacing
        ).isActive = true
        startLocationSearchButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor).isActive = true
        startLocationSearchButton
            .heightAnchor
            .constraint(equalToConstant: StartScreenViewController.startLocationSearchButtonHeight)
            .isActive = true

        startLocationSearchButton.rx.tap
            .subscribe(onNext: { [viewModel] _ in viewModel.startLocationSearch() })
            .disposed(by: disposeBag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapViewController.connect(mapStateProvider: viewModel, mapCenterListener: viewModel)
    }
}

extension StartScreenViewController {
    private static func startLocationSearchButton() -> UIButton {
        let button = UIButton(type: .custom)

        Shadows.enableShadows(onView: button)

        button.setImage(RiderImages.magnifyingGlass(), for: .normal)
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 3, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
        button.setTitle(RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.start-screen.button-title"),
                        for: .normal)
        button.setTitleColor(
            RideOsRiderResourceLoader.instance.getColor("ai.rideos.rider.start-screen.button-title-color"),
            for: .normal
        )
        button.contentHorizontalAlignment = .leading
        button.backgroundColor = .white

        return button
    }
}
