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

public class DrivePendingViewController: BackgroundMapViewController {
    private let startNavigationListener: () -> Void
    private let actionDialogView: ActionDialogView
    private let drivePendingViewModel: DrivePendingViewModel
    private let schedulerProvider: SchedulerProvider
    private let disposeBag = DisposeBag()

    public convenience init(titleText: String,
                            destination: CLLocationCoordinate2D,
                            startNavigationListener: @escaping () -> Void,
                            mapViewController: MapViewController,
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.init(titleText: titleText,
                  drivePendingViewModel: DefaultDrivePendingViewModel(destination: destination),
                  startNavigationListener: startNavigationListener,
                  mapViewController: mapViewController,
                  schedulerProvider: schedulerProvider)
    }

    public init(titleText: String,
                drivePendingViewModel: DrivePendingViewModel,
                startNavigationListener: @escaping () -> Void,
                mapViewController: MapViewController,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.drivePendingViewModel = drivePendingViewModel
        self.startNavigationListener = startNavigationListener
        self.schedulerProvider = schedulerProvider

        actionDialogView = ActionDialogView(
            titleText: titleText,
            actionButtonTitle: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.online.start-navigation-button.title"
            )
        )

        super.init(mapViewController: mapViewController)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        drivePendingViewModel.routeDetailText
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [actionDialogView] in actionDialogView.detailText = $0 })
            .disposed(by: disposeBag)

        actionDialogView.actionButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [startNavigationListener] _ in startNavigationListener() })
            .disposed(by: disposeBag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentBottomDialogStackView(actionDialogView) { [mapViewController, drivePendingViewModel] in
            mapViewController.connect(mapStateProvider: drivePendingViewModel)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dismissBottomDialogStackView(actionDialogView)
    }
}
