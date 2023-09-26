//
//  RelativeDateTitle.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 26/09/2023.
//

import SwiftUI

struct RelativeDateTitle: View {
    let date: Date
    
    @State var title: String = ""
    
    var body: some View {
        Text(title)
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name("applicationDidBecomeActive"))) { _ in
                setTitle()
            }
            .onAppear(perform: {
                setTitle()
            })
            .onChange(of: date, initial: false) { oldValue, newValue in
                setTitle()
            }
    }
    
    func setTitle() {
        title = formatDate(date)
    }
}

let timetableDayFormatter: RelativeDateTimeFormatter = {
    let formatter: RelativeDateTimeFormatter = RelativeDateTimeFormatter();
    formatter.dateTimeStyle = .named;
    formatter.formattingContext = .dynamic;
    formatter.unitsStyle = .abbreviated
    return formatter;
}();

func formatDate(_ date: Date) -> String {
    let dateComponents: DateComponents = Calendar.current.dateComponents([Calendar.Component.day], from: Calendar.current.startOfDay(for: Date()), to: date)
    return timetableDayFormatter.localizedString(from: dateComponents);
}

#Preview {
    RelativeDateTitle(date: Date())
}
