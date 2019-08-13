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

let milesPerMeter: Double = 0.00062137

extension String {
    public static func minutesLabelWith(timeInterval: TimeInterval) -> String {
        var timeInMinutes = Int(round(timeInterval / 60.0))
        if timeInMinutes == 0 {
            timeInMinutes = 1
        }

        return String(format: RideOsCommonResourceLoader.instance.getString("ai.rideos.common.minutes.format"),
                      timeInMinutes)
    }

    public static func milesLabelWith(meters: CLLocationDistance) -> String {
        let distanceInMiles = meters * milesPerMeter

        return String(format: RideOsCommonResourceLoader.instance.getString("ai.rideos.common.miles.format"),
                      distanceInMiles)
    }

    public static func timeOfDayLabelFrom(startDate: Date,
                                          interval: TimeInterval) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm"
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: startDate.addingTimeInterval(interval))
    }
}
