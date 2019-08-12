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
import RxSwift

public class UserStorageHistoricalSearchInteractor: HistoricalSearchInteractor {
    public static let historicalSearchOptionsUserStorageKey =
        UserStorageKey<[LocationAutocompleteResult]>("UserStorageHistoricalSearchInteractorSearchOptionsKey")

    private let userStorageReader: UserStorageReader
    private let userStorageWriter: UserStorageWriter
    private let schedulerProvider: SchedulerProvider
    private let maxSearchOptionCount: Int

    public init(userStorageReader: UserStorageReader = UserDefaultsUserStorageReader(),
                userStorageWriter: UserStorageWriter = UserDefaultsUserStorageWriter(),
                schedulerProvider: SchedulerProvider = DefaultSchedulerProvider(),
                maxSearchOptionCount: Int = 10) {
        self.userStorageReader = userStorageReader
        self.userStorageWriter = userStorageWriter
        self.schedulerProvider = schedulerProvider
        self.maxSearchOptionCount = maxSearchOptionCount
    }

    public var historicalSearchOptions: Observable<[LocationAutocompleteResult]> {
        return userStorageReader
            .observe(UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey)
            .map { $0 ?? [] }
    }

    public func store(searchOption: LocationAutocompleteResult) -> Completable {
        return Completable
            .create(subscribe: { completable in
                self.writeToUserStorage(searchOption: searchOption)
                completable(.completed)

                return Disposables.create()
            })
            .subscribeOn(schedulerProvider.io())
    }

    private var storedHistoricalSearchOptions: [LocationAutocompleteResult] {
        return userStorageReader
            .get(UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey) ?? []
    }

    private func writeToUserStorage(searchOption: LocationAutocompleteResult) {
        var currentSearchOptions = storedHistoricalSearchOptions

        currentSearchOptions.removeAll { $0 == searchOption }
        currentSearchOptions = [searchOption] + currentSearchOptions
        if currentSearchOptions.count > maxSearchOptionCount {
            currentSearchOptions = Array(currentSearchOptions[0 ..< maxSearchOptionCount])
        }

        userStorageWriter.set(key: UserStorageHistoricalSearchInteractor.historicalSearchOptionsUserStorageKey,
                              value: currentSearchOptions)
    }
}
