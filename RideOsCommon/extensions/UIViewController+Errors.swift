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

import grpc

public func logError(_ message: String) {
    LoggerDependencyRegistry.instance.logger.logError(message)
}

public func logWarn(_ message: String) {
    LoggerDependencyRegistry.instance.logger.logWarn(message)
}

public func logInfo(_ message: String) {
    LoggerDependencyRegistry.instance.logger.logInfo(message)
}

public func logNSError(_: String, error: NSError) {
    let domain = error.domain
    let code = error.code
    guard domain != "io.grpc" || code != Int(GRPC_STATUS_CANCELLED.rawValue) else {
        return
    }

    guard domain != NSCocoaErrorDomain || code != NSUserCancelledError else {
        return
    }

    logError(error.humanReadableDescription)
}

public func logFatalError(_ message: String) {
    #if DEBUG
        fatalError("FATAL ERROR: \(message)")
    #else
        logError(message)
    #endif
}

public extension UIViewController {
    func showErrorAlert(title: String, message: String? = nil) {
        if let message = message {
            logError("\(title) - \(message)")
        } else {
            logError("\(title)")
        }

        let buttonTitle = RideOsCommonResourceLoader.instance.getString("ai.rideos.common.uiviewcontroller.errors.ok")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }

    func showErrorAlert(title: String, error: Error) {
        let nsError = error as NSError
        let codeString: String
        if let grpcStatusString = nsError.gRPCStatusCodeString() {
            codeString = "\(nsError.code) (\(grpcStatusString))"
        } else {
            codeString = "\(nsError.code)"
        }

        logError("\(title) Description: \(error.localizedDescription) Code: \(codeString)")

        let message = "Description: \(error.localizedDescription)\nCode: \(codeString)"
        let buttonTitle = RideOsCommonResourceLoader.instance.getString("ai.rideos.common.uiviewcontroller.errors.ok")

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
        present(alert, animated: true)
    }
}
