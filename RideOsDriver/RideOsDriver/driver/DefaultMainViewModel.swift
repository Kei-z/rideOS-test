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

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                driverVehicleInteractor: DriverVehicleInteractor = DefaultDriverVehicleInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.userStorageReader = userStorageReader
        self.driverVehicleInteractor = driverVehicleInteractor

        // TODO: query the backend for vehicle info instead of relying on local storage
        let hasUserCompletedVehicleRegistration = userStorageReader.get(DriverSettingsKeys.vehicleInfo) == nil
        let initialState = hasUserCompletedVehicleRegistration ? MainViewState.vehicleUnregistered
            : MainViewState.offline

        stateMachine = StateMachine(schedulerProvider: schedulerProvider, initialState: initialState)
    }

    public func getMainViewState() -> Observable<MainViewState> {
        return stateMachine.state()
    }
}

// MARK: GoOnlineListener

extension DefaultMainViewModel: GoOnlineListener {
    public func goOnline() {
        stateMachine.asyncTransition { [driverVehicleInteractor, userStorageReader] currentState in
            guard case .offline = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return driverVehicleInteractor.markVehicleReady(vehicleId: userStorageReader.userId)
                .andThen(Single.just(MainViewState.online))
        }
    }
}

// MARK: GoOfflineListener

extension DefaultMainViewModel: GoOfflineListener {
    public func goOffline() {
        stateMachine.asyncTransition { [driverVehicleInteractor, userStorageReader] currentState in
            guard case .online = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return driverVehicleInteractor.markVehicleNotReady(vehicleId: userStorageReader.userId)
                .andThen(Single.just(MainViewState.offline))
        }
    }
}

// MARK: RegisterVehicleFinishedListener

extension DefaultMainViewModel: RegisterVehicleFinishedListener {
    public func vehicleRegistrationFinished() {
        stateMachine.asyncTransition { currentState in
            guard case .vehicleUnregistered = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }
            return Single.just(MainViewState.offline)
        }
    }
}
