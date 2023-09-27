//
//  WatchConnectivityStore.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 25/09/2023.
//

import Foundation
import WatchConnectivity
import KeychainSwift
#if os(watchOS)
import WatchKit
#endif

@Observable
final class WatchConnectivityStore: NSObject, WCSessionDelegate {
    // MARK: - Store states
    
    public var accounts: [UntisAccount] = []
    public var isReachable = false
    public var currentlySelected: UntisAccount?
    
    #if os(iOS)
    public var logFiles: [LogFile] = []
    #endif
    
    // MARK: - WCSession Callbacks
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        log.debug("activationDidCompleteWith activationState=\(activationState.rawValue) error=\(String(describing: error))", "WatchConnectivityStore")
    }
    
    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        log.debug("sessionWatchStateDidChange", "WatchConnectivityStore")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        log.debug("Session did become inactive", "WatchConnectivityStore")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        log.debug("Session did deactivate", "WatchConnectivityStore")
    }
    #endif
        
    func sessionReachabilityDidChange(_ session: WCSession) {
        log.debug("sessionReachabilityDidChange to \(session.isReachable)", "WatchConnectivityStore")
        if session.isReachable {
            isReachable = true
        } else {
            isReachable = false
        }
    }
    
    #if os(iOS)
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata: [String: Any] = file.metadata else {
            log.warning("Discard transferred file, because metadata is missing", "WatchConnectivityStore");
            return;
        }
        guard let metaType: String = metadata["type"] as? String else {
            log.warning("Discard transferred file, because type metadata is missing", "WatchConnectivityStore");
            return;
        }
        if metaType == "log" {
            guard let targetDirRoot: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                log.error("Missing target dir root", "WatchConnectivityStore")
                return;
            }
            let targetDir = targetDirRoot.appendingPathComponent("Log/", isDirectory: true).appendingPathComponent(file.fileURL.lastPathComponent, isDirectory: false);
            log.info("Move transferred file", context: ["at": file.fileURL, "to": targetDir]);
            do {
                try FileManager.default.moveItem(at: file.fileURL, to: targetDir);
                updateLogFiles()
            } catch(let error) {
                log.error("Failed to move transferred file", context: ["error": error]);
            }
        } else {
            log.warning("Discard transferred file, because type metadata is unknown", "WatchConnectivityStore");
        }
    }
    #endif
    
    #if os(watchOS)
    func session(_ session: WCSession, didReceiveMessageData messageData: Data) {
        guard let decodedData = try? decoder.decode(MessageContainer.self, from: messageData) else {
            log.warning("Failed to decode data. Do not update current credentials", "WatchConnectivityStore")
            return
        }
        if case .credentialsSync(let accounts) = decodedData {
            self.accounts = accounts
            saveToKeyChain()
            selectPrimaryAccount()
            log.debug("Did receive new credentials and store them in keychain", context: "WatchConnectivityStore")
        }
        if case .requestLogFile = decodedData {
            guard let delegate: ExtensionDelegate = WKExtension.shared().delegate as? ExtensionDelegate else {
                log.error("Missing Extension delegate", "WatchConnectivityStore");
                return;
            }
            guard let logLocation: URL = delegate.logLocation else {
                log.error("Missing log location", "WatchConnectivityStore");
                return;
            }
            if !FileManager.default.fileExists(atPath: logLocation.relativePath) {
                log.error("Log file doesn't exist", "WatchConnectivityStore");
                return;
            }
            let logDirectory: URL = logLocation.deletingLastPathComponent();
            let copyDate: Date = Date();
            let copyLogLocation: URL = logDirectory.appendingPathComponent("sitnu-\(copyDate.timeIntervalSince1970).log", isDirectory: false);
            try? FileManager.default.copyItem(at: logLocation, to: copyLogLocation);
            if !FileManager.default.fileExists(atPath: copyLogLocation.relativePath) {
                log.error("Failed to duplicate log file", "WatchConnectivityStore");
                return;
            }
            log.info("Start log transfer", context: ["location": copyLogLocation.absoluteURL]);
            session.transferFile(copyLogLocation, metadata: ["date": copyDate, "type": "log"]);
        }
    }
    
    func session(_ session: WCSession, didReceiveMessageData messageData: Data, replyHandler: @escaping (Data) -> Void) {
        self.session(session, didReceiveMessageData: messageData)
        replyHandler(Data())
    }
    #endif
    
    // MARK: - Init WC Session
    
    private let wcSession = WCSession.default
    /// Default store instance
    public static let `default` = WatchConnectivityStore()
    
    /// Setup the WCSession and load account data from Keychain into store
    /// Set `withWCSession` to false for background tasks and if you don't expect to receive credential updates
    func initialize(withWCSession: Bool = true) {
        if withWCSession {
            wcSession.delegate = self
            wcSession.activate()
            isReachable = wcSession.isReachable
            log.debug("WCSession activated", "WatchConnectivityStore")
        }
        loadFromKeyChain()
        if withWCSession {
            sessionReachabilityDidChange(wcSession)
            #if os(iOS)
            updateLogFiles()
            #endif
        }
    }
    
    // MARK: - Sync between devices
    
    #if os(iOS)
    func sync() {
        if !wcSession.isReachable {
            log.warning("Other device is not reachable. Can not update credentials on other device", "WatchConnectivityStore")
            return
        }
        log.debug("Sync accounts: \(accounts)")
        let dataMessage = MessageContainer.credentialsSync(accounts)
        guard let encodedData = try? encoder.encode(dataMessage) else {
            log.warning("Failed to encode data. Can not send to other device", "WatchConnectivityStore")
            return
        }
        wcSession.sendMessageData(encodedData, replyHandler: nil)
        log.debug("Send credentials to other device", "WatchConnectivityStore")
    }
    #endif
    
    // MARK: - Sync Local Data Store
    
    private let keychain = KeychainSwift()
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    private let key = "io.noim.project-sitnu.acc"
    
    /// Load current accounts from keychain and puts them into accounts var of this store
    func loadFromKeyChain() {
        guard let data = keychain.getData(key) else {
            accounts = []
            log.warning("Missing Account data in KeyChain. Set store to []", "WatchConnectivityStore")
            return
        }
        guard let decodedData = try? decoder.decode([UntisAccount].self, from: data) else {
            accounts = []
            log.warning("Failed to decode data. Set store to []", "WatchConnectivityStore")
            return
        }
        accounts = decodedData
        selectPrimaryAccount()
        log.debug("Successfully restored account data into store", "WatchConnectivityStore")
    }
    
    func selectPrimaryAccount() {
        if accounts.count == 0 {
            currentlySelected = nil
        }
        if currentlySelected != nil {
            return
        }
        if let firstPrimaryIndex: Int = accounts.firstIndex(where: { $0.primary }) {
            currentlySelected = accounts[firstPrimaryIndex]
        } else {
            currentlySelected = nil
        }
    }
    
    /// Takes the current value of accounts and stores it in the keychain
    func saveToKeyChain() {
        guard let encodedData = try? encoder.encode(accounts) else {
            log.warning("Failed to encode data. Will not save in KeyChain", "WatchConnectivityStore")
            return
        }
        keychain.set(encodedData, forKey: key)
    }
    
    // MARK: - Log Files Sync
    
    #if os(iOS)
    func updateLogFiles() {
        logFiles = LogFileManager.default.loadLogFiles();
    }
    
    func requestLogFiles() {
        if !wcSession.isReachable {
            log.warning("Other device is not reachable. Can not request log files", "WatchConnectivityStore")
            return
        }
        let dataMessage = MessageContainer.requestLogFile
        guard let encodedData = try? encoder.encode(dataMessage) else {
            log.warning("Failed to encode data. Can not send to other device", "WatchConnectivityStore")
            return
        }
        wcSession.sendMessageData(encodedData, replyHandler: nil)
        log.debug("Requested log files", "WatchConnectivityStore")
    }
    #endif
}
