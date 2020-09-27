//
//  LogFileViewer.swift
//  Project SITNU
//
//  Created by Nils Bergmann on 27/09/2020.
//

import SwiftUI

struct LogFileViewer: View {
    var logFile: LogFile;
    
    var streamReader: StreamReader?;
    
    @State var lines: [Line] = [];
    @State var loaded: Bool = false;
    @State var showShareSheet = false
    
    init(_ logFile: LogFile) {
        self.streamReader = StreamReader(path: logFile.url.path);
        self.logFile = logFile;
    }
    
    var body: some View {
        ScrollView {
            LazyStackPolyfill {
                ForEach(lines, id: \.nr) { (line) in
                    VStack {
                        HStack {
                            NavigationLink(destination: LineView(line: line)) {
                                Text(line.line)
                                    .font(.system(size: 12, design: .monospaced))
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        Divider()
                    }
                }
            }
        }
        .navigationBarTitle(logFile.name)
        .navigationBarItems(trailing: Button(action: {
            self.showShareSheet.toggle();
        }, label: {
            Image(systemName: "square.and.arrow.up")
        }))
        .onAppear() {
            if !self.loaded {
                self.loadLines()
            } else {
                log.debug("Already loaded")
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: [logFile.url])
        }
    }
    
    func loadLines() {
        self.loaded = true;
        log.debug("Load lines for log", context: ["path": logFile.url.path])
        guard let streamReader = self.streamReader else {
            log.error("Missing stream reader")
            return;
        }
        streamReader.rewind();
        for (index, line) in streamReader.enumerated() {
            withAnimation {
                self.lines.append(Line(nr: index, line: line))
            }
        }
    }
    
    struct Line: Identifiable {
        var id: Int { nr }
        var nr: Int;
        var line: String;
    }
}

struct LineView: View {
    var line: LogFileViewer.Line;
    
    var body: some View {
        ScrollView {
            VStack {
                Text(line.line)
                    .font(.system(size: 16, design: .monospaced))
                Spacer()
            }
        }
        .navigationBarTitle("Line: \(line.nr)")
    }
}

class StreamReader  {

    let encoding : String.Encoding
    let chunkSize : Int
    var fileHandle : FileHandle!
    let delimData : Data
    var buffer : Data
    var atEof : Bool

    init?(path: String, delimiter: String = "\n", encoding: String.Encoding = .utf8,
          chunkSize: Int = 4096) {

        guard let fileHandle = FileHandle(forReadingAtPath: path),
            let delimData = delimiter.data(using: encoding) else {
                return nil
        }
        self.encoding = encoding
        self.chunkSize = chunkSize
        self.fileHandle = fileHandle
        self.delimData = delimData
        self.buffer = Data(capacity: chunkSize)
        self.atEof = false
    }

    deinit {
        self.close()
    }

    /// Return next line, or nil on EOF.
    func nextLine() -> String? {
        precondition(fileHandle != nil, "Attempt to read from closed file")

        // Read data chunks from file until a line delimiter is found:
        while !atEof {
            if let range = buffer.range(of: delimData) {
                // Convert complete line (excluding the delimiter) to a string:
                let line = String(data: buffer.subdata(in: 0..<range.lowerBound), encoding: encoding)
                // Remove line (and the delimiter) from the buffer:
                buffer.removeSubrange(0..<range.upperBound)
                return line
            }
            let tmpData = fileHandle.readData(ofLength: chunkSize)
            if tmpData.count > 0 {
                buffer.append(tmpData)
            } else {
                // EOF or read error.
                atEof = true
                if buffer.count > 0 {
                    // Buffer contains last line in file (not terminated by delimiter).
                    let line = String(data: buffer as Data, encoding: encoding)
                    buffer.count = 0
                    return line
                }
            }
        }
        return nil
    }

    /// Start reading from the beginning of file.
    func rewind() -> Void {
        fileHandle.seek(toFileOffset: 0)
        buffer.count = 0
        atEof = false
    }

    /// Close the underlying file. No reading must be done after calling this method.
    func close() -> Void {
        fileHandle?.closeFile()
        fileHandle = nil
    }
}

extension StreamReader : Sequence {
    func makeIterator() -> AnyIterator<String> {
        return AnyIterator {
            return self.nextLine()
        }
    }
}

//protocol TextList: ObservableObject, RandomAccessCollection where Index == Int, Element: IdentifiableElement {}
//
//protocol IdentifiableElement: Identifiable where ID == Int {}
//
//class TextArray: TextList {
//
//    init(_ url: URL) {
//        let fm = FileManager.default;
//        guard let filePointer:UnsafeMutablePointer<FILE> = fopen(url.path, "r") else {
//            preconditionFailure("Could not open file at \(url.absoluteString)")
//        }
//
//        // a pointer to a null-terminated, UTF-8 encoded sequence of bytes
//        var lineByteArrayPointer: UnsafeMutablePointer<CChar>? = nil
//
//        // the smallest multiple of 16 that will fit the byte array for this line
//        var lineCap: Int = 0
//
//        // initial iteration
//        var bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
//
//        defer {
//            // remember to close the file when done
//            fclose(filePointer)
//        }
//
//        while (bytesRead > 0) {
//
//            // note: this translates the sequence of bytes to a string using UTF-8 interpretation
//            let lineAsString = String.init(cString:lineByteArrayPointer!)
//
//            // do whatever you need to do with this single line of text
//            // for debugging, can print it
//            print(lineAsString)
//
//            // updates number of bytes read, for the next iteration
//            bytesRead = getline(&lineByteArrayPointer, &lineCap, filePointer)
//        }
//    }
//
//    subscript(position: Int) -> Slice<TextArray> {
//        _read {
//            <#code#>
//        }
//    }
//
//    var startIndex: Int = 0;
//
//    var endIndex: Int;
//}

