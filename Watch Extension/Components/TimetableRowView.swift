//
//  TimetableRowView.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 21/09/2020.
//

import SwiftUI

struct TimetableRowView: View {
    // MARK: Props
    
    let period: Period;
    let timegrid: Timegrid?;
    let subjects: [Subject]?;
    
    // MARK: Computed
    
    let title: String;
    let subtitle: String;
    let color: Color;
    let acc: UntisAccount;
    
    init(account: UntisAccount, period: Period, timegrid: Timegrid?, subjects: [Subject]?) {
        self.period = period;
        self.timegrid = timegrid;
        self.subjects = subjects;
        self.acc = account;
        
        self.title = UntisUtil.default.getRowTitle(acc: account, period: period, timegrid: self.timegrid);
        self.subtitle = UntisUtil.default.getRowSubtitle(period: period);
        self.color = UntisUtil.default.getColor(for: period, subjects: self.subjects);
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(title)
                    .strikethrough(period.code == .cancelled)
                    .foregroundColor(color)
                Spacer()
            }
            Divider()
            HStack {
                Text(subtitle)
                    .strikethrough(period.code == .cancelled)
                Spacer()
            }
        }
    }
}
