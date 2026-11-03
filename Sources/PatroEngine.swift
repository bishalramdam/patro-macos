import Foundation
import JavaScriptCore

struct BikramDate: Codable, Equatable, Hashable {
    var year: Int
    var month: Int
    var day: Int
}

struct GregorianDate: Codable, Equatable, Hashable {
    var year: Int
    var month: Int
    var day: Int
}

struct TodayInfo: Codable {
    var year: Int
    var month: Int
    var day: Int
    var yearText: String
    var monthName: String
    var dayText: String
    var weekday: Int
    var weekdayName: String
    var weekdayShort: String
    var gregorian: GregorianDate
    var cleanYearLabel: String
    var cleanWithTithi: String
    var fullLabel: String
    var compactLabel: String
    var numericLabel: String
    var tithi: Int
    var tithiName: String
    var tithiLabel: String
    var paksha: String
    var isEkadashi: Bool
    var isPurnima: Bool
    var isAunsi: Bool
    var observances: String
    
    var bs: BikramDate {
        BikramDate(year: year, month: month, day: day)
    }
}

struct DayCellData: Codable, Identifiable, Equatable, Hashable {
    var id: String { "\(year)-\(month)-\(day)" }
    var year: Int
    var month: Int
    var day: Int
    var dayText: String
    var weekday: Int
    var weekdayName: String
    var gregorian: GregorianDate
    var gregorianDayText: String
    var tithi: Int
    var tithiName: String
    var tithiLabel: String
    var paksha: String
    var isEkadashi: Bool
    var isPurnima: Bool
    var isAunsi: Bool
    var isHoliday: Bool
    var isSaturday: Bool
    var hasMark: Bool
    var observanceSummary: String
}

struct WeekdayHeader: Codable, Identifiable, Equatable {
    var id: Int { index }
    var index: Int
    var name: String
    var isSaturday: Bool
}

struct MonthData: Codable {
    var year: Int
    var month: Int
    var title: String
    var gregorianSpan: String
    var confidence: String
    var provisionalNotice: String
    var weekdays: [WeekdayHeader]
    var weeks: [[DayCellData?]]
}

struct ConversionResult: Codable {
    var valid: Bool
    var sourceType: String?
    var year: Int?
    var month: Int?
    var day: Int?
    var bsFormatted: String?
    var bsFormattedDev: String?
    var gregFormatted: String?
    var weekdayName: String?
    var tithiLabel: String?
    var observance: String?
    var error: String?
}

class PatroEngine: ObservableObject {
    static let shared = PatroEngine()
    
    private var ctx = JSContext()!
    private let decoder = JSONDecoder()
    
    @Published var todayInfo: TodayInfo?
    @Published var currentMonth: MonthData?
    @Published var viewYear: Int = 2083
    @Published var viewMonth: Int = 7
    @Published var selectedDay: DayCellData?
    
    // User preferences:
    @Published var barFormat: String = "Year" {
        didSet { refreshToday() }
    }
    @Published var language: String = "Nepali" {
        didSet { refreshMonth() }
    }
    @Published var numerals: String = "Devanagari" {
        didSet { refreshMonth() }
    }
    @Published var showGregorianInGrid: Bool = true
    @Published var showTithiInGrid: Bool = true
    
    init() {
        setupContext()
        executeRefreshToday()
        if let today = todayInfo {
            viewYear = today.year
            viewMonth = today.month
        }
        executeRefreshMonth()
        selectToday()
    }
    
    func reloadEngine() {
        setupContext()
        executeRefreshToday()
        executeRefreshMonth()
        selectToday()
    }
    
    private func setupContext() {
        ctx = JSContext()!
        ctx.exceptionHandler = { _, exception in
            print("[PatroEngine JS Error]:", exception?.toString() ?? "unknown")
        }
        
        // Evaluate base script
        ctx.evaluateScript(PatroCoreJS.code)
        
        // If an updated CalendarData.js was downloaded / synced, override Data & Bikram
        if let customCalendar = PatroUpdateManager.shared.getCustomCalendarData() {
            let overrideDataScript = """
            (function() {
                \(customCalendar)
                Data.MONTH_LENGTHS = MONTH_LENGTHS;
                Data.FIRST_YEAR = FIRST_YEAR;
                Data.LAST_YEAR = LAST_YEAR;
                Data.ANCHOR_AD = ANCHOR_AD;
                Data.ATTESTED_THROUGH = ATTESTED_THROUGH;
                Data.PUBLISHED_THROUGH = PUBLISHED_THROUGH;
                
                // Recompute YEAR_OFFSETS in Bikram module
                var offsets = [];
                var total = 0;
                for (var i = 0; i < Data.MONTH_LENGTHS.length; i++) {
                    offsets.push(total);
                    for (var m = 0; m < 12; m++) total += Data.MONTH_LENGTHS[i][m];
                }
                offsets.push(total);
                YEAR_OFFSETS = offsets;
                TOTAL_DAYS = YEAR_OFFSETS[YEAR_OFFSETS.length - 1];
            })();
            """
            ctx.evaluateScript(overrideDataScript)
        }
        
        // If an updated Observances.js was downloaded / synced, override Observances
        if let customObs = PatroUpdateManager.shared.getCustomObservances() {
            let overrideObsScript = """
            (function() {
                \(customObs)
                Observances.forDate = forDate;
                Observances.isHoliday = isHoliday;
                Observances.named = named;
                Observances.summary = summary;
                Observances.forMonth = forMonth;
            })();
            """
            ctx.evaluateScript(overrideObsScript)
        }
    }
    
