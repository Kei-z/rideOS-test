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

public class DefaultOfflineViewModel: OfflineViewModel {
    private let userStorageReader: UserStorageReader
    private let driverVehicleInteractor: DriverVehicleInteractor
    private let stateMachine: StateMachine<OfflineViewState>
    private let logger: Logger
    private let disposeBag: DisposeBag

    public var offlineViewState: Observable<OfflineViewState> {
        return stateMachine.observeCurrentState()
    }

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.userStorageReader = userStorageReader
        self.driverVehicleInteractor = driverVehicleInteractor
        self.logger = logger

        stateMachine = StateMachine(schedulerProvider: schedulerProvider, initialState: .offline, logger: logger)
        disposeBag = DisposeBag()
    }

    public func goOnline() {
        guard let currentState = try? stateMachine.getCurrentState() else {
            return
        }

        switch currentState {
        case .offline, .failedToGoOnline:
            stateMachine.transition { _ in .goingOnline }

            driverVehicleInteractor.markVehicleReady(vehicleId: userStorageReader.userId)
                .asObservable()
                .logErrorsAndRetry(logger: logger)
                .subscribe(
                    onError: { [stateMachine] _ in
                        stateMachine.transition { _ in .failedToGoOnline }
                    },
                    onCompleted: { [stateMachine] in
                        stateMachine.transition { _ in .online }
                    }
                )
                .disposed(by: disposeBag)
        default:
            return
        }
    }
}
