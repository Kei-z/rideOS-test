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

public class CommonDependencyRegistry {
    public static var instance: CommonDependencyRegistry {
        guard let instance = CommonDependencyRegistry.globalInstance else {
            fatalError(
                """
                No CommonDependencyRegistry created. Please create one by calling CommonDependencyRegistry.create() or \
                creating a higher-level dependency registry by calling, ex: RiderDependencyRegistry.create() or \
                DriverDependencyRegistry.create().
                """
            )
        }
        return instance
    }

    public static func create(commonDependencyFactory: CommonDependencyFactory,
                              mapsDependencyFactory: MapsDependencyFactory) {
        globalInstance = CommonDependencyRegistry(commonDependencyFactory: commonDependencyFactory,
                                                  mapsDependencyFactory: mapsDependencyFactory)
    }

    private static var globalInstance: CommonDependencyRegistry?

    public let commonDependencyFactory: CommonDependencyFactory
    public let mapsDependencyFactory: MapsDependencyFactory

    private init(commonDependencyFactory: CommonDependencyFactory, mapsDependencyFactory: MapsDependencyFactory) {
        self.commonDependencyFactory = commonDependencyFactory
        self.mapsDependencyFactory = mapsDependencyFactory
    }
}
