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
import RxSwift

// An implementation of UserStorageReader that uses iOS's UserDefaults for underlying storage
//
// NOTE: We encode every type other than primitives such as strings, ints, and bools into Property Lists and
// store them as opaque Data. We can't use this approach for primitives because they cannot be directly encoded
// into Property Lists, so we special case them and skip encoding them as Property Lists.
public class UserDefaultsUserStorageReader: UserStorageReader {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    public var userId: String {
        if let userId = userDefaults.string(forKey: CommonUserStorageKeys.userId.key) {
            return userId
        } else {
            fatalError("No user Id set. Is there a user logged in?")
        }
    }

    public var environment: ServiceDefaultsValue {
        return ServiceDefaultsValue(
            rawValue: userDefaults.integer(
                forKey: rideSDKConstants.serviceDefaultsKey
            )
        ) ?? .production
    }

    public var fleetOption: FleetOption {
        return get(CommonUserStorageKeys.fleetOption) ?? .automatic
    }

    public func get<T>(_ key: UserStorageKey<T>) -> T? {
        if UserDefaultsUserStorageTypes.correspondsToPrimitiveType(key) {
            return userDefaults.value(forKey: key.key) as? T
        } else {
            if let data = userDefaults.value(forKey: key.key) as? Data {
                // swiftlint:disable force_try
                return try! PropertyListDecoder().decode(T.self, from: data)
                // swiftlint:enable force_try
            }
        }
        return nil
    }

    public func observe<T>(_ key: UserStorageKey<T>) -> Observable<T?> {
        if UserDefaultsUserStorageTypes.correspondsToPrimitiveType(key) {
            return userDefaults.rx.observe(T.self, key.key)
        } else {
            return userDefaults.rx.observe(Any.self, key.key)
                .map {
                    if let data = $0 as? Data {
                        // swiftlint:disable force_try
                        return try! PropertyListDecoder().decode(T.self, from: data)
                        // swiftlint:enable force_try
                    }
                    return nil
                }
        }
    }
}
