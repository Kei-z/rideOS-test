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
import RxSwiftExt

public class DefaultPreTripViewModel: PreTripViewModel {
    private static let defaultPreTripState = PreTripState.selectingPickupDropoff
    private static let defaultSeatCount: UInt32 = 1
    private static let tripInteractorRetryCount: UInt = 5

    private let disposeBag = DisposeBag()

    private let stateMachine: StateMachine<PreTripState>
    private weak var listener: PreTripListener?
    private let enableSeatCountSelection: Bool

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                tripInteractor: TripInteractor = DefaultTripInteractor(),
                listener: PreTripListener,
                enableSeatCountSelection: Bool,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                resolvedFleet: ResolvedFleet = ResolvedFleet.instance,
                passengerName: Observable<String> = defaultPassengerName(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        stateMachine = StateMachine(schedulerProvider: schedulerProvider,
                                    initialState: DefaultPreTripViewModel.defaultPreTripState)
        self.listener = listener
        self.enableSeatCountSelection = enableSeatCountSelection

        stateMachine.state()
            .observeOn(schedulerProvider.computation())
            .distinctUntilChanged()
            .filter(DefaultPreTripViewModel.isStateConfirmed)
            .withLatestFrom(resolvedFleet.resolvedFleet) { ($0, $1) }
            .withLatestFrom(passengerName) { ($0.0, $0.1, $1) }
            .flatMap { state, fleet, passengerName in
                DefaultPreTripViewModel.createTask(
                    passengerId: userStorageReader.userId,
                    passengerName: passengerName,
                    fleetId: fleet.fleetId,
                    state: state,
                    tripInteractor: tripInteractor,
                    logger: logger
                )
            }
            .subscribe(onNext: { listener.onTripCreated(tripId: $0) },
                       onError: { [stateMachine] _ in
                           DefaultPreTripViewModel.updateStateMachineOnTaskCreationFailure(stateMachine)
            })
            .disposed(by: disposeBag)
    }

    private static func isStateConfirmed(state: PreTripState) -> Bool {
        if case PreTripState.confirmed = state {
            return true
        }
        return false
    }

    private static func updateStateMachineOnTaskCreationFailure(_ stateMachine: StateMachine<PreTripState>) {
        stateMachine.transition { currentState in
            switch currentState {
            case .confirmed(let confirmedPickupLocation, let confirmedDropoffLocation, _, _):
                return .confirmingTrip(confirmedPickupLocation: confirmedPickupLocation,
                                       confirmedDropoffLocation: confirmedDropoffLocation)
            default:
                return currentState
            }
        }
    }

    public func getPreTripState() -> Observable<PreTripState> {
        return stateMachine.state()
    }

    public func cancelTripRequest() {
        listener?.cancelPreTrip()
    }

    public func confirmTrip(selectedVehicle: VehicleSelectionOption) {
        stateMachine.transition { [enableSeatCountSelection] currentState in
            guard case let .confirmingTrip(confirmedPickupLocation, confirmedDropoffLocation) = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called on invalid step \(currentState)")
            }

            if enableSeatCountSelection {
                return .confirmingSeats(confirmedPickupLocation: confirmedPickupLocation,
                                        confirmedDropoffLocation: confirmedDropoffLocation,
                                        selectedVehicle: selectedVehicle)
            } else {
                return .confirmed(confirmedPickupLocation: confirmedPickupLocation,
                                  confirmedDropoffLocation: confirmedDropoffLocation,
                                  numPassengers: DefaultPreTripViewModel.defaultSeatCount,
                                  selectedVehicle: selectedVehicle)
            }
        }
    }

    public func confirm(seatCount: UInt32) {
        stateMachine.transition { currentState in
            guard case let .confirmingSeats(confirmedPickupLocation, confirmedDropoffLocation, selectedVehicle) = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called on invalid step \(currentState)")
            }

            return .confirmed(confirmedPickupLocation: confirmedPickupLocation,
                              confirmedDropoffLocation: confirmedDropoffLocation,
                              numPassengers: seatCount,
                              selectedVehicle: selectedVehicle)
        }
    }

    private static func createTask(passengerId: String,
                                   passengerName: String,
                                   fleetId: String,
                                   state: PreTripState,
                                   tripInteractor: TripInteractor,
                                   logger: Logger) -> Observable<String> {
        if case let PreTripState.confirmed(confirmedPickupLocation,
                                           confirmedDropoffLocation,
                                           numPassengers,
                                           selectedVehicle) = state {
            var selectedVehicleId: String?
            if case let VehicleSelectionOption.manual(vehicle) = selectedVehicle {
                selectedVehicleId = vehicle.vehicleId
            }
            return tripInteractor
                .createTripForPassenger(passengerId: passengerId,
                                        contactInfo: ContactInfo(name: passengerName),
                                        fleetId: fleetId,
                                        numPassengers: numPassengers,
                                        pickupLocation: confirmedPickupLocation.namedTripLocation.tripLocation,
                                        dropoffLocation: confirmedDropoffLocation.namedTripLocation.tripLocation,
                                        vehicleId: selectedVehicleId)
                .logErrors(logger: logger)
                .retry(.immediate(maxCount: DefaultPreTripViewModel.tripInteractorRetryCount))
        } else {
            fatalError("\(#function) called while in invalid state")
        }
    }
}

