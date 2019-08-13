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
import Polyline
import RideOsApi
import RideOsCommon
import RxSwift

public class DefaultRiderTripStateInteractor: RiderTripStateInteractor {
    private let riderService: RideHailRiderRideHailRiderService
    private let geocodeInteractor: GeocodeInteractor
    private let polylineSimplifier: PolylineSimplifier
    private let logger: Logger
    private let disposeBag: DisposeBag

    public init(
        riderService: RideHailRiderRideHailRiderService = RideHailRiderRideHailRiderService.serviceWithApiHost(),
        geocodeInteractor: GeocodeInteractor = RiderDependencyRegistry.instance.mapsDependencyFactory.geocodeInteractor,
        polylineSimplifier: PolylineSimplifier = DefaultPolylineSimplifier(),
        logger: Logger = LoggerDependencyRegistry.instance.logger
    ) {
        self.riderService = riderService
        self.geocodeInteractor = geocodeInteractor
        self.polylineSimplifier = polylineSimplifier
        self.logger = logger
        disposeBag = DisposeBag()
    }

    public func getTripState(tripId: String, fleetId: String) -> Observable<RiderTripStateModel> {
        let getTripStateRequest = RideHailRiderGetTripStateRequestRC()
        getTripStateRequest.id_p = tripId

        // TODO(mmontalbo): Use non-RC RPC call when it is published.
        let getTripState: Single<RideHailRiderGetTripStateResponseRC> = Single.create { single in
            let call = self.riderService.rpcToGetTripStateRC(withRequest: getTripStateRequest) { response, error in
                if let error = error {
                    single(.error(error))
                    return
                }

                guard let response = response else {
                    single(.error(RiderTripStateInteractorError.invalidResponse))
                    return
                }

                single(.success(response))
            }
            call.start()
            return Disposables.create { call.cancel() }
        }

        let getReverseGeocodedPickupAndDropoff: Single<(GeocodedLocationModel, GeocodedLocationModel)> =
            getTripDefinition(taskId: tripId, fleetId: fleetId).flatMap { [unowned self] pickupAndDropoffCoordinates in
                // TODO(chrism): A downside of this approach is that we issue 2 rev geocode calls for each call
                // to getPassengerState() - i.e. lots of calls to Google. We should implement a caching
                // GeocodeInteractor to fix this
                Single.zip(
                    self.reverseGeocode(pickupAndDropoffCoordinates.0).asSingle(),
                    self.reverseGeocode(pickupAndDropoffCoordinates.1).asSingle()
                )
            }

        return Single.zip(getReverseGeocodedPickupAndDropoff, getTripState)
            .map { [polylineSimplifier] pickupAndDropoffLocation, getTripStateResponse in
                DefaultRiderTripStateInteractor.convertGetTripStateResponseToPassengerStateModel(
                    pickupLocation: pickupAndDropoffLocation.0,
                    dropoffLocation: pickupAndDropoffLocation.1,
                    tripId: tripId,
                    response: getTripStateResponse,
                    polylineSimplifier: polylineSimplifier
                )
            }.asObservable()
    }

    private func getTripDefinition(
        taskId: String,
        fleetId: String
    ) -> Single<(CLLocationCoordinate2D, CLLocationCoordinate2D)> {
        let request = RideHailRiderGetTripDefinitionRequest()
        request.id_p = taskId

        return Single.create { [unowned self] single in
            let call = self.riderService.rpcToGetTripDefinition(with: request) { response, error in
                if let error = error {
                    single(.error(error))
                    return
                }

                guard let response = response,
                    let definition = response.definition,
                    case .pickupDropoff = definition.tripTypeOneOfCase else {
                    single(.error(RiderTripStateInteractorError.invalidResponse))
                    return
                }

                let pickupLocationSingle: Single<CLLocationCoordinate2D>
                switch definition.pickupDropoff.pickup.typeOneOfCase {
                case .position:
                    pickupLocationSingle = Single.just(definition.pickupDropoff.pickup.position.coordinate())
                case .predefinedStopId:
                    pickupLocationSingle = self.getPreDefinedStop(
                        stopId: definition.pickupDropoff.pickup.predefinedStopId,
                        fleetId: fleetId
                    ).map { $0.position.coordinate() }
                default:
                    self.logger.logError(
                        "Unexpected pickup definition type: \(definition.pickupDropoff.pickup.typeOneOfCase)"
                    )
                    single(.error(RiderTripStateInteractorError.invalidResponse))
                    return
                }

                let dropoffLocationSingle: Single<CLLocationCoordinate2D>
                switch definition.pickupDropoff.dropoff.typeOneOfCase {
                case .position:
                    dropoffLocationSingle = Single.just(definition.pickupDropoff.dropoff.position.coordinate())
                case .predefinedStopId:
                    dropoffLocationSingle = self.getPreDefinedStop(
                        stopId: definition.pickupDropoff.dropoff.predefinedStopId,
                        fleetId: fleetId
                    ).map { $0.position.coordinate() }
                default:
                    self.logger.logError(
                        "Unexpected dropoff definition type: \(definition.pickupDropoff.dropoff.typeOneOfCase)"
                    )
                    single(.error(RiderTripStateInteractorError.invalidResponse))
                    return
                }

                Single.zip(pickupLocationSingle, dropoffLocationSingle).subscribe(onSuccess: {
                    single(.success(($0, $1)))
                }, onError: {
                    single(.error($0))
                }).disposed(by: self.disposeBag)
            }

            call.start()
            return Disposables.create { call.cancel() }
        }
    }

