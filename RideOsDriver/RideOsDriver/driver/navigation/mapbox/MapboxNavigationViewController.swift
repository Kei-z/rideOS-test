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

import MapboxCoreNavigation
import MapboxDirections
import MapboxNavigation
import RideOsApi
import RideOsCommon
import RxSwift

public class MapboxNavigationViewController: BackgroundMapViewController, VehicleNavigationController {
    private var navigationDoneListener: (() -> Void)?
    private var currentDestination = kCLLocationCoordinate2DInvalid

    private let schedulerProvider: SchedulerProvider
    private var mapboxNavigationViewController: MapboxNavigation.NavigationViewController?
    private let mapboxNavigationViewModel: MapboxNavigationViewModel
    private let simulatedDeviceLocator: SimulatedDeviceLocator?
    private let disposeBag = DisposeBag()

    public init(mapboxNavigationViewModel: MapboxNavigationViewModel = DefaultMapboxNavigationViewModel(),
                mapViewController: MapViewController,
                simulatedDeviceLocator: SimulatedDeviceLocator? = nil,
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider()) {
        self.mapboxNavigationViewModel = mapboxNavigationViewModel
        self.schedulerProvider = schedulerProvider
        self.simulatedDeviceLocator = simulatedDeviceLocator

        super.init(mapViewController: mapViewController)
    }

    deinit {
        mapboxNavigationViewController?.dismiss(animated: false, completion: nil)
    }

    required init?(coder _: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        mapboxNavigationViewModel.directions
            .observeOn(schedulerProvider.mainThread())
            .subscribe(onNext: { [unowned self] mapboxRoute in
                if let mapboxNavigationViewController = self.mapboxNavigationViewController {
                    mapboxNavigationViewController.route = mapboxRoute
                } else {
                    var options: NavigationOptions?

                    if self.simulatedDeviceLocator != nil {
                        let simulatedNavigationService = MapboxNavigationService(route: mapboxRoute,
                                                                                 simulating: .always)
                        options = NavigationOptions(navigationService: simulatedNavigationService)
                    }

                    let controller = MapboxNavigation.NavigationViewController(for: mapboxRoute, options: options)
                    controller.showsEndOfRouteFeedback = false
                    controller.delegate = self

                    // Set `self` as the `MapboxNavigation.NavigationServiceDelegate` instead
                    // of `mapboxNavigationViewController`. This is done so that we can directly receive
                    // location updates, and send those to `simulatedDeviceLocator`, if appropriate. All
                    // `MapboxNavigation.NavigationServiceDelegate` delegate methods end up being forwarded
                    // to `mapboxNavigationViewController` so it can update the navigation UI over the course of a
                    // trip, as normal.
                    controller.navigationService.delegate = self

                    self.mapboxNavigationViewController = controller
                    self.present(controller, animated: true, completion: nil)
                }
            })
            .disposed(by: disposeBag)
    }

    public func navigate(to destination: CLLocationCoordinate2D,
                         navigationDoneListener: @escaping () -> Void) {
        currentDestination = destination
        self.navigationDoneListener = navigationDoneListener
        mapboxNavigationViewModel.route(to: destination)
    }
}

// MARK: MapboxNavigation.NavigationViewControllerDelegate

extension MapboxNavigationViewController: MapboxNavigation.NavigationViewControllerDelegate {
    public func navigationViewControllerDidDismiss(_: MapboxNavigation.NavigationViewController,
                                                   byCanceling _: Bool) {
        navigationDoneListener?()
    }

    public func navigationViewController(_: MapboxNavigation.NavigationViewController,
                                         didArriveAt _: MapboxDirections.Waypoint) -> Bool {
        navigationDoneListener?()
        return true
    }

    public func navigationViewController(_: NavigationViewController,
                                         shouldRerouteFrom location: CLLocation) -> Bool {
        if mapboxNavigationViewModel.shouldHandleReroutes {
            mapboxNavigationViewModel.route(from: location.coordinate, to: currentDestination)
            return false
        }

        return true
    }
}

// MARK: MapboxNavigation.NavigationServiceDelegate

