//
//  FakeWidgetData.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2023.
//

import Foundation

struct WidgetFakeData {
    
    enum FakeType {
        case Break
        case Period
        case End
    }
    
    static func getWidgetFakeEntry(for type: FakeType) -> PeriodWidgetTimelineEntry {
        let account = UntisAccount(id: UUID(), username: "cool user", password: "1337", server: "hurensohn", school: "was juckt mich das", setDisplayName: "Cool School", authType: .PASSWORD, primary: true, preferShortRoom: false, preferShortSubject: false, preferShortTeacher: false, preferShortClass: false, showRoomInsteadOfTime: false)
        
        var period = Period(id: 1337, info: nil, substText: nil, lstext: nil, lsnumber: nil, statflags: nil, activityType: nil, studentGroup: nil, bkRemark: nil, bkText: nil, untisDate: 1337, untisStartTime: 755, untisEndTime: 840, untisLSType: nil, untisLessonCode: nil)
        
        let timegrid = Timegrid(days: [
            TimegridEntry(day: .friday, timeUnits: [
                Timeunit(name: "1.", startTime: 755, endTime: 840),
                Timeunit(name: "2.", startTime: 845, endTime: 930),
                Timeunit(name: "3.", startTime: 945, endTime: 1030),
                Timeunit(name: "4.", startTime: 1035, endTime: 1120),
                Timeunit(name: "5.", startTime: 1135, endTime: 1220),
                Timeunit(name: "6.", startTime: 1225, endTime: 1310)
            ])
        ])
        
        let subjects = [
            Subject(id: 1, name: "PH", longName: "Physik", foreColor: "FFFFFF", backColor: "0000FF")
        ]
        
        period.subjects = [
            Period.SubType(id: 1, name: "PH", longname: "Physik", externalkey: nil)
        ]
        
        period.teachers = [
            Period.SubType(id: 2, name: "SMD", longname: "Schmidt", externalkey: nil)
        ]
        
        period.rooms = [
            Period.SubType(id: 3, name: "M301", longname: nil, externalkey: nil)
        ]
        
        switch type {
        case .End:
            return PeriodWidgetTimelineEntry(date: Date(), info: .End(Date()))
        case .Break:
            return PeriodWidgetTimelineEntry(date: Date(), info: .Break(BreakTimelineEntry(date: self.getFutureDate(), period: period, timegrid: timegrid, subjects: subjects)))
        case .Period:
            return PeriodWidgetTimelineEntry(date: Date(), info: .Period(PeriodTimelineEntry(account: account, period: period, timegrid: timegrid, subjects: subjects)))
        }
        
    }
    
    static func getFutureDate() -> Date {
        let components = DateComponents(minute: 11, second: 14)
        let futureDate = Calendar.current.date(byAdding: components, to: Date())!
        
        return futureDate
    }
}
