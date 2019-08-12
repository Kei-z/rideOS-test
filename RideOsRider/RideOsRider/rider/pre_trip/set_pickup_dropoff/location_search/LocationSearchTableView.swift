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

public class LocationSearchTableView: UITableView {
    private static let searchResultsTableViewCellReuseId
        = "rideRider.LocationSearchTableView.searchResultsTableViewCellReuseIdentifier"
    private static let blankImageSize = CGSize(width: 20, height: 20)

    private static let primaryTextAttributes = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
        NSAttributedString.Key.foregroundColor: RideOsRiderResourceLoader.instance.getColor(
            "ai.rideos.rider.location-search.text.primary-color"
        ),
        NSAttributedString.Key.paragraphStyle: LocationSearchTableView.paragraphStyle(),
    ]

    private static let secondaryTextAttributes = [
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13),
        NSAttributedString.Key.foregroundColor: RideOsRiderResourceLoader.instance.getColor(
            "ai.rideos.rider.location-search.text.secondary-color"
        ),
    ]

    private static func paragraphStyle() -> NSParagraphStyle {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 10
        return paragraphStyle
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public init() {
        super.init(frame: .zero, style: .plain)

        separatorInset = UIEdgeInsets.zero
        backgroundColor = .white
        tableFooterView = UIView(frame: .zero)
        register(UITableViewCell.self,
                 forCellReuseIdentifier: LocationSearchTableView.searchResultsTableViewCellReuseId)
    }

    public func dequeueReusableCell(forLocationSearchOption locationSearchOption: LocationSearchOption) -> UITableViewCell {
        let cell = dequeueReusableCell(withIdentifier: LocationSearchTableView.searchResultsTableViewCellReuseId)!
        if let textLabel = cell.textLabel {
            textLabel.attributedText =
                LocationSearchTableView.labelAttributedText(forLocationSearchOption: locationSearchOption)
            textLabel.numberOfLines = 2
        }
        if let imageView = cell.imageView {
            imageView.image = LocationSearchTableView.image(forLocationSearchOption: locationSearchOption)
        }
        return cell
    }

    private static func labelAttributedText(forLocationSearchOption locationSearchOption: LocationSearchOption)
        -> NSAttributedString {
        switch locationSearchOption {
        case let .autocompleteLocation(autocompleteLocation), let .historical(autocompleteLocation):
            let string = NSMutableAttributedString(string: autocompleteLocation.primaryText,
                                                   attributes: LocationSearchTableView.primaryTextAttributes)
            string.append(NSAttributedString(string: "\n" + autocompleteLocation.secondaryText,
                                             attributes: LocationSearchTableView.secondaryTextAttributes))
            return string
        case .currentLocation, .selectOnMap:
            return NSAttributedString(string: locationSearchOption.displayName(),
                                      attributes: LocationSearchTableView.primaryTextAttributes)
        }
    }

    private static func image(forLocationSearchOption locationSearchOption: LocationSearchOption) -> UIImage {
        switch locationSearchOption {
        case .autocompleteLocation:
            return BlankImage.of(size: LocationSearchTableView.blankImageSize)
        case .currentLocation:
            return RiderImages.greyDotInCrosshairs()
        case .selectOnMap:
            return RiderImages.paperMap()
        case .historical:
            return RiderImages.clock()
        }
    }
}
