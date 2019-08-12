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

public class ActionDialogView: BottomDialogStackView {
    private static let labelTextColor =
        RideOsDriverResourceLoader.instance.getColor("ai.rideos.driver.action-dialog.label.text-color")

    public var detailText: String? {
        get {
            return detailLabel.text
        }
        set {
            detailLabel.text = newValue
        }
    }

    public var actionButtonTapEvents: ControlEvent<Void> {
        return actionButton.tapEvents
    }

    private let titleLabel = ActionDialogView.titleLabel()
    private let detailLabel = ActionDialogView.detailLabel()
    private let actionButton: StackedActionButtonContainerView

    public init(titleText: String, actionButtonTitle: String) {
        actionButton = StackedActionButtonContainerView(title: actionButtonTitle)

        super.init(stackedViews: [
            titleLabel,
            detailLabel,
            actionButton,
        ])

        titleLabel.text = titleText
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension ActionDialogView {
    private static func titleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textAlignment = .center
        label.textColor = ActionDialogView.labelTextColor
        return label
    }

    private static func detailLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textAlignment = .center
        label.textColor = ActionDialogView.labelTextColor
        return label
    }
}
