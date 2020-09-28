//
//  UntisClient.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation
import Alamofire
import Cache

class UntisClient {
    private var credentials: BasicUntisCredentials;
    private var session: Session;
    private var storage: Storage<String>?;
    private var disableCache: Bool = false;
    private lazy var intSerializer: UntisIntSerializer = UntisIntSerializer();
    private lazy var objectSerializer: UntisObjectSerializer = UntisObjectSerializer();
    private lazy var arraySerializer: UntisArraySerializer = UntisArraySerializer();
    
    typealias JsonObject = [String: Any];
    typealias JsonArray = [Any];
    
    init(credentials: BasicUntisCredentials) {
        self.credentials = credentials;
        let diskConfig = DiskConfig(name: "Untis", expiry: .date(Date().addingTimeInterval(60 * 60 * 24 * 14)), maxSize: 52428800)
        let memoryConfig = MemoryConfig(expiry: .never, countLimit: 40, totalCostLimit: 10)
        do {
            self.storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig, transformer: TransformerFactory.forCodable(ofType: String.self));
        } catch {
            self.disableCache = true;
        }
        let authStorage = self.storage?.transformCodable(ofType: AuthSession.self);
        let authKey = "\(self.credentials.username):\(self.credentials.school)@\(self.credentials.server)->AUTH";
        let authenticator = UntisAuthenticator(storage: authStorage, key: authKey);
        
        var alamofireCredentials: UntisCredentials = UntisCredentials(username: credentials.username, password: credentials.password, server: credentials.server, school: credentials.school);
        
        if authStorage != nil  {
            if let exists = try? authStorage?.existsObject(forKey: authKey) {
                if exists {
                    if let cachedSession = try? authStorage?.object(forKey: authKey) {
                        alamofireCredentials.issuedAt = cachedSession.issuedAt;
                        alamofireCredentials.session = cachedSession.session;
                        alamofireCredentials.id = cachedSession.id;
                        alamofireCredentials.type = cachedSession.type;
                    }
                }
            }
        }
        
