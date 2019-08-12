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
import RideOsCommon

public class RiderDependencyRegistry {
    public static var instance: RiderDependencyRegistry {
        guard let instance = RiderDependencyRegistry.globalInstance else {
            fatalError(
                "No RiderDependencyRegistry created. Please create one by calling RiderDependencyRegistry.create()"
            )
        }
        return instance
    }

    public static func create(riderDependencyFactory: RiderDependencyFactory = DefaultRiderDependencyFactory(),
                              mapsDependencyFactory: MapsDependencyFactory,
                              logger: Logger = ConsoleLogger()) {
        globalInstance = RiderDependencyRegistry(riderDependencyFactory: riderDependencyFactory,
                                                 mapsDependencyFactory: mapsDependencyFactory,
                                                 logger: logger)
    }

    private static var globalInstance: RiderDependencyRegistry?

    public let riderDependencyFactory: RiderDependencyFactory
    public let mapsDependencyFactory: MapsDependencyFactory

    private init(riderDependencyFactory: RiderDependencyFactory,
                 mapsDependencyFactory: MapsDependencyFactory,
                 logger: Logger) {
        self.riderDependencyFactory = riderDependencyFactory
        self.mapsDependencyFactory = mapsDependencyFactory
        registerCommonDependencyFactory()
        LoggerDependencyRegistry.create(logger: logger)
    }

    private func registerCommonDependencyFactory() {
        CommonDependencyRegistry.create(
            commonDependencyFactory: riderDependencyFactory,
            mapsDependencyFactory: mapsDependencyFactory
        )
    }
}
