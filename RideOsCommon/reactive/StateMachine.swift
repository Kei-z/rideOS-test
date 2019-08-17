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

public class StateMachine<T> {
    public typealias Transition = (T) throws -> T
    public typealias AsyncTransition = (T) throws -> Single<T>

    private let disposeBag = DisposeBag()
    private let stateTransitionSubject: PublishSubject<AsyncTransition> = PublishSubject()
    private let stateSubject: BehaviorSubject<T>
    private let logger: Logger

    public init(schedulerProvider: SchedulerProvider,
                initialState: T,
                logger: Logger = LoggerDependencyRegistry.instance.logger) {
        stateSubject = BehaviorSubject(value: initialState)
        self.logger = logger

        stateTransitionSubject
            .observeOn(schedulerProvider.computation())
            .withLatestFrom(stateSubject) { ($0, $1) }
            .flatMapLatest { transitionFunctionAndCurrentState -> Single<T> in
                let stateTransitionFunction = transitionFunctionAndCurrentState.0
                let currentState = transitionFunctionAndCurrentState.1

                // If the state transition fails, log the error and re-emit the current state instead of
                // stopping the state machine.
                do {
                    return try stateTransitionFunction(currentState)
                } catch {
                    logger.logError(error.humanReadableDescription)
                }

                return Single.just(currentState)
            }
            .subscribe(onNext: { [stateSubject] nextState in
                stateSubject.onNext(nextState)
            })
            .disposed(by: disposeBag)
    }

    public func transition(_ stateTransition: @escaping Transition) {
        stateTransitionSubject.onNext { [logger] currentState in
            do {
                return try Single.just(stateTransition(currentState))
            } catch {
                logger.logError(error.humanReadableDescription)
            }

            return Single.just(currentState)
        }
    }

    public func asyncTransition(_ stateTransition: @escaping AsyncTransition) {
        stateTransitionSubject.onNext(stateTransition)
    }

    public func observeCurrentState() -> Observable<T> {
        return stateSubject
    }

    public func getCurrentState() throws -> T {
        return try stateSubject.value()
    }
}
