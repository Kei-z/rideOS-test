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
import RxSwift

public class DefaultMainViewModel: MainViewModel {
    private static let pollInterval: RxTimeInterval = 1.0

    private let disposeBag = DisposeBag()
    private let stateMachine: StateMachine<MainViewState>

    private let tripInteractor: TripInteractor
    private let schedulerProvider: SchedulerProvider
    private let logger: Logger

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                tripInteractor: TripInteractor = DefaultTripInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.tripInteractor = tripInteractor
        self.schedulerProvider = schedulerProvider
        self.logger = logger
        stateMachine = StateMachine(schedulerProvider: schedulerProvider, initialState: .startScreen)
        startPollingForCurrentTask(passengerId: userStorageReader.userId)

        stateMachine.state()
            .distinctUntilChanged()
            .subscribe(onNext: { [logger] in logger.logDebug("Transitioning to state: \($0.json)") })
            .disposed(by: disposeBag)
    }

    public func getMainViewState() -> Observable<MainViewState> {
        return stateMachine.state()
    }

    public func startLocationSearch() {
        stateMachine.transition { _ in .preTrip }
    }

    // TODO(chrism): Technically we shouldn't need this since we continuously poll for the user's current trip
    public func onTripCreated(tripId: String) {
        stateMachine.transition { _ in .onTrip(tripId: tripId) }
    }

    public func cancelPreTrip() {
        stateMachine.transition { _ in .startScreen }
    }

    private func startPollingForCurrentTask(passengerId: String) {
        // TODO(chrism): handle backpressure
        Observable<Int>
            .interval(DefaultMainViewModel.pollInterval, scheduler: schedulerProvider.computation())
            .flatMapLatest { [tripInteractor, logger] _ in tripInteractor
                .getCurrentTrip(forPassenger: passengerId)
                .logErrors(logger: logger)
                .catchErrorJustComplete()
            }
            .distinctUntilChanged()
            .filterNil()
            .subscribe(onNext: { [stateMachine] tripId in
                stateMachine.transition { _ in .onTrip(tripId: tripId) }
            })
            .disposed(by: disposeBag)
    }

    public func tripFinished() {
        stateMachine.transition { _ in .startScreen }
    }
}
