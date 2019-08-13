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

public class TripCompletedDialog: BottomDialogStackView {
    private let confirmButton =
        StackedActionButtonContainerView(title: NSLocalizedString("Done",
                                                                  comment: "Trip completion confirmation button title"))

    public var confirmButtonTapEvents: ControlEvent<Void> {
        return confirmButton.tapEvents
    }

    public init(dropoffDisplayName: String) {
        super.init(stackedElements: [
            .customSpacing(spacing: 24),
            .view(view: TripCompletedDialog.headerLabel()),
            .customSpacing(spacing: 11),
            .view(view: TripCompletedDialog.dropoffLabel(dropoffDisplayName)),
            .customSpacing(spacing: 24),
            .view(view: confirmButton),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension TripCompletedDialog {
    private static func headerLabel() -> UILabel {
        return BottomDialogStackView.headerLabel(
            withText: NSLocalizedString("You've arrived at your destination",
                                        comment: "Trip completed dialog header text")
        )
    }

    private static func dropoffLabel(_ dropoffDisplayName: String) -> UILabel {
        let label = UILabel()
        label.text = dropoffDisplayName
        label.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        label.textAlignment = .center
        return label
    }
}