    func refreshToday() {
        executeRefreshToday()
    }
    
    private func executeRefreshToday() {
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000)
        let script = "JSON.stringify(PatroApp.getToday(\(nowMs), '\(language)', '\(numerals)'))"
        if let jsonStr = ctx.evaluateScript(script)?.toString(),
           let data = jsonStr.data(using: .utf8),
           let info = try? decoder.decode(TodayInfo.self, from: data) {
            self.todayInfo = info
        }
    }
    
    func refreshMonth() {
        executeRefreshMonth()
    }
    
    private func executeRefreshMonth() {
        let script = "JSON.stringify(PatroApp.getMonthData(\(viewYear), \(viewMonth), '\(language)', '\(numerals)', 0))"
        if let jsonStr = ctx.evaluateScript(script)?.toString(),
           let data = jsonStr.data(using: .utf8),
           let month = try? decoder.decode(MonthData.self, from: data) {
            self.currentMonth = month
            
            if let selected = self.selectedDay, selected.year == self.viewYear && selected.month == self.viewMonth {
                self.selectDayNumber(selected.day)
            } else if self.isViewingToday() {
                self.selectToday()
            } else {
                self.selectDayNumber(1)
            }
        }
    }
    
    func goToToday() {
        executeRefreshToday()
        if let today = todayInfo {
            viewYear = today.year
            viewMonth = today.month
            executeRefreshMonth()
            selectToday()
        }
    }
    
    func isViewingToday() -> Bool {
        guard let today = todayInfo else { return false }
        return viewYear == today.year && viewMonth == today.month
    }
    
    func selectToday() {
        guard let today = todayInfo else { return }
        selectDayNumber(today.day)
    }
    
    func selectDayNumber(_ day: Int) {
        guard let month = currentMonth else { return }
        for week in month.weeks {
            for cell in week {
                if let c = cell, c.day == day {
                    selectedDay = c
                    return
                }
            }
        }
    }
    
    func previousMonth() {
        let script = "JSON.stringify(Bikram.addMonths(\(viewYear), \(viewMonth), -1))"
        if let jsonStr = ctx.evaluateScript(script)?.toString(),
           let data = jsonStr.data(using: .utf8),
           let next = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
           let y = next["year"], let m = next["month"] {
            viewYear = y
            viewMonth = m
            refreshMonth()
        }
    }
    
    func nextMonth() {
        let script = "JSON.stringify(Bikram.addMonths(\(viewYear), \(viewMonth), 1))"
        if let jsonStr = ctx.evaluateScript(script)?.toString(),
           let data = jsonStr.data(using: .utf8),
           let next = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
           let y = next["year"], let m = next["month"] {
            viewYear = y
            viewMonth = m
            refreshMonth()
        }
    }
    
    func previousYear() {
        let script = "JSON.stringify(Bikram.addMonths(\(viewYear), \(viewMonth), -12))"
        if let jsonStr = ctx.evaluateScript(script)?.toString(),
           let data = jsonStr.data(using: .utf8),
           let next = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
           let y = next["year"], let m = next["month"] {
            viewYear = y
            viewMonth = m
            refreshMonth()
        }
    }
    
    func nextYear() {
        let script = "JSON.stringify(Bikram.addMonths(\(viewYear), \(viewMonth), 12))"
        if let jsonStr = ctx.evaluateScript(script)?.toString(),
           let data = jsonStr.data(using: .utf8),
           let next = try? JSONSerialization.jsonObject(with: data) as? [String: Int],
           let y = next["year"], let m = next["month"] {
            viewYear = y
            viewMonth = m
            refreshMonth()
        }
    }
    
    func convertDate(input: String) -> ConversionResult {
        let sanitized = input.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "'", with: "\\'")
        let script = "JSON.stringify(PatroApp.convertDate('\(sanitized)'))"
        guard let jsonStr = ctx.evaluateScript(script)?.toString(),
              let data = jsonStr.data(using: .utf8),
              let result = try? decoder.decode(ConversionResult.self, from: data) else {
            return ConversionResult(valid: false, error: "Calculation failed")
        }
        return result
    }
    
    func menuBarTitle() -> String {
        guard let today = todayInfo else { return "१७ कात्तिक २०८३" }
        switch barFormat {
        case "Year": // Default clean format: "१७ कात्तिक २०८३"
            return today.cleanYearLabel
        case "Full": // "मङ्गलबार, १७ कात्तिक २०८३"
            return today.fullLabel
        case "Numeric": // "२०८३-०७-१७"
            return today.numericLabel
        case "WithGregorian":
            let gregMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            let gName = gregMonthNames[max(0, min(11, today.gregorian.month - 1))]
            return "\(today.cleanYearLabel) (\(today.gregorian.day) \(gName))"
        default:
            return today.cleanYearLabel
        }
    }
}
