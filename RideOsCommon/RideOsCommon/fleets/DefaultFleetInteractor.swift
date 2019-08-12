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

public class DefaultFleetInteractor: FleetInteractor {
    private let operationsService: RideHailOperationsRideHailOperationsService

    public init(
        operationsService: RideHailOperationsRideHailOperationsService =
            RideHailOperationsRideHailOperationsService.serviceWithApiHost()
    ) {
        self.operationsService = operationsService
    }

    public var availableFleets: Observable<[FleetInfo]> {
        return Observable.create { observer in
            let getFleetsRequest = RideHailOperationsGetFleetsRequest()

            let call = self.operationsService.rpcToGetFleets(with: getFleetsRequest) { response, error in
                guard error == nil else {
                    observer.onError(error!)
                    return
                }

                guard let response = response else {
                    observer.onError(FleetInteractorError.invalidResponse)
                    return
                }

                guard let fleets = response.fleetArray as NSArray as? [RideHailCommonsFleet] else {
                    observer.onError(FleetInteractorError.invalidResponse)
                    return
                }

                observer.onNext(fleets.map {
                    FleetInfo(fleetId: $0.id_p, displayName: $0.id_p, center: nil, isPhantom: false)
                })
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }
}
