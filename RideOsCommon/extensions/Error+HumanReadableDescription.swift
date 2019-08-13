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

extension Error {
    public var humanReadableDescription: String {
        let error = self as NSError

        let domain = error.domain
        let code = error.code

        let description = error.localizedDescription
        let codeString: String
        if let grpcStatusString = error.gRPCStatusCodeString() {
            codeString = "\(code) (\(grpcStatusString))"
        } else {
            codeString = "\(code)"
        }

        return "domain:\(domain) code:\(codeString) description:\(description)"
    }
}
