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

open class BottomDialogStackView: UIView {
    public enum StackedElement {
        case view(view: UIView)
        case customSpacing(spacing: CGFloat)

        public var view: UIView? {
            switch self {
            case let .view(view):
                return view
            default:
                return nil
            }
        }

        public var customSpacing: CGFloat? {
            switch self {
            case let .customSpacing(spacing):
                return spacing
            default:
                return nil
            }
        }
    }

    private static let defaultVerticalSpacing: CGFloat = 9.0
    private static let separatorColor =
        RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.dialog.color.separator")
    private static let headerLabelTextColor =
        RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.dialog.color.header-text")

    private let stackView = UIStackView()

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(stackedViews: [UIView]) {
        super.init(frame: .zero)
        setupStackView(withElements: stackedViews.map { StackedElement.view(view: $0) })
    }

    // NOTE: views should be ordered from top to bottom
    public init(stackedElements: [StackedElement]) {
        super.init(frame: .zero)
        setupStackView(withElements: stackedElements)
    }

    private func setupStackView(withElements elements: [StackedElement]) {
        backgroundColor = .white

        addSubview(stackView)
        activateMaxSizeConstraintsOnSubview(stackView)
        stackView.axis = .vertical
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = BottomDialogStackView.calculateLayoutMargins(elements)
        stackView.spacing = BottomDialogStackView.defaultVerticalSpacing

        elements
            .map { $0.view }
            .filter { $0 != nil }
            .map { $0! }
            .forEach(stackView.addArrangedSubview)

        // Skip the first and last elements since any customSpacing instances there are handled in
        // calculateLayoutMargins()
        for index in 1 ..< elements.count - 1 {
            if let spacing = elements[index].customSpacing, let previousView = elements[index - 1].view {
                stackView.setCustomSpacing(spacing, after: previousView)
            }
        }
    }

    private static func calculateLayoutMargins(_ elements: [StackedElement]) -> UIEdgeInsets {
        let top: CGFloat
        if let firstElement = elements.first, let topInset = firstElement.customSpacing {
            top = topInset
        } else {
            top = 8.0
        }

        let bottom: CGFloat
        if let lastElement = elements.last, let bottomInset = lastElement.customSpacing {
            bottom = bottomInset
        } else {
            bottom = 16.0
        }

        return UIEdgeInsets(top: top, left: 0, bottom: bottom, right: 0)
    }

    public static func headerLabel(withText text: String) -> UILabel {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = text
        label.textAlignment = .center
        label.textColor = BottomDialogStackView.headerLabelTextColor
        return label
    }

    public static func separatorView(horizontalInset: CGFloat = 0.0) -> UIView {
        let separatorView = UIView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        separatorView.backgroundColor = BottomDialogStackView.separatorColor

        return InsetView(view: separatorView,
                         margins: UIEdgeInsets(top: 0.0, left: horizontalInset, bottom: 0.0, right: horizontalInset))
    }

    public static func insetSeparatorView() -> UIView {
        return BottomDialogStackView.separatorView(horizontalInset: 16.0)
    }

    // Returns a horizontal UIStackView with the specified left and right views. The content hugging priority is set so
    // that the right view retains its intrinsic content size while the left view is stretched to cover the remainder
    // of the row
    public static func rowWith(stretchedLeftView: UIView, rightView: UIView) -> UIView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        stackView.addArrangedSubview(stretchedLeftView)
        stackView.addArrangedSubview(rightView)

        stretchedLeftView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        rightView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return stackView
    }

    public static let defaultCancelButtonTitle =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.dialog.default-cancel-button-title")
    public static func cancelButton(
        withTitle title: String = BottomDialogStackView.defaultCancelButtonTitle
    ) -> UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitleColor(
            RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.dialog.color.cancel-button-title"),
            for: .normal
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return button
    }
}