    private func getPreDefinedStop(stopId: String, fleetId: String) -> Single<RideHailCommonsPredefinedStop> {
        let request = RideHailRiderFindPredefinedStopRequest()
        request.fleetId = fleetId
        request.searchParameters = RideHailRiderStopSearchParameters()
        request.searchParameters.stopId = stopId

        return Single<RideHailCommonsPredefinedStop>.create { single in
            let call = self.riderService.rpcToFindPredefinedStop(with: request) { response, error in
                if let error = error {
                    single(.error(error))
                    return
                }

                guard let response = response,
                    let stop = response.predefinedStopArray.firstObject as? RideHailCommonsPredefinedStop else {
                    single(.error(RiderTripStateInteractorError.invalidResponse))
                    return
                }

                single(.success(stop))
            }

            call.start()
            return Disposables.create { call.cancel() }
        }
    }

    private func reverseGeocode(_ location: CLLocationCoordinate2D) -> Observable<GeocodedLocationModel> {
        let defaultGeocodedLocation = GeocodedLocationModel(displayName: "", location: location)
        return geocodeInteractor
            .reverseGeocode(location: location, maxResults: 1)
            .map { $0.first ?? defaultGeocodedLocation }
            .logErrorsRetryAndDefault(to: defaultGeocodedLocation, logger: logger)
    }

    private static func convertGetTripStateResponseToPassengerStateModel(
        pickupLocation: GeocodedLocationModel,
        dropoffLocation: GeocodedLocationModel,
        tripId: String,
        response: RideHailRiderGetTripStateResponseRC,
        polylineSimplifier: PolylineSimplifier
    ) -> RiderTripStateModel {
        switch response.state.tripStateOneOfCase {
        case .waitingForAssignment:
            return .waitingForAssignment(passengerPickupLocation: pickupLocation,
                                         passengerDropoffLocation: dropoffLocation)
        case .drivingToPickup:
            return .drivingToPickup(
                passengerPickupLocation: pickupLocation,
                passengerDropoffLocation: dropoffLocation,
                route: DefaultRiderTripStateInteractor.route(from: response.state,
                                                             tripId: tripId,
                                                             polylineSimplifier: polylineSimplifier),
                vehiclePosition: DefaultRiderTripStateInteractor.vehiclePosition(from: response.state),
                vehicleInfo: DefaultRiderTripStateInteractor.vehicleInfo(from: response.state),
                waypoints: DefaultRiderTripStateInteractor.waypoints(from: response.state, tripId: tripId)
            )
        case .waitingForPickup:
            return .waitingForPickup(
                passengerPickupLocation: pickupLocation,
                passengerDropoffLocation: dropoffLocation,
                vehiclePosition: DefaultRiderTripStateInteractor.vehiclePosition(from: response.state),
                vehicleInfo: DefaultRiderTripStateInteractor.vehicleInfo(from: response.state)
            )
        case .drivingToDropoff:
            return .drivingToDropoff(
                passengerPickupLocation: pickupLocation,
                passengerDropoffLocation: dropoffLocation,
                route: DefaultRiderTripStateInteractor.route(from: response.state,
                                                             tripId: tripId,
                                                             polylineSimplifier: polylineSimplifier),
                vehiclePosition: DefaultRiderTripStateInteractor.vehiclePosition(from: response.state),
                vehicleInfo: DefaultRiderTripStateInteractor.vehicleInfo(from: response.state),
                waypoints: DefaultRiderTripStateInteractor.waypoints(from: response.state, tripId: tripId)
            )
        case .canceled:
            return .cancelled(
                passengerPickupLocation: pickupLocation,
                passengerDropoffLocation: dropoffLocation,
                reason: DefaultRiderTripStateInteractor.cancelReason(from: response.state)
            )
        case .completed:
            return .completed(passengerPickupLocation: pickupLocation, passengerDropoffLocation: dropoffLocation)
        default:
            return .unknown
        }
    }

