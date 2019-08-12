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

public class DefaultSetPickupDropoffViewModel: SetPickupDropoffViewModel {
    private let disposeBag = DisposeBag()
    private let stepSubject = BehaviorSubject<SetPickupDropOffDisplayState.Step>(value: .searchingForPickupDropoff)
    private let locationStateStateMachine: StateMachine<LocationState>

    private weak var listener: SetPickupDropoffListener?

    public init(listener: SetPickupDropoffListener,
                initialPickup: PreTripLocation?,
                initialDropoff: PreTripLocation?,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.listener = listener
        locationStateStateMachine = StateMachine(
            schedulerProvider: schedulerProvider,
            initialState: LocationState(pickup: initialPickup,
                                        dropoff: initialDropoff,
                                        changedByUser: false)
        )

        locationStateStateMachine.state()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] locationState in
                if let (pickup, dropoff) = locationState.completedPickupDropoff() {
                    self.listener?.set(pickup: pickup, dropoff: dropoff)
                } else {
                    self.stepSubject.onNext(.searchingForPickupDropoff)
                }
            })
            .disposed(by: disposeBag)
    }

    public func getDisplayState() -> Observable<SetPickupDropOffDisplayState> {
        return Observable
            .combineLatest(stepSubject, locationStateStateMachine.state())
            .distinctUntilChanged { $0 == $1 }
            .map { step, locationState in
                SetPickupDropOffDisplayState(step: step,
                                             pickup: locationState.pickup?.desiredAndAssignedLocation,
                                             dropoff: locationState.dropoff?.desiredAndAssignedLocation)
            }
    }

    private func getCurrentStep() -> SetPickupDropOffDisplayState.Step {
        do {
            return try stepSubject.value()
        } catch {
            fatalError("Unable to fetch current step")
        }
    }

    public func setPickup(_ pickup: PreTripLocation) {
        locationStateStateMachine.transition { currentState in
            LocationState(pickup: pickup,
                          dropoff: currentState.dropoff,
                          changedByUser: true)
        }
    }

    public func setDropoff(_ dropoff: PreTripLocation) {
        locationStateStateMachine.transition { currentState in
            LocationState(pickup: currentState.pickup,
                          dropoff: dropoff,
                          changedByUser: true)
        }
    }

    private struct LocationState: Equatable {
        let pickup: PreTripLocation?
        let dropoff: PreTripLocation?
        let changedByUser: Bool

        func completedPickupDropoff() -> (PreTripLocation, PreTripLocation)? {
            if changedByUser, let pickup = pickup, let dropoff = dropoff {
                return (pickup, dropoff)
            }
            return nil
        }
    }
}

// MARK: LocationSearchListener

extension DefaultSetPickupDropoffViewModel: LocationSearchListener {
    public func selectPickup(_ pickup: GeocodedLocationModel) {
        setPickup(
            PreTripLocation(
                desiredAndAssignedLocation: DesiredAndAssignedLocation(
                    desiredLocation: NamedTripLocation(geocodedLocation: pickup)
                ),
                wasSetOnMap: false
            )
        )
    }

    public func selectDropoff(_ dropoff: GeocodedLocationModel) {
        setDropoff(
            PreTripLocation(
                desiredAndAssignedLocation: DesiredAndAssignedLocation(
                    desiredLocation: NamedTripLocation(geocodedLocation: dropoff)
                ),
                wasSetOnMap: false
            )
        )
    }

    public func setPickupOnMap() {
        stepSubject.onNext(.settingPickupOnMap)
    }

    public func setDropoffOnMap() {
        stepSubject.onNext(.settingDropoffOnMap)
    }

    public func cancelLocationSearch() {
        listener?.cancelSetPickupDropoff()
    }

    public func doneSearching() {
        locationStateStateMachine.transition { currentState in
            LocationState(pickup: currentState.pickup,
                          dropoff: currentState.dropoff,
                          changedByUser: true)
        }
    }
}

// MARK: ConfirmLocationListener

extension DefaultSetPickupDropoffViewModel: ConfirmLocationListener {
    public func confirmLocation(_ location: DesiredAndAssignedLocation) {
        switch getCurrentStep() {
        case .settingPickupOnMap:
            setPickup(PreTripLocation(desiredAndAssignedLocation: location, wasSetOnMap: true))
        case .settingDropoffOnMap:
            setDropoff(PreTripLocation(desiredAndAssignedLocation: location, wasSetOnMap: true))
        default:
            fatalError("\(#function) called on an invalid step")
        }
    }

    public func cancelConfirmLocation() {
        stepSubject.onNext(.searchingForPickupDropoff)
    }
}
