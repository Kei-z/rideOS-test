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

public class BeforePickupDialog: MatchedToVehicleDialog {
    private let headerLabel = BottomDialogStackView.headerLabel(withText: "")
    private let pickupDropoffLabel = BeforePickupDialog.pickupDropoffLabel()
    private let cancelButton = BottomDialogStackView.cancelButton()
    private let licensePlateAndContactButton = LicensePlateAndContactButtonView()
    private let editPickupButton = BeforePickupDialog.editPickupButton()

    public var headerText: String? {
        get {
            return headerLabel.text
        }
        set {
            headerLabel.text = newValue
        }
    }

    public var waypointLabel: String? {
        get {
            return pickupDropoffLabel.text
        }
        set {
            pickupDropoffLabel.text = newValue
        }
    }

    public var licensePlate: String? {
        get {
            return licensePlateAndContactButton.licensePlate
        }
        set {
            licensePlateAndContactButton.licensePlate = newValue
        }
    }

    public var isShowingContactButton: Bool {
        get {
            return licensePlateAndContactButton.isShowingContactButton
        }
        set {
            licensePlateAndContactButton.isShowingContactButton = newValue
        }
    }

    public var contactButtonTapEvents: ControlEvent<Void> {
        return licensePlateAndContactButton.contactButtonTapEvents
    }

    public var cancelButtonTapEvents: ControlEvent<Void> {
        return cancelButton.rx.tap
    }

    public var editButtonTapEvents: ControlEvent<Void> {
        return editPickupButton.rx.tap
    }

    public init() {
        super.init(stackedElements: [
            .view(view: headerLabel),
            .customSpacing(spacing: 9.0),
            .view(view: BottomDialogStackView.separatorView()),
            .customSpacing(spacing: 23.0),
            .view(view: BottomDialogStackView.rowWith(stretchedLeftView: pickupDropoffLabel, rightView: editPickupButton)),
            .customSpacing(spacing: 23.0),
            .view(view: BottomDialogStackView.insetSeparatorView()),
            .customSpacing(spacing: 23.0),
            .view(view: licensePlateAndContactButton),
            .customSpacing(spacing: 15.0),
            .view(view: cancelButton),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension BeforePickupDialog {
    private static func pickupDropoffLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return label
    }

    private static func editPickupButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(RiderImages.pencil(), for: .normal)
        return button
    }
}
