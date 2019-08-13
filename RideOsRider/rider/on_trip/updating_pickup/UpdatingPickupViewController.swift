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

public class UpdatingPickupViewController: BackgroundMapViewController {
    private let dialogView = UpdatingPickupDialog()

    public init(mapViewController: MapViewController) {
        super.init(mapViewController: mapViewController, showSettingsButton: false)
    }

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) is unimplemented")
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentBottomDialogStackView(dialogView)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBottomDialogStackView(dialogView)
    }
}
