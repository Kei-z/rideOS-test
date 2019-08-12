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

public class ConfirmSeatsDialog: BottomDialogStackView {
    private let actionButton = StackedActionButtonContainerView(
        title: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-seats.button-title")
    )

    private let seatSelectionView = SeatSelectionView()

    public var selectedSeatCount: UInt32 {
        return seatSelectionView.selectedSeatCount
    }

    public var confirmButtonTapEvents: ControlEvent<Void> {
        return actionButton.tapEvents
    }

    public init() {
        super.init(stackedElements: [
            .customSpacing(spacing: 13),
            .view(view: ConfirmSeatsDialog.numberOfRidersLabel()),
            .customSpacing(spacing: 19),
            .view(view: seatSelectionView),
            .customSpacing(spacing: 23),
            .view(view: actionButton),
            .customSpacing(spacing: 13),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension ConfirmSeatsDialog {
    private static func numberOfRidersLabel() -> UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-seats.label")
        return label
    }
}
