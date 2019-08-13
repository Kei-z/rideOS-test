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

public class DefaultCurrentTripViewModel: CurrentTripViewModel {
    private static let riderTripStatePollInterval: RxTimeInterval = 1.0
    private static let defaultPickupZoom = Float(16.0)
    private static let routeWidth = Float(4)
    private static let routeColor = UIColor.gray

    private let disposeBag = DisposeBag()
    private let cancellingSubject = BehaviorSubject(value: false)

    private let tripId: String
    private weak var listener: CurrentTripListener?
    private let riderTripStateInteractor: RiderTripStateInteractor
    private let schedulerProvider: SchedulerProvider
    public let riderTripState: Observable<RiderTripStateModel>
    private var latestRiderTripState: RiderTripStateModel?

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                tripId: String,
                resolvedFleet: ResolvedFleet = ResolvedFleet.instance,
                listener: CurrentTripListener,
                riderTripStateInteractor: RiderTripStateInteractor = DefaultRiderTripStateInteractor(),
                tripInteractor: TripInteractor = DefaultTripInteractor(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        self.tripId = tripId
        self.listener = listener
        self.riderTripStateInteractor = riderTripStateInteractor
        self.schedulerProvider = schedulerProvider

        riderTripState = Observable<Int>
            .interval(DefaultCurrentTripViewModel.riderTripStatePollInterval,
                      scheduler: schedulerProvider.computation())
            .subscribeOn(schedulerProvider.computation())
            .withLatestFrom(resolvedFleet.resolvedFleet) { ($0, $1) }
            .flatMapLatest { _, fleet in
                riderTripStateInteractor
                    .getTripState(tripId: tripId, fleetId: fleet.fleetId)
                    .logErrors(logger: logger)
                    .catchErrorJustComplete()
            }
            .startWith(RiderTripStateModel.unknown)
            .share(replay: 1, scope: .whileConnected)

        cancellingSubject
            .observeOn(schedulerProvider.io())
            .distinctUntilChanged()
            .filter { $0 }
            .flatMapLatest { _ in
                tripInteractor
                    .cancelTrip(passengerId: userStorageReader.userId, tripId: tripId)
                    .asObservable()
                    .logErrorsRetryAndCompleteOnError(logger: logger)
            }
            .subscribe(onCompleted: { [cancellingSubject] in cancellingSubject.onNext(false) })
            .disposed(by: disposeBag)

        riderTripState
            .subscribe(onNext: { [unowned self] in self.latestRiderTripState = $0 })
            .disposed(by: disposeBag)
    }

    public func cancelTrip() {
        cancellingSubject.onNext(true)
    }

    public func editPickup() {
        listener?.editPickup()
    }

    public func encodedState(_ encoder: JSONEncoder) -> Data? {
        if let latestPassengerState = latestRiderTripState {
            return try? encoder.encode(DebugModel(tripId: tripId, passengerState: latestPassengerState))
        }
        return nil
    }

    private struct DebugModel: Encodable {
        let tripId: String
        let passengerState: RiderTripStateModel
    }
}
