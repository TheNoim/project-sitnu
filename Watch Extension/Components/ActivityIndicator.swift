//
//  ActivityIndicator.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import Foundation
import SwiftUI
import Combine

class LoadingTimer {

    let publisher = Timer.publish(every: 1 / 60, on: .main, in: .default)
    private var timerCancellable: Cancellable?

    func start() {
        self.timerCancellable = publisher.connect()
    }

    func cancel() {
        self.timerCancellable?.cancel()
    }
}

struct ActivityIndicator: View {
    init(active: Bool?) {
        if active != nil {
            self.active = active!;
        } else {
            self.active = false;
        }
    }
    
    var active: Bool = false;
    
    @State private var index = 0

    private let images = (1...60).map { UIImage(named: "Activity\($0)")! }
    private var timer = LoadingTimer()

    var body: some View {
        if active {
            Image(uiImage: images[index])
                .resizable()
                .imageScale(.small)
                .frame(width: 58, height: 58, alignment: .center)
                .onReceive(
                    timer.publisher,
                    perform: { _ in
                        self.index = self.index + 1
                        if self.index >= 60 { self.index = 0 }
                    }
                )
                .onAppear { self.timer.start() }
                .onDisappear { self.timer.cancel() }
        } else {
            EmptyView()
        }
    }
    
}

struct ActivityIndicator_Preview: PreviewProvider {
    static var previews: some View {
        ActivityIndicator(active: true)
    }
}
