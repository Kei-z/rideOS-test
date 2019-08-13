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
import RxCocoa
import RxSwift

public class PreTripCoordinator: Coordinator {
    private let viewModel: PreTripViewModel
    private let disposeBag = DisposeBag()

    private let schedulerProvider: SchedulerProvider
    private let mapViewController: MapViewController

    public convenience init(listener: PreTripListener,
                            mapViewController: MapViewController,
                            navigationController: UINavigationController,
                            schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.init(
            viewModel: RiderDependencyRegistry.instance.riderDependencyFactory.preTripViewModel(withListener: listener),
            mapViewController: mapViewController,
            navigationController: navigationController,
            schedulerProvider: schedulerProvider
        )
    }

    public init(viewModel: PreTripViewModel,
                mapViewController: MapViewController,
                navigationController: UINavigationController,
                schedulerProvider: SchedulerProvider) {
        self.viewModel = viewModel
        self.schedulerProvider = schedulerProvider
        self.mapViewController = mapViewController
        super.init(navigationController: navigationController)
    }

    public override func activate() {
        viewModel.getPreTripState()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] preTripState in
                switch preTripState {
                case .selectingPickupDropoff:
                    self.showChild(
                        coordinator: SetPickupDropoffCoordinator(
                            listener: self.viewModel,
                            mapViewController: self.mapViewController,
                            navigationController: self.navigationController
                        )
                    )
                case .confirmingPickup(let unconfirmedPickupLocation, _):
                    self.showChild(viewController: ConfirmLocationViewController.buildForConfirmPickup(
                        mapViewController: self.mapViewController,
                        initialLocation: Observable.just(
                            unconfirmedPickupLocation
                                .desiredAndAssignedLocation
                                .desiredLocation
                                .tripLocation
                                .location
                        ).asSingle(),
                        listener: self.viewModel
                    ))
                case let .confirmingDropoff(_, unconfirmedDropoffLocation):
                    self.showChild(viewController: ConfirmLocationViewController.buildForConfirmDropoff(
                        mapViewController: self.mapViewController,
                        initialLocation: Observable.just(
                            unconfirmedDropoffLocation
                                .desiredAndAssignedLocation
                                .desiredLocation
                                .tripLocation
                                .location
                        ).asSingle(),
                        listener: self.viewModel
                    ))
                case let .confirmingTrip(confirmedPickupLocation, confirmedDropoffLocation):
                    self.showChild(viewController: ConfirmTripViewController(
                        mapViewController: self.mapViewController,
                        pickupLocation: confirmedPickupLocation.namedTripLocation,
                        dropoffLocation: confirmedDropoffLocation.namedTripLocation,
                        listener: self.viewModel,
                        confirmTripViewModelBuilder: ConfirmTripViewModelBuilder()
                    ))
                case .confirmingSeats(let confirmedPickupLocation, let confirmedDropoffLocation, _):
                    self.showChild(viewController: ConfirmSeatsViewController(
                        mapViewController: self.mapViewController,
                        listener: self.viewModel
                    ))
                case .confirmed(let confirmedPickupLocation, let confirmedDropoffLocation, _, _):
                    self.showChild(viewController: RequestingTripViewController(
                        mapViewController: self.mapViewController,
                        pickupText: confirmedPickupLocation.namedTripLocation.displayName,
                        dropoffText: confirmedDropoffLocation.namedTripLocation.displayName,
                        cancelListener: self.viewModel.cancelTripRequest
                    ))
                }
            })
            .disposed(by: disposeBag)
    }
}
