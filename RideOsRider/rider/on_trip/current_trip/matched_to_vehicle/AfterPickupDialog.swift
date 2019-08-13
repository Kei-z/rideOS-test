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

public class AfterPickupDialog: MatchedToVehicleDialog {
    private let headerLabel = BottomDialogStackView.headerLabel(withText: "")
    private let pickupDropoffLabel = AfterPickupDialog.pickupDropoffLabel()
    private let cancelButton = BottomDialogStackView.cancelButton()
    private let licensePlateAndContactButton = LicensePlateAndContactButtonView()

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

    // // TODO(chrism): Currently, we provide the showCancelButton option because we use AfterPickupDialog for the
    // waiting-for-pickup state due to https://github.com/rideOS/pangea/issues/5322. Once that is fixed and we switch
    // waiting-for-pickup to use BeforePickupDialog, we should consider removing the option and always hiding the cancel
    // button. We might also want to consider keeping it and making it an app-level configuration option in case some
    // partners want to support trip cancellations after the rider is in the car.
    public init(showCancelButton: Bool = false) {
        var stackedElements: [BottomDialogStackView.StackedElement] = [
            .customSpacing(spacing: 24.0),
            .view(view: headerLabel),
            .customSpacing(spacing: 11.0),
            .view(view: pickupDropoffLabel),
            .customSpacing(spacing: 24.0),
            .view(view: BottomDialogStackView.insetSeparatorView()),
            .customSpacing(spacing: 16.0),
            .view(view: licensePlateAndContactButton),
        ]

        if showCancelButton {
            stackedElements.append(.customSpacing(spacing: 8.0))
            stackedElements.append(.view(view: cancelButton))
        } else {
            stackedElements.append(.customSpacing(spacing: 24.0))
        }

        super.init(stackedElements: stackedElements)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension AfterPickupDialog {
    private static func pickupDropoffLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        return label
    }
}
