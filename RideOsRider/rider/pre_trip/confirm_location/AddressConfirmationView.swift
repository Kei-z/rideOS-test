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

public class AddressConfirmationView: UIView {
    private static let margin: CGFloat = 16.0

    private let label = AddressConfirmationView.label()
    private let icon = UIButton(type: .custom)

    public init(showEditButton: Bool) {
        super.init(frame: .zero)

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        if showEditButton {
            label.leadingAnchor.constraint(equalTo: leadingAnchor,
                                           constant: AddressConfirmationView.margin).isActive = true
        } else {
            label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        }
        label.topAnchor.constraint(equalTo: topAnchor).isActive = true
        label.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true

        if showEditButton {
            addSubview(icon)
            icon.setImage(RiderImages.pencil(), for: .normal)
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.trailingAnchor.constraint(equalTo: trailingAnchor,
                                           constant: -AddressConfirmationView.margin).isActive = true
            icon.topAnchor.constraint(equalTo: topAnchor).isActive = true
            icon.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var editButtonTapEvents: ControlEvent<Void> {
        return icon.rx.tap
    }

    public var labelTextBinder: Binder<String?> {
        return label.rx.text
    }
}

extension AddressConfirmationView {
    private static func label() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        return label
    }
}
