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

public class PickupDropoffLabelView: UIView {
    private let verticalStackView = PickupDropoffLabelView.verticalStackView()

    private let pickupLabel = UILabel()
    private let pickupHorizontalStackView: UIStackView

    private let dropoffLabel = UILabel()
    private let dropoffHorizontalStackView: UIStackView

    public var pickupText: String? {
        get {
            return pickupLabel.text
        }
        set {
            pickupLabel.text = newValue
        }
    }

    public var dropoffText: String? {
        get {
            return dropoffLabel.text
        }
        set {
            dropoffLabel.text = newValue
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(pickupString: String? = nil, dropoffString: String? = nil) {
        pickupHorizontalStackView = PickupDropoffLabelView.horizontalStackView(
            withTitleLabel: PickupDropoffLabelView.pickupTitleLabel(),
            textLabel: pickupLabel
        )
        dropoffHorizontalStackView = PickupDropoffLabelView.horizontalStackView(
            withTitleLabel: PickupDropoffLabelView.dropoffTitleLabel(),
            textLabel: dropoffLabel
        )
        super.init(frame: .zero)

        addSubview(verticalStackView)
        activateMaxSizeConstraintsOnSubview(verticalStackView)

        pickupText = pickupString
        dropoffText = dropoffString

        verticalStackView.addArrangedSubview(pickupHorizontalStackView)
        verticalStackView.addArrangedSubview(dropoffHorizontalStackView)
    }
}

extension PickupDropoffLabelView {
    private static func pickupTitleLabel() -> UILabel {
        let label = PickupDropoffLabelView.titleLabel()
        label.text = RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.pickup-label")
        return label
    }

    private static func dropoffTitleLabel() -> UILabel {
        let label = PickupDropoffLabelView.titleLabel()
        label.text = RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.dropoff-label")
        return label
    }

    private static func horizontalStackView(withTitleLabel titleLabel: UILabel, textLabel: UILabel) -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.addArrangedSubview(InsetView(view: titleLabel,
                                               margins: UIEdgeInsets(top: 0, left: 16.0, bottom: 0, right: 0)))
        stackView.addArrangedSubview(textLabel)
        return stackView
    }

    private static func titleLabel() -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = RideOsRiderResourceLoader.instance.getColor("ai.rideos.rider.pickup-dropoff-label.color")
        label.widthAnchor.constraint(equalToConstant: 78).isActive = true
        return label
    }

    private static func verticalStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 18.0
        return stackView
    }
}
