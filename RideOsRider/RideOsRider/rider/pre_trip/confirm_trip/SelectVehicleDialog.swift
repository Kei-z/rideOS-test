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

public class SelectVehicleDialog: BottomDialogStackView {
    private static let headerText =
        RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.vehicle-selection.header")
    private static let vehiclePickerFont = UIFont.systemFont(ofSize: 17.0)

    private var currentlySelectedVehicle = VehicleSelectionOption.automatic
    private let selectVehicleButton = StackedActionButtonContainerView(
        title: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.vehicle-selection.button-title")
    )

    private let disposeBag = DisposeBag()
    private let vehiclePicker = UIPickerView()

    public var selectVehicleButtonTapEvents: ControlEvent<Void> {
        return selectVehicleButton.tapEvents
    }

    public func bindToVehiclePicker(vehicles: Observable<[VehicleSelectionOption]>) -> Disposable {
        return vehicles.bind(to: vehiclePicker.rx.items) { _, item, _ in
            let label = UILabel()
            label.text = item.displayName
            label.font = SelectVehicleDialog.vehiclePickerFont
            label.textAlignment = .center
            return label
        }
    }

    public var selectedVehicle: VehicleSelectionOption {
        return currentlySelectedVehicle
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public init() {
        super.init(stackedViews: [
            BottomDialogStackView.headerLabel(withText: SelectVehicleDialog.headerText),
            vehiclePicker,
            selectVehicleButton,
        ])

        vehiclePicker.rx.modelSelected(VehicleSelectionOption.self)
            .subscribe(onNext: { [unowned self] selectedVehicle in
                if let selected = selectedVehicle.first {
                    self.currentlySelectedVehicle = selected
                } else {
                    fatalError("Unknown selected vehicle")
                }
            })
            .disposed(by: disposeBag)
    }
}
