import Foundation
import RxSwift
import RxTest

public extension TestScheduler {
    // Creates a `TestableObserver` instance which immediately subscribes to the `source` and disposes the subscription
    // at virtual time 100000.
    func record<O: ObservableConvertibleType>(_ source: O) -> TestableObserver<O.E> {
        let observer = createObserver(O.E.self)
        let disposable = source.asObservable().bind(to: observer)
        scheduleAt(100_000) {
            disposable.dispose()
        }
        return observer
    }
}
