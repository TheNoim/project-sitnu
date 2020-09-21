//
//  AccountSelector.swift
//  Watch Extension
//
//  Created by Nils Bergmann on 20/09/2020.
//

import SwiftUI

struct AccountSelector: View {
    @EnvironmentObject var accountStore: AccountStore;
    @Binding var isOpen: Bool;
    
    var body: some View {
        List {
            ForEach(self.accountStore.accounts) { account in
                Button(displayName(account: account)) {
                    self.accountStore.selected = account;
                    self.isOpen.toggle();
                }
            }
        }
    }

    func displayName(account: UntisAccount) -> String {
        if account.primary {
            return "\(account.displayName) (Primary)";
        } else {
            return account.displayName;
        }
    }
}

struct AccountSelector_Previews: PreviewProvider {
    static var previews: some View {
        AccountSelector(isOpen: .constant(true))
    }
}
