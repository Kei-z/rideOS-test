import Foundation
import RxSwift
import RxTest
import XCTest

/**
 Assert a list of Recorded events has emitted the provided elements with no stop events in between. A single completion
 event, however IS allowed in the stream after the provided elements have been emitted. This method does not take event
 times into consideration.

 NOTE: this is basically a copy of XCTAssertRecordedElements() that does not fail if stream contains a terminating
 completion event after all of the specified elements.

 - parameter stream: Array of recorded events.
 - parameter elements: Array of expected elements.
 */

// swiftlint:disable identifier_name

public func AssertRecordedElementsIgnoringCompletion<T: Equatable>(_ stream: [Recorded<Event<T>>],
                                                                   _ elements: [T],
                                                                   file _: StaticString = #file,
                                                                   line _: UInt = #line) {
    XCTAssertTrue(stream.count == elements.count || stream.count == elements.count + 1)

    if !elements.isEmpty {
        XCTAssertRecordedElements(Array(stream[0 ..< elements.count]), elements)
    }

    if stream.count == elements.count + 1 {
        XCTAssertTrue(stream.last!.value.isCompleted)
    }
}

// swiftlint:enable identifier_name
