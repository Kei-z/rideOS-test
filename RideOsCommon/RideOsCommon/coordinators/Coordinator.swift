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

open class Coordinator: EncodedStateProvider {
    public let navigationController: UINavigationController

    // Keep a strong reference to the child Coordinator so it doesn't get de-allocated
    private var activeChildCoordinator: Coordinator?

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    open func activate() {
        fatalError("Coordinator does not implement \(#function). Its subclasses should")
    }

    public func showChild(viewController: UIViewController) {
        navigationController.popViewController(animated: false)
        navigationController.pushViewController(viewController, animated: false)

        // Release our strong reference to the previous coordinator (if any)
        activeChildCoordinator = nil
    }

    public func showChild(coordinator: Coordinator) {
        coordinator.activate()
        activeChildCoordinator = coordinator
    }

    open func encodedState(_ encoder: JSONEncoder) -> Data? {
        if let child = activeChildCoordinator {
            return child.encodedState(encoder)
        }

        if let child = navigationController.topViewController as? EncodedStateProvider {
            return child.encodedState(encoder)
        }

        return nil
    }
}
