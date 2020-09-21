//
//  SearchBar.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 20/09/2020.
//

import SwiftUI

struct SearchBar: View {
    var placeholder: String
        
    @Binding var text: String
    
    @Environment(\.colorScheme) var colorScheme

    var backgroundColor: Color {
      if colorScheme == .dark {
           return Color(.systemGray5)
       } else {
           return Color(.systemGray6)
       }
    }
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
            if text != "" {
                Image(systemName: "xmark.circle.fill")
                    .imageScale(.medium)
                    .foregroundColor(Color(.systemGray3))
                    .padding(3)
                    .onTapGesture {
                        withAnimation {
                            self.text = ""
                          }
                    }
            }
        }
        .padding(10)
        .background(backgroundColor)
        .cornerRadius(12)
        .padding(.vertical, 10)
    }
}

struct SearchBar_Previews: PreviewProvider {
    static var previews: some View {
        SearchBar(placeholder: "Test", text: .constant("Whatever"))
    }
}
