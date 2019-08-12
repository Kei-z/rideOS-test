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

public enum FleetOption: Equatable, Codable {
    case automatic
    case manual(fleetInfo: FleetInfo)

    private static let automaticFleetDisplayName =
        RideOsCommonResourceLoader.instance.getString("ai.rideos.common.automatic-fleet-display-name")
    public var displayName: String {
        switch self {
        case .automatic:
            return FleetOption.automaticFleetDisplayName
        case let .manual(fleetInfo):
            return fleetInfo.displayName
        }
    }
}

// MARK: Codable

extension FleetOption {
    private enum CodingKeys: CodingKey {
        case isAutomatic
        case manual
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .automatic:
            try container.encode(true, forKey: .isAutomatic)
        case let .manual(fleetInfo):
            try container.encode(false, forKey: .isAutomatic)
            try container.encode(fleetInfo, forKey: .manual)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if try container.decode(Bool.self, forKey: .isAutomatic) {
            self = .automatic
        } else {
            self = .manual(fleetInfo: try container.decode(FleetInfo.self, forKey: .manual))
        }
    }
}