// MARK: SetPickupDropoffListener

extension DefaultPreTripViewModel {
    public func set(pickup: PreTripLocation, dropoff: PreTripLocation) {
        stateMachine.transition { currentState in
            guard case .selectingPickupDropoff = currentState else {
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called on invalid step \(currentState)")
            }

            if dropoff.wasSetOnMap {
                if pickup.wasSetOnMap {
                    return .confirmingTrip(confirmedPickupLocation: pickup.desiredAndAssignedLocation,
                                           confirmedDropoffLocation: dropoff.desiredAndAssignedLocation)
                } else {
                    return .confirmingPickup(unconfirmedPickupLocation: pickup,
                                             confirmedDropoffLocation: dropoff.desiredAndAssignedLocation)
                }
            } else {
                return .confirmingDropoff(unconfirmedPickupLocation: pickup,
                                          unconfirmedDropoffLocation: dropoff)
            }
        }
    }

    public func cancelSetPickupDropoff() {
        listener?.cancelPreTrip()
    }
}

// MARK: ConfirmLocationListener

extension DefaultPreTripViewModel: ConfirmLocationListener {
    public func confirmLocation(_ location: DesiredAndAssignedLocation) {
        stateMachine.transition { currentState in
            switch currentState {
            case .confirmingDropoff(let unconfirmedPickupLocation, _):
                if unconfirmedPickupLocation.wasSetOnMap {
                    return .confirmingTrip(confirmedPickupLocation: unconfirmedPickupLocation.desiredAndAssignedLocation,
                                           confirmedDropoffLocation: location)
                } else {
                    return .confirmingPickup(unconfirmedPickupLocation: unconfirmedPickupLocation,
                                             confirmedDropoffLocation: location)
                }
            case let .confirmingPickup(_, confirmedDropoffLocation):
                return .confirmingTrip(confirmedPickupLocation: location,
                                       confirmedDropoffLocation: confirmedDropoffLocation)

            default:
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called on invalid step \(currentState)")
            }
        }
    }

    public func cancelConfirmLocation() {
        stateMachine.transition { currentState in
            switch currentState {
            case .confirmingPickup(_, _), .confirmingDropoff:
                return .selectingPickupDropoff
            default:
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called on invalid step \(currentState)")
            }
        }
    }

    public func cancelConfirmTrip() {
        stateMachine.transition { currentState in
            switch currentState {
            case .confirmingTrip:
                return .selectingPickupDropoff
            default:
                throw InvalidStateTransitionError.invalidStateTransition(
                    "\(#function) called on invalid step \(currentState)")
            }
        }
    }

    public static func defaultPassengerName() -> Observable<String> {
        let preferredName = UserDefaultsUserStorageReader().get(CommonUserStorageKeys.preferredName)
        if let preferredName = preferredName, preferredName.isNotEmpty {
            return Observable.just(preferredName)
        }
        return User.currentUser.profileObservable
            .map { $0.email }
            .map { $0 ?? "" }
    }
}
