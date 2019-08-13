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

public class LocationSearchTextField: UITextField {
    private static let textFieldBackgroundColor =
        RideOsRiderResourceLoader.instance.getColor("ai.rideos.rider.location-search.text-field.background-color")
    private static let leftViewPadding: CGFloat = 8.0

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public init(leftImage: UIImage) {
        super.init(frame: .zero)

        leftViewMode = .always
        borderStyle = .roundedRect
        clearButtonMode = .whileEditing
        backgroundColor = LocationSearchTextField.textFieldBackgroundColor
        clearsOnBeginEditing = true
        autocorrectionType = .no
        autocapitalizationType = .none

        let imageView = UIImageView(image: leftImage)
        if let size = imageView.image?.size {
            // Offset the image by leftViewPadding to the right
            imageView.frame = CGRect(x: 0.0,
                                     y: 0.0,
                                     width: size.width + LocationSearchTextField.leftViewPadding,
                                     height: size.height)
        }
        imageView.contentMode = .right
        leftView = imageView
    }
}
