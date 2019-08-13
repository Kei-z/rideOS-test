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

import Auth0
import RideOsApi
import RxSwift

public class User {
    public static let scopes = "email offline_access openid profile"
    public static let currentUser = User()

    weak var delegate: UserDelegate?

    private let credentialsManager: CredentialsManager
    private var cachedProfile: Profile?

    public var profile: Profile? {
        return cachedProfile
    }

    init(credentialsManager: CredentialsManager = CredentialsManager(authentication: Auth0.authentication()),
         configuration: Configuration = Configuration.sharedConfiguration) {
        self.credentialsManager = credentialsManager
        configuration.setTokenProvider(getAccessToken)
    }

    public func getAccessToken(_ callback: @escaping (String?) -> Void) {
        credentialsManager.credentials(withScope: User.scopes) { error, credentials in
            guard error == nil, let accessToken = credentials?.accessToken else {
                // There's an issue with the credentials, force the user to log in again
                print("User: Could not get credentials \(error!.localizedDescription)")
                self.delegate?.credentials(areInvalid: self)
                callback(nil)
                return
            }
            callback(accessToken)
        }
    }

    public func fetchProfile(callback: ((Profile?) -> Void)?) {
        getAccessToken { accessToken in
            guard let accessToken = accessToken else {
                print("User: Could not fetch user info, not logged in")
                callback?(nil)
                return
            }

            Auth0.authentication()
                .userInfo(token: accessToken)
                .start { result in
                    switch result {
                    case let .success(profile):
                        self.cachedProfile = profile
                        callback?(profile)
                    case let .failure(error):
                        logError("User: Could not fetch user info (\(error.localizedDescription))")
                        callback?(nil)
                    }
                }
        }
    }

    public var profileObservable: Observable<Profile> {
        return Observable.create { observer in
            self.getAccessToken { accessToken in
                guard let accessToken = accessToken else {
                    observer.onError(FetchAccessTokenError.noAccessToken)
                    return
                }

                Auth0.authentication()
                    .userInfo(token: accessToken)
                    .start { result in
                        switch result {
                        case let .success(profile):
                            observer.onNext(profile)
                        case let .failure(error):
                            observer.onError(error)
                        }
                    }
            }
            return Disposables.create()
        }
    }

    public func hasCredentials() -> Bool {
        return credentialsManager.hasValid()
    }

    public func updateCredentials(_ credentials: Credentials) -> Bool {
        return credentialsManager.store(credentials: credentials)
    }

    public func clearCredentials() -> Bool {
        return credentialsManager.clear()
    }
}

protocol UserDelegate: NSObjectProtocol {
    func credentials(areInvalid user: User)
}

public enum FetchAccessTokenError: Error {
    case noAccessToken
}
