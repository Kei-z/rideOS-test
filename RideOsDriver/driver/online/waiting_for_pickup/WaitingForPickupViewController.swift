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

public class WaitingForPickupViewController: BackgroundMapViewController {
    private let waitingForPickupListener: () -> Void
    private let actionDialogView: ActionDialogView
    private let schedulerProvider: SchedulerProvider
    private let disposeBag = DisposeBag()

    public init(tripResourceInfo: TripResourceInfo,
                waitingForPickupListener: @escaping () -> Void,
                mapViewController: MapViewController,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.waitingForPickupListener = waitingForPickupListener
        self.schedulerProvider = schedulerProvider

        actionDialogView = ActionDialogView(
            titleText: String(
                format: RideOsDriverResourceLoader.instance.getString(
                    "ai.rideos.driver.online.waiting-for-pickup.title-format"
                ),
                tripResourceInfo.numberOfPassengers
            ),
            actionButtonTitle: RideOsDriverResourceLoader.instance.getString(
                "ai.rideos.driver.online.waiting-for-pickup.button.title"
            )
        )

        super.init(mapViewController: mapViewController)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        actionDialogView.actionButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [waitingForPickupListener] _ in waitingForPickupListener() })
            .disposed(by: disposeBag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        presentBottomDialogStackView(actionDialogView)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        dismissBottomDialogStackView(actionDialogView)
    }
}
