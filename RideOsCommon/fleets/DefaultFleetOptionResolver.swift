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
import Foundation
import RxSwift
import RxSwiftExt

public class DefaultFleetOptionResolver: FleetOptionResolver {
    private static let fleetInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)

    private let fleetInteractor: FleetInteractor
    private let deviceLocator: DeviceLocator
    private let schedulerProvider: SchedulerProvider
    private let logger: Logger

    public init(fleetInteractor: FleetInteractor = CommonDependencyRegistry.instance.commonDependencyFactory.fleetInteractor,
                deviceLocator: DeviceLocator = CoreLocationDeviceLocator(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.fleetInteractor = fleetInteractor
        self.deviceLocator = deviceLocator
        self.schedulerProvider = schedulerProvider
        self.logger = logger
    }

    public func resolve(fleetOption: FleetOption) -> Observable<FleetInfoResolutionResponse> {
        switch fleetOption {
        case .automatic:
            return resolveAutomatic()
                .map { FleetInfoResolutionResponse(fleetInfo: $0, wasRequestedFleetAvailable: true) }
        case let .manual(fleet):
            // Note: We need to specify the full prototype for the lambda because the compiler is not smart enough to
            // figure out the return type with an "if" statement in the lambda
            return availableFleets
                .observeOn(schedulerProvider.computation())
                .flatMap { [unowned self] (availableFleets: [FleetInfo]) -> Observable<FleetInfoResolutionResponse> in
                    if let index = availableFleets.firstIndex(where: { $0.fleetId == fleet.fleetId }) {
                        return Observable.just(FleetInfoResolutionResponse(fleetInfo: availableFleets[index],
                                                                           wasRequestedFleetAvailable: true))
                    }
                    // If the specified fleet is in not the list of available fleets, treat it as if the user chose
                    // "automatic" fleet selection but set wasRequestedFleetAvailable to false
                    return self.resolveAutomatic()
                        .map { FleetInfoResolutionResponse(fleetInfo: $0, wasRequestedFleetAvailable: false) }
                }
        }
    }

    private var availableFleets: Observable<[FleetInfo]> {
        return fleetInteractor
            .availableFleets
            .subscribeOn(schedulerProvider.io())
            .logErrors(logger: logger)
            .retry(DefaultFleetOptionResolver.fleetInteractorRepeatBehavior)
            .catchErrorJustReturn([FleetInfo.defaultFleetInfo])
    }

    private func resolveAutomatic() -> Observable<FleetInfo> {
        return Observable
            .combineLatest(
                deviceLocator.observeCurrentLocation().map { $0.coordinate },
                availableFleets
            )
            .subscribeOn(schedulerProvider.io())
            .observeOn(schedulerProvider.computation())
            .map { location, availableFleets in
                DefaultFleetOptionResolver.findBestFleet(location: location,
                                                         availableFleets: availableFleets) ?? FleetInfo.defaultFleetInfo
            }
    }

    private static func findBestFleet(location: CLLocationCoordinate2D, availableFleets: [FleetInfo]) -> FleetInfo? {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let fleetSortFunc = { (left: FleetInfo, right: FleetInfo) throws -> Bool in
            guard let leftCenter = left.center, let rightCenter = right.center else {
                fatalError("Center coordinates not specified")
            }
            let leftLocation = CLLocation(latitude: leftCenter.latitude, longitude: leftCenter.longitude)
            let rightLocation = CLLocation(latitude: rightCenter.latitude, longitude: rightCenter.longitude)

            return clLocation.distance(from: leftLocation) < clLocation.distance(from: rightLocation)
        }

        let availableFleetsWithCenters = availableFleets.filter { $0.center != nil }

        // Default to picking the closest real (non-phantom) fleet
        let sortedRealFleets = try? availableFleetsWithCenters.filter { !$0.isPhantom }.sorted(by: fleetSortFunc)
        if let bestRealFleet = sortedRealFleets?.first {
            return bestRealFleet
        }

        // If there are no real fleets, pick the closest fleet of any type (including phantom)
        let sortedAllFleets = try? availableFleetsWithCenters.sorted(by: fleetSortFunc)
        if let bestFleet = sortedAllFleets?.first {
            return bestFleet
        }

        return nil
    }
}
