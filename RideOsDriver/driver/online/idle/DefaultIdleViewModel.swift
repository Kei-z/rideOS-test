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

public class DefaultIdleViewModel: IdleViewModel {
    private let userStorageReader: UserStorageReader
    private let driverVehicleInteractor: DriverVehicleInteractor
    private let stateMachine: StateMachine<IdleViewState>
    private let logger: Logger
    private let disposeBag: DisposeBag

    public var idleViewState: Observable<IdleViewState> {
        return stateMachine.observeCurrentState()
    }

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.userStorageReader = userStorageReader
        self.driverVehicleInteractor = driverVehicleInteractor
        self.logger = logger

        stateMachine = StateMachine(schedulerProvider: schedulerProvider, initialState: .online, logger: logger)
        disposeBag = DisposeBag()
    }

    public func goOffline() {
        guard let currentState = try? stateMachine.getCurrentState() else {
            return
        }

        switch currentState {
        case .online, .failedToGoOffline:
            stateMachine.transition { _ in .goingOffline }

            driverVehicleInteractor.markVehicleNotReady(vehicleId: userStorageReader.userId)
                .asObservable()
                .logErrorsAndRetry(logger: logger)
                .subscribe(
                    onError: { [stateMachine] _ in
                        stateMachine.transition { _ in .failedToGoOffline }
                    },
                    onCompleted: { [stateMachine] in
                        stateMachine.transition { _ in .offline }
                    }
                )
                .disposed(by: disposeBag)
        default:
            return
        }
    }
}
