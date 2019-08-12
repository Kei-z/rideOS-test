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

public class LowConnectivityBannerView: UIView {
    private static let bannerColor =
        RideOsCommonResourceLoader.instance.getColor("ai.rideos.common.low-connectivity.color.banner")
    private static let labelBottomOffset: CGFloat = -9.0

    private let label = LowConnectivityBannerView.label()

    public init() {
        super.init(frame: .zero)
        backgroundColor = LowConnectivityBannerView.bannerColor

        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.bottomAnchor.constraint(equalTo: bottomAnchor,
                                      constant: LowConnectivityBannerView.labelBottomOffset).isActive = true
        label.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
}

extension LowConnectivityBannerView {
    private static func label() -> UILabel {
        let label = UILabel()
        label.text = RideOsCommonResourceLoader.instance.getString("ai.rideos.common.low-connectivity.message")
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }
}
