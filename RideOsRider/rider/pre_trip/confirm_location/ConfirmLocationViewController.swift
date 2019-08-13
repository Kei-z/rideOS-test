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

public class ConfirmLocationViewController: BackgroundMapViewController, MapCenterListener {
    private static let pinImageViewBottomOffset: CGFloat = 5.0

    private let disposeBag = DisposeBag()
    private let cancelButton: SquareImageButton

    private let confirmLocationView: ConfirmLocationView

    private let viewModel: ConfirmLocationViewModel
    private let schedulerProvider: SchedulerProvider
    private let pinImageView: UIImageView

    public init(headerText: String,
                buttonText: String,
                pinImage: UIImage,
                showEditButton: Bool = true,
                mapViewController: MapViewController,
                viewModel: ConfirmLocationViewModel,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.viewModel = viewModel
        self.schedulerProvider = schedulerProvider
        pinImageView = UIImageView(image: pinImage)
        confirmLocationView = ConfirmLocationView(headerText: headerText,
                                                  buttonText: buttonText,
                                                  showEditButton: showEditButton)
        cancelButton = SquareImageButton(image: RiderImages.back())

        super.init(mapViewController: mapViewController, showSettingsButton: false)
    }

    public required init?(coder _: NSCoder) {
        fatalError("ConfirmLocationViewController does not support NSCoder")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(pinImageView)
        pinImageView.translatesAutoresizingMaskIntoConstraints = false
        pinImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pinImageView.bottomAnchor.constraint(
            equalTo: view.centerYAnchor,
            // offset the image to account for the fact that the point of the pin is not exactly at the bottom of the
            // image
            constant: ConfirmLocationViewController.pinImageViewBottomOffset
        ).isActive = true

        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        cancelButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true

        cancelButton.tapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: viewModel.cancel)
            .disposed(by: disposeBag)

        confirmLocationView.editButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: viewModel.cancel)
            .disposed(by: disposeBag)

        viewModel.selectedLocationDisplayName
            .observeOn(schedulerProvider.mainThread())
            .bind(to: confirmLocationView.locationLabelTextBinder)
            .disposed(by: disposeBag)

        confirmLocationView.confirmLocationButtonTapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [viewModel] _ in viewModel.confirmLocation() })
            .disposed(by: disposeBag)

        viewModel.reverseGeocodingStatus
            .observeOn(schedulerProvider.mainThread())
            .throttle(0.5, scheduler: schedulerProvider.mainThread())
            .subscribe(onNext: { [confirmLocationView] status in
                switch status {
                case .notInProgress:
                    confirmLocationView.set(isAnimatingProgress: false)
                    confirmLocationView.isConfirmLocationButtonEnabled = true
                case .inProgress:
                    confirmLocationView.set(isAnimatingProgress: true)
                    confirmLocationView.isConfirmLocationButtonEnabled = false
                case .error:
                    // TODO(chrism): improve how we handle errors
                    confirmLocationView.set(isAnimatingProgress: true)
                    confirmLocationView.isConfirmLocationButtonEnabled = false
                }
            })
            .disposed(by: disposeBag)

        presentBottomDialogStackView(confirmLocationView)
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        dismissBottomDialogStackView(confirmLocationView)
    }

    public func mapCenterDidMove(to coordinate: CLLocationCoordinate2D) {
        viewModel.onCameraMoved(location: coordinate)
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        presentBottomDialogStackView(confirmLocationView)
        mapViewController.connect(mapStateProvider: viewModel, mapCenterListener: self)
    }
}

// MARK: - Factory methods

extension ConfirmLocationViewController {
    public static func buildForSetPickup(mapViewController: MapViewController,
                                         initialLocation: Single<CLLocationCoordinate2D>,
                                         listener: ConfirmLocationListener) -> ConfirmLocationViewController {
        return ConfirmLocationViewController(
            headerText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.set-pickup.header"),
            buttonText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.set-pickup.button-title"),
            pinImage: RiderImages.blackPin(),
            mapViewController: mapViewController,
            viewModel: ConfirmLocationViewModelBuilder.buildViewModelForPickup(initialLocation: initialLocation,
                                                                               listener: listener)
        )
    }

    public static func buildForConfirmPickup(mapViewController: MapViewController,
                                             initialLocation: Single<CLLocationCoordinate2D>,
                                             listener: ConfirmLocationListener) -> ConfirmLocationViewController {
        return ConfirmLocationViewController(
            headerText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-pickup.header"),
            buttonText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-pickup.button-title"),
            pinImage: RiderImages.blackPin(),
            mapViewController: mapViewController,
            viewModel: ConfirmLocationViewModelBuilder.buildViewModelForPickup(initialLocation: initialLocation,
                                                                               listener: listener)
        )
    }

    public static func buildForConfirmDropoff(mapViewController: MapViewController,
                                              initialLocation: Single<CLLocationCoordinate2D>,
                                              listener: ConfirmLocationListener) -> ConfirmLocationViewController {
        return ConfirmLocationViewController(
            headerText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-dropoff.header"),
            buttonText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.confirm-dropoff.button-title"),
            pinImage: RiderImages.blackPinWithStar(),
            mapViewController: mapViewController,
            viewModel: ConfirmLocationViewModelBuilder.buildViewModelForDropoff(initialLocation: initialLocation,
                                                                                listener: listener)
        )
    }

    public static func buildForSetDropoff(mapViewController: MapViewController,
                                          initialLocation: Single<CLLocationCoordinate2D>,
                                          listener: ConfirmLocationListener) -> ConfirmLocationViewController {
        return ConfirmLocationViewController(
            headerText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.set-dropoff.header"),
            buttonText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.set-dropoff.button-title"),
            pinImage: RiderImages.blackPinWithStar(),
            mapViewController: mapViewController,
            viewModel: ConfirmLocationViewModelBuilder.buildViewModelForDropoff(initialLocation: initialLocation,
                                                                                listener: listener)
        )
    }

    public static func buildForEditPickup(mapViewController: MapViewController,
                                          initialLocation: Single<CLLocationCoordinate2D>,
                                          listener: ConfirmLocationListener) -> ConfirmLocationViewController {
        return ConfirmLocationViewController(
            headerText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.on-trip.edit-pickup.header"),
            buttonText: RideOsRiderResourceLoader.instance.getString("ai.rideos.rider.on-trip.edit-pickup.button"),
            pinImage: RiderImages.blackPin(),
            showEditButton: false,
            mapViewController: mapViewController,
            viewModel: ConfirmLocationViewModelBuilder.buildViewModelForPickup(initialLocation: initialLocation,
                                                                               listener: listener)
        )
    }
}
