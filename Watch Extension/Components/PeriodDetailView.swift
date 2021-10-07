//
//  PeriodDetailView.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 21/09/2020.
//

import SwiftUI

let formatter = ListFormatter()

struct PeriodDetailView: View {
    var period: Period?;
    var subjects: [Subject]?;
    var timegrid: Timegrid?;
    var acc: UntisAccount;
    
    init(account: UntisAccount, period: Period?, timegrid: Timegrid?, subjects: [Subject]?) {
        self.period = period;
        self.timegrid = timegrid;
        self.subjects = subjects;
        self.acc = account;
    }
    
    var body: some View {
        if period != nil {
            _PeriodDetailView(account: acc, period: period!, timegrid: timegrid, subjects: subjects)
        } else {
            EmptyView()
        }
    }
}

struct _PeriodDetailView: View {
    var period: Period;
    var subjects: [Subject]?;
    var timegrid: Timegrid?;
    
    var title: String;
    var color: Color;
    var subtitle: String;
    var teachers: String;
    var rooms: String;
    var acc: UntisAccount;
    
    init(account: UntisAccount, period: Period, timegrid: Timegrid?, subjects: [Subject]?) {
        self.period = period;
        self.timegrid = timegrid;
        self.subjects = subjects;
        self.acc = account;
        
        self.title = UntisUtil.default.getRowTitle(acc: account, period: period, timegrid: self.timegrid);
        self.color = UntisUtil.default.getColor(for: period, subjects: self.subjects);
        self.subtitle = UntisUtil.default.getRowSubtitle(period: period)
        
        let teacherNames = self.period.teachers.map({ account.preferShortTeacher ? $0.shortDisplayName : $0.displayName })
        self.teachers = formatter.string(from: teacherNames) ?? "-";
        
        let roomNames = self.period.rooms.map({ account.preferShortRoom ? $0.shortDisplayName : $0.displayName })
        self.rooms = formatter.string(from: roomNames) ?? "-";
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .strikethrough(period.code == .cancelled)
                    .foregroundColor(color)
                    .font(.largeTitle)
                Spacer()
            }
            HStack {
                Text("Time:")
                Text(subtitle)
                    .strikethrough(period.code == .cancelled)
                Spacer()
            }
            if self.period.teachers.count > 0 {
                HStack {
                    Text("Teacher:")
                    Text(self.teachers)
                    Spacer()
                }
            }
            if self.period.rooms.count > 0 {
                HStack {
                    Text("Room:")
                    Text(self.rooms)
                    Spacer()
                }
            }
            if let subsText = self.period.substText {
                HStack {
                    Text("Sub Text: \(subsText)")
                    Spacer()
                }
            }
            if let info = self.period.info {
                HStack {
                    Text("Info: \(info)")
                    Spacer()
                }
            }
            Spacer()
        }
    }
}

//struct PeriodDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        PeriodDetailView()
//    }
//}
