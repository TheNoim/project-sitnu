//
//  AccountStore.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import Foundation

class AccountStore: ObservableObject {
    @Published var accounts: [UntisAccount] = [];
    @Published var initialFetch: Bool = false;
    @Published var selected: UntisAccount?;
}
