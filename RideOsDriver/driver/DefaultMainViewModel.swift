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
    private let userStorageReader: UserStorageReader
    private let driverVehicleInteractor: DriverVehicleInteractor
    private let stateMachine: StateMachine<MainViewState>
    private let logger: Logger

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.userStorageReader = userStorageReader
        self.driverVehicleInteractor = driverVehicleInteractor
        self.logger = logger

        stateMachine = StateMachine(schedulerProvider: schedulerProvider, initialState: .unknown, logger: logger)
    }

    public func getMainViewState() -> Observable<MainViewState> {
        let getStatusDisposable = driverVehicleInteractor.getVehicleStatus(vehicleId: userStorageReader.userId)
            .asObservable()
            .logErrorsRetryAndDefault(to: .notReady, logger: logger)
            .subscribe(onNext: { [stateMachine] in
                switch $0 {
                case .unregistered:
                    stateMachine.transition { _ in .vehicleUnregistered }
                case .ready:
                    stateMachine.transition { _ in .online }
                case .notReady:
                    stateMachine.transition { _ in .offline }
                }
            })

        return stateMachine.observeCurrentState()
            .filter { $0 != .unknown }
            .do(onDispose: { getStatusDisposable.dispose() })
    }
}

// MARK: GoOnlineListener

extension DefaultMainViewModel: GoOnlineListener {
    public func didGoOnline() {
        stateMachine.transition { currentState in
            guard case .offline = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return MainViewState.online
        }
    }
}

// MARK: GoOfflineListener

extension DefaultMainViewModel: GoOfflineListener {
    public func didGoOffline() {
        stateMachine.transition { currentState in
            guard case .online = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return MainViewState.offline
        }
    }
}

// MARK: RegisterVehicleFinishedListener

extension DefaultMainViewModel: RegisterVehicleFinishedListener {
    public func vehicleRegistrationFinished() {
        stateMachine.transition { currentState in
            guard case .vehicleUnregistered = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return MainViewState.offline
        }
    }
}
