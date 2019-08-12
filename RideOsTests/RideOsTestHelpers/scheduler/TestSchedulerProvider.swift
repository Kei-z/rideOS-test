import Foundation
import RideOsCommon
import RxSwift
import RxTest

public class TestSchedulerProvider: SchedulerProvider {
    let scheduler: TestScheduler

    public init(scheduler: TestScheduler) {
        self.scheduler = scheduler
    }

    public func io() -> SchedulerType {
        return scheduler
    }

    public func computation() -> SchedulerType {
        return scheduler
    }

    public func mainThread() -> SchedulerType {
        return scheduler
    }
}
