//
//  PeriodTimelineProvider.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2023.
//

import Foundation
import WidgetKit
import SwiftyBeaver

struct PeriodTimelineProvider: TimelineProvider {
    var bgUtility = BackgroundUtility();
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<PeriodWidgetTimelineEntry>) -> Void) {
        initBeaver()
        log.debug("Hello from timeline")
        let date = Date()
        self.getTimelineEntries(after: date, limit: 8) { entries in
            log.debug("Timeline entries fetched", context: entries)
            
            let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: date)!
            
            if let entries, entries.count > 0 {
                let timeline = Timeline(entries: entries, policy: .after(nextUpdateDate))
                
                completion(timeline)
            } else {
                let timeline = Timeline(entries: [PeriodWidgetTimelineEntry(date: date, info: .End(date))], policy: .after(nextUpdateDate))
                
                completion(timeline)
            }
        }
    }
    
    func getSnapshot(in context: Self.Context, completion: @escaping (PeriodWidgetTimelineEntry) -> Void) {
        initBeaver()
        log.debug("Hello from snapshot")
        self.getTimelineEntries(after: Date(), limit: 1) { entries in
            if let firstEntry = entries?.first {
                completion(firstEntry)
            } else {
                let date = Date()
                completion(PeriodWidgetTimelineEntry(date: date, info: .End(date)))
            }
        }
    }
    
    func placeholder(in context: Self.Context) -> PeriodWidgetTimelineEntry {
        initBeaver()
        return PeriodWidgetTimelineEntry(date: Date(), info: .Placeholder)
    }
    
    func getTimelineEntries(after date: Date, limit: Int, withHandler handler: @escaping ([PeriodWidgetTimelineEntry]?) -> Void) {
        self.getAllUntisInformation(for: date) {
            handler([]);
        } handler: { (periods, timegrid, subjects) in
            // .filter({ $0.startTime > date || ($0.startTime < date && $0.endTime > date) })
            var entries: [PeriodWidgetTimelineEntry] = [];
            var lastEndTime: Date = date;
            guard let account = self.bgUtility.getPrimaryAccount() else {
                return handler(nil);
            }
            
            if let currentPeriod = periods.first(where: { $0.startTime <= date && $0.endTime >= date }) {
                if let nextPeriod = periods.first(where: { $0.startTime >= date && $0.id != currentPeriod.id }) {
                    let n = nextPeriod.startTime.timeIntervalSince1970;
                    let c = currentPeriod.endTime.timeIntervalSince1970;
                    if abs(n - c) <= 1 {
                        // The next entry is the next period
                        let nextEntry = PeriodWidgetTimelineEntry(date: lastEndTime, info: .Period(PeriodTimelineEntry(account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                        entries.appendWithLimitCheck(limit, item: nextEntry);
                    } else {
                        // We need to add a break entry
                        let nextEntry = PeriodWidgetTimelineEntry(date: lastEndTime, info: .Break(BreakTimelineEntry(date: currentPeriod.endTime, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                        entries.appendWithLimitCheck(limit, item: nextEntry);
                        let nextPeriodEntry = PeriodWidgetTimelineEntry(date: nextPeriod.startTime, info: PeriodTimelineEntryInfo.Period(PeriodTimelineEntry(account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                        entries.appendWithLimitCheck(limit, item: nextPeriodEntry);
                    }
                    // Every next period needs to be after this time
                    lastEndTime = nextPeriod.endTime;
                } else {
                    // No next Period. The next entry is the end of the timeline
                    let endEntry = PeriodWidgetTimelineEntry(date: currentPeriod.endTime, info: PeriodTimelineEntryInfo.End(date))
                    entries.appendWithLimitCheck(limit, item: endEntry);
                    // We don't need to add anything anymore. We can just return.
                    return handler(entries);
                }
            } else {
                if let nextPeriod = periods.first(where: { $0.startTime >= date }) {
                    // New Timeline
                    let nextEntry = PeriodWidgetTimelineEntry(date: Date(), info: PeriodTimelineEntryInfo.Break(BreakTimelineEntry(date: lastEndTime, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                    entries.appendWithLimitCheck(limit, item: nextEntry);
                    let nextPeriodEntry = PeriodWidgetTimelineEntry(date: nextPeriod.startTime, info: PeriodTimelineEntryInfo.Period(PeriodTimelineEntry(account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                    entries.appendWithLimitCheck(limit, item: nextPeriodEntry);
                    lastEndTime = nextPeriod.endTime;
                } else {
                    // No next Period. The next entry is the end of the timeline
                    let endEntry = PeriodWidgetTimelineEntry(date: Date(), info: PeriodTimelineEntryInfo.End(date))
                    entries.appendWithLimitCheck(limit, item: endEntry);
                    // We don't need to add anything anymore. We can just return.
                    return handler(entries);
                }
            }
            
            if entries.count >= limit {
                return handler(entries);
            }
            
            while (true) {
                if let nextPeriod = periods.first(where: { $0.startTime >= lastEndTime }) {
                    let n = nextPeriod.startTime.timeIntervalSince1970;
                    let c = lastEndTime.timeIntervalSince1970;
                    if abs(n - c) <= 1 {
                        // We don't need a break entry
                        let nextEntry = PeriodWidgetTimelineEntry(date: lastEndTime, info: PeriodTimelineEntryInfo.Period(PeriodTimelineEntry(account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                        entries.appendWithLimitCheck(limit, item: nextEntry);
                    } else {
                        // We need to add a break entry, because there is time between last period and next period
                        let breakEntry = PeriodWidgetTimelineEntry(date: lastEndTime, info: PeriodTimelineEntryInfo.Break(BreakTimelineEntry(date: lastEndTime, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                        entries.appendWithLimitCheck(limit, item: breakEntry);
                        let nextPeriodEntry = PeriodWidgetTimelineEntry(date: nextPeriod.startTime, info: .Period(PeriodTimelineEntry(account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects)))
                        entries.appendWithLimitCheck(limit, item: nextPeriodEntry);
                    }
                    lastEndTime = nextPeriod.endTime;
                } else {
                    // There is no next period. This is the end of timeline
                    let endEntry = PeriodWidgetTimelineEntry(date: lastEndTime, info: PeriodTimelineEntryInfo.End(lastEndTime))
                    entries.appendWithLimitCheck(limit, item: endEntry);
                    break;
                }
                
                if entries.count >= limit {
                    // We can't add anything anymore
                    break;
                }
            }
            return handler(entries);
        }
    }
    
    // MARK: Untis functions
    
    func getUntisTimeline(start date: Date, handler: @escaping ([Period]?) -> Void) {
        guard let untis = self.bgUtility.getUntisClient() else {
            return handler(nil);
        }
        untis.getTimetable(for: getFetchDate(date: date), cachedHandler: nil) { result in
            var periods: [Period] = [];
            guard let currentPeriods = try? result.get() else {
                return handler(nil);
            }
            periods.append(contentsOf: currentPeriods);
            untis.getTimetable(for: Calendar.current.date(byAdding: .day, value: 1, to: getFetchDate(date: date))!, cachedHandler: nil) { tomorrowResult in
                guard let tomorrowPeriods = try? tomorrowResult.get() else {
                    return handler(nil);
                }
                periods.append(contentsOf: tomorrowPeriods);
                if periods.count < 1 {
                    return handler(nil);
                }
                let sorted = periods
                    .sortedPeriods(useEndtime: true)
                    .filter({ $0.code != .cancelled });
                
                handler(sorted);
            }
        }
    }
    
    func getTimegrid(handler: @escaping (Timegrid?) -> Void) {
        guard let untis = self.bgUtility.getUntisClient() else {
            return handler(nil);
        }
        untis.getTimegrid(cachedHandler: nil) { result in
            guard let timegrid = try? result.get() else {
                return handler(nil);
            }
            handler(timegrid);
        }
    }
    
    func getSubjects(handler: @escaping ([Subject]?) -> Void) {
        guard let untis = self.bgUtility.getUntisClient() else {
            return handler(nil);
        }
        untis.getSubjectColors(cachedHandler: nil) { result in
            guard let subjects = try? result.get() else {
                return handler(nil);
            }
            handler(subjects);
        }
    }
    
    func getAllUntisInformation(for date: Date, failedHandler: @escaping () -> Void, handler: @escaping ([Period], Timegrid, [Subject]) -> Void) {
        self.getTimegrid { timegrid in
            guard let timegrid = timegrid else {
                print("No timegrid")
                return failedHandler();
            }
            self.getSubjects { subjects in
                guard let subjects = subjects else {
                    print("No subjects")
                    return failedHandler();
                }
                self.getUntisTimeline(start: date) { (periods) in
                    guard let periods = periods else {
                        print("No periods")
                        return failedHandler();
                    }
                    handler(periods, timegrid, subjects);
                }
            }
        }
    }
}

extension Array where Element == PeriodWidgetTimelineEntry {
    
    mutating func appendWithLimitCheck(_ limit: Int, item: PeriodWidgetTimelineEntry) {
        if self.count < limit {
            self.append(item);
        }
    }
    
}
