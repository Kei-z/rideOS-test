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

public class RequestingTripDialog: BottomDialogStackView {
    private static let headerText = RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.requesting-trip.header")

    private let pickupDropoffLabelView = PickupDropoffLabelView()
    private let cancelButton = BottomDialogStackView.cancelButton()

    public var pickupText: String? {
        get {
            return pickupDropoffLabelView.pickupText
        }
        set {
            pickupDropoffLabelView.pickupText = newValue
        }
    }

    public var dropoffText: String? {
        get {
            return pickupDropoffLabelView.dropoffText
        }
        set {
            pickupDropoffLabelView.dropoffText = newValue
        }
    }

    public var cancelButtonTapEvents: ControlEvent<Void> {
        return cancelButton.rx.tap
    }

    public init(pickupText: String? = nil, dropoffText: String? = nil) {
        super.init(stackedElements: [
            .view(view: BottomDialogStackView.headerLabel(withText: RequestingTripDialog.headerText)),
            .customSpacing(spacing: 8.0),
            .view(view: IndeterminateProgressView()),
            .customSpacing(spacing: 20.0),
            .view(view: pickupDropoffLabelView),
            .customSpacing(spacing: 37.0),
            .view(view: cancelButton),
        ])

        self.pickupText = pickupText
        self.dropoffText = dropoffText
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}
