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
    private let schedulerProvider: SchedulerProvider

    public init(goOnlineListener: GoOnlineListener,
                mapViewController: MapViewController,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.schedulerProvider = schedulerProvider
        super.init(mapViewController: mapViewController)
        self.goOnlineListener = goOnlineListener
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        offlineDialogView.goOnlineTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] _ in self.goOnlineListener?.goOnline() })
            .disposed(by: disposeBag)
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
