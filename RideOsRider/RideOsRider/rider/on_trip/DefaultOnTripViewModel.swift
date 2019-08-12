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
import RxSwiftExt

public class DefaultOnTripViewModel: OnTripViewModel {
    private static let tripInteractorRepeatBehavior = RepeatBehavior.immediate(maxCount: 5)
    private let disposeBag = DisposeBag()

    // TODO(chrism): We should consider using a StateMachine for this and adding a transition helper like Android's
    // StateTransitions::transitionIf()
    private let displayStateSubject = BehaviorSubject<OnTripDisplayState>(value: .currentTrip)

    private let tripId: String
    private weak var tripFinishedListener: TripFinishedListener?
    private let tripInteractor: TripInteractor

    public init(tripId: String,
                tripFinishedListener: TripFinishedListener,
                tripInteractor: TripInteractor = DefaultTripInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.tripId = tripId
        self.tripFinishedListener = tripFinishedListener
        self.tripInteractor = tripInteractor

        displayStateSubject
            .distinctUntilChanged()
            .map(DefaultOnTripViewModel.getUpdatedPickupLocation)
            .filterNil()
            .observeOn(schedulerProvider.io())
            .flatMap { [tripId, tripInteractor] newPickupLocation in
                tripInteractor
                    .editPickup(tripId: tripId, newPickupLocation: newPickupLocation.namedTripLocation.tripLocation)
                    .logErrors(logger: logger)
                    .retry(DefaultOnTripViewModel.tripInteractorRepeatBehavior)
            }
            .subscribe(onError: { [displayStateSubject] _ in
                displayStateSubject.onNext(.currentTrip)
            })
            .disposed(by: disposeBag)
    }

    public var displayState: Observable<OnTripDisplayState> {
        return displayStateSubject
    }

    public func editPickup() {
        displayStateSubject.onNext(.editingPickup)
    }

    public func confirmLocation(_ location: DesiredAndAssignedLocation) {
        displayStateSubject.onNext(.updatingPickup(newPickupLocation: location))
    }

    public func cancelConfirmLocation() {
        displayStateSubject.onNext(.currentTrip)
    }

    public func tripFinished() {
        tripFinishedListener?.tripFinished()
    }

    private static func getUpdatedPickupLocation(
        fromDisplayState state: OnTripDisplayState
    ) -> DesiredAndAssignedLocation? {
        switch state {
        case let .updatingPickup(newPickupLocation):
            return newPickupLocation
        default:
            return nil
        }
    }
}
