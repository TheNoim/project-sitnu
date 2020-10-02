//
//  ResponseSerializer.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation
import Alamofire

struct UntisResponseSerializer: ResponseSerializer {
    let baseSerializer: JSONResponseSerializer;
    
    init() {
        self.baseSerializer = JSONResponseSerializer();
    }
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [String: Any] {
        let json = try self.baseSerializer.serialize(request: request, response: response, data: data, error: error);
        
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
        return root;
    }
}

struct UntisIntSerializer: ResponseSerializer {
    let baseUntisResponseSerializer: UntisResponseSerializer;
    
    init() {
        self.baseUntisResponseSerializer = UntisResponseSerializer();
    }
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> Int64 {
        log.debug("Start serializing")
        
        let root = try self.baseUntisResponseSerializer.serialize(request: request, response: response, data: data, error: error);
        
        log.debug("Got this as result", context: ["result": root["result"]]);
        
        guard let result = root["result"] as? Int64 else {
            log.error("Missing server result", context: ["json": root, "error": error as Any, "usedSerializer": "Int"])
            throw UntisError.untis(type: .serverMissingResult);
        }
        
        return result;
    }
}

struct UntisArraySerializer: ResponseSerializer {
    let baseUntisResponseSerializer: UntisResponseSerializer;
    
    init() {
        self.baseUntisResponseSerializer = UntisResponseSerializer();
    }
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [Any] {
        let root = try self.baseUntisResponseSerializer.serialize(request: request, response: response, data: data, error: error);
        
        guard let result = root["result"] as? [Any] else {
            log.error("Missing server result", context: ["json": root, "error": error as Any, "usedSerializer": "Array"])
            throw UntisError.untis(type: .serverMissingResult);
        }
        
        return result;
    }
}

struct UntisObjectSerializer: ResponseSerializer {
    let baseUntisResponseSerializer: UntisResponseSerializer;
    
    init() {
        self.baseUntisResponseSerializer = UntisResponseSerializer();
    }
    
    func serialize(request: URLRequest?, response: HTTPURLResponse?, data: Data?, error: Error?) throws -> [String: Any] {
        let root = try self.baseUntisResponseSerializer.serialize(request: request, response: response, data: data, error: error);
        
        guard let result = root["result"] as? [String: Any] else {
            log.error("Missing server result", context: ["json": root, "error": error as Any, "usedSerializer": "Object"])
            throw UntisError.untis(type: .serverMissingResult);
        }
        
        return result;
    }
}
