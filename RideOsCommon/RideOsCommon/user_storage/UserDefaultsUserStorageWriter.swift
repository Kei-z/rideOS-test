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
import RideOsApi

// An implementation of UserStorageWriter that uses iOS's UserDefaults for underlying storage
public class UserDefaultsUserStorageWriter: UserStorageWriter {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    public func set(userId: String) {
        userDefaults.set(userId, forKey: CommonUserStorageKeys.userId.key)
    }

    public func set(environment: ServiceDefaultsValue) {
        userDefaults.set(environment.rawValue, forKey: rideSDKConstants.serviceDefaultsKey)
    }

    public func set(fleetOption: FleetOption) {
        set(key: CommonUserStorageKeys.fleetOption, value: fleetOption)
    }

    public func set<T>(key: UserStorageKey<T>, value: T?) {
        if let value = value {
            if UserDefaultsUserStorageTypes.correspondsToPrimitiveType(key) {
                userDefaults.set(value, forKey: key.key)
            } else {
                // swiftlint:disable force_try
                userDefaults.set(try! PropertyListEncoder().encode(value), forKey: key.key)
                // swiftlint:enable force_try
            }
        } else {
            userDefaults.removeObject(forKey: key.key)
        }
    }
}
