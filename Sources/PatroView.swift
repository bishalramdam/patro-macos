import SwiftUI
import AppKit

struct PatroView: View {
    @ObservedObject var engine = PatroEngine.shared
    @State private var selectedTab: Int = 0 // 0: Calendar, 1: Converter, 2: Settings
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Tab Header
            HStack(spacing: 12) {
                TabButton(title: "पात्रो", icon: "calendar", isSelected: selectedTab == 0) {
                    selectedTab = 0
                }
                TabButton(title: "रूपान्तरक", icon: "arrow.left.arrow.right", isSelected: selectedTab == 1) {
                    selectedTab = 1
                }
                TabButton(title: "सेटिङ", icon: "gearshape", isSelected: selectedTab == 2) {
                    selectedTab = 2
                }
                
                Spacer()
                
                // Quit button
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(6)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("पात्रो बन्द गर्नुहोस् (Quit Patro)")
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 8)
            
            Divider()
                .opacity(0.5)
            
            // Content Body based on selected Tab
            Group {
                if selectedTab == 0 {
                    CalendarTabView(engine: engine, onOpenConverter: {
                        selectedTab = 1
                    })
                } else if selectedTab == 1 {
                    ConverterTabView(engine: engine, onSelectDate: { y, m, d in
                        engine.viewYear = y
                        engine.viewMonth = m
                        engine.refreshMonth()
                        engine.selectDayNumber(d)
                        selectedTab = 0
                    })
                } else {
                    SettingsTabView(engine: engine)
                }
            }
            .frame(width: 350)
        }
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
        .frame(width: 350)
    }
}

// Visual Effect View for native macOS frosted glass
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

