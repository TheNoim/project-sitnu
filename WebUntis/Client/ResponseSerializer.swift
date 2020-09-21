//
//  ResponseSerializer.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation
import Alamofire

struct UntisResponseSerializer<Result>: ResponseSerializer {
    typealias SerializedObject = Result;
    
    func serialize<Result>(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Result {
        let json = try JSONResponseSerializer().serialize(request: request, response: response, data: data, error: error);
        
        guard let root = json as? [String: Any] else {
            throw UntisError.untis(type: .serverError);
        }
        
        if let error = root["error"] as? [String: Any] {
            guard let code = error["code"] as? Int else {
                throw UntisError.untis(type: .unknown);
            }
            // TODO: Add more error codes
            switch (code) {
            case -8520:
                // Retry with new credentials
                throw AuthenticationError.missingCredential;
            case -8509:
                throw UntisError.untis(type: .permissionDenied);
            case -32601:
                throw UntisError.untis(type: .methodNotFound);
            default:
                throw UntisError.untis(type: .unknown);
            }
        }
        
        guard let result = root["result"] as? Result else {
            throw UntisError.untis(type: .serverMissingResult);
        }
        
        return result;
    }
}
