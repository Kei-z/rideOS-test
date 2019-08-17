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
import RideOsCommon
import RxSwift

public class DefaultVehicleUnregisteredViewModel: VehicleUnregisteredViewModel {
    private static let defaultState = VehicleUnregisteredViewState.preRegistration

    private let disposeBag = DisposeBag()

    private weak var registerVehicleFinishedListener: RegisterVehicleFinishedListener?
    private let schedulerProvider: SchedulerProvider

    private let stateMachine: StateMachine<VehicleUnregisteredViewState>

    public init(registerVehicleFinishedListener: RegisterVehicleFinishedListener,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.registerVehicleFinishedListener = registerVehicleFinishedListener
        self.schedulerProvider = schedulerProvider

        stateMachine = StateMachine(schedulerProvider: schedulerProvider,
                                    initialState: DefaultVehicleUnregisteredViewModel.defaultState,
                                    logger: logger)
    }

    public func getVehicleUnregisteredViewState() -> Observable<VehicleUnregisteredViewState> {
        return stateMachine.observeCurrentState()
    }
}

// MARK: StartVehicleRegistrationListener

extension DefaultVehicleUnregisteredViewModel: StartVehicleRegistrationListener {
    public func startVehicleRegistration() {
        stateMachine.asyncTransition { currentState in
            guard case .preRegistration = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }
            return Single.just(VehicleUnregisteredViewState.registering)
        }
    }
}

// MARK: RegisterVehicleListener

extension DefaultVehicleUnregisteredViewModel: RegisterVehicleListener {
    public func cancelVehicleRegistration() {
        stateMachine.asyncTransition { currentState in
            guard case .registering = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }
            return Single.just(VehicleUnregisteredViewState.preRegistration)
        }
    }

    public func finishVehicleRegistration() {
        registerVehicleFinishedListener?.vehicleRegistrationFinished()
    }
}
