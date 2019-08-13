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

public class ResourceLoader {
    private let fallbackBundle: Bundle

    public convenience init(frameworkBundle: Bundle, bundleName: String) {
        guard let bundlePath = frameworkBundle.path(forResource: bundleName, ofType: "bundle"),
            let bundle = Bundle(path: bundlePath) else {
            fatalError("Unable to load bundle \(bundleName)")
        }
        self.init(fallbackBundle: bundle)
    }

    public init(fallbackBundle: Bundle) {
        self.fallbackBundle = fallbackBundle
    }

    public func getString(_ key: String) -> String {
        // First, try to read the string from the main Bundle in case the user has provided an override
        let localizedFromMainBundle = NSLocalizedString(key, bundle: .main, comment: "")
        if localizedFromMainBundle != key {
            return localizedFromMainBundle
        }

        // If the string isn't in the main bundle, read it from the current bundle
        return NSLocalizedString(key, bundle: fallbackBundle, comment: "")
    }

    public func getColor(_ key: String) -> UIColor {
        if let color = UIColor(named: key, in: .main, compatibleWith: nil) {
            return color
        }

        guard let color = UIColor(named: key, in: fallbackBundle, compatibleWith: nil) else {
            fatalError("Unable to find color \(key)")
        }

        return color
    }

    public func getImage(_ key: String) -> UIImage {
        if let image = UIImage(named: key, in: .main, compatibleWith: nil) {
            return image
        }

        guard let image = UIImage(named: key, in: fallbackBundle, compatibleWith: nil) else {
            fatalError("Unable to find image \(key)")
        }

        return image
    }
}
