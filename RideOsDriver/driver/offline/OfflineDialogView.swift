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

import RideOsCommon
import RxCocoa
import UIKit

public class OfflineDialogView: BottomDialogStackView {
    private static let headerLabelText =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.offline.header-text")
    private static let goOnlineButtonTitle =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.offline.go-online-button.title")

    public var goOnlineTapEvents: ControlEvent<Void> {
        return goOnlineButton.tapEvents
    }

    private let headerLabel = BottomDialogStackView.headerLabel(withText: OfflineDialogView.headerLabelText)
    private let goOnlineButton = StackedActionButtonContainerView(title: OfflineDialogView.goOnlineButtonTitle)

    public init() {
        super.init(stackedViews: [
            headerLabel,
            goOnlineButton,
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}
