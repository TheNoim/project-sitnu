//
//  Timetable.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import SwiftUI
import ClockKit

let timetableDayFormatter: RelativeDateTimeFormatter = {
    let formatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter();
    formatter.dateTimeStyle = .named;
    formatter.formattingContext = .dynamic;
    formatter.unitsStyle = .abbreviated
    return formatter;
}();

struct TimetableView: View {
    let account: UntisAccount;
    @State var untis: UntisClient?;
    @State var timegrid: Timegrid?;
    @State var periods: [Period]?;
    @State var subjects: [Subject]?;
    @State var date: Date = Calendar.current.startOfDay(for: Date());
    @State var title: String = "";
    @State var checkedDate: Date = Date();
    
    // Swipe detection
    @State var startPos : CGPoint = .zero
    @State var isSwipping = true
    
    // Detail View
    @State var isDetail: Bool = false;
    @State var selectedPeriod: Period?;
    
    @State var forceRefresh: Bool = false;
    
    var body: some View {
        VStack {
            Text(title)
                .font(.largeTitle)
            if periods != nil && periods!.count > 0 {
                ForEach(periods!) { period in
                    Button {
                        if forceRefresh {
                            return
                        }
                        withAnimation {
                            self.selectedPeriod = period;
                            self.isDetail.toggle();
                        }
                    } label: {
                        TimetableRowView(period: period, timegrid: self.timegrid, subjects: self.subjects)
                    }
                }
                .sheet(isPresented: $isDetail, content: {
                    PeriodDetailView(period: selectedPeriod, timegrid: self.timegrid, subjects: self.subjects)
                })
            } else if periods == nil {
                ActivityIndicator(active: true)
            } else {
                Text("No periods for this day")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            HStack {
                Button("<") {
                    if forceRefresh == false {
                        self.setDate(by: .back);
                    }
                }
                Button(">") {
                    if forceRefresh == false {
                        self.setDate(by: .forward);
                    }
                }
            }
            Button(forceRefresh ? "..." : "Force refresh") {
                if forceRefresh == false {
                    forceRefresh = true;
                    self.getTimetable(finish: {
                        self.reloadComplications(finish: {
                            self.forceRefresh = false;
                        }, force: true)
                    }, force: true)
                }
            }
        }
        .onAppear() {
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
                if self.startPos.x > gesture.location.x && yDist < xDist {
                    // LEFT
                    self.setDate(by: .forward);
                }
                else if self.startPos.x < gesture.location.x && yDist < xDist {
                    // RIGHT
                    self.setDate(by: .back);
                }
                self.isSwipping.toggle()
            }
        )
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("applicationDidBecomeActive"))) { _ in
            log.debug("Received notification applicationDidBecomeActive")
            DispatchQueue.main.async {
                self.setTitle();
                if !Calendar.current.isDate(self.checkedDate, inSameDayAs: Date()) {
                    log.debug("Last time app was opened was yesterday. Set date to today");
                    self.setDate(to: Calendar.current.startOfDay(for: Date()));
                }
            }
        }
    }
    
    enum DateDirection {
        case forward;
        case back;
    }
    
    func setDate(by direction: DateDirection) {
        var nextDate: Date?;
        if direction == .forward {
            nextDate = Calendar.current.date(byAdding: .day, value: 1, to: self.date);
        } else {
            nextDate = Calendar.current.date(byAdding: .day, value: -1, to: self.date);
        }
        if let nextDate = nextDate {
            self.setDate(to: nextDate);
        }
    }
    
    func setDate(to date: Date) {
        self.date = date;
        self.periods = nil;
        self.setTitle();
        self.getTimetable(finish: nil);
        self.checkedDate = Date();
    }
    
    func setTitle() {
        let dateComponents: DateComponents = Calendar.current.dateComponents([Calendar.Component.day], from: Calendar.current.startOfDay(for: Date()), to: self.date)
        self.title = timetableDayFormatter.localizedString(from: dateComponents);
    }
    
    func createClient() {
        let credentials: BasicUntisCredentials = BasicUntisCredentials(username: self.account.username, password: self.account.password, server: self.account.server, school: self.account.school, authType: self.account.authType);
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
        let finishCall = finish ?? {};
        if !self.account.primary {
            return finishCall();
        }
        var lastImportTime: Int64?;
        self.untis?.getLatestImportTime(force: force, cachedHandler: { (importTime) in
            lastImportTime = importTime;
        }, completion: { result in
            guard let newImportTime = try? result.get() else {
                if BackgroundUtility.shared.shouldReloadComplications() {
                    BackgroundUtility.shared.reloadComplications();
                }
                return finishCall();
            }
            if force || lastImportTime == nil || lastImportTime! != newImportTime || BackgroundUtility.shared.shouldReloadComplications() {
                BackgroundUtility.shared.reloadComplications();
            }
            return finishCall();
        })
    }
}

//struct Timetable_Previews: PreviewProvider {
//    static var previews: some View {
//        Timetable()
//    }
//}
