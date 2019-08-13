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
import StoreKit

public class DefaultUrlLauncher: NSObject, UrlLauncher, SKStoreProductViewControllerDelegate {
    private static let contactFailedAlertTitle =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.url-launcher.failure")
    private static let contactFailedAlertMessageFormat =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.url-launcher.unknown-scheme.format")

    private let application: UIApplication

    public init(application: UIApplication = UIApplication.shared) {
        self.application = application
    }

    public func launch(url: URL, parentViewController: UIViewController) {
        if application.canOpenURL(url) {
            application.open(url, options: [:], completionHandler: nil)
        } else {
            if let scheme = url.scheme, let appStoreId = KnownAppSchemes.schemeToAppStoreId[scheme] {
                presentAppStore(productId: appStoreId, scheme: scheme, parentViewController: parentViewController)
            } else {
                presentUnknownSchemeAlert(scheme: url.scheme, parentViewController: parentViewController)
            }
        }
    }

    private func presentUnknownSchemeAlert(scheme: String?, parentViewController: UIViewController) {
        parentViewController.showErrorAlert(
            title: DefaultUrlLauncher.contactFailedAlertTitle,
            message: String(format: DefaultUrlLauncher.contactFailedAlertMessageFormat, scheme ?? "unknown")
        )
    }

    private func presentAppStore(productId: String, scheme: String, parentViewController: UIViewController) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self

        let loadProductParameters = [SKStoreProductParameterITunesItemIdentifier: productId]
        storeViewController.loadProduct(withParameters: loadProductParameters) { result, _ in
            if result {
                parentViewController.present(storeViewController, animated: true, completion: nil)
            } else {
                self.presentUnknownSchemeAlert(scheme: scheme, parentViewController: parentViewController)
            }
        }
    }

    public func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}
