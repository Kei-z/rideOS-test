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
import MapKit
import RideOsCommon
import RxSwift

public class ConfirmTripViewController: BackgroundMapViewController {
    private let disposeBag = DisposeBag()
    private let cancelButton = SquareImageButton(image: RiderImages.back())

    private let selectVehicleDialog: SelectVehicleDialog = SelectVehicleDialog()

    private let confirmTripDialog: ConfirmTripDialog
    private let viewModel: ConfirmTripViewModel
    private let schedulerProvider: SchedulerProvider

    public required init?(coder _: NSCoder) {
        fatalError("ConfirmLocationViewController does not support NSCoder")
    }

    public convenience init(
        mapViewController: MapViewController,
        pickupLocation: NamedTripLocation,
        dropoffLocation: NamedTripLocation,
        listener: ConfirmTripListener,
        confirmTripViewModelBuilder: ConfirmTripViewModelBuilder
    ) {
        self.init(pickupString: pickupLocation.displayName,
                  dropoffString: dropoffLocation.displayName,
                  mapViewController: mapViewController,
                  viewModel: confirmTripViewModelBuilder.buildViewModel(
                      pickupLocation: pickupLocation.tripLocation.location,
                      dropoffLocation: dropoffLocation.tripLocation.location,
                      pickupIcon: ConfirmTripViewController.getPickupIcon(),
                      dropoffIcon: ConfirmTripViewController.getDropoffIcon(),
                      listener: listener,
                      routeDisplayStringFormatter: ConfirmTripViewController.routeInfoDisplayString
                  ))
    }

    public init(pickupString: String,
                dropoffString: String,
                mapViewController: MapViewController,
                viewModel: ConfirmTripViewModel,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        confirmTripDialog = ConfirmTripDialog(pickupString: pickupString, dropoffString: dropoffString)
        self.viewModel = viewModel
        self.schedulerProvider = schedulerProvider
        super.init(mapViewController: mapViewController, showSettingsButton: false)
    }

    private static func getPickupIcon() -> DrawableMarkerIcon {
        return DrawableMarkerIcons.pickupPin()
    }

    private static func getDropoffIcon() -> DrawableMarkerIcon {
        return DrawableMarkerIcons.dropoffPin()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        confirmTripDialog.timeAndDistanceAttributedText = NSAttributedString(
            string: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-trip.loading-route-header")
        )

        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        cancelButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true

        cancelButton.tapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: viewModel.cancel)
            .disposed(by: disposeBag)

        if viewModel.enableManualVehicleSelection {
            confirmTripDialog.requestRideButtonTapEvents
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: { [unowned self] _ in
                    self.dismissBottomDialogStackView(self.confirmTripDialog)
                    self.presentBottomDialogStackView(self.selectVehicleDialog)
                })
                .disposed(by: disposeBag)

            selectVehicleDialog
                .bindToVehiclePicker(vehicles: viewModel.vehicleSelectionOptions)
                .disposed(by: disposeBag)

            selectVehicleDialog.selectVehicleButtonTapEvents
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: { [viewModel, selectVehicleDialog] _ in
                    viewModel.confirmTrip(selectedVehicle: selectVehicleDialog.selectedVehicle)
                })
                .disposed(by: disposeBag)
        } else {
            confirmTripDialog.requestRideButtonTapEvents
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: { [viewModel] _ in viewModel.confirmTrip(selectedVehicle: .automatic) })
                .disposed(by: disposeBag)
        }

        viewModel.getRouteInformation()
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [confirmTripDialog] routeInformation in
                confirmTripDialog.timeAndDistanceAttributedText = routeInformation
            })
            .disposed(by: disposeBag)

        viewModel.fetchingRouteStatus
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [confirmTripDialog] status in
                switch status {
                case .inProgress:
                    confirmTripDialog.isRequestRideButtonEnabled = false
                    confirmTripDialog.set(isAnimatingProgress: true)
                case .done:
                    confirmTripDialog.isRequestRideButtonEnabled = true
                    confirmTripDialog.set(isAnimatingProgress: false)
                case .error:
                    confirmTripDialog.isRequestRideButtonEnabled = false
                    confirmTripDialog.set(isAnimatingProgress: true)
                }
            })
            .disposed(by: disposeBag)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBottomDialogStackView(confirmTripDialog)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentBottomDialogStackView(confirmTripDialog) { [mapViewController, viewModel] in
            mapViewController.connect(mapStateProvider: viewModel)
        }
    }

    private static func routeInfoDisplayString(route: Route) -> NSAttributedString {
        return NSAttributedString.milesAndMinutesLabelWith(meters: route.travelDistanceMeters,
                                                           timeInterval: route.travelTime)
    }
}
