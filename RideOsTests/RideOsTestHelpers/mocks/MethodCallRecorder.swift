import Foundation

open class MethodCallRecorder {
    public var methodCalls: [String] = []

    public init() {}

    public func recordMethodCall(_ methodName: String) {
        methodCalls.append(methodName)
    }
}
