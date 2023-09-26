//
//  LogFileListView.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2020.
//

import SwiftUI

struct LogFileListView: View {
    @State var logFiles: [LogFile];
    
    @State private var editMode = EditMode.inactive
    
    @Environment(WatchConnectivityStore.self) var store
    
    var body: some View {
        List {
            ForEach(logFiles, id: \.name) { (file) in
                NavigationLink(destination: logFileViewer(for: file)) {
                    VStack {
                        HStack {
                            Text(file.url.relativePath)
                            Spacer()
                        }
                        HStack {
                            RelativeTimeFormatter(date: file.date)
                                .font(.caption)
                            Spacer()
                        }
                    }
                }
                .id("log-file-entry@\(file.name)")
            }
            .onDelete { files in
                let fm = FileManager.default;
                for fileIndex in files {
                    let file = self.logFiles[fileIndex];
                    do {
                        try fm.removeItem(at: file.url);
                        let _ = withAnimation {
                            logFiles.remove(at: fileIndex)
                        }
                    } catch (let error) {
                        log.error("Failed to remove log file", context: ["error": error]);
                    }
                }
                withAnimation {
                    self.store.updateLogFiles();
                }
            }
        }
        .environment(\.editMode, $editMode)
        .navigationBarItems(trailing: Button(action: {
            withAnimation {
                if self.editMode == .inactive {
                    self.editMode = .active;
                } else {
                    self.editMode = .inactive;
                }
            }
        }) {
            Text("Edit")
                .frame(height: 44)
        })
        .navigationBarTitle("Log files")
    }
    
    func logFileViewer(for file: LogFile) -> some View {
        return LogFileViewer(file).id("log-file-view@\(file.name)");
    }
}

struct LogFileListView_Previews: PreviewProvider {
    static var previews: some View {
        LogFileListView(logFiles: [])
    }
}
