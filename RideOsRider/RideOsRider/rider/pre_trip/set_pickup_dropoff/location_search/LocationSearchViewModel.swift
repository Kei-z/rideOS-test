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
import RxSwift

public protocol LocationSearchViewModel {
    // Set the search text for pickup
    func setPickupText(_ text: String)

    // Set the search text for dropoff
    func setDropoffText(_ text: String)

    // Set whether the user is currently entering search text for pickup or dropoff
    func setFocus(_ focus: LocationSearchFocusType)

    // Call when a search option is selected
    func makeSelection(_ selectedLocation: LocationSearchOption)

    // Call when the user cancels the search
    func cancel()

    // Call when the user is done searching for both pickup and dropoff
    func done()

    // Get current list of geocoded options based on current search text
    func getLocationOptions() -> Observable<[LocationSearchOption]>

    func getSelectedPickup() -> Observable<String>

    func getSelectedDropOff() -> Observable<String>

    func isDoneActionEnabled() -> Observable<Bool>
}
