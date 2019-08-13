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

import Eureka
import Foundation
import UIKit

class AccountSettingsFormViewController: FormViewController {
    private let userStorageReader: UserStorageReader
    private let userStorageWriter: UserStorageWriter
    private let userEmailAddress: String?

    init(userStorageReader: UserStorageReader,
         userStorageWriter: UserStorageWriter,
         userEmailAddress: String?) {
        self.userStorageReader = userStorageReader
        self.userStorageWriter = userStorageWriter
        self.userEmailAddress = userEmailAddress
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) is unimplemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = MainSettingsFormViewController.editProfileString

        let preferredNameSectionTitle = RideOsCommonResourceLoader.instance.getString(
            "ai.rideos.common.settings.account.preferred-name"
        )
        form +++ Section(preferredNameSectionTitle)
            <<< TextRow { [userStorageReader] row in
                row.value = userStorageReader.get(CommonUserStorageKeys.preferredName)
            }.onChange { [userStorageWriter] row in
                userStorageWriter.set(key: CommonUserStorageKeys.preferredName, value: row.value)
            }

        let emailAddressSectionTitle = RideOsCommonResourceLoader.instance.getString(
            "ai.rideos.common.settings.account.email-address"
        )
        form +++ Section(emailAddressSectionTitle)
            <<< LabelRow { row in
                row.title = userEmailAddress
                row.baseCell.backgroundColor = self.tableView.backgroundColor
            }
    }
}
