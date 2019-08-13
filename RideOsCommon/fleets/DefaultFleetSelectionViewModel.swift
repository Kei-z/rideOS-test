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
import RxSwiftExt

public class DefaultFleetSelectionViewModel: FleetSelectionViewModel {
    private static let fleetInteractorRepeatBehavior: RepeatBehavior = .immediate(maxCount: 5)

    private let disposeBag = DisposeBag()

    private let fleetInteractor: FleetInteractor
    private let fleetOptionResolver: FleetOptionResolver
    private let userStorageWriter: UserStorageWriter
    private let selectedFleetOptionSubject: BehaviorSubject<FleetOption>
    private let schedulerProvider: SchedulerProvider
    private let fleetInfoResolutionResponseObservable: Observable<FleetInfoResolutionResponse>
    private let logger: Logger

    public convenience init(fleetInteractor: FleetInteractor = CommonDependencyRegistry.instance.commonDependencyFactory.fleetInteractor,
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.init(fleetInteractor: fleetInteractor,
                  fleetOptionResolver: DefaultFleetOptionResolver(fleetInteractor: fleetInteractor),
                  userStorageWriter: UserDefaultsUserStorageWriter(),
                  userStorageReader: UserDefaultsUserStorageReader(),
                  schedulerProvider: schedulerProvider)
    }

    public init(fleetInteractor: FleetInteractor,
                fleetOptionResolver: FleetOptionResolver,
                userStorageWriter: UserStorageWriter,
                userStorageReader: UserStorageReader,
                schedulerProvider: SchedulerProvider,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.fleetInteractor = fleetInteractor
        self.fleetOptionResolver = fleetOptionResolver
        self.userStorageWriter = userStorageWriter
        selectedFleetOptionSubject = BehaviorSubject(value: userStorageReader.fleetOption)
        self.schedulerProvider = schedulerProvider
        self.logger = logger

        fleetInfoResolutionResponseObservable = selectedFleetOptionSubject
            .flatMapLatest { [fleetOptionResolver] selectedFleet in
                fleetOptionResolver.resolve(fleetOption: selectedFleet)
            }
            .share(replay: 1)

        // Whenever a the FleetOptionResolver indicates wasRequestedFleetAvailable == false (i.e. the FleetOption.manual
        // is no longer valid), reset the stored FleetOption to .automatic
        fleetInfoResolutionResponseObservable
            .observeOn(schedulerProvider.computation())
            .filter { !$0.wasRequestedFleetAvailable }
            .subscribe(onNext: { [userStorageWriter] _ in userStorageWriter.set(fleetOption: .automatic) })
            .disposed(by: disposeBag)
    }

    public var availableFleets: Observable<[FleetOption]> {
        return fleetInteractor
            .availableFleets
            .subscribeOn(schedulerProvider.io())
            .logErrors(logger: logger)
            .retry(DefaultFleetSelectionViewModel.fleetInteractorRepeatBehavior)
            .observeOn(schedulerProvider.computation())
            .map {
                [FleetOption.automatic] + $0.map(DefaultFleetSelectionViewModel.toFleetOption)
            }
    }

    public func select(fleetOption: FleetOption) {
        userStorageWriter.set(fleetOption: fleetOption)
        selectedFleetOptionSubject.onNext(fleetOption)
    }

    public var resolvedFleet: Observable<FleetInfo> {
        return fleetInfoResolutionResponseObservable.map { $0.fleetInfo }
    }

    private static func toFleetOption(fleetInfo: FleetInfo) -> FleetOption {
        return .manual(fleetInfo: fleetInfo)
    }
}