        let interceptor = AuthenticationInterceptor(authenticator: authenticator, credential: alamofireCredentials);
        let rootQueue = DispatchQueue(label: "com.app.session.rootQueue")
        let requestQueue = DispatchQueue(label: "com.app.session.requestQueue")
        let serializationQueue = DispatchQueue(label: "com.app.session.serializationQueue")
        self.session = Session(rootQueue: rootQueue, requestQueue: requestQueue, serializationQueue: serializationQueue, interceptor: interceptor);
        
    }
    
    // MARK: - API Implementations
    
    // MARK: Subject Colors
    
    public func getSubjectColors(force: Bool = false, cachedHandler: (([Subject]) -> Void)?, completion: @escaping (Swift.Result<[Subject], Error>) -> Void) {
        var refresh: Bool = force;
        let subjectsStorage = self.storage?.transformCodable(ofType: SubjectsCache.self);
        let cacheKey = self.getCacheKey(for: "SUBJECTS");
        if let subjectCache = try? subjectsStorage?.object(forKey: cacheKey) {
            refresh = subjectCache.expired || force;
            if refresh && cachedHandler != nil {
                cachedHandler!(subjectCache.subjects);
            } else if !refresh {
                completion(.success(subjectCache.subjects));
            }
        } else {
            refresh = true;
        }
        if refresh {
            self.doArrayRequest(method: .SUBJECTS) { response in
                switch response {
                case .success(let subjectsEncoded):
                    var subjectArray: [Subject] = [];
                    for entry in subjectsEncoded {
                        if let subject = try? Subject(from: entry) {
                            subjectArray.append(subject);
                        }
                    }
                    let subjectCache = SubjectsCache(subjects: subjectArray)
                    try? subjectsStorage!.setObject(subjectCache, forKey: cacheKey);
                    completion(.success(subjectArray));
                    break;
                case .failure(let error):
                    completion(.failure(error));
                    break;
                }
            }
        }
    }
    
    // MARK: Timetable
    
    enum TimetableFlag: Int, Codable, Equatable {
        case Booking
        case Info
        case SubstitutionText
        case LessonText
        case LessonNumber
        case StudentGroup
        case OnlyBase
    }
    
    public func getTimetable(for date: Date = Date(), with flags: [TimetableFlag] = [TimetableFlag.Info, TimetableFlag.LessonText, TimetableFlag.StudentGroup, TimetableFlag.SubstitutionText], and force: Bool = false, cachedHandler: (([Period]) -> Void)?, completion: @escaping (Swift.Result<[Period], Error>) -> Void) {
        var refresh: Bool = force;
        let untisDate = UntisClient.getDateFormatter().string(from: date);
        let params = ["options": [
            "element": [
                "id": "auto",
                "type": "auto"
            ],
            "startDate": untisDate,
            "endDate": untisDate,
            "showInfo": flags.has(flag: .Info),
            "showSubstText": flags.has(flag: .SubstitutionText),
            "showLsText": flags.has(flag: .LessonText),
            "showStudentgroup": flags.has(flag: .StudentGroup),
            "showLsNumber": flags.has(flag: .LessonNumber),
            "showBooking": flags.has(flag: .Booking),
            "onlyBaseTimetable": flags.has(flag: .OnlyBase),
            "klasseFields": ["id", "name", "longname"],
            "roomFields": ["id", "name", "longname"],
            "subjectFields": ["id", "name", "longname"],
            "teacherFields": ["id", "name", "longname"],
        ]];
        let timetableStorage = self.storage?.transformCodable(ofType: TimetableCache.self);
        let cacheKey = self.getCacheKey(for: "TIMETABLE_\(untisDate)_\(flags.map({ $0.rawValue }))");
        if let timetableCache = try? timetableStorage?.object(forKey: cacheKey) {
            refresh = timetableCache.expired || force;
            if refresh && cachedHandler != nil {
                cachedHandler!(timetableCache.periods);
            } else if !refresh {
                completion(.success(timetableCache.periods));
            }
        } else {
            refresh = true;
        }
        if refresh {
            self.doArrayRequest(method: .TIMETABLE, parameters: params) { response in
                switch response {
                case .success(let timetableEncoded):
                    var periodsArray: [Period] = [];
                    for entry in timetableEncoded {
                        if let period = try? Period(from: entry) {
                            periodsArray.append(period);
                        }
                    }
                    let timetableCache = TimetableCache(periods: periodsArray);
                    try? timetableStorage!.setObject(timetableCache, forKey: cacheKey);
                    completion(.success(periodsArray));
                    break;
                case .failure(let error):
                    completion(.failure(error));
                    break;
                }
            }
        }
    }
    
    // MARK: Timegrid
    
    public func getTimegrid(force: Bool = false, cachedHandler: ((Timegrid) -> Void)?, completion: @escaping (Swift.Result<Timegrid, Error>) -> Void) {
        var refresh: Bool = force;
        let timegridStorage = self.storage?.transformCodable(ofType: TimegridCache.self);
        let cacheKey = self.getCacheKey(for: "TIMEGRID");
        if let timegridCache = try? timegridStorage?.object(forKey: cacheKey) {
            refresh = timegridCache.expired || force;
            if refresh && cachedHandler != nil {
                cachedHandler!(timegridCache.timegrid);
            } else if !refresh {
                completion(.success(timegridCache.timegrid));
            }
        } else {
            refresh = true;
        }
        if refresh {
            self.doArrayRequest(method: .TIMEGRID) { response in
                switch response {
                case .success(let timegridEncoded):
                    var timegridArray: [TimegridEntry] = [];
                    for entry in timegridEncoded {
                        if let timegridEntry = try? TimegridEntry(from: entry) {
                            timegridArray.append(timegridEntry);
                        }
                    }
                    let timegrid = Timegrid(days: timegridArray);
                    let timegridCache = TimegridCache(timegrid: timegrid)
                    try? timegridStorage!.setObject(timegridCache, forKey: cacheKey);
                    completion(.success(timegrid));
                    break;
                case .failure(let error):
                    completion(.failure(error));
                    break;
                }
            }
        }
    }
    
    // MARK: Latest Import Time
    
    public func getLatestImportTime(force: Bool = false, cachedHandler: ((Int) -> Void)?, completion: @escaping (Swift.Result<Int, Error>) -> Void) {
        var refresh: Bool = force;
        let intStorage = self.storage?.transformCodable(ofType: ImportTimeCache.self);
        let cacheKey = self.getCacheKey(for: "IMPORT_TIME");
        if let timeCache = try? intStorage?.object(forKey: cacheKey) {
            refresh = timeCache.expired || force;
            if refresh && cachedHandler != nil {
                cachedHandler!(timeCache.time);
            } else if !refresh {
                completion(.success(timeCache.time));
            }
        } else {
            refresh = true;
        }
        if refresh {
            self.doRequest(method: .IMPORT_TIME, serializer: self.intSerializer) { response in
                if let time = try? response.get() {
                    let timeCache = ImportTimeCache(time: time);
                    try? intStorage!.setObject(timeCache, forKey: cacheKey);
                }
                completion(response);
            }
        }
        
    }
    
    // MARK: - Private Utilities
    
    public static func getDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "YYYYMMdd";
        return formatter;
    }
    
    /**
     Get cache key for current credentials
     */
    private func getCacheKey(for key: String) -> String {
        return "\(self.credentials.username):\(self.credentials.school)@\(self.credentials.server)->\(key)";
    }
    
    // MARK: - Do Request
    
    private func doObjectRequest(method: WebUntisMethod, parameters: [String: Any] = [:], completion: @escaping (Swift.Result<JsonObject, Error>) -> Void) {
        self.doRequest(method: method, parameters: parameters, serializer: self.objectSerializer) { result in
            completion(result);
        }
    }
    
    private func doArrayRequest(method: WebUntisMethod, parameters: [String: Any] = [:], completion: @escaping (Swift.Result<JsonArray, Error>) -> Void) {
        self.doRequest(method: method, parameters: parameters, serializer: self.arraySerializer) { result in
            completion(result);
        }
    }
    
    private func doRequest<T: ResponseSerializer>(method: WebUntisMethod, parameters: [String: Any] = [:], serializer: T, completion: @escaping (Swift.Result<T.SerializedObject, Error>) -> Void) {
        let body: Parameters = [
            "id": "SITNU",
            "method": method.rawValue,
            "jsonrpc": "2.0",
            "params": parameters
        ];
        self.session.download("https://\(self.credentials.server)/WebUntis/jsonrpc.do?school=\(self.credentials.school)", method: .post, parameters: body, encoding: JSONEncoding.default).response(responseSerializer: serializer) { response in
            switch response.result {
            case .success(let serializedObject):
                completion(.success(serializedObject));
                break;
            case .failure(let error):
                completion(.failure(error));
                break;
            }
        }
    }
}

extension Array where Element == UntisClient.TimetableFlag {
    func has(flag: UntisClient.TimetableFlag) -> Bool {
        for f in self {
            if f == flag {
                return true
            }
        }
        return false;
    }
}
