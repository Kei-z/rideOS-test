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
import NicoProgress

public class IndeterminateProgressView: UIView {
    private let separatorView = BottomDialogStackView.separatorView()
    private let progressView = NicoProgressBar()

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func set(isAnimatingProgress: Bool) {
        progressView.isHidden = !isAnimatingProgress
    }

    public init() {
        super.init(frame: .zero)
        addSubview(separatorView)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        separatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true

        addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        progressView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        progressView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        progressView.heightAnchor.constraint(lessThanOrEqualToConstant: 2.0).isActive = true

        progressView.transition(to: .indeterminate)
        progressView.primaryColor =
            RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.indeterminate-progress-bar.color.primary")
        progressView.secondaryColor =
            RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.indeterminate-progress-bar.color.secondary")

        set(isAnimatingProgress: true)
    }
}
