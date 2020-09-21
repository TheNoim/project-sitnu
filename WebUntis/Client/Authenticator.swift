//
//  Authenticator.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation
import Alamofire
import Cache

class UntisAuthenticator: Authenticator {
    let cache: Storage<AuthSession>?;
    let key: String;
    
    init(storage: Storage<AuthSession>?, key: String) {
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
                        body[keyPath: "params.options.element.id"] = credential.id;
                        update = true;
                    }
                }
                if let type: String = body[keyPath: "params.options.element.type"] as? String {
                    if type == "auto" {
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
        AF.request("https://\(credential.server)/WebUntis/jsonrpc.do?school=\(credential.school)", method: .post, parameters: login, encoding: JSONEncoding.default).responseJSON { response in
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
                    let cacheCredentials = AuthSession(username: newCredentials.username, password: newCredentials.password, server: newCredentials.server, school: newCredentials.school, session: newCredentials.session, issuedAt: newCredentials.issuedAt, type: newCredentials.type, id: newCredentials.id);
                    let _ = try? self.cache!.setObject(cacheCredentials, forKey: self.key);
                }
                completion(.success(newCredentials));
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
