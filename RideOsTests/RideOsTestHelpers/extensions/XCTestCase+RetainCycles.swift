import Foundation
import XCTest

// NOTE: This is shamelessly borrowed from: https://paul-samuels.com/blog/2018/11/20/unit-testing-retain-cycles/
public extension XCTestCase {
    // TODO(chrism): We should consider moving this into ReactiveTestCase and coming up with a clever way to ensure
    // that it is always run on the object-under-test
    func assertNil(_ subject: AnyObject?, after: @escaping () -> Void, file: StaticString = #file, line: UInt = #line) {
        guard let value = subject else {
            return XCTFail("Argument must not be nil", file: file, line: line)
        }
        addTeardownBlock { [weak value] in
            after()
            XCTAssert(value == nil, "Expected subject to be nil after test! Retain cycle?", file: file, line: line)
        }
    }
}
