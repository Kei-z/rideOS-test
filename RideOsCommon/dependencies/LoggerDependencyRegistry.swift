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

public class LoggerDependencyRegistry {
    public static var instance: LoggerDependencyRegistry {
        guard let instance = LoggerDependencyRegistry.globalInstance else {
            fatalError(
                """
                No LoggerDependencyRegistry created. Please create one by calling LoggerDependencyRegistry.create() or \
                creating a higher-level dependency registry by calling, ex: RiderDependencyRegistry.create() or \
                DriverDependencyRegistry.create().
                """
            )
        }
        return instance
    }

    public static func create(logger: Logger) {
        globalInstance = LoggerDependencyRegistry(logger: logger)
    }

    private static var globalInstance: LoggerDependencyRegistry?

    public let logger: Logger

    private init(logger: Logger) {
        self.logger = logger
    }
}
