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

public enum RiderTripStateModel: Equatable, Encodable {
    case waitingForAssignment(
        passengerPickupLocation: GeocodedLocationModel,
        passengerDropoffLocation: GeocodedLocationModel
    )
    case drivingToPickup(
        passengerPickupLocation: GeocodedLocationModel,
        passengerDropoffLocation: GeocodedLocationModel,
        route: Route,
        vehiclePosition: VehiclePosition,
        vehicleInfo: VehicleInfo,
        waypoints: [PassengerWaypoint]
    )
    case waitingForPickup(
        passengerPickupLocation: GeocodedLocationModel,
        passengerDropoffLocation: GeocodedLocationModel,
        vehiclePosition: VehiclePosition,
        vehicleInfo: VehicleInfo
    )
    case drivingToDropoff(
        passengerPickupLocation: GeocodedLocationModel,
        passengerDropoffLocation: GeocodedLocationModel,
        route: Route,
        vehiclePosition: VehiclePosition,
        vehicleInfo: VehicleInfo,
        waypoints: [PassengerWaypoint]
    )
    case completed(
        passengerPickupLocation: GeocodedLocationModel,
        passengerDropoffLocation: GeocodedLocationModel
    )
    case cancelled(
        passengerPickupLocation: GeocodedLocationModel,
        passengerDropoffLocation: GeocodedLocationModel,
        reason: CancelReason
    )
    case unknown

    public var pickupLocation: GeocodedLocationModel {
        switch self {
        case .waitingForAssignment(let pickupLocation, _),
             .drivingToPickup(let pickupLocation, _, _, _, _, _),
             .waitingForPickup(let pickupLocation, _, _, _),
             .drivingToDropoff(let pickupLocation, _, _, _, _, _),
             .completed(let pickupLocation, _),
             .cancelled(let pickupLocation, _, _):
            return pickupLocation
        case .unknown:
            return GeocodedLocationModel(displayName: "invalid", location: kCLLocationCoordinate2DInvalid)
        }
    }

    public var dropoffLocation: GeocodedLocationModel {
        switch self {
        case let .waitingForAssignment(_, dropoffLocation),
             .drivingToPickup(_, let dropoffLocation, _, _, _, _),
             .waitingForPickup(_, let dropoffLocation, _, _),
             .drivingToDropoff(_, let dropoffLocation, _, _, _, _),
             let .completed(_, dropoffLocation),
             .cancelled(_, let dropoffLocation, _):
            return dropoffLocation
        case .unknown:
            return GeocodedLocationModel(displayName: "invalid", location: kCLLocationCoordinate2DInvalid)
        }
    }

    // NOTE: It's super lame that this is apparently the only way in Swift to compare 2 enums with associated values
    // without regard for their assocated values
    public func hasSameCase(as otherPassengerStateModel: RiderTripStateModel) -> Bool {
        switch (self, otherPassengerStateModel) {
        case (.waitingForAssignment(_), .waitingForAssignment(_)):
            return true
        case (.drivingToPickup(_), .drivingToPickup(_)):
            return true
        case (.waitingForPickup(_), .waitingForPickup(_)):
            return true
        case (.drivingToDropoff(_), .drivingToDropoff(_)):
            return true
        case (.completed(_), .completed(_)):
            return true
        case (.cancelled(_), .cancelled(_)):
            return true
        default:
            return false
        }
    }
}

// MARK: Encodable

