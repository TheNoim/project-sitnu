//
//  InfinitePageView.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 26/09/2023.
//

import Foundation
import SwiftUI

struct InfinitePageView<C, T>: View where C: View, T: Hashable {
    @Binding var selection: T
    @Binding var currentDate: Date
    @Binding var currentTab: Int
    
    let before: (T) -> T
    let after: (T) -> T
    
    @ViewBuilder let view: (T) -> C
        
    var body: some View {
        let previousIndex = before(selection)
        let nextIndex = after(selection)
        
        TabView(selection: $currentTab) {
            view(previousIndex)
                .tag(-1)
            
            view(selection)
                .onDisappear() {
                    
                    if currentTab != 0 {
                        if currentTab < 0 {
                            currentDate = Date.targetedYesterday
                        } else {
                            currentDate = Date.targetedTomorrow
                        }
                        Date.targetedDate = currentDate
                    }
                    
                    if currentTab != 0 {
                        selection = currentTab < 0 ? previousIndex : nextIndex
                        currentTab = 0
                    }
                }
                .tag(0)
            
            view(nextIndex)
                .tag(1)
        }
        .tabViewStyle(.verticalPage)
        .disabled(currentTab != 0) // FIXME: workaround to avoid glitch when swiping twice very quickly
    }
}

extension Date {
    
    static var targetedDate: Date? = Date()
    static var targetedYesterday: Date { return targetedDate!.dayBefore }
    static var targetedTomorrow:  Date { return targetedDate!.dayAfter }
    
    var dayBefore: Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
    }
    var dayAfter: Date {
        return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
    }
    var noon: Date {
        return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
    }
}
