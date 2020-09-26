//
//  ActivityIndicator.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import Foundation
import SwiftUI
import SDWebImageSwiftUI

struct ActivityIndicator: View {
    var active: Bool = false;
    
    var body: some View {
        WebImage(url: Bundle.main.url(forResource: "activity", withExtension: "png"), isAnimating: .constant(active))
            .antialiased(true)
            .interpolation(.high)
    }
    
}
