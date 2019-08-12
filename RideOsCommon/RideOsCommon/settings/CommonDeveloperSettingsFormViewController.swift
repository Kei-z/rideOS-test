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
import RideOsApi
import RxSwift

open class CommonDeveloperSettingsFormViewController: FormViewController {
    private enum Tags {
        static let fleetIdSelectorRow = "fleet_id_selector"
        static let fleetIdLabelRow = "fleet_id_label"
    }

    private let disposeBag = DisposeBag()

    // public so that subclasses have access
    public let userStorageReader: UserStorageReader
    public let userStorageWriter: UserStorageWriter

    private let fleetSelectionViewModel: FleetSelectionViewModel
    private let schedulerProvider: SchedulerProvider

    public required init?(coder _: NSCoder) {
        fatalError("\(#function) is unimplemented")
    }

    public init(userStorageReader: UserStorageReader,
                userStorageWriter: UserStorageWriter,
                fleetSelectionViewModel: FleetSelectionViewModel,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.userStorageReader = userStorageReader
        self.userStorageWriter = userStorageWriter
        self.fleetSelectionViewModel = fleetSelectionViewModel
        self.schedulerProvider = schedulerProvider
        super.init(nibName: nil, bundle: nil)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = MainSettingsFormViewController.developerSettingsString

        setupForm()

        fleetSelectionViewModel
            .availableFleets
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] fleetOptions in
                // swiftlint:disable force_cast
                let row = self.form.rowBy(tag: Tags.fleetIdSelectorRow) as! PushRow<FleetOption>
                // swiftlint:enable force_cast

                row.options = fleetOptions
                row.updateCell()
            })
            .disposed(by: disposeBag)

        fleetSelectionViewModel.resolvedFleet
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] fleetInfo in
                // swiftlint:disable force_cast
                let row = self.form.rowBy(tag: Tags.fleetIdLabelRow) as! LabelRow
                // swiftlint:enable force_cast
                row.title = fleetInfo.fleetId
                row.updateCell()
            })
            .disposed(by: disposeBag)
    }

    private func setupForm() {
        let appRestartSectionTitle = RideOsCommonResourceLoader.instance.getString(
            "ai.rideos.common.settings.developer.app-restart"
        )
        form +++ Section(appRestartSectionTitle)

        let environmentSectionTitle = RideOsCommonResourceLoader.instance.getString(
            "ai.rideos.common.settings.developer.environment-section"
        )
        form +++ Section(environmentSectionTitle)
            <<< PushRow<ServiceDefaultsValue> { row in
                let environmentTitle = RideOsCommonResourceLoader.instance.getString(
                    "ai.rideos.common.settings.developer.environment-title"
                )
                row.title = environmentTitle
                row.options = [.production, .staging, .development]
                row.value = self.userStorageReader.environment
                row.displayValueFor = {
                    guard let value = $0 else {
                        return nil
                    }

                    switch value {
                    case .production:
                        return RideOsCommonResourceLoader.instance
                            .getString("ai.rideos.common.settings.developer.environment.production")
                    case .staging:
                        return RideOsCommonResourceLoader.instance
                            .getString("ai.rideos.common.settings.developer.environment.staging")
                    case .development:
                        return RideOsCommonResourceLoader.instance
                            .getString("ai.rideos.common.settings.developer.environment.development")
                    }
                }
            }
            .onChange { row in
                if let value = row.value {
                    self.userStorageWriter.set(environment: value)
                    row.updateCell()
                }
            }

        setupFleetFormSection()
    }

    private func setupFleetFormSection() {
        let fleetSelectionSectionTitle = RideOsCommonResourceLoader.instance.getString(
            "ai.rideos.common.settings.developer.fleet-section"
        )
        form +++ Section(fleetSelectionSectionTitle)
            <<< PushRow<FleetOption> { row in
                row.title =
                    RideOsCommonResourceLoader.instance.getString("ai.rideos.common.settings.developer.fleet-title")
                row.selectorTitle =
                    RideOsCommonResourceLoader.instance.getString("ai.rideos.common.settings.developer.fleet-selector")
                row.options = []
                row.value = self.userStorageReader.fleetOption
                row.tag = Tags.fleetIdSelectorRow
                row.displayValueFor = {
                    guard let value = $0 else {
                        return nil
                    }
                    return value.displayName
                }
            }
            .onPresent { _, selectorController in selectorController.enableDeselection = false }
            .onChange { row in
                if let fleet = row.value {
                    self.fleetSelectionViewModel.select(fleetOption: fleet)
                } else {
                    fatalError("Invalid FleetOption")
                }
            }

        let activeFleetSectionTitle = RideOsCommonResourceLoader.instance.getString(
            "ai.rideos.common.settings.developer.active-fleet-id-section-title"
        )

        form +++ Section(activeFleetSectionTitle)
            <<< LabelRow { row in
                row.tag = Tags.fleetIdLabelRow
                row.baseCell.backgroundColor = self.tableView.backgroundColor
            }
    }

    private static func environment(from serviceDefaultsValue: ServiceDefaultsValue) -> String {
        switch serviceDefaultsValue {
        case .production:
            return NSLocalizedString("Production", comment: "Production environment name")
        case .staging:
            return NSLocalizedString("Staging", comment: "Staging environment name")
        case .development:
            return NSLocalizedString("Development", comment: "Development environment name")
        }
    }
}
