//
//  Authenticator.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation
import Alamofire
import Cache
import SwiftOTP

class UntisAuthenticator: Authenticator {
    let cache: Storage<String, AuthSession>?;
    let key: String;
    
    init(storage: Storage<String, AuthSession>?, key: String) {
        self.cache = storage;
        self.key = key;
    }
    
    func apply(_ credential: UntisCredentials, to urlRequest: inout URLRequest) {
        urlRequest.setValue("JSESSIONID=\(credential.session!)", forHTTPHeaderField: "Cookie");
        urlRequest.httpShouldHandleCookies = true;
        
        // Autofill options.element with current session information
        if let httpBody: Data = urlRequest.httpBody {
            if var body: [String: Any] = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
                var update: Bool = false;
                if let id: String = body[keyPath: "params.options.element.id"] as? String {
                    if id == "auto" {
                        log.debug("Replace params.options.element.id with \(String(describing: credential.id))")
                        body[keyPath: "params.options.element.id"] = credential.id;
                        update = true;
                    }
                }
                if let type: String = body[keyPath: "params.options.element.type"] as? String {
                    if type == "auto" {
                        log.debug("Replace params.options.element.type with \(String(describing: credential.type))")
                        body[keyPath: "params.options.element.type"] = credential.type;
                        update = true;
                    }
                }
                
                if update {
                    if let serializedData: Data = try? JSONSerialization.data(withJSONObject: body, options: []) {
                        urlRequest.httpBody = serializedData;
                    }
                }
            }
        }
    }
    
    func refresh(_ credential: UntisCredentials, for session: Session, completion: @escaping (Swift.Result<UntisCredentials, Error>) -> Void) {
        let configuration = URLSessionConfiguration.af.default;
        configuration.httpShouldSetCookies = false;
        let session = Session(configuration: configuration)
        if credential.authType == AuthType.PASSWORD {
            let login: Parameters = [
                "id": "SITNU",
                "method": "authenticate",
                "jsonrpc": "2.0",
                "params": [
                    "user": credential.username,
                    "password": credential.password,
                    "client": "SITNU"
                ]
            ];
            session.request("https://\(credential.server)/WebUntis/jsonrpc.do?school=\(credential.school)", method: .post, parameters: login, encoding: JSONEncoding.default).responseJSON { response in
                let _ = session; // Keep reference
                switch response.result {
                    case .failure(let error):
                        completion(.failure(UntisError.alamofire(error: error)));
                        break;
                    case .success(_):
                        guard let json = try? response.result.get() as? [String: Any] else {
                            completion(.failure(UntisError.untis(type: .resultParseError)))
                            return
                        }
                        guard let result = json["result"] as? [String: Any] else {
                            guard let error = json[keyPath: "error.code"] as? Int else {
                                completion(.failure(UntisError.untis(type: .serverMissingResult)));
                                return;
                            }
                            if error == -8504 {
                                completion(.failure(UntisError.untis(type: .invalidLogin)));
                                return;
                            } else {
                                completion(.failure(UntisError.untis(type: .unknown)));
                                return;
                            }
                        }
                        guard let sessionId = result["sessionId"] as? String else {
                            completion(.failure(UntisError.untis(type: .invalidLogin)));
                            return;
                        }
                        guard let type = result["personType"] as? Int else {
                            completion(.failure(UntisError.untis(type: .invalidPersonType)));
                            return;
                        }
                        guard let id = result["personId"] as? Int else {
                            completion(.failure(UntisError.untis(type: .invalidPersonId)));
                            return;
                        }
                        var newCredentials = credential;
                        newCredentials.type = type;
                        newCredentials.id = id;
                        newCredentials.session = sessionId;
                        newCredentials.issuedAt = Date();
                        if self.cache != nil {
                            let cacheCredentials = AuthSession(username: newCredentials.username, password: newCredentials.password, server: newCredentials.server, school: newCredentials.school, authType: newCredentials.authType, session: newCredentials.session, issuedAt: newCredentials.issuedAt, type: newCredentials.type, id: newCredentials.id);
                            let _ = try? self.cache!.setObject(cacheCredentials, forKey: self.key);
                        }
                        completion(.success(newCredentials));
                }
            }
        } else {
            guard let secretData = base32DecodeToData(credential.password) else {
                completion(.failure(UntisError.custom(errorDescription: "Failed to decode OTP secret")));
                return;
            }
            guard let tokenObject = TOTP(secret: secretData) else {
                completion(.failure(UntisError.custom(errorDescription: "Failed to create OTP token object")));
                return;
            };
            let currentDate = Date();
            guard let token = tokenObject.generate(time: currentDate) else {
                completion(.failure(UntisError.custom(errorDescription: "Failed to generate OTP token")));
                return;
            }
            let login: Parameters = [
                "id": "SITNU",
                "method": "getUserData2017",
                "jsonrpc": "2.0",
                "params": [
                    [
                        "auth": [
                            "clientTime": Double(currentDate.timeIntervalSince1970 * 1000),
                            "user": credential.username,
                            "otp": token
                        ]
                    ]
                ]
            ];
            session.request("https://\(credential.server)/WebUntis/jsonrpc_intern.do?school=\(credential.school)&a=0&s=\(credential.server)&m=getUserData2017&v=i3.23.0", method: .post, parameters: login, encoding: JSONEncoding.default).responseJSON { response in
                let _ = session; // Keep reference
                switch response.result {
                    case .failure(let error):
                        completion(.failure(UntisError.alamofire(error: error)));
                        break;
                    case .success(_):
                        if let headerFields = response.response?.allHeaderFields as? [String: String], let URL = response.request?.url {
                            let cookies = HTTPCookie.cookies(withResponseHeaderFields: headerFields, for: URL)
                            var sessionId: String?;
                            for cookie in cookies {
                                if cookie.name == "JSESSIONID" {
                                    sessionId = cookie.value;
                                }
                            }
                            if sessionId == nil {
                                completion(.failure(UntisError.untis(type: .invalidLogin)));
                                return;
                            }
                            
                            guard let json = try? response.result.get() as? [String: Any] else {
                                completion(.failure(UntisError.untis(type: .resultParseError)))
                                return
                            }
                            
                            guard let result = json["result"] as? [String: Any] else {
                                guard let error = json[keyPath: "error.code"] as? Int else {
                                    completion(.failure(UntisError.untis(type: .serverMissingResult)));
                                    return;
                                }
                                if error == -8504 {
                                    completion(.failure(UntisError.untis(type: .invalidLogin)));
                                    return;
                                } else {
                                    completion(.failure(UntisError.untis(type: .unknown)));
                                    return;
                                }
                            }
                            
                            guard let userData = result["userData"] as? [String: Any] else {
                                completion(.failure(UntisError.untis(type: .missingUserData)));
                                return;
                            }
                            
                            guard let elemType = userData["elemType"] as? String else {
                                completion(.failure(UntisError.untis(type: .invalidLogin)));
                                return;
                            }
                            
                            guard let elemId = userData["elemId"] as? Int else {
                                completion(.failure(UntisError.untis(type: .invalidLogin)));
                                return;
                            }
                            
                            var newCredentials = credential;
                            switch elemType {
                            case "TEACHER":
                                newCredentials.type = 2;
                                break;
                            case "STUDENT":
                                newCredentials.type = 5;
                                break;
                            default:
                                newCredentials.type = 5;
                                break;
                            }
                            newCredentials.id = elemId;
                            newCredentials.session = sessionId;
                            newCredentials.issuedAt = Date();
                            if self.cache != nil {
                                let cacheCredentials = AuthSession(username: newCredentials.username, password: newCredentials.password, server: newCredentials.server, school: newCredentials.school, authType: newCredentials.authType, session: newCredentials.session, issuedAt: newCredentials.issuedAt, type: newCredentials.type, id: newCredentials.id);
                                let _ = try? self.cache!.setObject(cacheCredentials, forKey: self.key);
                            }
                            completion(.success(newCredentials));
                        } else {
                            completion(.failure(UntisError.untis(type: .missingSessionCookie)));
                        }
                        break;
                }
            }
        }
    }
    
    func didRequest(_ urlRequest: URLRequest, with response: HTTPURLResponse, failDueToAuthenticationError error: Error) -> Bool {
        // If authentication server CANNOT invalidate credentials, return `false`
        if let underlyingError = error.asAFError?.underlyingError {
            if let authError = underlyingError as? Alamofire.AuthenticationError {
                if authError == .missingCredential {
                    return true;
                }
            }
        }
        return false
    }
    
    func isRequest(_ urlRequest: URLRequest, authenticatedWith credential: UntisCredentials) -> Bool {
        // If authentication server CANNOT invalidate credentials, return `true`
        if credential.session == nil {
            return false;
        }
        return urlRequest.headers.first(where: { $0.name == "Cookie" && $0.value == "JSESSIONID=\(credential.session!)" }) != nil
    }
}
