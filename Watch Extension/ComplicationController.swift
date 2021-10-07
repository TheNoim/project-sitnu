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

    // MARK: - Timeline Configuration
    
    func getTimelineEndDate(for complication: CLKComplication, withHandler handler: @escaping (Date?) -> Void) {
        let requestDate = Date();
        log.debug("Get timeline end date")
        // Call the handler with the last entry date you can currently provide or nil if you can't support future timelines
        self.getUntisTimeline(start: getDateWithOffset(for: Date())) { (periods) in
            guard let periods = periods else {
                log.warning("No periods")
                if let endDate = Calendar.current.date(byAdding: .day, value: 1, to: requestDate) {
                    let startOfDay = Calendar.current.startOfDay(for: endDate)
                    if let endOfDay = Calendar.current.date(byAdding: .hour, value: 24, to: startOfDay) {
                        log.debug("Set end of timeline to", context: ["endTime": endOfDay])
                        return handler(endOfDay);
                    }
                }
                return handler(nil);
            }
            guard let last = periods.last else {
                log.warning("No last period")
                if let endDate = Calendar.current.date(byAdding: .day, value: 1, to: requestDate) {
                    let startOfDay = Calendar.current.startOfDay(for: endDate)
                    if let endOfDay = Calendar.current.date(byAdding: .hour, value: 24, to: startOfDay) {
                        log.debug("Set end of timeline to", context: ["endTime": endOfDay])
                        return handler(endOfDay);
                    }
                }
                return handler(nil);
            }
            log.debug("New timeline end date", context: ["endTime": last.endTime])
            handler(last.endTime);
        }
        
    }
    
    func getPrivacyBehavior(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationPrivacyBehavior) -> Void) {
        // Call the handler with your desired behavior when the device is locked
        handler(.showOnLockScreen)
    }

    // MARK: - Timeline Population
    
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        let currentDate = Date();
        log.debug("Get current timeline entry")
        self.getAllUntisInformation(for: currentDate) {
            log.error("Failed handler was called. Error or End of Timeline")
            if let endOfTimelineEntry = self.getTimelineEndEntry(for: complication, and: currentDate) {
                return handler(endOfTimelineEntry);
            }
            handler(nil);
        } handler: { (periods, timegrid, subjects) in
            // If there is currently a period
            if let currentPeriod = periods.first(where: { $0.startTime < currentDate && $0.endTime > currentDate }) {
                guard let account = self.bgUtility.getPrimaryAccount() else {
                    return handler(nil);
                }
                let currentEntry = self.getComplicationEntry(for: complication, account: account, period: currentPeriod, timegrid: timegrid, subjects: subjects);
                log.debug("Current entry is current period", context: ["currentDate": currentDate, "startTime": currentPeriod.startTime, "endTime": currentPeriod.endTime]);
                handler(currentEntry);
            } else {
                // It is currently a break
                if let nextPeriodIndex = periods.firstIndex(where: { $0.startTime > currentDate }) {
                    let nextPeriod = periods[nextPeriodIndex];
                    var breakDate = Calendar.current.startOfDay(for: currentDate); // If it is a new timeline
                    if nextPeriodIndex >= 1 {
                        // There is a period before
                        let lastPeriod = periods[nextPeriodIndex - 1]
                        // The start date of the break template is the end date of the last period
                        breakDate = Calendar.current.date(byAdding: .nanosecond, value: 1, to: lastPeriod.endTime)!;
                    }
                    let breakEntry = self.getBreakComplicationEntry(for: complication, date: breakDate, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                    log.debug("Current entry needs break template", context: ["currentDate": currentDate, "nextPeriodStartTime": nextPeriod.startTime, "nextPeriodEndTime": nextPeriod.endTime, "breakDate": breakDate]);
                    handler(breakEntry);
                } else {
                    log.debug("Current entry is timeline end");
                    // End of timeline
                    let endOfTimelineEntry = self.getTimelineEndEntry(for: complication, and: currentDate);
                    handler(endOfTimelineEntry);
                }
            }
        }

    }
    
    func getTimelineEntries(for complication: CLKComplication, after date: Date, limit: Int, withHandler handler: @escaping ([CLKComplicationTimelineEntry]?) -> Void) {
        self.getAllUntisInformation(for: date) {
            log.error("Failed handler was called. Error or End of Timeline. Pass empty array")
            handler([]);
        } handler: { (periods, timegrid, subjects) in
            // .filter({ $0.startTime > date || ($0.startTime < date && $0.endTime > date) })
            var entries: [CLKComplicationTimelineEntry] = [];
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
                        let nextEntry = self.getComplicationEntry(for: complication, account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                        entries.appendWithLimitCheck(limit, item: nextEntry!);
                    } else {
                        // We need to add a break entry
                        let nextEntry = self.getBreakComplicationEntry(for: complication, date: currentPeriod.endTime, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                        entries.appendWithLimitCheck(limit, item: nextEntry!);
                        let nextPeriodEntry = self.getComplicationEntry(for: complication, account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                        entries.appendWithLimitCheck(limit, item: nextPeriodEntry!);
                    }
                    // Every next period needs to be after this time
                    lastEndTime = nextPeriod.endTime;
                } else {
                    // No next Period. The next entry is the end of the timeline
                    let endEntry = self.getTimelineEndEntry(for: complication, and: date);
                    entries.appendWithLimitCheck(limit, item: endEntry!);
                    // We don't need to add anything anymore. We can just return.
                    return handler(entries);
                }
            } else {
                if let nextPeriod = periods.first(where: { $0.startTime >= date }) {
                    // New Timeline
                    let nextEntry = self.getBreakComplicationEntry(for: complication, date: lastEndTime, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                    entries.appendWithLimitCheck(limit, item: nextEntry!);
                    let nextPeriodEntry = self.getComplicationEntry(for: complication, account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                    entries.appendWithLimitCheck(limit, item: nextPeriodEntry!);
                    lastEndTime = nextPeriod.endTime;
                } else {
                    // No next Period. The next entry is the end of the timeline
                    let endEntry = self.getTimelineEndEntry(for: complication, and: date);
                    entries.appendWithLimitCheck(limit, item: endEntry!);
                    // We don't need to add anything anymore. We can just return.
                    return handler(entries);
                }
            }
            
            while (true) {
                if let nextPeriod = periods.first(where: { $0.startTime >= lastEndTime }) {
                    let n = nextPeriod.startTime.timeIntervalSince1970;
                    let c = lastEndTime.timeIntervalSince1970;
                    if abs(n - c) <= 1 {
                        // We don't need a break entry
                        let nextEntry = self.getComplicationEntry(for: complication, account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                        entries.appendWithLimitCheck(limit, item: nextEntry!);
                    } else {
                        // We need to add a break entry, because there is time between last period and next period
                        let breakEntry = self.getBreakComplicationEntry(for: complication, date: lastEndTime, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                        entries.appendWithLimitCheck(limit, item: breakEntry!);
                        let nextPeriodEntry = self.getComplicationEntry(for: complication, account: account, period: nextPeriod, timegrid: timegrid, subjects: subjects);
                        entries.appendWithLimitCheck(limit, item: nextPeriodEntry!);
                    }
                    lastEndTime = nextPeriod.endTime;
                } else {
                    // There is no next period. This is the end of timeline
                    let endEntry = self.getTimelineEndEntry(for: complication, and: lastEndTime);
                    entries.appendWithLimitCheck(limit, item: endEntry!);
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

    // MARK: - Sample Templates
    
    func getLocalizableSampleTemplate(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTemplate?) -> Void) {
        // This method will be called once per supported complication, and the results will be cached
        handler(nil)
    }
    
    // MARK: Entry generators
    
    func getBreakComplicationEntry(for complication: CLKComplication, date: Date, period: Period, timegrid: Timegrid, subjects: [Subject]) -> CLKComplicationTimelineEntry? {
        var template: CLKComplicationTemplate?;
        
        switch complication.family {
        case .modularLarge, .graphicRectangular:
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
            if complication.family == .modularLarge {
                let localTemplate = CLKComplicationTemplateModularLargeStandardBody()
                localTemplate.headerTextProvider = titleTextProvider;
                localTemplate.body1TextProvider = subTitleTextProvider;
                localTemplate.body2TextProvider = relativeTextProvder;
                template = localTemplate;
            } else {
                let localTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
                localTemplate.headerTextProvider = titleTextProvider;
                localTemplate.body1TextProvider = subTitleTextProvider;
                localTemplate.body2TextProvider = relativeTextProvder;
                template = localTemplate;
            }
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphiccircularstacktext
        case .graphicCorner:
            let innerColor = UntisUtil.default.getColor(for: period, subjects: subjects);
            let title = "Break";
            let relativeTextProvder = CLKRelativeDateTextProvider(date: period.startTime, style: .timer, units: [.hour, .minute, .second]);
            if let uiColor = UIColor(hex: innerColor.description) {
                relativeTextProvder.tintColor = uiColor;
            }
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            let localTemplate = CLKComplicationTemplateGraphicCornerStackText();
            localTemplate.outerTextProvider = titleTextProvider;
            localTemplate.innerTextProvider = relativeTextProvder;
            template = localTemplate;
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphiccornerstacktext
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplatecircularsmallstacktext
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplatemodularsmallstacktext
        case .graphicCircular, .modularSmall, .circularSmall:
            let innerColor = UntisUtil.default.getColor(for: period, subjects: subjects);
            let title = "Break";
            let relativeTextProvder = CLKRelativeDateTextProvider(date: period.startTime, style: .timer, units: [.hour, .minute, .second]);
            if let uiColor = UIColor(hex: innerColor.description) {
                relativeTextProvder.tintColor = uiColor;
            }
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            if complication.family == .graphicCircular {
                let localTemplate = CLKComplicationTemplateGraphicCircularStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            } else if complication.family == .modularSmall {
                let localTemplate = CLKComplicationTemplateModularSmallStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            } else {
                let localTemplate = CLKComplicationTemplateCircularSmallStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            }
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphicextralargecircularstacktext
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                let titleColor = UntisUtil.default.getColor(for: period, subjects: subjects);
                let title = "Break";
                let titleTextProvider = CLKSimpleTextProvider(text: title);
                let relativeTextProvder = CLKRelativeDateTextProvider(date: period.startTime, style: .timer, units: [.hour, .minute, .second]);
                if let uiColor = UIColor(hex: titleColor.description) {
                    relativeTextProvder.tintColor = uiColor;
                }
                let localTemplate = CLKComplicationTemplateGraphicExtraLargeCircularStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
                break;
            }
            break;
        @unknown default:
            return nil;
        }
        
        if template != nil {
            return CLKComplicationTimelineEntry(date: Calendar.current.date(byAdding: .nanosecond, value: 1, to: date)!, complicationTemplate: template!)
        }
        return nil;
    }
    
    func getComplicationEntry(for complication: CLKComplication, account: UntisAccount, period: Period, timegrid: Timegrid, subjects: [Subject]) -> CLKComplicationTimelineEntry? {
        var template: CLKComplicationTemplate?;
        
        switch complication.family {
        case .modularLarge, .graphicRectangular:
            let title = UntisUtil.default.getRowTitle(acc: account, period: period, timegrid: timegrid);
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
            if complication.family == .modularLarge {
                let localTemplate = CLKComplicationTemplateModularLargeStandardBody()
                localTemplate.headerTextProvider = titleTextProvider;
                localTemplate.body1TextProvider = subTitleTextProvider;
                localTemplate.body2TextProvider = relativeTextProvder;
                template = localTemplate;
            } else {
                let localTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
                localTemplate.headerTextProvider = titleTextProvider;
                localTemplate.body1TextProvider = subTitleTextProvider;
                localTemplate.body2TextProvider = relativeTextProvder;
                template = localTemplate;
            }
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphiccircularstacktext
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplatecircularsmallstacktext
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplatemodularsmallstacktext
        case .graphicCircular, .modularSmall, .circularSmall:
            let title = UntisUtil.default.getShortRowTitle(period: period, timegrid: timegrid);
            let innerColor = UntisUtil.default.getColor(for: period, subjects: subjects);
            let relativeTextProvder = CLKRelativeDateTextProvider(date: period.endTime, style: .timer, units: [.hour, .minute, .second]);
            if let uiColor = UIColor(hex: innerColor.description) {
                relativeTextProvder.tintColor = uiColor;
            }
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            if complication.family == .graphicCircular {
                let localTemplate = CLKComplicationTemplateGraphicCircularStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            } else if complication.family == .modularSmall {
                let localTemplate = CLKComplicationTemplateModularSmallStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            } else {
                let localTemplate = CLKComplicationTemplateCircularSmallStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            }
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphiccornerstacktext
        case .graphicCorner:
            let title = UntisUtil.default.getShortRowTitle(period: period, timegrid: timegrid);
            let innerColor = UntisUtil.default.getColor(for: period, subjects: subjects);
            let relativeTextProvder = CLKRelativeDateTextProvider(date: period.endTime, style: .timer, units: [.hour, .minute, .second]);
            if let uiColor = UIColor(hex: innerColor.description) {
                relativeTextProvder.tintColor = uiColor;
            }
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            let localTemplate = CLKComplicationTemplateGraphicCornerStackText();
            localTemplate.outerTextProvider = titleTextProvider;
            localTemplate.innerTextProvider = relativeTextProvder;
            template = localTemplate;
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphicextralargecircularstacktext
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                let title = UntisUtil.default.getShortRowTitle(period: period, timegrid: timegrid);
                let titleColor = UntisUtil.default.getColor(for: period, subjects: subjects);
                let relativeTextProvder = CLKRelativeDateTextProvider(date: period.endTime, style: .timer, units: [.hour, .minute, .second]);
                let titleTextProvider = CLKSimpleTextProvider(text: title);
                if let uiColor = UIColor(hex: titleColor.description) {
                    titleTextProvider.tintColor = uiColor;
                }
                let localTemplate = CLKComplicationTemplateGraphicExtraLargeCircularStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = relativeTextProvder;
                template = localTemplate;
            }
            break;
        @unknown default:
            return nil;
        }
        if template != nil {
            return CLKComplicationTimelineEntry(date: Calendar.current.date(byAdding: .nanosecond, value: 1, to: period.startTime)!, complicationTemplate: template!)
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
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphicrectangularstandardbody
        case .graphicRectangular:
            let title = "End of Timeline";
            let titleColor: UIColor = .yellow;
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            titleTextProvider.tintColor = titleColor;
            let subTitleTextProvider = CLKSimpleTextProvider(text: "You did it!");
            let localTemplate = CLKComplicationTemplateGraphicRectangularStandardBody()
            localTemplate.headerTextProvider = titleTextProvider;
            localTemplate.body1TextProvider = subTitleTextProvider;
            template = localTemplate;
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphiccircularstacktext
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplatecircularsmallstacktext
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplatemodularsmallstacktext
        case .graphicCircular, .modularSmall, .circularSmall:
            let title = "End";
            let innerColor: UIColor = .yellow;
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            let subTitleTextProvider = CLKSimpleTextProvider(text: ":-)");
            subTitleTextProvider.tintColor = innerColor;
            if complication.family == .graphicCircular {
                let localTemplate = CLKComplicationTemplateGraphicCircularStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = subTitleTextProvider;
                template = localTemplate;
            } else if complication.family == .modularSmall {
                let localTemplate = CLKComplicationTemplateModularSmallStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = subTitleTextProvider;
                template = localTemplate;
            } else {
                let localTemplate = CLKComplicationTemplateCircularSmallStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = subTitleTextProvider;
                template = localTemplate;
            }
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphiccornerstacktext
        case .graphicCorner:
            let title = "End";
            let innerColor: UIColor = .yellow;
            let titleTextProvider = CLKSimpleTextProvider(text: title);
            let subTitleTextProvider = CLKSimpleTextProvider(text: "You did it!");
            subTitleTextProvider.tintColor = innerColor;
            let localTemplate = CLKComplicationTemplateGraphicCornerStackText();
            localTemplate.outerTextProvider = titleTextProvider;
            localTemplate.innerTextProvider = subTitleTextProvider;
            template = localTemplate;
            break;
        // https://developer.apple.com/documentation/clockkit/clkcomplicationtemplategraphicextralargecircularstacktext
        case .graphicExtraLarge:
            if #available(watchOSApplicationExtension 7.0, *) {
                let title = "End";
                let titleColor: UIColor = .yellow;
                let titleTextProvider = CLKSimpleTextProvider(text: title);
                let subTitleTextProvider = CLKSimpleTextProvider(text: ":-)");
                titleTextProvider.tintColor = titleColor;
                let localTemplate = CLKComplicationTemplateGraphicExtraLargeCircularStackText();
                localTemplate.line1TextProvider = titleTextProvider;
                localTemplate.line2TextProvider = subTitleTextProvider;
                template = localTemplate;
            }
            break;
        @unknown default:
            return nil;
        }
        
        if template != nil {
            return CLKComplicationTimelineEntry(date: Calendar.current.date(byAdding: .nanosecond, value: 1, to: date)!, complicationTemplate: template!)
        }
        return nil;
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

extension Array where Element == CLKComplicationTimelineEntry {
    
    mutating func appendWithLimitCheck(_ limit: Int, item: CLKComplicationTimelineEntry) {
        if self.count < limit {
            self.append(item);
        }
    }
    
}
