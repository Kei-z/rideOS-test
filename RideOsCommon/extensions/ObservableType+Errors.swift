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
import RxSwiftExt

extension ObservableType {
    public static func defaultRepeatBehavior() -> RepeatBehavior {
        return RepeatBehavior.immediate(maxCount: 5)
    }

    public func logErrors(logger: Logger) -> Observable<E> {
        // swiftformat:disable redundantSelf
        return self.do(onError: { logger.logError($0.humanReadableDescription) })
        // swiftformat:enable redundantSelf
    }

    public func logErrorsAndRetry(
        repeatBehavior: RepeatBehavior = Self.defaultRepeatBehavior(),
        logger: Logger
    ) -> Observable<E> {
        return logErrors(logger: logger).retry(repeatBehavior)
    }

    public func logErrorsRetryAndDefault(
        to defaultValue: E,
        with repeatBehavior: RepeatBehavior = Self.defaultRepeatBehavior(),
        logger: Logger
    ) -> Observable<E> {
        return logErrorsAndRetry(repeatBehavior: repeatBehavior, logger: logger).catchErrorJustReturn(defaultValue)
    }

    public func logErrorsRetryAndCompleteOnError(
        with repeatBehavior: RepeatBehavior = Self.defaultRepeatBehavior(),
        logger: Logger
    ) -> Observable<E> {
        return logErrors(logger: logger).retry(repeatBehavior).catchErrorJustComplete()
    }
}
