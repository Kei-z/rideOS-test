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

public class DriverDependencyRegistry {
    public static var instance: DriverDependencyRegistry {
        guard let instance = DriverDependencyRegistry.globalInstance else {
            fatalError(
                "No DriverDependencyRegistry created. Please create one by calling DriverDependencyRegistry.create()"
            )
        }
        return instance
    }

    public static func create(driverDependencyFactory: DriverDependencyFactory = DefaultDriverDependencyFactory(),
                              mapsDependencyFactory: MapsDependencyFactory,
                              logger: Logger = ConsoleLogger()) {
        globalInstance = DriverDependencyRegistry(driverDependencyFactory: driverDependencyFactory,
                                                  mapsDependencyFactory: mapsDependencyFactory,
                                                  logger: logger)
    }

    private static var globalInstance: DriverDependencyRegistry?

    public let driverDependencyFactory: DriverDependencyFactory
    public let mapsDependencyFactory: MapsDependencyFactory

    private init(driverDependencyFactory: DriverDependencyFactory,
                 mapsDependencyFactory: MapsDependencyFactory,
                 logger: Logger) {
        self.driverDependencyFactory = driverDependencyFactory
        self.mapsDependencyFactory = mapsDependencyFactory
        LoggerDependencyRegistry.create(logger: logger)
        registerCommonDependencyFactory()
    }

    private func registerCommonDependencyFactory() {
        CommonDependencyRegistry.create(
            commonDependencyFactory: driverDependencyFactory,
            mapsDependencyFactory: mapsDependencyFactory
        )
    }
}
