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
import RxCocoa
import UIKit

public class PreRegistrationDialogView: BottomDialogStackView {
    private static let headerLabelText =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.vehicle-unregistered.header-text")

    private static let registerVehicleButtonTitle =
        RideOsDriverResourceLoader.instance.getString(
            "ai.rideos.driver.vehicle-unregistered.register-vehicle-button.title")

    public var registerVehicleTapEvents: ControlEvent<Void> {
        return registerVehicleButton.tapEvents
    }

    private let headerLabel = BottomDialogStackView.headerLabel(withText: PreRegistrationDialogView.headerLabelText)
    private let registerVehicleButton = StackedActionButtonContainerView(
        title: PreRegistrationDialogView.registerVehicleButtonTitle
    )

    public init() {
        // override headerLabel defaults
        headerLabel.numberOfLines = 0
        headerLabel.textAlignment = NSTextAlignment.left

        super.init(stackedElements: [
            .view(view: InsetView(view: headerLabel, margins: UIEdgeInsets(floatLiteral: 16.0))),
            .customSpacing(spacing: 16),
            .view(view: registerVehicleButton),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}
