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
import NotificationBannerSwift
import Reachability
import RideOsApi
import RxReachability
import RxSwift

public class LowConnectivityMonitor {
    private static let lowConnectivityBannerBaseHeight: CGFloat = 32.0

    private let disposeBag = DisposeBag()
    private let reachability = Reachability(hostname: RideOsApiHost.getApiHost())
    private let lowConnectivityBanner = LowConnectivityMonitor.lowConnectivityBanner()

    private let schedulerProvider: SchedulerProvider

    public init(schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.schedulerProvider = schedulerProvider
    }

    public func beginMonitoringNetworkConnectivity(parentViewController: UIViewController) {
        try? reachability?.startNotifier()

        Reachability.rx.isReachable
            .observeOn(schedulerProvider.mainThread())
            .distinctUntilChanged()
            .subscribe(onNext: { [unowned self, unowned parentViewController] in
                if $0 {
                    self.lowConnectivityBanner.dismiss()
                } else {
                    // NOTE: We set the height when we display the banner instead of at initialization because
                    // safeAreaInsets isn't yet set properly then
                    self.lowConnectivityBanner.bannerHeight = LowConnectivityMonitor.lowConnectivityBannerBaseHeight
                        + parentViewController.view.safeAreaInsets.top
                    self.lowConnectivityBanner.show(on: parentViewController)
                }
            })
            .disposed(by: disposeBag)
    }
}

extension LowConnectivityMonitor {
    private static func lowConnectivityBanner() -> NotificationBanner {
        let banner = NotificationBanner(customView: LowConnectivityBannerView())
        banner.autoDismiss = false
        return banner
    }
}
