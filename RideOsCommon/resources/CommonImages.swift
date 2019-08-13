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

public class CommonImages {
    public static func greenPin() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.images.green-pin")
    }

    public static func redPin() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.images.red-pin")
    }

    public static func car() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.images.car")
    }

    public static func menu() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.map.menu")
    }

    public static func crosshair() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.map.crosshair")
    }

    public static func person() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.settings.profile.person")
    }

    public static func gear() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.settings.profile.gear")
    }

    public static func userPhotoMask() -> UIImage {
        return RideOsCommonResourceLoader.instance.getImage("ai.rideos.common.settings.profile.user-photo-mask")
    }
}
