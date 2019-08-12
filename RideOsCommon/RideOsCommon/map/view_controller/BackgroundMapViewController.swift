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
import RxSwift

// A view controller that contains a MapViewController as one of its children. The MapViewController's view will
// be sized to cover this view controller's entire view and will be sent to the back-most z-level. If a MapStateProvider
// and (optionally) a MapCenterListener are provided, will connect them to the underlying MapViewController's MapView
// when appropriate.
open class BackgroundMapViewController: UIViewController {
    private static let directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20,
                                                                          leading: 16,
                                                                          bottom: 16,
                                                                          trailing: 16)
    private static let dialogViewBottomConstraintId = "BottomDialogStackViewBottomConstraintId"
    private static let dialogViewAnimationDuration: CFTimeInterval = 0.2

    public let mapViewController: MapViewController
    private let showSettingsButton: Bool

    public init(mapViewController: MapViewController,
                showSettingsButton: Bool = true) {
        self.mapViewController = mapViewController
        self.showSettingsButton = showSettingsButton
        super.init(nibName: nil, bundle: nil)

        mapViewController.view.preservesSuperviewLayoutMargins = true

        view.directionalLayoutMargins = BackgroundMapViewController.directionalLayoutMargins
    }

    public required init?(coder _: NSCoder) {
        fatalError("BackgroundMapViewController does not support NSCoder")
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // TODO(chrism): It's unclear why this is necessary, but there are cases where viewWillAppear is called while
        // the map view is still a subview of a different parent view controller's view
        if mapViewController.view.superview != nil {
            mapViewController.view.removeFromSuperview()
        }

        addChild(mapViewController)
        view.addSubview(mapViewController.view)
        view.sendSubviewToBack(mapViewController.view)
        view.activateMaxSizeConstraintsOnSubview(mapViewController.view)
        mapViewController.didMove(toParent: self)

        mapViewController.showSettingsButton = showSettingsButton
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        mapViewController.willMove(toParent: nil)
        mapViewController.view.removeFromSuperview()
        mapViewController.removeFromParent()
    }

    public func presentBottomDialogStackView(_ dialogView: BottomDialogStackView, completion: (() -> Void)? = nil) {
        view.addSubview(dialogView)
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        dialogView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        dialogView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        let dialogViewBottomConstraint = dialogView.bottomAnchor.constraint(equalTo: view.bottomAnchor,
                                                                            constant: view.frame.height)
        dialogViewBottomConstraint.identifier = BackgroundMapViewController.dialogViewBottomConstraintId
        dialogViewBottomConstraint.isActive = true

        view.layoutIfNeeded()

        UIView.animate(withDuration: BackgroundMapViewController.dialogViewAnimationDuration, animations: {
            dialogViewBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }, completion: { [mapViewController] _ in
            mapViewController.mapInsets = UIEdgeInsets(top: 0, left: 0, bottom: dialogView.frame.height, right: 0)
            completion?()
        })
    }

    public func dismissBottomDialogStackView(_ dialogView: BottomDialogStackView) {
        if dialogView.superview !== view {
            return
        }

        view.layoutIfNeeded()

        mapViewController.mapInsets = UIEdgeInsets.zero

        UIView.animate(withDuration: BackgroundMapViewController.dialogViewAnimationDuration, animations: {
            if let bottomDialogViewConstraint = self.view.constraints.first(where: {
                $0.identifier == BackgroundMapViewController.dialogViewBottomConstraintId
            }) {
                bottomDialogViewConstraint.constant = self.view.frame.height
            }
        }, completion: { [mapViewController] _ in
            mapViewController.mapInsets = UIEdgeInsets.zero
            dialogView.removeFromSuperview()
        })
    }
}
