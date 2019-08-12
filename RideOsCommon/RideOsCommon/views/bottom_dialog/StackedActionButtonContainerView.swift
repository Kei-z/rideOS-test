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
import RxCocoa

// An action button that's designed to be stacked within a BottomDialogStackView
open class StackedActionButtonContainerView: InsetView {
    // The color of the button
    private static let buttonColorEnabled =
        RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.action-button.color.enabled")
    private static let buttonColorDisabled =
        RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.action-button.color.disabled")

    // The insets of the button's content (i.e. title) within the UIButton itself
    private static let buttonContentInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)

    // The corner radius of the UIButton
    private static let buttonCornerRadius: CGFloat = 4.0

    // The margins of the UIButton within its container view
    private static let containerViewMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    private let button = UIButton()

    public var isButtonEnabled: Bool {
        get {
            return button.isEnabled
        }
        set {
            button.isEnabled = newValue
            if newValue {
                button.backgroundColor = StackedActionButtonContainerView.buttonColorEnabled
            } else {
                button.backgroundColor = StackedActionButtonContainerView.buttonColorDisabled
            }
        }
    }

    public var tapEvents: ControlEvent<Void> {
        return button.rx.tap
    }

    public init(title: String) {
        button.setTitle(title, for: .normal)
        button.contentEdgeInsets = StackedActionButtonContainerView.buttonContentInsets
        button.layer.cornerRadius = StackedActionButtonContainerView.buttonCornerRadius

        super.init(view: button, margins: StackedActionButtonContainerView.containerViewMargins)

        isButtonEnabled = true
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
