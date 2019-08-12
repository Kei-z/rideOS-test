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

public class LicensePlateAndContactButtonView: UIView {
    private let contactButton = LicensePlateAndContactButtonView.contactButton()
    private let licensePlateIconAndLabel = LicensePlateAndContactButtonView.licensePlateIconAndLabel()

    public var licensePlate: String? {
        get {
            return licensePlateIconAndLabel.label.text
        }
        set {
            licensePlateIconAndLabel.label.text = newValue
        }
    }

    public var isShowingContactButton: Bool {
        get {
            return !contactButton.isHidden
        }
        set {
            contactButton.isHidden = !newValue
        }
    }

    public var contactButtonTapEvents: ControlEvent<Void> {
        return contactButton.rx.tap
    }

    public init() {
        super.init(frame: .zero)

        let stackView = BottomDialogStackView.rowWith(stretchedLeftView: licensePlateIconAndLabel,
                                                      rightView: contactButton)
        addSubview(stackView)
        activateMaxSizeConstraintsOnSubview(stackView)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension LicensePlateAndContactButtonView {
    private static func contactButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.setImage(RiderImages.chatBubble(), for: .normal)
        button.contentHorizontalAlignment = .right
        return button
    }

    private static func licensePlateIconAndLabel() -> IconLabelView {
        let licensePlateIconAndLabel = IconLabelView(isCentered: false)
        licensePlateIconAndLabel.icon.image = RiderImages.carFront()
        licensePlateIconAndLabel.label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        return licensePlateIconAndLabel
    }
}
