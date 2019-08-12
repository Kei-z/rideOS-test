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
import RxCocoa
import RxSwift

public class MapViewController: UIViewController {
    private let disposeBag = DisposeBag()
    private let settingsButton = SquareImageButton(image: CommonImages.menu())
    private let recenterButton = SquareImageButton(
        image: CommonImages.crosshair(),
        backgroundColor: .clear,
        enableShadows: false
    )

    private var recenterButtonBottomConstraint: NSLayoutConstraint?

    private let viewModel: MapViewModel
    private var mapView: UIMapView
    private let schedulerProvider: SchedulerProvider
    private var mapStateProviderConnectionDisposable: Disposable?

    public var showSettingsButton: Bool {
        get {
            return !settingsButton.isHidden
        }
        set {
            settingsButton.isHidden = !newValue
        }
    }

    public var settingsButtonTapEvents: ControlEvent<Void> {
        return settingsButton.tapEvents
    }

    public required init?(coder _: NSCoder) {
        fatalError("MapViewController does not support NSCoder")
    }

    public init(viewModel: MapViewModel = DefaultMapViewModel(),
                mapView: UIMapView = CommonDependencyRegistry.instance.mapsDependencyFactory.mapView,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.viewModel = viewModel
        self.mapView = mapView
        self.schedulerProvider = schedulerProvider

        super.init(nibName: nil, bundle: nil)

        view.addSubview(mapView)
        view.activateMaxSizeConstraintsOnSubview(mapView)

        view.addSubview(settingsButton)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        settingsButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor).isActive = true
        settingsButton.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor).isActive = true

        view.addSubview(recenterButton)
        recenterButton.translatesAutoresizingMaskIntoConstraints = false
        recenterButtonBottomConstraint =
            recenterButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor)
        recenterButtonBottomConstraint?.isActive = true
        recenterButton.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor).isActive = true

        mapView.setMapDragListener(viewModel)

        viewModel.cameraUpdatesToPerform

            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [mapView] cameraUpdate in mapView.moveCamera(cameraUpdate) })
            .disposed(by: disposeBag)

        viewModel.shouldAllowRecentering
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [recenterButton] in
                recenterButton.isHidden = !$0
            })
            .disposed(by: disposeBag)

        recenterButton.tapEvents
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] in
                self.recenterMap()
            })
            .disposed(by: disposeBag)

        showSettingsButton = true
    }

    public var topAnchor: NSLayoutYAxisAnchor {
        if showSettingsButton {
            return settingsButton.bottomAnchor
        } else {
            return view.safeAreaLayoutGuide.topAnchor
        }
    }

    public var mapInsets: UIEdgeInsets {
        get {
            return mapView.mapInsets
        }
        set {
            mapView.mapInsets = newValue
            recenterButtonBottomConstraint?.constant = -newValue.bottom
        }
    }

    public var visibleRegion: LatLngBounds { return mapView.visibleRegion }

    public func connect(mapStateProvider: MapStateProvider, mapCenterListener: MapCenterListener? = nil) {
        disconnectMapStateProviderIfNecessary()
        mapView.setMapCenterListener(mapCenterListener)

        mapStateProviderConnectionDisposable = CompositeDisposable(disposables: [
            // Camera updates pass through the view model for appropriate filtering
            mapStateProvider.getCameraUpdates()
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: { [viewModel] cameraUpdate in
                    viewModel.requestCameraUpdate(cameraUpdate, forced: false)
                }),
            // Paths, markers, and map settings get sent directly to the view
            mapStateProvider.getPaths()
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: mapView.showPaths),
            mapStateProvider.getMarkers()
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: mapView.showMarkers),
            mapStateProvider.getMapSettings()
                .observeOn(schedulerProvider.mainThread())
                .subscribe(onNext: mapView.setMapSettings),
        ])
        recenterMap()
    }

    private func disconnectMapStateProviderIfNecessary() {
        if let disposable = mapStateProviderConnectionDisposable {
            disposable.dispose()
            mapStateProviderConnectionDisposable = nil
            mapView.setMapCenterListener(nil)
        }
    }

    public func recenterMap() {
        viewModel.recenterMap()
    }

    deinit {
        disconnectMapStateProviderIfNecessary()
    }
}