extension RiderTripStateModel {
    enum CodingKeys: CodingKey {
        case waitingForAssignment, drivingToPickup, waitingForPickup, drivingToDropoff, completed, cancelled, unknown
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .waitingForAssignment(passengerPickupLocation, passengerDropoffLocation):
            let model = WaitingForAssignmentModel(passengerPickupLocation: passengerPickupLocation,
                                                  passengerDropoffLocation: passengerDropoffLocation)
            try container.encode(model, forKey: .waitingForAssignment)
        case let .drivingToPickup(passengerPickupLocation,
                                  passengerDropoffLocation,
                                  route,
                                  vehiclePosition,
                                  vehicleInfo,
                                  waypoints):
            let model = DrivingToPickupModel(passengerPickupLocation: passengerPickupLocation,
                                             passengerDropoffLocation: passengerDropoffLocation,
                                             route: route,
                                             vehiclePosition: vehiclePosition,
                                             vehicleInfo: vehicleInfo,
                                             waypoints: waypoints)
            try container.encode(model, forKey: .drivingToPickup)
        case let .waitingForPickup(passengerPickupLocation,
                                   passengerDropoffLocation,
                                   vehiclePosition,
                                   vehicleInfo):
            let model = WaitingForPickupModel(passengerPickupLocation: passengerPickupLocation,
                                              passengerDropoffLocation: passengerDropoffLocation,
                                              vehiclePosition: vehiclePosition,
                                              vehicleInfo: vehicleInfo)
            try container.encode(model, forKey: .waitingForPickup)
        case let .drivingToDropoff(passengerPickupLocation,
                                   passengerDropoffLocation,
                                   route,
                                   vehiclePosition,
                                   vehicleInfo,
                                   waypoints):
            let model = DrivingToDropoffModel(passengerPickupLocation: passengerPickupLocation,
                                              passengerDropoffLocation: passengerDropoffLocation,
                                              route: route,
                                              vehiclePosition: vehiclePosition,
                                              vehicleInfo: vehicleInfo,
                                              waypoints: waypoints)
            try container.encode(model, forKey: .drivingToDropoff)
        case let .completed(passengerPickupLocation, passengerDropoffLocation):
            let model = CompletedModel(passengerPickupLocation: passengerPickupLocation,
                                       passengerDropoffLocation: passengerDropoffLocation)
            try container.encode(model, forKey: .completed)
        case let .cancelled(passengerPickupLocation, passengerDropoffLocation, reason):
            let model = CancelledModel(passengerPickupLocation: passengerPickupLocation,
                                       passengerDropoffLocation: passengerDropoffLocation,
                                       reason: reason)
            try container.encode(model, forKey: .cancelled)
        case .unknown:
            try container.encode(UnknownModel(), forKey: .unknown)
        }
    }

    // TODO(chrism): Ideally we'd also use these structs for the associated values within PassengerStateModel (one value
    // per case) instead of the status quo where we have several associated values per case
    struct WaitingForAssignmentModel: Equatable, Codable {
        public let passengerPickupLocation: GeocodedLocationModel
        public let passengerDropoffLocation: GeocodedLocationModel
    }

    struct DrivingToPickupModel: Equatable, Codable {
        public let passengerPickupLocation: GeocodedLocationModel
        public let passengerDropoffLocation: GeocodedLocationModel
        public let route: Route
        public let vehiclePosition: VehiclePosition
        public let vehicleInfo: VehicleInfo
        public let waypoints: [PassengerWaypoint]
    }

    struct WaitingForPickupModel: Equatable, Codable {
        public let passengerPickupLocation: GeocodedLocationModel
        public let passengerDropoffLocation: GeocodedLocationModel
        public let vehiclePosition: VehiclePosition
        public let vehicleInfo: VehicleInfo
    }

    struct DrivingToDropoffModel: Equatable, Codable {
        public let passengerPickupLocation: GeocodedLocationModel
        public let passengerDropoffLocation: GeocodedLocationModel
        public let route: Route
        public let vehiclePosition: VehiclePosition
        public let vehicleInfo: VehicleInfo
        public let waypoints: [PassengerWaypoint]
    }

    struct CompletedModel: Equatable, Codable {
        public let passengerPickupLocation: GeocodedLocationModel
        public let passengerDropoffLocation: GeocodedLocationModel
    }

    struct CancelledModel: Equatable, Codable {
        public let passengerPickupLocation: GeocodedLocationModel
        public let passengerDropoffLocation: GeocodedLocationModel
        public let reason: CancelReason
    }

    struct UnknownModel: Equatable, Codable {}
}

public struct CancelReason: Equatable, Codable {
    public enum Source: String, Codable {
        case unknown
        case requestor
        case vehicle
    }

    public let source: Source
    public let description: String

    public init(source: Source, description: String) {
        self.source = source
        self.description = description
    }
}

public struct PassengerWaypoint: Equatable, Codable {
    public let location: CLLocationCoordinate2D

    public init(location: CLLocationCoordinate2D) {
        self.location = location
    }
}
