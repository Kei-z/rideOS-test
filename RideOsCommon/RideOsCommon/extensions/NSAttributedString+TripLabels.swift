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

import CoreLocation

extension NSAttributedString {
    private static let defaultSystemFont = UIFont.systemFont(ofSize: 16)

    private static func defaultParagraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        return paragraphStyle
    }

    public static func milesAndMinutesLabelWith(
        meters: CLLocationDistance,
        timeInterval: TimeInterval
    ) -> NSAttributedString {
        let label = NSMutableAttributedString(
            string: NSLocalizedString(
                String.minutesLabelWith(timeInterval: timeInterval), comment: "Minutes label"
            ),
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 22, weight: .semibold),
                         NSAttributedString.Key.paragraphStyle: NSAttributedString.defaultParagraphStyle()]
        )

        label.append(NSAttributedString(
            string: NSLocalizedString(String(format: " (%@)", String.milesLabelWith(meters: meters)),
                                      comment: "Miles label"),
            attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                         NSAttributedString.Key.foregroundColor: UIColor.gray]
        ))

        return label
    }

    public static func minutesLabelWith(timeInterval: TimeInterval) -> NSAttributedString {
        return NSAttributedString(
            string: NSLocalizedString(String.minutesLabelWith(timeInterval: timeInterval), comment: "Minutes label"),
            attributes: [NSAttributedString.Key.font: defaultSystemFont,
                         NSAttributedString.Key.paragraphStyle: NSAttributedString.defaultParagraphStyle()]
        )
    }
}
