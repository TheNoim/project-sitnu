//
//  Project_SITNUTests.swift
//  Project SITNUTests
//
//  Created by Nils Bergmann on 18/09/2020.
//

import XCTest
@testable import Project_SITNU

class Project_SITNUTests: XCTestCase {
    
    private var credentials: BasicUntisCredentials?;

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        let testBundle = Bundle(for: type(of: self));
        guard let file = testBundle.path(forResource: "credentials", ofType: "plist"), let configuration = NSDictionary(contentsOfFile: file) as? [String: Any] else {
            throw "Please save credentials in credentials.plist.";
        }
        guard let username = configuration["username"] as? String, let password = configuration["password"] as? String, let server = configuration["server"] as? String, let school = configuration["school"] as? String else {
            throw "You forgot something.";
        }
        self.credentials = BasicUntisCredentials(username: username, password: password, server: server, school: school)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testGetTimegrid() throws {
        let expectation = XCTestExpectation(description: "Fetch timegrid")
        
        let credentials = self.credentials!;
        let client = UntisClient(credentials: credentials);
        
        client.getTimegrid { (timegrid) in
            print("Cached timegrid: \(timegrid)")
        } completion: { (response) in
            switch response {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                break;
            case .success(let timegrid):
                XCTAssertNotNil(timegrid, "Timegrid should not be nil");
                print("Final timegrid: \(timegrid)")
                break;
            }
            expectation.fulfill();
        }

        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetLatestImportTime() throws {
        let expectation = XCTestExpectation(description: "Fetch latest import time")
        
        let credentials = self.credentials!;
        let client = UntisClient(credentials: credentials);
        
        client.getLatestImportTime(force: false) { (time) in
            print("Cached time: \(time)");
        } completion: { (response) in
            switch response {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                break;
            case .success(let time):
                XCTAssertNotNil(time, "Time should not be nil");
                print("Final time: \(time)")
                break;
            }
            expectation.fulfill();
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func testGetTimetable() throws {
        let expectation = XCTestExpectation(description: "Fetch timetable")
        
        let credentials = self.credentials!;
        let client = UntisClient(credentials: credentials);
        
        let testDate = Calendar.current.date(byAdding: .day, value: 4, to: Date())!
        
        client.getTimetable(for: testDate, and: true) { (timetable) in
            print("Cached timetable: \(timetable)");
        } completion: { (response) in
            switch response {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                break;
            case .success(let timetable):
                XCTAssertNotNil(timetable, "Timetable should not be nil");
                print("Final timetable: \(timetable)")
                break;
            }
            expectation.fulfill();
        }

        wait(for: [expectation], timeout: 10.0)
    }
    
    func testSubjects() throws {
        let expectation = XCTestExpectation(description: "Fetch subjects")
        
        let credentials = self.credentials!;
        let client = UntisClient(credentials: credentials);
                
        client.getSubjectColors { (timetable) in
            print("Cached subjects: \(timetable)");
        } completion: { (response) in
            switch response {
            case .failure(let error):
                XCTFail(error.localizedDescription)
                break;
            case .success(let subjects):
                XCTAssertNotNil(subjects, "Subjects should not be nil");
                print("Final subjects: \(subjects)")
                break;
            }
            expectation.fulfill();
        }

        wait(for: [expectation], timeout: 10.0)
    }

}

extension String: Error {}
