//
//  AddView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 19/09/2020.
//

import SwiftUI
import Alamofire
import CodeScanner
import SwiftyBeaver

struct School: Codable, Identifiable {
    var id: Int { self.schoolId }
    
    var server: String;
    let displayName: String;
    var loginName: String;
    var user: String = "";
    var password: String = "";
    var useSecret: Bool = false;
    let schoolId: Int;
    let address: String;
    
    private enum CodingKeys: String, CodingKey {
        case server, displayName, loginName, schoolId, address
    }
}

struct SchoolSearchView: View {
    @State var schools: [School] = [];
    @State var searchTerm: String = "";
    @State var dataRequest: DataRequest?;
    @State var error: String = "";
    @State var qrSchool: School?;
    @State var scannedCode = false;
    let throttler = Throttler(minimumDelay: 0.5)
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(placeholder: "School name", text: $searchTerm.onChange({ _ in
                    self.throttler.throttle {
                        log.debug("Call search")
                        self.search();
                    }
                }))
                    .padding()
                if self.error.isEmpty {
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
                        NavigationLink(destination: AddView(school: School(server: "", displayName: "", loginName: "", password: "", schoolId: 0, address: ""))) {
                            VStack {
                                HStack {
                                    Text("Manual")
                                        .bold()
                                    Spacer()
                                }
                                HStack {
                                    Text("Enter details manual")
                                        .italic()
                                        .fontWeight(.light)
                                    Spacer()
                                }
                            }
                        }
                        if scannedCode {
                            NavigationLink(destination: AddView(school: qrSchool ?? School(server: "", displayName: "", loginName: "", password: "", schoolId: 0, address: "")), isActive: $scannedCode) {
                                EmptyView()
                            }
                        }
                        NavigationLink(destination: CodeScannerView(codeTypes: [.qr], completion: { result in
                            if case let .success(code) = result {
                                let cleanedUrl = code.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!;
                                log.debug("Code", cleanedUrl);
                                guard let url = URL(string: cleanedUrl) else {
                                    log.error("Failed to parse url");
                                    return;
                                }
                                if url.scheme != "untis" {
                                    return;
                                }
                                if url.host != "setschool" {
                                    return;
                                }
                                guard let components = url.components else {
                                    log.error("Failed to parse get parameters");
                                    return;
                                }
                                guard let schoolUrl = components.queryItems?["url"] else {
                                    log.error("No url");
                                    return;
                                }
                                guard let school = components.queryItems?["school"] else {
                                    log.error("No school");
                                    return;
                                }
                                guard let user = components.queryItems?["user"] else {
                                    log.error("No user");
                                    return;
                                }
                                guard let key = components.queryItems?["key"] else {
                                    log.error("No key");
                                    return;
                                }
                                guard let schoolNumberString = components.queryItems?["schoolNumber"], let schoolNumber = Int(schoolNumberString) else {
                                    log.error("No schoolNumber");
                                    return;
                                }
                                log.debug("key: \(key) user: \(user) school: \(school) url: \(schoolUrl)")
                                self.qrSchool = School(server: schoolUrl, displayName: "", loginName: school, user: user, password: key, useSecret: true, schoolId: schoolNumber, address: "")
                                self.scannedCode = true;
                            }
                        })) {
                            VStack {
                                HStack {
                                    Text("QR Code")
                                        .bold()
                                    Spacer()
                                }
                                HStack {
                                    Text("Use your camera to scan a QR-Code")
                                        .italic()
                                        .fontWeight(.light)
                                    Spacer()
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Text("Error: \(self.error)").foregroundColor(.red)
                        Spacer()
                    }.padding()
                    Spacer()
                }
            }
            .navigationBarTitle("Search School")
        }
    }
    
    func search() {
        self.error = "";
        if self.dataRequest != nil {
            if !self.dataRequest!.isCancelled && !self.dataRequest!.isFinished {
                self.dataRequest!.cancel();
            }
        }
        if !self.searchTerm.isEmpty {
            let searchQuery = self.searchTerm;
            AF.sessionConfiguration.timeoutIntervalForRequest = 5;
            self.dataRequest = AF.request("https://mobile.webuntis.com/ms/schoolquery2", method: .post, parameters: [
                "id": "wu_schulsuche-1600519970383",
                "method": "searchSchool",
                "params": [["search": searchQuery]],
                "jsonrpc": "2.0"
            ], encoding: JSONEncoding.default).responseJSON { response in
                switch response.result {
                case .failure(let error):
                    log.error("School search error", error.localizedDescription);
                    break;
                case .success(let result):
                    if let dic = result as? [String: Any] {
                        if let schoolDicArray = dic[keyPath: "result.schools"] {
                            if let schools = try? [School].init(from: schoolDicArray) {
                                withAnimation {
                                    self.schools = schools;
                                }
                            } else {
                                log.error("Failed to parse result.schools")
                            }
                        }
                        if let errorCode = dic[keyPath: "error.code"] as? Int {
                            if errorCode == -6003 {
                                self.error = "Too many results. Please enter more details"
                            } else {
                                if let errorMessage = dic[keyPath: "error.message"] as? String {
                                    self.error = "Unknown error with code \(errorCode). Untis message: \(errorMessage)";
                                } else {
                                    self.error = "Unknown error with code \(errorCode)";
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

extension URL {
    var components: URLComponents? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)
    }
}

extension Array where Iterator.Element == URLQueryItem {
    subscript(_ key: String) -> String? {
        return first(where: { $0.name == key })?.value
    }
}
