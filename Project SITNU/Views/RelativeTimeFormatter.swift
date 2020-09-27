//
//  RelativeTimeFormatter.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2020.
//

import SwiftUI

struct RelativeTimeFormatter: View {
    @State var formattedString: String = "";
    
    var date: Date;
    
    var body: some View {
        Text(formattedString)
            .onAppear() {
                let formatter = RelativeDateTimeFormatter();
                self.formattedString = formatter.localizedString(for: date, relativeTo: Date())
            }
    }
}

struct RelativeTimeFormatter_Previews: PreviewProvider {
    static var previews: some View {
        RelativeTimeFormatter(date: Date())
    }
}
