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

public class CurrentTripCoordinator: Coordinator {
    private let disposeBag = DisposeBag()

    private let mapViewController: MapViewController
    private let viewModel: CurrentTripViewModel
    private weak var tripFinishedListener: TripFinishedListener?
    private let schedulerProvider: SchedulerProvider
    private var childViewController: UIViewController?

    public convenience init(tripId: String,
                            listener: CurrentTripListener,
                            tripFinishedListener: TripFinishedListener,
                            mapViewController: MapViewController,
                            navigationController: UINavigationController) {
        self.init(viewModel: DefaultCurrentTripViewModel(tripId: tripId, listener: listener),
                  tripFinishedListener: tripFinishedListener,
                  mapViewController: mapViewController,
                  navigationController: navigationController)
    }

    public init(viewModel: CurrentTripViewModel,
                tripFinishedListener: TripFinishedListener,
                mapViewController: MapViewController,
                navigationController: UINavigationController,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.viewModel = viewModel
        self.tripFinishedListener = tripFinishedListener
        self.mapViewController = mapViewController
        self.schedulerProvider = schedulerProvider
        super.init(navigationController: navigationController)
    }

    public override func activate() {
        viewModel.riderTripState
            .observeOn(schedulerProvider.mainThread())
            .distinctUntilChanged { passengerState0, passengerState1 in
                passengerState0.hasSameCase(as: passengerState1)
            }
            .subscribe(onNext: { [unowned self] passengerState in
                switch passengerState {
                case .waitingForAssignment:
                    self.showWaitingForAssignment(passengerState)
                case .drivingToPickup:
                    self.showDrivingToPickup(passengerState)
                case .waitingForPickup:
                    self.showWaitingForPickup(passengerState)
                case .drivingToDropoff:
                    self.showDrivingToDropoff(passengerState)
                case let .cancelled(_, _, reason):
                    self.handleCancelledTrip(reason: reason)
                case let .completed(_, dropoffLocation):
                    self.showTripCompleted(dropoffLocation)
                default:
                    break
                }
            })
            .disposed(by: disposeBag)

        viewModel.riderTripState
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] passengerState in
                if let observer = self.childViewController as? PassengerStateObserver {
                    observer.updatePassengerState(passengerState)
                }
            })
            .disposed(by: disposeBag)
    }

    private func showWaitingForAssignment(_ passengerState: RiderTripStateModel) {
        childViewController = WaitingForAssignmentViewController(mapViewController: mapViewController,
                                                                 initialPassengerState: passengerState,
                                                                 cancelListener: viewModel.cancelTrip)
        showChild(viewController: childViewController!)
    }

    private func showDrivingToPickup(_ passengerState: RiderTripStateModel) {
        childViewController = DrivingToPickupViewController(mapViewController: mapViewController,
                                                            passengerState: passengerState,
                                                            cancelListener: viewModel.cancelTrip,
                                                            editPickupListener: viewModel.editPickup)
        showChild(viewController: childViewController!)
    }

    private func showWaitingForPickup(_ passengerState: RiderTripStateModel) {
        childViewController = WaitingForPickupViewController(mapViewController: mapViewController,
                                                             initialPassengerState: passengerState,
                                                             cancelListener: viewModel.cancelTrip)
        showChild(viewController: childViewController!)
    }

    private func showDrivingToDropoff(_ passengerState: RiderTripStateModel) {
        childViewController = DrivingToDropoffViewController(mapViewController: mapViewController,
                                                             initialPassengerState: passengerState,
                                                             cancelListener: viewModel.cancelTrip)
        showChild(viewController: childViewController!)
    }

    private func showTripCompleted(_ dropoffLocation: GeocodedLocationModel) {
        childViewController = TripCompletedViewController(mapViewController: mapViewController,
                                                          tripFinishedListener: tripFinishedListener,
                                                          dropoffLocation: dropoffLocation)
        showChild(viewController: childViewController!)
    }

    private func handleCancelledTrip(reason: CancelReason) {
        switch reason.source {
        case .requestor:
            // The rider cancelled, so just call tripFinishedListener immediately
            tripFinishedListener?.tripFinished()
        default:
            navigationController.topViewController?.present(tripCancelledAlertController(reason),
                                                            animated: true,
                                                            completion: nil)
        }
    }

    public override func encodedState(_ encoder: JSONEncoder) -> Data? {
        return viewModel.encodedState(encoder)
    }
}

extension CurrentTripCoordinator {
    private func tripCancelledAlertController(_ reason: CancelReason) -> UIAlertController {
        let alertController = UIAlertController(
            title: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.trip-cancelled-alert.title"),
            message: CurrentTripCoordinator.tripCancelledAlertMessage(reason),
            preferredStyle: UIAlertController.Style.alert
        )
        alertController.addAction(
            UIAlertAction(
                title: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.trip-cancelled-alert.action.ok"),
                style: UIAlertAction.Style.default,
                handler: { [tripFinishedListener] _ in tripFinishedListener?.tripFinished() }
            )
        )
        return alertController
    }

    private static func tripCancelledAlertMessage(_ reason: CancelReason) -> String {
        var message = RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.trip-cancelled-alert.message")
        if reason.description.isNotEmpty {
            message += "\nReason: " + reason.description
        }
        return message
    }
}
