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

open class IconLabelView: UIView {
    private static let iconLabelHorizontalSpacing: CGFloat = 9.0

    public let label = UILabel()
    public let icon = UIImageView()
    let isCentered: Bool

    public init(isCentered: Bool = true) {
        self.isCentered = isCentered

        super.init(frame: .zero)

        addSubview(icon)
        addSubview(label)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        // Remove any constraints that we've previously applied
        removeConstraints(constraints)

        let labelWidth = label.frame.maxX - label.frame.minX
        let iconWidth = icon.frame.maxX - icon.frame.minX
        let totalWidth = labelWidth + iconWidth + IconLabelView.iconLabelHorizontalSpacing

        icon.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        if isCentered {
            icon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            icon.leadingAnchor.constraint(equalTo: centerXAnchor, constant: -0.5 * totalWidth).isActive = true
            label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        } else {
            icon.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
            icon.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }

        label.leadingAnchor.constraint(equalTo: icon.trailingAnchor,
                                       constant: IconLabelView.iconLabelHorizontalSpacing).isActive = true

        heightAnchor.constraint(equalToConstant: max(icon.frame.height, label.frame.height)).isActive = true
    }

    public required init?(coder _: NSCoder) {
        fatalError("IconLabelView does not support NSCoder")
    }
}
