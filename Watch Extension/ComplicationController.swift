//
//  ComplicationController.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 19/09/2020.
//

import ClockKit
import Cache

class ComplicationController: NSObject, CLKComplicationDataSource {
    
    var bgUtility: BackgroundUtility = BackgroundUtility();
    
    // MARK: - Complication Configuration

    @available(watchOSApplicationExtension 7.0, *)
    func getComplicationDescriptors(handler: @escaping ([CLKComplicationDescriptor]) -> Void) {
        let descriptors = [
            CLKComplicationDescriptor(identifier: "complication", displayName: "Project SITNU", supportedFamilies: CLKComplicationFamily.allCases)
            // Multiple complication support can be added here with more descriptors
        ]
        
        // Call the handler with the currently supported complication descriptors
        handler(descriptors)
    }
    
    @available(watchOSApplicationExtension 7.0, *)
    func handleSharedComplicationDescriptors(_ complicationDescriptors: [CLKComplicationDescriptor]) {
        // Do any necessary work to support these newly shared complication descriptors
    }

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        self.getUntisTimeline(start: Date()) { (periods) in
            guard let periods = periods else {
                return handler(nil);
            }
            guard let last = periods.last else {
                return handler(nil);
            }
            handler(last.endTime);
        }
        
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        self.getAllUntisInformation(for: Date()) {
            handler(nil);
        } handler: { (periods, timegrid, subjects) in
            let endEntry = self.getTimelineEndEntry(for: complication, and: Date());
            if let currentPeriod = periods.first(where: { $0.startTime <= Date() && $0.endTime >= Date() }) {
                if let entry = self.getComplicationEntry(for: complication, period: currentPeriod, timegrid: timegrid, subjects: subjects) {
                    return handler(entry);
                } else {
                    return handler(endEntry);
                }
            } else {
                if let nextPeriod = periods.first(where: { $0.startTime >= Date() }) {
                    if let entry = self.getBreakComplicationEntry(for: complication, date: Date(), period: nextPeriod, timegrid: timegrid, subjects: subjects) {
                        return handler(entry);
                    } else {
                        return handler(endEntry);
                    }
                } else {
                    return handler(endEntry);
                }
            }
        }

    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        self.getAllUntisInformation(for: date) {
            handler(nil);
        } handler: { (periods, timegrid, subjects) in
            var entries: [CLKComplicationTimelineEntry] = [];
            var startIndex: Int = 0;
            if let currentPeriodIndex = periods.firstIndex(where: { $0.startTime <= Date() && $0.endTime >= Date() }) {
                startIndex = currentPeriodIndex;
            } else if let nextPeriodIndex = periods.firstIndex(where: { $0.startTime >= Date() }) {
                startIndex = nextPeriodIndex;
                if let breakTemplate = self.getBreakComplicationEntry(for: complication, date: Date(), period: periods[nextPeriodIndex], timegrid: timegrid, subjects: subjects) {
                    entries.append(breakTemplate);
                }
            } else {
                guard let endEntry = self.getTimelineEndEntry(for: complication, and: Date()) else {
                    return handler(nil);
                }
                return handler([endEntry]);
            }
            while (startIndex <= (periods.count - 1) && entries.count < limit) {
                if let periodEntry = self.getComplicationEntry(for: complication, period: periods[startIndex], timegrid: timegrid, subjects: subjects) {
                    entries.append(periodEntry);
                }
                if entries.count < limit {
                    if startIndex + 1 <= (periods.count - 1) {
                        let nextPeriod = periods[startIndex + 1]
                        if let breakTemplate = self.getBreakComplicationEntry(for: complication, date: periods[startIndex].endTime, period: nextPeriod, timegrid: timegrid, subjects: subjects) {
                            entries.append(breakTemplate);
                            startIndex = startIndex + 1;
                            continue;
                        }
                        
                    }
                    if entries.count < limit {
                        let endEntry = self.getTimelineEndEntry(for: complication, and: periods[startIndex].endTime)!;
                        entries.append(endEntry);
                        startIndex = startIndex + 1;
                    }
                }
            }
            handler(entries);
        }
    }

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    // MARK: Entry generators
    
    func getBreakComplicationEntry(for complication: CLKComplication, date: Date, period: Period, timegrid: Timegrid, subjects: [Subject]) -> CLKComplicationTimelineEntry? {
        var template: CLKComplicationTemplate?;
        
        switch complication.family {
        case .modularLarge:
            var title = "Next";
            if period.subjects.count > 0 {
                title = "Next: \(UntisUtil.default.getSubtypeListString(subTypes: period.subjects))"
            }
            let titleColor = UntisUtil.default.getColor(for: period, subjects: subjects);
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            if let uiColor = UIColor(hex: titleColor.description) {
                titleTextProvider.tintColor = uiColor;
            }
            var subTitle = "";
            if period.rooms.count > 0 && period.teachers.count > 0 {
                subTitle = "In \(UntisUtil.default.getSubtypeListString(subTypes: period.rooms)) by \(UntisUtil.default.getSubtypeListString(subTypes: period.teachers))"
            } else if period.rooms.count > 0 {
                subTitle = "In \(UntisUtil.default.getSubtypeListString(subTypes: period.rooms))"
            } else if period.teachers.count > 0 {
                subTitle = "By \(UntisUtil.default.getSubtypeListString(subTypes: period.teachers))"
            } else {
                subTitle = "-";
            }
            let subTitleTextProvider = CLKSimpleTextProvider(text: subTitle);
            let relativeTextProvder = CLKRelativeDateTextProvider(date: period.startTime, style: .timer, units: [.hour, .minute, .second]);
            let localTemplate = CLKComplicationTemplateModularLargeStandardBody()
            localTemplate.headerTextProvider = titleTextProvider;
            localTemplate.body1TextProvider = subTitleTextProvider;
            localTemplate.body2TextProvider = relativeTextProvder;
            template = localTemplate;
            break;
        @unknown default:
            return nil;
        }
        
        if template != nil {
            return CLKComplicationTimelineEntry(date: date, complicationTemplate: template!)
        }
        return nil;
    }
    
    func getComplicationEntry(for complication: CLKComplication, period: Period, timegrid: Timegrid, subjects: [Subject]) -> CLKComplicationTimelineEntry? {
        var template: CLKComplicationTemplate?;
        
        switch complication.family {
        case .modularLarge:
            let title = UntisUtil.default.getRowTitle(period: period, timegrid: timegrid);
            let titleColor = UntisUtil.default.getColor(for: period, subjects: subjects);
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            if let uiColor = UIColor(hex: titleColor.description) {
                titleTextProvider.tintColor = uiColor;
            }
            var subTitle = "";
            if period.rooms.count > 0 && period.teachers.count > 0 {
                subTitle = "In \(UntisUtil.default.getSubtypeListString(subTypes: period.rooms)) by \(UntisUtil.default.getSubtypeListString(subTypes: period.teachers))"
            } else if period.rooms.count > 0 {
                subTitle = "In \(UntisUtil.default.getSubtypeListString(subTypes: period.rooms))"
            } else if period.teachers.count > 0 {
                subTitle = "By \(UntisUtil.default.getSubtypeListString(subTypes: period.teachers))"
            } else {
                subTitle = "-";
            }
            let subTitleTextProvider = CLKSimpleTextProvider(text: subTitle);
            let relativeTextProvder = CLKRelativeDateTextProvider(date: period.endTime, style: .timer, units: [.hour, .minute, .second]);
            let localTemplate = CLKComplicationTemplateModularLargeStandardBody()
            localTemplate.headerTextProvider = titleTextProvider;
            localTemplate.body1TextProvider = subTitleTextProvider;
            localTemplate.body2TextProvider = relativeTextProvder;
            template = localTemplate;
            break;
        @unknown default:
            return nil;
        }
        if template != nil {
            return CLKComplicationTimelineEntry(date: period.startTime, complicationTemplate: template!)
        }
        return nil;
    }
    
    func getTimelineEndEntry(for complication: CLKComplication, and date: Date) -> CLKComplicationTimelineEntry? {
        var template: CLKComplicationTemplate?;
        
        switch complication.family {
        case .modularLarge:
            let title = "End of Timeline";
            let titleColor: UIColor = .yellow;
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            titleTextProvider.tintColor = titleColor;
            let subTitleTextProvider = CLKSimpleTextProvider(text: "You did it!");
            let localTemplate = CLKComplicationTemplateModularLargeStandardBody()
            localTemplate.headerTextProvider = titleTextProvider;
            localTemplate.body1TextProvider = subTitleTextProvider;
            template = localTemplate;
            break;
        @unknown default:
            return nil;
        }
        
        if template != nil {
            return CLKComplicationTimelineEntry(date: date, complicationTemplate: template!)
        }
        return nil;
    }
    
    // MARK: Untis functions
    
    func getUntisTimeline(start date: Date, handler: @escaping ([Period]?) -> Void) {
        guard let untis = self.bgUtility.getUntisClient() else {
            return handler(nil);
        }
        untis.getTimetable(for: date, cachedHandler: nil) { result in
            var periods: [Period] = [];
            guard let currentPeriods = try? result.get() else {
                return handler(nil);
            }
            periods.append(contentsOf: currentPeriods);
            untis.getTimetable(for: Calendar.current.date(byAdding: .day, value: 1, to: date)!, cachedHandler: nil) { tomorrowResult in
                guard let tomorrowPeriods = try? tomorrowResult.get() else {
                    return handler(nil);
                }
                periods.append(contentsOf: tomorrowPeriods);
                if periods.count < 1 {
                    return handler(nil);
                }
                let sorted = periods.filter({ $0.startTime > date }).filter({ $0.code != .cancelled }).sortedPeriods(useEndtime: true);
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
                return failedHandler();
            }
            self.getSubjects { subjects in
                guard let subjects = subjects else {
                    return failedHandler();
                }
                self.getUntisTimeline(start: date) { (periods) in
                    guard let periods = periods else {
                        return failedHandler();
                    }
                    handler(periods, timegrid, subjects);
                }
            }
        }
    }
}
