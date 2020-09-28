//
//  LogFiles.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2020.
//

import Foundation

final class LogFileManager {
    
    public static let `default`: LogFileManager = LogFileManager();
    
    func loadLogFiles() -> [LogFile] {
        guard let targetDirRoot: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return [];
        }
        let targetDir = targetDirRoot.appendingPathComponent("Log/", isDirectory: true);
        do {
            try FileManager.default.contentsOfDirectory(atPath: targetDir.relativePath);
        } catch (let error) {
            log.error(error.localizedDescription)
        }
        guard let files: [String] = try? FileManager.default.contentsOfDirectory(atPath: targetDir.relativePath) else {
            return [];
        }
        let urls: [URL] = files
                    .map({ URL(fileURLWithPath: $0, relativeTo: targetDir) })
                    .filter({ $0.pathExtension == "log" || $0.pathExtension == ".log" });
        
        var logFiles: [LogFile] = [];
        
        for url in urls {
            let splitted = url.deletingPathExtension().lastPathComponent.split(separator: "-");
            if splitted.count != 2 {
                continue;
            }
            let logName = splitted[0];
            let typeOrName = splitted[1];
            if logName != "sitnu" {
                continue;
            }
            if typeOrName == "ios" {
                logFiles.append(LogFile(url: url, date: Date(), type: .iOS));
                continue;
            }
            guard let timeSince1970: Double = Double(typeOrName) else {
                continue;
            }
            let date: Date = Date(timeIntervalSince1970: timeSince1970);
            logFiles.append(LogFile(url: url, date: date, type: .watchOS));
        }
        
        logFiles.sort(by: { $0.date.compare($1.date) == .orderedDescending })
        
        return logFiles;
    }
    
}

enum LogFileType {
    case iOS;
    case watchOS;
}

struct LogFile {
    let url: URL;
    var name: String {
        self.url.lastPathComponent;
    }
    let date: Date;
    let type: LogFileType;
}
