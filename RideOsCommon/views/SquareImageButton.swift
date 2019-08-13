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
import RxCocoa

public class SquareImageButton: UIView {
    private let button = UIButton()

    public var tapEvents: ControlEvent<Void> {
        return button.rx.tap
    }

    public init(image: UIImage, backgroundColor: UIColor = .white, enableShadows: Bool = true) {
        super.init(frame: .zero)

        addSubview(button)
        activateMaxSizeConstraintsOnSubview(button)
        if enableShadows {
            Shadows.enableShadows(onView: self)
        }
        self.backgroundColor = backgroundColor
        button.setImage(image, for: .normal)
    }

    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
