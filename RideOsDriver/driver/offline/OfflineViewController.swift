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

public class OfflineViewController: BackgroundMapViewController {
    private weak var goOnlineListener: GoOnlineListener?

    private let disposeBag = DisposeBag()
    private let offlineDialogView = OfflineDialogView()
    private let mapStateProvider = FollowCurrentLocationMapStateProvider(icon: DrawableMarkerIcons.car())
    private let viewModel: OfflineViewModel
    private let schedulerProvider: SchedulerProvider

    public init(goOnlineListener: GoOnlineListener,
                mapViewController: MapViewController,
                viewModel: OfflineViewModel = DefaultOfflineViewModel(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.goOnlineListener = goOnlineListener
        self.schedulerProvider = schedulerProvider
        self.viewModel = viewModel

        super.init(mapViewController: mapViewController)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        offlineDialogView.set(isAnimatingProgress: false)

        offlineDialogView.goOnlineTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [viewModel] _ in viewModel.goOnline() })
            .disposed(by: disposeBag)

        viewModel.offlineViewState
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] currentState in
                switch currentState {
                case .offline:
                    self.offlineDialogView.set(isAnimatingProgress: false)
                    self.offlineDialogView.isGoOnlineButtonEnabled = true
                case .goingOnline:
                    self.offlineDialogView.set(isAnimatingProgress: true)
                    self.offlineDialogView.isGoOnlineButtonEnabled = false
                case .online:
                    self.goOnlineListener?.didGoOnline()
                case .failedToGoOnline:
                    self.offlineDialogView.set(isAnimatingProgress: false)
                    self.offlineDialogView.isGoOnlineButtonEnabled = true
                    self.present(self.goingOnlineFailedAlertController(),
                                 animated: true,
                                 completion: nil)
                }

            }).disposed(by: disposeBag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentBottomDialogStackView(offlineDialogView) { [mapViewController, mapStateProvider] in
            mapViewController.connect(mapStateProvider: mapStateProvider)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dismissBottomDialogStackView(offlineDialogView)
    }
}

extension OfflineViewController {
    private func goingOnlineFailedAlertController() -> UIAlertController {
        let alertController = UIAlertController(
            title: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.offline.go-online-failed-alert.title"
            ),
            message: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.offline.go-online-failed-alert.message"
            ),
            preferredStyle: UIAlertController.Style.alert
        )

        alertController.addAction(
            UIAlertAction(
                title: RideOsDriverResourceLoader.instance.getString(
                    "ai.rideos.driver.offline.go-online-failed-alert.action.ok"
                ),
                style: UIAlertAction.Style.default
            )
        )
        return alertController
    }
}
