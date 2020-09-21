//
//  Timetable.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import SwiftUI
import ClockKit

struct TimetableView: View {
    let account: UntisAccount;
    @State var untis: UntisClient?;
    @State var timegrid: Timegrid?;
    @State var periods: [Period]?;
    @State var subjects: [Subject]?;
    @State var date: Date = Calendar.current.startOfDay(for: Date());
    @State var title: String = "";
    
    // Swipe detection
    @State var startPos : CGPoint = .zero
    @State var isSwipping = true
    
    // Detail View
    @State var isDetail: Bool = false;
    @State var selectedPeriod: Period?;
    
    @State var forceRefresh: Bool = false;
    
    var dayFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter();
        formatter.dateTimeStyle = .named;
        formatter.formattingContext = .dynamic;
        formatter.unitsStyle = .abbreviated;
        return formatter;
    }();
    
    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
            if periods != nil {
                ForEach(periods!) { period in
                    Button {
                        if forceRefresh {
                            return
                        }
                        self.selectedPeriod = period;
                        self.isDetail.toggle();
                    } label: {
                        TimetableRowView(period: period, timegrid: self.timegrid, subjects: self.subjects)
                    }
                    .sheet(isPresented: $isDetail, content: {
                        if selectedPeriod != nil {
                            PeriodDetailView(period: selectedPeriod!, timegrid: self.timegrid, subjects: self.subjects)
                        }
                    })
                }
            }
            Button(forceRefresh ? "..." : "Force refresh") {
                if forceRefresh {
                    return;
                }
                forceRefresh = true;
                self.getTimetable(finish: {
                    self.reloadComplications(finish: {
                        self.forceRefresh = false;
                    }, force: true)
                }, force: true)
            }
        }
        .onAppear() {
            print("onAppear()")
            self.setTitle();
            self.createClient()
            self.getTimegrid();
            self.getTimetable(finish: nil);
            self.getSubjects();
            self.reloadComplications(finish: nil);
        }
        .gesture(DragGesture()
            .onChanged { gesture in
                if self.isSwipping {
                    self.startPos = gesture.location
                    self.isSwipping.toggle()
                }
            }
            .onEnded { gesture in
                if forceRefresh {
                    self.isSwipping.toggle()
                    return
                }
                let xDist: CGFloat = abs(gesture.location.x - self.startPos.x)
                let yDist: CGFloat = abs(gesture.location.y - self.startPos.y)
                if self.startPos.y <  gesture.location.y && yDist > xDist {
                    // DOWN
                    print("DOWN")
                }
                else if self.startPos.y >  gesture.location.y && yDist > xDist {
                    // UP
                    print("UP")
                }
                else if self.startPos.x > gesture.location.x && yDist < xDist {
                    // LEFT
                    self.setDate(to: Calendar.current.date(byAdding: .day, value: 1, to: self.date)!);
                }
                else if self.startPos.x < gesture.location.x && yDist < xDist {
                    // RIGHT
                    self.setDate(to: Calendar.current.date(byAdding: .day, value: -1, to: self.date)!)
                }
                self.isSwipping.toggle()
            }
        )
    }
    
    func setDate(to date: Date) {
        self.date = date;
        self.setTitle();
        self.getTimetable(finish: nil);
    }
    
    func setTitle() {
        self.title = self.dayFormatter.localizedString(from: Calendar.current.dateComponents([Calendar.Component.day], from: Calendar.current.startOfDay(for: Date()), to: self.date));
    }
    
    func createClient() {
        let credentials = BasicUntisCredentials(username: self.account.username, password: self.account.password, server: self.account.server, school: self.account.school);
        self.untis = UntisClient(credentials: credentials);
    }
    
    func getTimegrid() {
        self.untis!.getTimegrid { timegrid in
            self.timegrid = timegrid;
        } completion: { result in
            if let timegrid: Timegrid = try? result.get() {
                self.timegrid = timegrid;
            }
        }
    }
    
    func getTimetable(finish: (() -> Void)?, force: Bool = false) {
        let searchedDate: Date = self.date;
        self.untis!.getTimetable(for: searchedDate, and: force) { (periods) in
            // Only update if still same day
            if searchedDate == self.date {
                self.periods = periods.sortedPeriods();
            }
        } completion: { (result) in
            // Only update if still same day
            if searchedDate == self.date {
                if let periods: [Period] = try? result.get() {
                    self.periods = periods.sortedPeriods();
                }
            }
            if finish != nil {
                finish!();
            }
        }
    }
    
    func getSubjects() {
        self.untis!.getSubjectColors { (subjects) in
            self.subjects = subjects;
        } completion: { result in
            if let subjects: [Subject] = try? result.get() {
                self.subjects = subjects;
            }
        }

    }
    
    func reloadComplications(finish: (() -> Void)?, force: Bool = false) {
        if !self.account.primary {
            if finish != nil {
                finish!();
            }
            return;
        }
        guard let complications = CLKComplicationServer.sharedInstance().activeComplications else {
            if finish != nil {
                finish!();
            }
            return;
        }
        var lastImportTime: Int?;
        self.untis?.getLatestImportTime(force: force, cachedHandler: { (importTime) in
            lastImportTime = importTime;
        }, completion: { result in
            guard let newImportTime = try? result.get() else {
                if finish != nil {
                    finish!();
                }
                return;
            }
            if lastImportTime == nil {
                for complication in complications {
                    CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
                }
            } else {
                if lastImportTime! != newImportTime {
                    for complication in complications {
                        CLKComplicationServer.sharedInstance().reloadTimeline(for: complication)
                    }
                }
            }
            if finish != nil {
                finish!();
            }
        })
    }
}

//struct Timetable_Previews: PreviewProvider {
//    static var previews: some View {
//        Timetable()
//    }
//}