extension MapboxNavigationViewController: NavigationServiceDelegate {
    public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        return mapboxNavigationViewController?.navigationService(service, shouldRerouteFrom: location) ??
            RouteController.DefaultBehavior.shouldRerouteFromLocation
    }

    public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        mapboxNavigationViewController?.navigationService(service, willRerouteFrom: location)
    }

    public func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        return mapboxNavigationViewController?.navigationService(service, shouldDiscard: location) ??
            RouteController.DefaultBehavior.shouldDiscardLocation
    }

    public func navigationService(_ service: NavigationService,
                                  didRerouteAlong route: MapboxDirections.Route,
                                  at location: CLLocation?,
                                  proactive: Bool) {
        mapboxNavigationViewController?.navigationService(service,
                                                          didRerouteAlong: route,
                                                          at: location,
                                                          proactive: proactive)
    }

    public func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        mapboxNavigationViewController?.navigationService(service, didFailToRerouteWith: error)
    }

    public func navigationService(_ service: NavigationService,
                                  didUpdate progress: RouteProgress,
                                  with location: CLLocation,
                                  rawLocation: CLLocation) {
        simulatedDeviceLocator?.updateSimulatedLocation(location)

        mapboxNavigationViewController?.navigationService(service,
                                                          didUpdate: progress,
                                                          with: location,
                                                          rawLocation: rawLocation)
    }

    public func navigationService(_ service: NavigationService,
                                  didPassVisualInstructionPoint instruction: VisualInstructionBanner,
                                  routeProgress: RouteProgress) {
        mapboxNavigationViewController?.navigationService(service,
                                                          didPassVisualInstructionPoint: instruction,
                                                          routeProgress: routeProgress)
    }

    public func navigationService(_ service: NavigationService,
                                  didPassSpokenInstructionPoint instruction: SpokenInstruction,
                                  routeProgress: RouteProgress) {
        mapboxNavigationViewController?.navigationService(service,
                                                          didPassSpokenInstructionPoint: instruction,
                                                          routeProgress: routeProgress)
    }

    public func navigationService(_ service: NavigationService,
                                  willArriveAt waypoint: MapboxDirections.Waypoint,
                                  after remainingTimeInterval: TimeInterval,
                                  distance: CLLocationDistance) {
        mapboxNavigationViewController?.navigationService(service,
                                                          willArriveAt: waypoint,
                                                          after: remainingTimeInterval,
                                                          distance: distance)
    }

    public func navigationService(_ service: NavigationService,
                                  didArriveAt waypoint: MapboxDirections.Waypoint) -> Bool {
        return mapboxNavigationViewController?.navigationService(service, didArriveAt: waypoint) ??
            RouteController.DefaultBehavior.didArriveAtWaypoint
    }

    public func navigationService(_ service: NavigationService,
                                  shouldPreventReroutesWhenArrivingAt waypoint: MapboxDirections.Waypoint) -> Bool {
        return mapboxNavigationViewController?.navigationService(service,
                                                                 shouldPreventReroutesWhenArrivingAt: waypoint) ??
            RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
    }

    public func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool {
        return mapboxNavigationViewController?.navigationServiceShouldDisableBatteryMonitoring(service) ??
            RouteController.DefaultBehavior.shouldDisableBatteryMonitoring
    }

    public func navigationService(_ service: NavigationService,
                                  willBeginSimulating progress: RouteProgress,
                                  becauseOf reason: SimulationIntent) {
        mapboxNavigationViewController?.navigationService(service, willBeginSimulating: progress, becauseOf: reason)
    }

    public func navigationService(_ service: NavigationService,
                                  didBeginSimulating progress: RouteProgress,
                                  becauseOf reason: SimulationIntent) {
        mapboxNavigationViewController?.navigationService(service, didBeginSimulating: progress, becauseOf: reason)
    }

    public func navigationService(_ service: NavigationService,
                                  willEndSimulating progress: RouteProgress,
                                  becauseOf reason: SimulationIntent) {
        mapboxNavigationViewController?.navigationService(service, willEndSimulating: progress, becauseOf: reason)
    }

    public func navigationService(_ service: NavigationService,
                                  didEndSimulating progress: RouteProgress,
                                  becauseOf reason: SimulationIntent) {
        mapboxNavigationViewController?.navigationService(service, didEndSimulating: progress, becauseOf: reason)
    }
}
