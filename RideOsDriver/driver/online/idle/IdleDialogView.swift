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
    private static let progressLabelText =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.online.idle.go-offline-progress-text")
    private static let headerLabelText =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.online.idle.header-title")
    private static let goOfflineButtonTitle =
        RideOsDriverResourceLoader.instance.getString("ai.rideos.driver.online.idle.go-offline-button.title")

    public var goOfflineTapEvents: ControlEvent<Void> {
        return goOfflineButton.tapEvents
    }

    public var isGoOfflineButtonEnabled: Bool {
        get {
            return goOfflineButton.isButtonEnabled
        }
        set {
            goOfflineButton.isButtonEnabled = newValue
        }
    }

    private let progressLabel = BottomDialogStackView.headerLabel(withText: IdleDialogView.progressLabelText)
    private let progressIndicatorView = IndeterminateProgressView()
    private let headerLabel = BottomDialogStackView.headerLabel(withText: IdleDialogView.headerLabelText)
    private let goOfflineButton = StackedActionButtonContainerView(title: IdleDialogView.goOfflineButtonTitle)

    public init() {
        super.init(stackedElements: [
            .view(view: progressLabel),
            .customSpacing(spacing: 8.0),
            .view(view: progressIndicatorView),
            .customSpacing(spacing: 16.0),
            .view(view: headerLabel),
            .view(view: goOfflineButton),
        ])
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public func set(isAnimatingProgress: Bool) {
        progressLabel.isHidden = !isAnimatingProgress
        progressIndicatorView.isHidden = !isAnimatingProgress
        progressIndicatorView.set(isAnimatingProgress: isAnimatingProgress)
    }
}
