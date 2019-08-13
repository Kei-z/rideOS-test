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

public class IdleDialogView: BottomDialogStackView {
    private static let headerLabelText =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.online.idle-header-title")
    private static let goOfflineButtonTitle =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.online.go-offline-button.title")

    public var goOfflineTapEvents: ControlEvent<Void> {
        return goOfflineButton.tapEvents
    }

    private let headerLabel = BottomDialogStackView.headerLabel(withText: IdleDialogView.headerLabelText)
    private let goOfflineButton = StackedActionButtonContainerView(title: IdleDialogView.goOfflineButtonTitle)

    public init() {
        super.init(stackedViews: [
            headerLabel,
            goOfflineButton,
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}