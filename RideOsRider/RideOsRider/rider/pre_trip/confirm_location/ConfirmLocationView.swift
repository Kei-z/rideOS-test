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

public class ConfirmLocationView: BottomDialogStackView {
    private let geocodedLocationLabel: AddressConfirmationView
    private let confirmLocationButton: StackedActionButtonContainerView
    private let progressView = IndeterminateProgressView()

    public var confirmLocationButtonTapEvents: ControlEvent<Void> {
        return confirmLocationButton.tapEvents
    }

    public var editButtonTapEvents: ControlEvent<Void> {
        return geocodedLocationLabel.editButtonTapEvents
    }

    public var locationLabelTextBinder: Binder<String?> {
        return geocodedLocationLabel.labelTextBinder
    }

    public var isConfirmLocationButtonEnabled: Bool {
        get {
            return confirmLocationButton.isButtonEnabled
        }
        set {
            confirmLocationButton.isButtonEnabled = newValue
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(headerText: String, buttonText: String, showEditButton: Bool) {
        geocodedLocationLabel = AddressConfirmationView(showEditButton: showEditButton)
        progressView.heightAnchor.constraint(equalToConstant: 2.0).isActive = true

        confirmLocationButton = StackedActionButtonContainerView(title: buttonText)

        super.init(stackedElements: [
            .view(view: BottomDialogStackView.headerLabel(withText: headerText)),
            .view(view: progressView),
            .customSpacing(spacing: 24.0),
            .view(view: geocodedLocationLabel),
            .customSpacing(spacing: 24.0),
            .view(view: confirmLocationButton),
        ])
    }

    public func set(isAnimatingProgress: Bool) {
        progressView.set(isAnimatingProgress: isAnimatingProgress)
    }
}
