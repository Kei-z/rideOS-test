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

public class ConfirmTripDialog: BottomDialogStackView {
    private let timeAndDistanceLabel = UILabel()
    private let progressView = IndeterminateProgressView()

    public var timeAndDistanceAttributedText: NSAttributedString? {
        get {
            return timeAndDistanceLabel.attributedText
        }
        set {
            timeAndDistanceLabel.attributedText = newValue
        }
    }

    public func set(isAnimatingProgress: Bool) {
        progressView.set(isAnimatingProgress: isAnimatingProgress)
    }

    public var isRequestRideButtonEnabled: Bool {
        get {
            return requestRideButton.isButtonEnabled
        }
        set {
            requestRideButton.isButtonEnabled = newValue
        }
    }

    private let requestRideButton = StackedActionButtonContainerView(
        title: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-trip.request-ride-button-title")
    )

    public var requestRideButtonTapEvents: ControlEvent<Void> {
        return requestRideButton.tapEvents
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(pickupString: String, dropoffString: String) {
        timeAndDistanceLabel.textAlignment = .center

        super.init(stackedElements: [
            .customSpacing(spacing: 6.0),
            .view(view: timeAndDistanceLabel),
            .customSpacing(spacing: 7.0),
            .view(view: progressView),
            .customSpacing(spacing: 24.0),
            .view(view: PickupDropoffLabelView(pickupString: pickupString, dropoffString: dropoffString)),
            .customSpacing(spacing: 24.0),
            .view(view: requestRideButton),
        ])
    }
}
