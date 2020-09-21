//
//  Errors.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

// Error Design: https://stackoverflow.com/a/57081275/5868190

import Foundation
import Alamofire

enum UntisError {
    case network(type: Enums.NetworkError)
    case custom(errorDescription: String?)
    case alamofire(error: AFError)
    case untis(type: Enums.UntisErrors)
    
    class Enums { }
}

extension UntisError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .network(let type): return type.localizedDescription
            case .custom(let errorDescription): return errorDescription
            case .alamofire(let error): return error.errorDescription
            case .untis(let error): return error.errorDescription
        }
    }
}

// MARK: - Network Errors

extension UntisError.Enums {
    enum NetworkError {
        case parsing
        case notFound
        case custom(errorCode: Int?, errorDescription: String?)
    }
}

extension UntisError.Enums.NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .parsing: return "Parsing error"
            case .notFound: return "URL Not Found"
            case .custom(_, let errorDescription): return errorDescription
        }
    }

    var errorCode: Int? {
        switch self {
            case .parsing: return nil
            case .notFound: return 404
            case .custom(let errorCode, _): return errorCode
        }
    }
}

// MARK: - Untis Error

extension UntisError.Enums {
    enum UntisErrors: Equatable {
        case unknown
        case unauthorized
        case credentialsNotSet
        case noElementProvided
        case serverError
        case serverMissingResult
        case invalidPersonType
        case invalidPersonId
        case permissionDenied
        case methodNotFound
        case resultParseError
        case invalidLogin
        case custom(errorCode: Int?, errorDescription: String?)
        
        static let ErrorMap: [Int: UntisErrors] = [
            -32601: .methodNotFound,
            -8509: .permissionDenied,
            505: .invalidPersonId,
            504: .invalidPersonType,
            502: .serverMissingResult,
            501: .serverError,
            -7002: .noElementProvided,
            402: .credentialsNotSet,
            -8520: .unauthorized,
            -500: .unknown,
            -501: .resultParseError,
            -8504: .invalidLogin
        ]
        
        func fromUntisCode(code: Int) -> UntisErrors {
            guard let error = UntisErrors.ErrorMap[code] else {
                return .unknown;
            }
            return error;
        }
    }
}

extension UntisError.Enums.UntisErrors: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .custom(_, let errorDescription): return errorDescription
            case .unknown: return "Unknown WebUntis error"
            case .unauthorized: return "Unauthorized"
            case .credentialsNotSet: return "Credentials not set"
            case .noElementProvided: return "No element provided"
            case .serverError: return "WebUntis server error"
            case .serverMissingResult: return "Server missing result"
            case .invalidPersonType: return "Invalid person type"
            case .invalidPersonId: return "Invalid person id"
            case .permissionDenied: return "Permission denied"
            case .methodNotFound: return "Method not found"
            case .resultParseError: return "Server result parse error"
            case .invalidLogin: return "Invalid credentials"
        }
    }

    var errorCode: Int? {
        for (key, error) in UntisError.Enums.UntisErrors.ErrorMap {
            if self == error {
                return key;
            }
        }
        return -500;
    }
}