    private static func vehicleInfo(from tripState: RideHailCommonsTripState) -> VehicleInfo {
        let assignedVehicleInfo: RideHailCommonsVehicleInfo
        let assignedVehicleContactInfo: RideHailCommonsContactInfo

        switch tripState.tripStateOneOfCase {
        case .drivingToPickup:
            guard let vehicleInfo = tripState.drivingToPickup.assignedVehicle.info,
                let contactInfo = vehicleInfo.driverInfo.contactInfo else {
                fatalError("Expected non-nil assigned vehicle info for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehicleInfo = vehicleInfo
            assignedVehicleContactInfo = contactInfo
        case .waitingForPickup:
            guard let vehicleInfo = tripState.waitingForPickup.assignedVehicle.info,
                let contactInfo = vehicleInfo.driverInfo.contactInfo else {
                fatalError("Expected non-nil assigned vehicle info for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehicleInfo = vehicleInfo
            assignedVehicleContactInfo = contactInfo
        case .drivingToDropoff:
            guard let vehicleInfo = tripState.drivingToDropoff.assignedVehicle.info,
                let contactInfo = vehicleInfo.driverInfo.contactInfo else {
                fatalError("Expected non-nil assigned vehicle info for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehicleInfo = vehicleInfo
            assignedVehicleContactInfo = contactInfo
        default:
            fatalError("Expected state with assigned vehicle, not \(tripState.tripStateOneOfCase)")
        }

        let contactUrl: URL?

        if assignedVehicleContactInfo.contactURL.isNotEmpty {
            contactUrl = URL(string: assignedVehicleContactInfo.contactURL)
        } else {
            contactUrl = nil
        }

        return VehicleInfo(licensePlate: assignedVehicleInfo.licensePlate, contactInfo: ContactInfo(url: contactUrl))
    }

    private static func vehiclePosition(from tripState: RideHailCommonsTripState) -> VehiclePosition {
        let assignedVehicle: RideHailCommonsAssignedVehicle

        switch tripState.tripStateOneOfCase {
        case .drivingToPickup:
            guard let vehicle = tripState.drivingToPickup.assignedVehicle else {
                fatalError("Expected non-nil assigned vehicle for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehicle = vehicle
        case .waitingForPickup:
            guard let vehicle = tripState.waitingForPickup.assignedVehicle else {
                fatalError("Expected non-nil assigned vehicle for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehicle = vehicle
        case .drivingToDropoff:
            guard let vehicle = tripState.drivingToDropoff.assignedVehicle else {
                fatalError("Expected non-nil assigned vehicle for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehicle = vehicle
        default:
            fatalError("Expected state with assigned vehicle, not \(tripState.tripStateOneOfCase)")
        }

        guard let assignedVehicleHeading = assignedVehicle.heading.value,
            let assignedVehicleHeadingDirection = CLLocationDirection(exactly: assignedVehicleHeading.value) else {
            fatalError("Expected state with assigned vehicle, \(tripState.tripStateOneOfCase), to have non-nil heading")
        }

        return VehiclePosition(vehicleId: assignedVehicle.id_p,
                               position: assignedVehicle.position.coordinate(),
                               heading: assignedVehicleHeadingDirection)
    }

    private static func route(
        from tripState: RideHailCommonsTripState,
        tripId: String,
        polylineSimplifier: PolylineSimplifier
    ) -> Route {
        let assignedVehiclePlanSteps: [RideHailCommonsVehicleState_Step]

        switch tripState.tripStateOneOfCase {
        case .drivingToPickup:
            guard let plan = tripState.drivingToPickup.assignedVehicle.planThroughTripEnd,
                let planSteps = plan.stepArray as? [RideHailCommonsVehicleState_Step] else {
                fatalError("Expected non-nil assigned vehicle plan for state \(tripState.tripStateOneOfCase)")
            }

            assignedVehiclePlanSteps = planSteps
                .prefix { $0.tripId != tripId || $0.vehicleActionOneOfCase != .pickupRider }
                .filter { $0.vehicleActionOneOfCase == .driveToLocation }
        case .drivingToDropoff:
            guard let plan = tripState.drivingToDropoff.assignedVehicle.planThroughTripEnd,
                let planSteps = plan.stepArray as? [RideHailCommonsVehicleState_Step] else {
                fatalError("Expected non-nil assigned vehicle plan for state \(tripState.tripStateOneOfCase)")
            }

            assignedVehiclePlanSteps = planSteps
                .prefix { $0.tripId != tripId || $0.vehicleActionOneOfCase != .dropoffRider }
                .filter { $0.vehicleActionOneOfCase == .driveToLocation }
        default:
            fatalError("Expected state with assigned vehicle plan, not \(tripState.tripStateOneOfCase)")
        }

        let planCoordinates = assignedVehiclePlanSteps
            .compactMap { Polyline(encodedPolyline: $0.driveToLocation.route.polyline).coordinates }
            .reduce([], +)

        let planTravelTime = assignedVehiclePlanSteps.map { step in
            guard let route = step.driveToLocation.route else {
                return 0.0
            }

            return route.travelTimeInSeconds
        }.reduce(0.0, +)

        let planTravelDistanceMeters = assignedVehiclePlanSteps.map { step in
            guard let route = step.driveToLocation.route else {
                return 0.0
            }

            return route.distanceInMeters
        }.reduce(0.0, +)

        guard planCoordinates.count > 0 else {
            return Route(coordinates: [],
                         travelTime: planTravelTime,
                         travelDistanceMeters: planTravelDistanceMeters)
        }

        return Route(coordinates: polylineSimplifier.simplify(polyline: planCoordinates),
                     travelTime: planTravelTime,
                     travelDistanceMeters: planTravelDistanceMeters)
    }

    private static func waypoints(
        from tripState: RideHailCommonsTripState,
        tripId: String
    ) -> [PassengerWaypoint] {
        let assignedVehiclePlanSteps: [RideHailCommonsVehicleState_Step]

        switch tripState.tripStateOneOfCase {
        case .drivingToPickup:
            guard let planSteps = tripState.drivingToPickup.assignedVehicle.planThroughTripEnd.stepArray
                as? [RideHailCommonsVehicleState_Step] else {
                fatalError("Expected non-nil assigned vehicle plan for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehiclePlanSteps = planSteps
        case .drivingToDropoff:
            guard let planSteps = tripState.drivingToDropoff.assignedVehicle.planThroughTripEnd.stepArray
                as? [RideHailCommonsVehicleState_Step] else {
                fatalError("Expected non-nil assigned vehicle plan for state \(tripState.tripStateOneOfCase)")
            }
            assignedVehiclePlanSteps = planSteps
        default:
            fatalError("Expected state with assigned vehicle plan, not \(tripState.tripStateOneOfCase)")
        }

        return assignedVehiclePlanSteps
            .prefix { $0.tripId != tripId || $0.vehicleActionOneOfCase != .dropoffRider }
            .filter { DefaultRiderTripStateInteractor.isDisplayable(step: $0, tripId: tripId) }
            .map { PassengerWaypoint(location: $0.position.coordinate()) }
    }

    // A displayable waypoint should have the following 2 traits:
    // 1. It should not be part of the rider's task
    // 2. It should be a pickup or drop-off step
    // This filter basically leaves displayable points along the rider's route to show other tasks that need to take
    // place along the way.
    private static func isDisplayable(step: RideHailCommonsVehicleState_Step, tripId: String) -> Bool {
        switch step.vehicleActionOneOfCase {
        case .pickupRider, .dropoffRider:
            return step.tripId != tripId
        default:
            return false
        }
    }

    private static func cancelReason(from tripState: RideHailCommonsTripState) -> CancelReason {
        let tripCancelSource: RideHailCommonsTripState_CancelSource
        let tripCancelReasonDescription: String

        switch tripState.tripStateOneOfCase {
        case .canceled:
            tripCancelSource = tripState.canceled.source
            tripCancelReasonDescription = tripState.canceled.description_p
        default:
            fatalError("Expected state with canceled trip, not \(tripState.tripStateOneOfCase)")
        }

        let source: CancelReason.Source
        switch tripCancelSource {
        case .rider:
            source = .requestor
        case .driver:
            source = .vehicle
        default:
            source = .unknown
        }

        return CancelReason(source: source, description: tripCancelReasonDescription)
    }
}
