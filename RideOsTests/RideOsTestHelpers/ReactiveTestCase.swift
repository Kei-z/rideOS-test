import Foundation
import RxSwift
import RxTest
import XCTest

open class ReactiveTestCase: XCTestCase {
    public var scheduler: TestScheduler!
    public var disposeBag: DisposeBag!

    open override func setUp() {
        super.setUp()
        scheduler = TestScheduler(initialClock: 0)
        disposeBag = DisposeBag()
    }

    public func startSchedulerAndApplyClosures(_ closures: [() -> Void]) {
        let times = 0 ..< closures.count
        scheduler
            .createColdObservable(zip(times, closures).map { .next($0, $1) })
            .subscribe(onNext: { closure in closure() })
            .disposed(by: disposeBag)
        scheduler.start()
    }
}
