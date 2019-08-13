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
import Foundation
import RideOsCommon
import RxSwift

public class WaitingForAssignmentViewController: BackgroundMapViewController {
    private let disposeBag = DisposeBag()
    private let dialogView = RequestingTripDialog()

    private let viewModel: WaitingForAssignmentViewModel
    private let schedulerProvider: SchedulerProvider
    private let cancelListener: () -> Void

    public required init?(coder _: NSCoder) {
        fatalError("WaitingForAssignmentViewController does not support NSCoder")
    }

    public convenience init(mapViewController: MapViewController,
                            initialPassengerState: RiderTripStateModel,
                            cancelListener: @escaping () -> Void,
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.init(mapViewController: mapViewController,
                  viewModel: DefaultWaitingForAssignmentViewModel(initialPassengerState: initialPassengerState),
                  cancelListener: cancelListener,
                  schedulerProvider: schedulerProvider)
    }

    public init(mapViewController: MapViewController,
                viewModel: WaitingForAssignmentViewModel,
                cancelListener: @escaping () -> Void,
                schedulerProvider: SchedulerProvider) {
        self.viewModel = viewModel
        self.schedulerProvider = schedulerProvider
        self.cancelListener = cancelListener
        super.init(mapViewController: mapViewController)
    }

    public override func viewDidLoad() {
        viewModel.pickupDropoff
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [dialogView] pickupDropoff in
                dialogView.pickupText = pickupDropoff.pickup.displayName
                dialogView.dropoffText = pickupDropoff.dropoff.displayName
            })
            .disposed(by: disposeBag)

        dialogView.cancelButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in
                let alertController =
                    CancelTripAlertController.cancelTripAlertController(withConfirmationListener: self.cancelListener)
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapViewController.connect(mapStateProvider: viewModel)
        presentBottomDialogStackView(dialogView)
    }
}

// MARK: PassengerStateObserver

extension WaitingForAssignmentViewController: PassengerStateObserver {
    public func updatePassengerState(_ state: RiderTripStateModel) {
        viewModel.updatePassengerState(state)
    }
}
