//
//  Timetable.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import Foundation

let dateFormatter = { () -> DateFormatter in
    let f = DateFormatter();
    f.dateFormat = "yyyyMMdd";
    return f;
}();
let timeAndDateFormatter = { () -> DateFormatter in
    let f = DateFormatter();
    f.dateFormat = "yyyyMMddHHmm";
    return f;
}();


struct Period: Codable, Identifiable {
    // MARK: 1to1 transformations
    
    let id: Int;
    let info: String?;
    let substText: String?;
    let lstext: String?;
    let lsnumber: Int?;
    let statflags: String?;
    let activityType: String?;
    let studentGroup: String?;
    let bkRemark: String?;
    let bkText: String?;
    let klassen: [SubType];
    let teachers: [SubType];
    let subjects: [SubType];
    let rooms: [SubType];
    
    // MARK: Computed
    
    var date: Date {
        let dateString = String(format: "%08d", untisDate);
        return dateFormatter.date(from: dateString) ?? Date();
    }
    
    var startTime: Date {
        let dateString = String(format: "%08d", untisDate);
        let startTimeString = String(format: "%04d", self.untisStartTime);
        return timeAndDateFormatter.date(from: "\(dateString)\(startTimeString)") ?? Date();
    }
    
    var endTime: Date {
        let dateString = String(format: "%08d", untisDate);
        let endTimeString = String(format: "%04d", self.untisEndTime);
        return timeAndDateFormatter.date(from: "\(dateString)\(endTimeString)") ?? Date();
    }
    
    var lessonType: LessonType { LessonType.init(rawValue: self.untisLSType ?? "ls") ?? .lesson }
    var code: LessonCode { LessonCode.init(rawValue: self.untisLessonCode ?? "") ?? .normal }
    
    // MARK: Original untis types
    
    let untisDate: Int;
    let untisStartTime: Int;
    let untisEndTime: Int;
    let untisLSType: String?;
    let untisLessonCode: String?;
    
    // MARK: Untis enums
    
    enum LessonType: String, Codable {
        case lesson = "ls"
        case officeHour = "oh"
        case standBy = "sb"
        case breakSupervision = "bs"
        case examination = "ex"
    }
    
    enum LessonCode: String, Codable {
        case normal = ""
        case cancelled = "cancelled"
        case irregular = "irregular"
    }
    
    // MARK: Untis structs
    
    struct SubType: Codable {
        let id: Int;
        let name: String?;
        let longname: String?;
        let externalkey: String?;
    }
    
    // MARK: Coding keys
    
    enum CodingKeys: String, CodingKey {
        case untisDate = "date"
        case untisStartTime = "startTime"
        case untisEndTime = "endTime"
        case untisLSType = "lstype"
        case untisLessonCode = "code"
        case info = "info"
        case substText = "substText"
        case lstext = "lstext"
        case lsnumber = "lsnumber"
        case statflags = "statflags"
        case activityType = "activityType"
        case studentGroup = "sg"
        case bkRemark = "bkRemark"
        case bkText = "bkText"
        case klassen = "kl"
        case teachers = "te"
        case subjects = "su"
        case rooms = "ro"
        case id
    }
}
