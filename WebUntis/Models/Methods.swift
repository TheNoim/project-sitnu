//
//  Methods.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 18/09/2020.
//

import Foundation

enum WebUntisMethod: String {
    case AUTHENTICATE = "authenticate"
    case STATUS = "getStatusData"
    case TIMETABLE = "getTimetable"
    case TIMEGRID = "getTimegridUnits"
    case SUBJECTS = "getSubjects"
    case IMPORT_TIME = "getLatestImportTime"
}
