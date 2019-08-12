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

public class DefaultDrivingViewModel: DrivingViewModel {
    private let finishedDrivingListener: () -> Void
    private let destination: CLLocationCoordinate2D
    private let schedulerProvider: SchedulerProvider

    private let stateMachine: StateMachine<DrivingViewState.Step>

    public init(finishedDrivingListener: @escaping () -> Void,
                destination: CLLocationCoordinate2D,
                initialStep: DrivingViewState.Step = .drivePending,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.finishedDrivingListener = finishedDrivingListener
        self.destination = destination
        self.schedulerProvider = schedulerProvider

        stateMachine = StateMachine(schedulerProvider: schedulerProvider, initialState: initialStep)
    }

    public var drivingViewState: Observable<DrivingViewState> {
        return stateMachine.state()
            .distinctUntilChanged()
            .map { [destination] in DrivingViewState(drivingStep: $0, destination: destination) }
    }

    public func startNavigation() {
        stateMachine.transition { currentState in
            guard case .drivePending = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return .navigating
        }
    }

    public func confirmArrival() {
        stateMachine.transition { [finishedDrivingListener] currentState in
            guard case .confirmingArrival = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            finishedDrivingListener()

            return currentState
        }
    }

    public func finishedNavigation() {
        stateMachine.transition { currentState in
            guard case .navigating = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called during invalid state: \(currentState)")
            }

            return .confirmingArrival
        }
    }
}
