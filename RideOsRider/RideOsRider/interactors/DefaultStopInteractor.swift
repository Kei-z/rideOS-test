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

import CoreLocation
import Foundation
import RideOsApi
import RxSwift

public class DefaultStopInteractor: StopInteractor {
    private let riderService: RideHailRiderRideHailRiderService
    public init(riderService: RideHailRiderRideHailRiderService = RideHailRiderRideHailRiderService.serviceWithApiHost()) {
        self.riderService = riderService
    }

    public func getStop(nearLocation location: CLLocationCoordinate2D, forFleet fleetId: String) -> Observable<Stop> {
        return Observable.create { observer in
            let request = RideHailRiderFindPredefinedStopRequest()
            request.searchParameters.queryPosition = Position(coordinate: location)
            request.fleetId = fleetId

            let call = self.riderService.rpcToFindPredefinedStop(with: request) { response, error in
                if let error = error {
                    observer.onError(error)
                    return
                }

                guard let response = response,
                    let stop = response.predefinedStopArray.firstObject as? RideHailCommonsPredefinedStop,
                    let position = stop.position else {
                    observer.onError(StopInteractorError.invalidResponse)
                    return
                }

                observer.onNext(Stop(location: position.coordinate(), locationId: stop.id_p))
            }

            call.start()

            return Disposables.create { call.cancel() }
        }
    }
}
