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

// A simple UIView that contains another UIView inset within it
open class InsetView: UIView {
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public init(view: UIView, margins: UIEdgeInsets, backgroundColor: UIColor = .white) {
        super.init(frame: .zero)

        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.topAnchor.constraint(equalTo: topAnchor, constant: margins.top).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -margins.bottom).isActive = true
        view.leftAnchor.constraint(equalTo: leftAnchor, constant: margins.left).isActive = true
        view.rightAnchor.constraint(equalTo: rightAnchor, constant: -margins.right).isActive = true
        self.backgroundColor = backgroundColor
    }
}
