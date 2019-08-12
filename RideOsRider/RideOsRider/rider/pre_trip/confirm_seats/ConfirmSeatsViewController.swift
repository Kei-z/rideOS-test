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

public class ConfirmSeatsViewController: BackgroundMapViewController {
    private let disposeBag = DisposeBag()
    private let confirmSeatsDialog = ConfirmSeatsDialog()
    private let obscuringView = UIView()
    private let cancelButton = SquareImageButton(image: RiderImages.back())

    private weak var listener: ConfirmSeatsListener?

    private let schedulerProvider: SchedulerProvider

    public init(mapViewController: MapViewController,
                listener: ConfirmSeatsListener,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.listener = listener
        self.schedulerProvider = schedulerProvider
        super.init(mapViewController: mapViewController, showSettingsButton: false)
    }

    public required init?(coder _: NSCoder) {
        fatalError("ConfirmSeatsViewController does not support NSCoder")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        confirmSeatsDialog.confirmButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in
                self.listener?.confirm(seatCount: self.confirmSeatsDialog.selectedSeatCount)
            })
            .disposed(by: disposeBag)

        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        cancelButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true

        view.addSubview(obscuringView)
        view.activateMaxSizeConstraintsOnSubview(obscuringView)
        obscuringView.backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 0.5)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBottomDialogStackView(confirmSeatsDialog)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentBottomDialogStackView(confirmSeatsDialog)
    }
}
