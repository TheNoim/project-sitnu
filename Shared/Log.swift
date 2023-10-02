//
//  Log.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 28/09/2023.
//

import Foundation
import SwiftyBeaver

let log = SwiftyBeaver.self

var fileManager: FileManager = .default;
var logLocation: URL?;

var logsInitialized = false

func initBeaver() {
    if logsInitialized {
        return
    }
    logsInitialized = true
    
    // Override point for customization after application launch.
    let logFormat: String = "$DHH:mm:ss.SSS$d $C$L$c $N.$F:$l - $M $X"
    
    let console: ConsoleDestination = ConsoleDestination()
    console.useNSLog = true
    console.format = logFormat;
    log.addDestination(console)
    
    DispatchQueue(label: "log").async {
        if let url: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            let logUrl: URL = url.appendingPathComponent("Log/", isDirectory: true).appendingPathComponent("sitnu-ios.log", isDirectory: false);
            logLocation = logUrl;
            let file = FileDestination(logFileURL: logUrl);
            file.format = logFormat;
            log.addDestination(file)
            log.debug("Added file destination")
        }
    }
}
