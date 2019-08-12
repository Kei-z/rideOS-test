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
import RxSwift

public protocol FleetOptionResolver {
    // Resolves a FleetOption into a FleetInfo
    func resolve(fleetOption: FleetOption) -> Observable<FleetInfoResolutionResponse>
}

public struct FleetInfoResolutionResponse: Equatable {
    public let fleetInfo: FleetInfo

    // If the requested FleetOption is .manual and corresponds to a fleet that is not available, this will be true.
    // Otherwise, it will be false.
    public let wasRequestedFleetAvailable: Bool

    public init(fleetInfo: FleetInfo, wasRequestedFleetAvailable: Bool) {
        self.fleetInfo = fleetInfo
        self.wasRequestedFleetAvailable = wasRequestedFleetAvailable
    }
}
