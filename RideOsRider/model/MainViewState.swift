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

public enum MainViewState: Equatable, Encodable {
    case startScreen
    case preTrip
    case onTrip(tripId: String)
}

// MARK: Encodable

extension MainViewState {
    enum CodingKeys: CodingKey {
        case startScreen, preTrip, onTrip
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .startScreen:
            try container.encode(true, forKey: .startScreen)
        case .preTrip:
            try container.encode(true, forKey: .preTrip)
        case let .onTrip(taskId):
            try container.encode(taskId, forKey: .onTrip)
        }
    }

    public var json: String {
        if let jsonData = try? JSONEncoder().encode(self), let jsonString = String(data: jsonData, encoding: .utf8) {
            return jsonString
        }
        return ""
    }
}
