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

public class VehicleRegistrationViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let vehicleRegistrationView = VehicleRegistrationView()

    private let vehicleRegistrationViewModel: VehicleRegistrationViewModel
    private let schedulerProvider: SchedulerProvider

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public init(vehicleRegistrationViewModel: VehicleRegistrationViewModel,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.vehicleRegistrationViewModel = vehicleRegistrationViewModel
        self.schedulerProvider = schedulerProvider

        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(vehicleRegistrationView)
        view.activateMaxSizeConstraintsOnSubview(vehicleRegistrationView)

        // Update the view model when any of the text boxes change
        vehicleRegistrationView.firstNameFieldTextEvents
            .orEmpty
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [vehicleRegistrationViewModel] value in
                vehicleRegistrationViewModel.setFirstNameText(value)
            })
            .disposed(by: disposeBag)
        vehicleRegistrationView.phoneNumberFieldTextEvents
            .orEmpty
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [vehicleRegistrationViewModel] value in
                vehicleRegistrationViewModel.setPhoneNumberText(value)
            })
            .disposed(by: disposeBag)
        vehicleRegistrationView.licensePlateFieldTextEvents
            .orEmpty
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [vehicleRegistrationViewModel] value in
                vehicleRegistrationViewModel.setLicensePlateText(value)
            })
            .disposed(by: disposeBag)
        vehicleRegistrationView.riderCapacityFieldTextEvents
            .orEmpty
            .asSignal(onErrorJustReturn: "")
            .emit(onNext: { [vehicleRegistrationViewModel] value in
                vehicleRegistrationViewModel.setRiderCapacityText(value)
            })
            .disposed(by: disposeBag)

        // Enable the done button when the view model says so
        vehicleRegistrationViewModel.isSubmitActionEnabled()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [vehicleRegistrationView] isSubmitEnabled in
                vehicleRegistrationView.isSubmitButtonEnabled = isSubmitEnabled
            })
            .disposed(by: disposeBag)

        vehicleRegistrationView.cancelButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [vehicleRegistrationViewModel] in vehicleRegistrationViewModel.cancel() })
            .disposed(by: disposeBag)

        vehicleRegistrationView.submitButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [vehicleRegistrationViewModel] in vehicleRegistrationViewModel.submit() })
            .disposed(by: disposeBag)
    }
}
