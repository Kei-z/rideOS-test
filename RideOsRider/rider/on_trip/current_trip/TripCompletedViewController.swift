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

public class TripCompletedViewController: BackgroundMapViewController {
    private let disposeBag = DisposeBag()

    private weak var tripFinishedListener: TripFinishedListener?
    private let dialog: TripCompletedDialog
    private let schedulerProvider: SchedulerProvider

    public init(mapViewController: MapViewController,
                tripFinishedListener: TripFinishedListener?,
                dropoffLocation: GeocodedLocationModel,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.tripFinishedListener = tripFinishedListener
        dialog = TripCompletedDialog(dropoffDisplayName: dropoffLocation.displayName)
        self.schedulerProvider = schedulerProvider

        super.init(mapViewController: mapViewController)
    }

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) is unimplemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        dialog.confirmButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in self.tripFinishedListener?.tripFinished() })
            .disposed(by: disposeBag)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBottomDialogStackView(dialog)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentBottomDialogStackView(dialog)
    }
}
