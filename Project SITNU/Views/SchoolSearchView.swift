//
//  AddView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import SwiftUI
import Alamofire

struct School: Codable, Identifiable {
    var id: Int { self.schoolId }
    
    let server: String;
    let displayName: String;
    let loginName: String;
    let schoolId: Int;
    let address: String;
}

struct SchoolSearchView: View {
    @State var schools: [School] = [];
    @State var searchTerm: String = "";
    @State var dataRequest: DataRequest?;
    let throttler = Throttler(minimumDelay: 0.5)
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(placeholder: "School name", text: $searchTerm.onChange({ _ in
                    self.throttler.throttle {
                        print("Call search")
                        self.search();
                    }
                }))
                    .padding()
                List {
                    ForEach(self.schools) { (school: School) in
                        NavigationLink(destination: AddView(school: school)) {
                            VStack {
                                HStack {
                                    Text(school.displayName)
                                        .bold()
                                    Spacer()
                                }
                                HStack {
                                    Text(school.address)
                                        .italic()
                                        .fontWeight(.light)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Search School")
        }
    }
    
    func search() {
        if self.dataRequest != nil {
            if !self.dataRequest!.isCancelled && !self.dataRequest!.isFinished {
                self.dataRequest!.cancel();
            }
        }
        if !self.searchTerm.isEmpty {
            let searchQuery = self.searchTerm;
            self.dataRequest = AF.request("https://mobile.webuntis.com/ms/schoolquery2", method: .post, parameters: [
                "id": "wu_schulsuche-1600519970383",
                "method": "searchSchool",
                "params": [["search": searchQuery]],
                "jsonrpc": "2.0"
            ], encoding: JSONEncoding.default).responseJSON { response in
                switch response.result {
                case .failure(let error):
                    print("School search error: \(error.localizedDescription)")
                    break;
                case .success(let result):
                    if let dic = result as? [String: Any] {
                        if let schoolDicArray = dic[keyPath: "result.schools"] {
                            if let schools = try? [School].init(from: schoolDicArray) {
                                withAnimation {
                                    self.schools = schools;
                                }
                            }
                        }
                    }
                    break;
                }
            }
        }
    }
}

struct SchoolSearchView_Previews: PreviewProvider {
    static var previews: some View {
        SchoolSearchView()
    }
}
