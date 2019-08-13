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
import RxCocoa
import RxSwift

public typealias MatchedToVehicleDialog = BottomDialogStackView & MatchedToVehicleView

public class MatchedToVehicleViewController: BackgroundMapViewController, PassengerStateObserver {
    private let disposeBag = DisposeBag()

    private let dialogView: MatchedToVehicleDialog
    private let viewModel: MatchedToVehicleViewModel
    private let urlLauncher: UrlLauncher

    public required init?(coder _: NSCoder) {
        fatalError("MatchedToVehicleViewController does not support NSCoder")
    }

    public init(dialogView: MatchedToVehicleDialog,
                mapViewController: MapViewController,
                viewModel: MatchedToVehicleViewModel,
                cancelListener: @escaping () -> Void,
                schedulerProvider: SchedulerProvider) {
        self.dialogView = dialogView
        self.viewModel = viewModel
        urlLauncher = DefaultUrlLauncher()
        super.init(mapViewController: mapViewController)

        viewModel.dialogModel
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [dialogView] in
                dialogView.headerText = $0.status
                dialogView.waypointLabel = $0.nextWaypoint
                dialogView.licensePlate = $0.vehicleInfo.licensePlate
                dialogView.isShowingContactButton = !$0.vehicleInfo.contactInfo.isEmpty
            })
            .disposed(by: disposeBag)

        dialogView.contactButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .withLatestFrom(viewModel.dialogModel)
            .subscribe(onNext: { [unowned self] in
                if let contactUrl = $0.vehicleInfo.contactInfo.url {
                    self.urlLauncher.launch(url: contactUrl, parentViewController: self)
                }
            })
            .disposed(by: disposeBag)

        dialogView.cancelButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in
                let alertController =
                    CancelTripAlertController.cancelTripAlertController(withConfirmationListener: cancelListener)
                self.present(alertController, animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }

    public func updatePassengerState(_ state: RiderTripStateModel) {
        viewModel.updatePassengerState(state)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentBottomDialogStackView(dialogView) { [mapViewController, viewModel] in
            mapViewController.connect(mapStateProvider: viewModel)
        }
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBottomDialogStackView(dialogView)
    }
}