// Tab button component
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 9)
            .background(isSelected ? Color.accentColor.opacity(0.18) : Color.clear)
            .foregroundColor(isSelected ? .accentColor : .primary.opacity(0.75))
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Calendar Tab View
struct CalendarTabView: View {
    @ObservedObject var engine: PatroEngine
    var onOpenConverter: () -> Void
    @State private var copied: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Month navigation bar
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.currentMonth?.title ?? "")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(engine.currentMonth?.gregorianSpan ?? "")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 4) {
                    Button(action: { engine.previousYear() }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("अघिल्लो वर्ष (Previous Year)")
                    
                    Button(action: { engine.previousMonth() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("अघिल्लो महिना (Previous Month)")
                    
                    Button(action: { engine.goToToday() }) {
                        Text("आज")
                            .font(.system(size: 11, weight: .semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(engine.isViewingToday() ? Color.accentColor : Color.secondary.opacity(0.15))
                            .foregroundColor(engine.isViewingToday() ? .white : .primary)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("आजको मितिमा जानुहोस् (Today)")
                    
                    Button(action: { engine.nextMonth() }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("पछिल्लो महिना (Next Month)")
                    
                    Button(action: { engine.nextYear() }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("पछिल्लो वर्ष (Next Year)")
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)
            
            // Weekday Header (आइत, सोम, मङ्गल ...)
            if let month = engine.currentMonth {
                HStack(spacing: 0) {
                    ForEach(month.weekdays) { wd in
                        Text(wd.name)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(wd.isSaturday ? Color.red.opacity(0.9) : Color.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 4)
                
                // Clean Calendar Days Grid
                VStack(spacing: 3) {
                    ForEach(0..<month.weeks.count, id: \.self) { weekIndex in
                        let week = month.weeks[weekIndex]
                        HStack(spacing: 3) {
                            ForEach(0..<week.count, id: \.self) { dayIndex in
                                if let cell = week[dayIndex] {
                                    DayCellView(
                                        cell: cell,
                                        isToday: isTodayCell(cell),
                                        isSelected: engine.selectedDay?.day == cell.day,
                                        showGregorian: engine.showGregorianInGrid
                                    )
                                    .onTapGesture {
                                        engine.selectedDay = cell
                                    }
                                } else {
                                    // Empty padding cell
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(maxWidth: .infinity, minHeight: 36)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
            }
            
            Divider()
                .padding(.vertical, 4)
            
            // Clean Selected Day Details Card
            let currentDay = engine.selectedDay
            let activeDay = currentDay?.dayText ?? (engine.todayInfo?.dayText ?? "१७")
            let activeWeekday = currentDay?.weekdayName ?? (engine.todayInfo?.weekdayName ?? "मङ्गलबार")
            let activeObservance = currentDay?.observanceSummary ?? (engine.todayInfo?.observances ?? "")
            let isSatOrHol = (currentDay?.isSaturday ?? false) || (currentDay?.isHoliday ?? false)
            let gregDay = currentDay?.gregorian.day ?? (engine.todayInfo?.gregorian.day ?? 3)
            let gregMonth = currentDay?.gregorian.month ?? (engine.todayInfo?.gregorian.month ?? 11)
            let gregYear = currentDay?.gregorian.year ?? (engine.todayInfo?.gregorian.year ?? 2026)
            let gMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            let gName = gMonthNames[max(0, min(11, gregMonth - 1))]
            
            HStack(alignment: .center, spacing: 12) {
                // Big Day number
                VStack(spacing: 1) {
                    Text(activeDay)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isSatOrHol ? Color.red : Color.accentColor)
                    Text(activeWeekday)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .frame(width: 48)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(activeDay) \(engine.currentMonth?.title ?? "")")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("\(gregDay) \(gName) \(gregYear) AD (\(activeWeekday))")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                    
                    if !activeObservance.isEmpty {
                        Text(activeObservance)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isSatOrHol ? Color.red : Color.primary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // Copy Date Button
                Button(action: {
                    copyDateInfo(
                        dayText: activeDay,
                        weekday: activeWeekday,
                        gregDay: gregDay,
                        gregMonth: gregMonth,
                        gregYear: gregYear,
                        observance: activeObservance
                    )
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11))
                        Text(copied ? "Copied" : "Copy")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(copied ? Color.green.opacity(0.18) : Color.secondary.opacity(0.12))
                    .foregroundColor(copied ? .green : .primary)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("मिति क्लिपबोर्डमा कपी गर्नुहोस्")
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
        }
    }
    
    private func isTodayCell(_ cell: DayCellData) -> Bool {
        guard let today = engine.todayInfo else { return false }
        return cell.year == today.year && cell.month == today.month && cell.day == today.day
    }
    
    private func copyDateInfo(dayText: String, weekday: String, gregDay: Int, gregMonth: Int, gregYear: Int, observance: String) {
        let gMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let gName = gMonthNames[max(0, min(11, gregMonth - 1))]
        var text = "\(dayText) \(engine.currentMonth?.title ?? ""), \(weekday) (\(gregDay) \(gName) \(gregYear))"
        if !observance.isEmpty {
            text += " - \(observance)"
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        withAnimation {
            copied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                copied = false
            }
        }
    }
}

// Clean Minimal Day Cell View (No Tithi text, No Moon Icons)
struct DayCellView: View {
    let cell: DayCellData
    let isToday: Bool
    let isSelected: Bool
    let showGregorian: Bool
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        VStack(spacing: 1) {
            // Bikram Day number
            Text(cell.dayText)
                .font(.system(size: 13, weight: isSelected || isToday ? .bold : .medium))
                .foregroundColor(cell.isSaturday || cell.isHoliday ? Color.red : Color.primary)
            
            // Clean Gregorian day number
            if showGregorian {
                Text(cell.gregorianDayText)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(Color.secondary.opacity(0.75))
            }
        }
        .frame(maxWidth: .infinity, minHeight: showGregorian ? 36 : 28)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.accentColor.opacity(0.2) :
                      isToday ? Color.accentColor.opacity(0.12) :
                      isHovered ? Color.secondary.opacity(0.08) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.accentColor :
                        isToday ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Converter Tab View
struct ConverterTabView: View {
    @ObservedObject var engine: PatroEngine
    var onSelectDate: (Int, Int, Int) -> Void
    
    @State private var bsInput: String = ""
    @State private var adInput: String = ""
    @State private var conversionResult: ConversionResult?
    @State private var activeMode: String = "BS" // "BS" or "AD"
    
    var body: some View {
        VStack(spacing: 12) {
            Text("वि.सं. ↔ ई.सं. मिति रूपान्तरक")
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 10)
            
            // Mode selector
            Picker("", selection: $activeMode) {
                Text("वि.सं. बाट ई.सं. (BS ➔ AD)").tag("BS")
                Text("ई.सं. बाट वि.सं. (AD ➔ BS)").tag("AD")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal, 14)
            .onChange(of: activeMode) { _ in
                runConversion()
            }
            
            // Input Fields
            VStack(alignment: .leading, spacing: 6) {
                if activeMode == "BS" {
                    Text("विक्रम संवत् मिति लेख्नुहोस् (YYYY-MM-DD):")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("उदा: २०८३-०७-१७ वा 2083/7/17", text: $bsInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 13))
                            .onChange(of: bsInput) { _ in
                                runConversion()
                            }
                        
                        Button("आज") {
                            if let today = engine.todayInfo {
                                bsInput = "\(today.year)-\(String(format: "%02d", today.month))-\(String(format: "%02d", today.day))"
                                runConversion()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(5)
                    }
                } else {
                    Text("Gregorian (AD) Date (YYYY-MM-DD):")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("e.g. 2026-11-03", text: $adInput)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 13))
                            .onChange(of: adInput) { _ in
                                runConversion()
                            }
                        
                        Button("Today") {
                            if let today = engine.todayInfo {
                                adInput = "\(today.gregorian.year)-\(String(format: "%02d", today.gregorian.month))-\(String(format: "%02d", today.gregorian.day))"
                                runConversion()
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(5)
                    }
                }
            }
            .padding(.horizontal, 14)
            
            // Clean Result Card (No Tithi)
            if let res = conversionResult, res.valid {
                VStack(spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("विक्रम संवत् (BS):")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(res.bsFormattedDev ?? (res.bsFormatted ?? ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.accentColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 3) {
                            Text("इस्वी संवत् (AD):")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Text(res.gregFormatted ?? "")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Divider()
                    
                    HStack {
                        Text(res.weekdayName ?? "")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        if let obs = res.observance, !obs.isEmpty {
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(obs)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                    }
                    
                    // Jump to calendar button
                    Button(action: {
                        if let y = res.year, let m = res.month, let d = res.day {
                            onSelectDate(y, m, d)
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                            Text("पात्रोमा हेर्नुहोस् (Open in Calendar)")
                        }
                        .font(.system(size: 11, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(12)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
                .padding(.horizontal, 14)
            } else if let res = conversionResult, let err = res.error, !err.isEmpty {
                Text(err)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 14)
            }
            
            Spacer().frame(height: 10)
        }
        .onAppear {
            if let today = engine.todayInfo {
                bsInput = "\(today.year)-\(String(format: "%02d", today.month))-\(String(format: "%02d", today.day))"
                adInput = "\(today.gregorian.year)-\(String(format: "%02d", today.gregorian.month))-\(String(format: "%02d", today.gregorian.day))"
                runConversion()
            }
        }
    }
    
    private func runConversion() {
        if activeMode == "BS" {
            conversionResult = engine.convertDate(input: bsInput)
        } else {
            conversionResult = engine.convertDate(input: adInput)
        }
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var engine: PatroEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("सेटिङ तथा प्राथमिकताहरू")
                .font(.system(size: 14, weight: .bold))
                .padding(.top, 10)
            
            // Menu bar label format
            VStack(alignment: .leading, spacing: 5) {
                Text("मेनु बार फर्म्याट (Menu Bar Format):")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $engine.barFormat) {
                    Text("वर्षसहित (१७ कात्तिक २०८३)").tag("Year")
                    Text("विस्तृत (मङ्गलबार, १७ कात्तिक २०८३)").tag("Full")
                    Text("अंग्रेजी मितिसहित (१७ कात्तिक २०८३, 3 Nov)").tag("WithGregorian")
                    Text("अङ्क मात्र (२०८३-०७-१७)").tag("Numeric")
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            // Numerals Style
            VStack(alignment: .leading, spacing: 5) {
                Text("अङ्कको लिपि (Numerals):")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $engine.numerals) {
                    Text("देवनागरी (०१२३४५६७८९)").tag("Devanagari")
                    Text("ल्याटिन (0123456789)").tag("Latin")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Language
            VStack(alignment: .leading, spacing: 5) {
                Text("भाषा (Language):")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Picker("", selection: $engine.language) {
                    Text("नेपाली (Nepali)").tag("Nepali")
                    Text("English").tag("English")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            // Grid Toggles
            Toggle("क्यालेन्डर कोठामा अंग्रेजी मिति देखाउने (AD in Grid)", isOn: $engine.showGregorianInGrid)
                .font(.system(size: 12))
            
            Divider()
            
            // Auto-Update & GitHub Sync Section
            CalendarSyncSection()
            
            Divider()
            
            // About App
            VStack(alignment: .leading, spacing: 3) {
                Text("Patro for macOS")
                    .font(.system(size: 12, weight: .bold))
                Text("Bikram Sambat 2000–2090 BS (Clean Date Calendar)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer().frame(height: 8)
        }
        .padding(.horizontal, 14)
    }
}

// Calendar Sync & GitHub Auto-Update Section
struct CalendarSyncSection: View {
    @ObservedObject var updater = PatroUpdateManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("पात्रो डेटा तथा अद्यावधिक (Calendar Sync)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("प्रमाणित: \(updater.publishedThrough) सम्म")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(4)
            }
            
            Text("GitHub को yogeshojha/patro मा नयाँ वर्षको डेटा अपडेट हुनासाथ एप पुनः रिबिल्ड नगरी यहाँबाट सिधै अपडेट गर्न सकिन्छ:")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // Buttons
            HStack(spacing: 8) {
                // Online GitHub Update Button
                Button(action: {
                    updater.checkForUpdates(manual: true)
                }) {
                    HStack(spacing: 4) {
                        if updater.isChecking {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 10))
                        }
                        Text(updater.isChecking ? "जाँचिँदैछ..." : "GitHub बाट अपडेट गर्नुहोस्")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(updater.isChecking)
                
                // Local Repo Sync Button
                Button(action: {
                    let localRepo = "/Users/bishal/Documents/antigravity/lucid-pasteur/patro"
                    updater.syncFromLocalRepo(repoPath: localRepo)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                        Text("स्थानीय फोल्डरबाट")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundColor(.primary)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("स्थानीय patro/ फोल्डरबाट नयाँ फाइल सिङ्क गर्नुहोस्")
            }
            .padding(.top, 2)
            
            // Status Message Display
            if !updater.statusMessage.isEmpty {
                HStack(alignment: .top, spacing: 5) {
                    Image(systemName: updater.statusType == .success ? "checkmark.circle.fill" :
                                      updater.statusType == .error ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(updater.statusType == .success ? .green :
                                        updater.statusType == .error ? .red : .blue)
                        .padding(.top, 1)
                    
                    Text(updater.statusMessage)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(updater.statusType == .success ? .green :
                                        updater.statusType == .error ? .red : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 3)
            }
        }
    }
}
