import Foundation

class PatroUpdateManager: ObservableObject {
    static let shared = PatroUpdateManager()
    
    private let fileManager = FileManager.default
    private let githubCalendarDataURL = URL(string: "https://raw.githubusercontent.com/yogeshojha/patro/master/CalendarData.js")!
    private let githubObservancesURL = URL(string: "https://raw.githubusercontent.com/yogeshojha/patro/master/Observances.js")!
    
    @Published var isChecking: Bool = false
    @Published var statusMessage: String = ""
    @Published var statusType: StatusType = .info
    @Published var publishedThrough: Int = 2083
    @Published var lastCheckedDateText: String = "अहिलेसम्म जाँचिएको छैन"
    
    enum StatusType {
        case info
        case success
        case error
    }
    
    var appSupportDir: URL {
        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let dir = paths[0].appendingPathComponent("Patro", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    var localCalendarDataURL: URL {
        appSupportDir.appendingPathComponent("CalendarData.js")
    }
    
    var localObservancesURL: URL {
        appSupportDir.appendingPathComponent("Observances.js")
    }
    
    private var metadataURL: URL {
        appSupportDir.appendingPathComponent("metadata.json")
    }
    
    init() {
        loadMetadata()
        detectCurrentPublishedThrough()
    }
    
    func detectCurrentPublishedThrough() {
        var content = ""
        if fileManager.fileExists(atPath: localCalendarDataURL.path),
           let saved = try? String(contentsOf: localCalendarDataURL, encoding: .utf8) {
            content = saved
        } else {
            content = PatroCoreJS.code
        }
        
        if let match = content.range(of: "PUBLISHED_THROUGH\\s*=\\s*(\\d+)", options: .regularExpression) {
            let matchedStr = String(content[match])
            let digits = matchedStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
            if let year = Int(digits) {
                self.publishedThrough = year
            }
        }
    }
    
    func getCustomCalendarData() -> String? {
        if fileManager.fileExists(atPath: localCalendarDataURL.path),
           let content = try? String(contentsOf: localCalendarDataURL, encoding: .utf8) {
            return cleanScript(content)
        }
        return nil
    }
    
    func getCustomObservances() -> String? {
        if fileManager.fileExists(atPath: localObservancesURL.path),
           let content = try? String(contentsOf: localObservancesURL, encoding: .utf8) {
            return cleanScript(content)
        }
        return nil
    }
    
    private func cleanScript(_ raw: String) -> String {
        return raw.components(separatedBy: "\n").map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix(".pragma") || trimmed.hasPrefix(".import") {
                return ""
            }
            return line
        }.joined(separator: "\n")
    }
    
    func checkForUpdates(manual: Bool = false) {
        guard !isChecking else { return }
        isChecking = true
        statusMessage = "GitHub बाट नयाँ डेटा जाँच गरिँदैछ..."
        statusType = .info
        
        var request = URLRequest(url: githubCalendarDataURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isChecking = false
                    self.statusType = .error
                    self.statusMessage = "इन्टरनेट त्रुटि: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data,
                  let text = String(data: data, encoding: .utf8),
                  text.contains("MONTH_LENGTHS") else {
                DispatchQueue.main.async {
                    self.isChecking = false
                    self.statusType = .error
                    self.statusMessage = "GitHub बाट अवैध क्यालेन्डर डेटा प्राप्त भयो।"
                }
                return
            }
            
            // Extract remote published through year
            var remoteYear = self.publishedThrough
            if let match = text.range(of: "PUBLISHED_THROUGH\\s*=\\s*(\\d+)", options: .regularExpression) {
                let matchedStr = String(text[match])
                let digits = matchedStr.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                if let y = Int(digits) {
                    remoteYear = y
                }
            }
            
            // Also fetch Observances.js in parallel
            self.fetchObservances { [weak self] in
                guard let self = self else { return }
                
                // Save CalendarData.js
                try? text.write(to: self.localCalendarDataURL, atomically: true, encoding: .utf8)
                
                DispatchQueue.main.async {
                    self.isChecking = false
                    let previousYear = self.publishedThrough
                    self.publishedThrough = remoteYear
                    self.saveMetadata()
                    
                    // Reload PatroEngine
                    PatroEngine.shared.reloadEngine()
                    
                    if remoteYear > previousYear {
                        self.statusType = .success
                        self.statusMessage = "🎉 नयाँ वर्ष \(remoteYear) को आधिकारिक डेटा सफलतापूर्वक अपडेट भयो!"
                    } else {
                        self.statusType = .success
                        self.statusMessage = "तपाईँको क्यालेन्डर डेटा पहिले नै नवीनतम (Latest: \(remoteYear) सम्म) छ।"
                    }
                }
            }
        }.resume()
    }
    
    private func fetchObservances(completion: @escaping () -> Void) {
        var request = URLRequest(url: githubObservancesURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self else { completion(); return }
            if let data = data, let text = String(data: data, encoding: .utf8), text.contains("FIXED_BIKRAM") {
                try? text.write(to: self.localObservancesURL, atomically: true, encoding: .utf8)
            }
            completion()
        }.resume()
    }
    
    func syncFromLocalRepo(repoPath: String) {
        let calPath = "\(repoPath)/CalendarData.js"
        let obsPath = "\(repoPath)/Observances.js"
        
        guard fileManager.fileExists(atPath: calPath) else {
            statusType = .error
            statusMessage = "उक्त फोल्डरमा CalendarData.js भेटिएन: \(repoPath)"
            return
        }
        
        if let calText = try? String(contentsOfFile: calPath, encoding: .utf8) {
            try? calText.write(to: localCalendarDataURL, atomically: true, encoding: .utf8)
        }
        if let obsText = try? String(contentsOfFile: obsPath, encoding: .utf8) {
            try? obsText.write(to: localObservancesURL, atomically: true, encoding: .utf8)
        }
        
        detectCurrentPublishedThrough()
        saveMetadata()
        PatroEngine.shared.reloadEngine()
        
        statusType = .success
        statusMessage = "स्थानीय फोल्डरबाट सफलतापूर्वक डेटा सिङ्क भयो (प्रमाणित: \(publishedThrough) सम्म)!"
    }
    
    private func saveMetadata() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        lastCheckedDateText = formatter.string(from: Date())
        
        let meta: [String: Any] = [
            "lastChecked": lastCheckedDateText,
            "publishedThrough": publishedThrough
        ]
        if let data = try? JSONSerialization.data(withJSONObject: meta) {
            try? data.write(to: metadataURL)
        }
    }
    
    private func loadMetadata() {
        if let data = try? Data(contentsOf: metadataURL),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let date = json["lastChecked"] as? String {
                lastCheckedDateText = date
            }
            if let year = json["publishedThrough"] as? Int {
                publishedThrough = year
            }
        }
    }
}
