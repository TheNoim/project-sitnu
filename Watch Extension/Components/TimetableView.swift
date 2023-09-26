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
    @State private var currentDate = Calendar.current.startOfDay(for: Date())
    @State private var currentDateOffset = Calendar.current.startOfDay(for: Date())
    @State private var currentTab = 0
    
    var body: some View {
        InfinitePageView(selection: $currentDateOffset, currentDate: $currentDate, currentTab: $currentTab, before: { Calendar.current.date(byAdding: .day, value: -1, to: $0)! }, after: { Calendar.current.date(byAdding: .day, value: 1, to: $0)! }) { date in
            _TimetableView(account: account, date: date)
        }
        .onChange(of: currentDate) { oldValue, newValue in
            log.debug("currentDate: \(formatDate(oldValue)) -> \(formatDate(newValue))")
        }
        .onChange(of: currentDateOffset) { oldValue, newValue in
            log.debug("currentDateOffset: \(formatDate(oldValue)) -> \(formatDate(newValue))")
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("applicationDidBecomeActive"))) { _ in
            log.debug("Received notification applicationDidBecomeActive")
            if !Calendar.current.isDate(currentDate, inSameDayAs: Date()) {
                log.debug("Last time app was opened was yesterday. Set date to today");
                withAnimation {
                    currentDateOffset = Calendar.current.startOfDay(for: Date())
                    currentDate = Calendar.current.startOfDay(for: Date())
                    currentTab = 0
                }
            }
        }
    }
}

struct _TimetableView: View {
    let account: UntisAccount;
    let date: Date;
    @State var untis: UntisClient?;
    @State var timegrid: Timegrid?;
    @State var periods: [Period]?;
    @State var subjects: [Subject]?;
    @State var checkedDate: Date = Date();
    @State var isAccountChanger: Bool = false;
    
    // Swipe detection
    @State var startPos : CGPoint = .zero
    @State var isSwipping = true
    
    // Detail View
    @State var isDetail: Bool = false;
    @State var selectedPeriod: Period?;
    
    @State var forceRefresh: Bool = false;
    @State var tabStyle = Color.gray.gradient
        
    var body: some View {
        ScrollViewReader { reader in
            ScrollView {
                RelativeDateTitle(date: date)
                    .font(.largeTitle)
                    .id("Top")
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
                            TimetableRowView(account: account, period: period, timegrid: self.timegrid, subjects: self.subjects)
                        }
                    }
                    .sheet(isPresented: $isDetail, content: {
                        if isDetail {
                            PeriodDetailView(period: $selectedPeriod, subjects: self.subjects, timegrid: self.timegrid, acc: account)
                        }
                    })
                } else if periods == nil {
                    ActivityIndicator(active: true)
                } else {
                    Text("No periods for this day")
                        .font(.footnote)
                        .foregroundColor(.secondary)
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
                Divider()
                Button("Change account") {
                    self.isAccountChanger.toggle();
                }
                .id("Bottom")
                .foregroundColor(.yellow)
                .sheet(isPresented: $isAccountChanger, content: { AccountSelector(isOpen: $isAccountChanger) })
                .onChange(of: date, initial: false) { oldValue, newValue in
                    if oldValue < newValue {
                        log.debug("Reset scroll position")
                        reader.scrollTo("Top")
                    }
                    self.setShapeStyle()
                    self.getTimegrid();
                    self.getTimetable(finish: nil);
                    self.getSubjects();
                    self.reloadComplications(finish: nil);
                }
            }
            .onAppear() {
                self.setShapeStyle()
                self.createClient()
                self.getTimegrid();
                self.getTimetable(finish: nil);
                self.getSubjects();
                self.reloadComplications(finish: nil);
            }
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("applicationDidBecomeActive"))) { _ in
                log.debug("Received notification applicationDidBecomeActive")
                self.setShapeStyle()
            }
            .containerBackground(self.tabStyle, for: .tabView)
        }
    }
    
    func setShapeStyle() {
        if Calendar.current.isDateInToday(date) {
            tabStyle = Color.green.gradient
        } else if Calendar.current.isDateInYesterday(date) {
            tabStyle = Color.red.gradient
        } else if Calendar.current.isDateInTomorrow(date) {
            tabStyle = Color.blue.gradient
        } else {
            tabStyle = Color.gray.gradient
        }
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
