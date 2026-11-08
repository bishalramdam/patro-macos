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

// Dropdown picker kind
enum ActiveDropdown: Equatable {
    case year, month, day
}

struct DropdownItem: Identifiable, Equatable {
    let id: Int
    let title: String
}

// Capsule Toggle for BS / AD with fixed geometry (prevents line-breaks and layout shifts)
struct ModeCapsuleToggle: View {
    @Binding var pickerMode: String // "BS" or "AD"
    var isEnglish: Bool = false
    var onChange: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                if pickerMode != "BS" {
                    pickerMode = "BS"
                    onChange?()
                }
            }) {
                Text(isEnglish ? "BS" : "वि.सं.")
                    .font(.system(size: 11, weight: pickerMode == "BS" ? .bold : .medium))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundColor(pickerMode == "BS" ? .white : .secondary)
                    .frame(width: 42, height: 22)
                    .background(pickerMode == "BS" ? Color.accentColor : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
            .help(isEnglish ? "Bikram Sambat (BS)" : "विक्रम संवत् (BS)")
            
            Button(action: {
                if pickerMode != "AD" {
                    pickerMode = "AD"
                    onChange?()
                }
            }) {
                Text(isEnglish ? "AD" : "ई.सं.")
                    .font(.system(size: 11, weight: pickerMode == "AD" ? .bold : .medium))
                    .lineLimit(1)
                    .fixedSize()
                    .foregroundColor(pickerMode == "AD" ? .white : .secondary)
                    .frame(width: 42, height: 22)
                    .background(pickerMode == "AD" ? Color.accentColor : Color.clear)
                    .cornerRadius(4)
            }
            .buttonStyle(PlainButtonStyle())
            .help(isEnglish ? "Gregorian (AD)" : "इस्वी संवत् (AD)")
        }
        .padding(2)
        .frame(width: 88, height: 26)
        .background(Color.secondary.opacity(0.12))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.12), lineWidth: 0.5)
        )
    }
}

// Scrollable Dropdown Menu (normal web-like scrolling with smooth trackpad / mouse wheel)
struct ScrollableDropdownMenu: View {
    let items: [DropdownItem]
    let selectedId: Int
    let width: CGFloat
    var visibleRows: Int = 10
    let onSelect: (Int) -> Void
    
    // Explicit height to fit ~10 rows (approx 236pt)
    private var menuHeight: CGFloat {
        let rowHeight: CGFloat = 23
        let contentHeight = CGFloat(items.count) * rowHeight + 6
        let maxAllowed = CGFloat(visibleRows) * rowHeight + 6
        return min(contentHeight, maxAllowed)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 1) {
                    ForEach(items) { item in
                        let isSelected = item.id == selectedId
                        DropdownRow(
                            title: item.title,
                            isSelected: isSelected,
                            onSelect: {
                                onSelect(item.id)
                            }
                        )
                        .id(item.id)
                    }
                }
                .padding(3)
            }
            .frame(width: width, height: menuHeight)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.4), radius: 10, x: 0, y: 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.25), lineWidth: 0.5)
            )
            .onAppear {
                DispatchQueue.main.async {
                    proxy.scrollTo(selectedId, anchor: .center)
                }
            }
        }
    }
}

// Single item row inside the scrollable dropdown
struct DropdownRow: View {
    let title: String
    let isSelected: Bool
    let onSelect: () -> Void
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 4) {
                Text(verbatim: title)
                    .font(.system(size: 11.5, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
                    .fixedSize()
                Spacer(minLength: 2)
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 8.5, weight: .bold))
                }
            }
            .frame(height: 22)
            .padding(.horizontal, 7)
            .background(
                isSelected ? Color.accentColor :
                isHovered ? Color.secondary.opacity(0.12) : Color.clear
            )
            .foregroundColor(
                isSelected ? Color.white : Color.primary
            )
            .cornerRadius(4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Calendar Tab View
struct CalendarTabView: View {
    @ObservedObject var engine: PatroEngine
    var onOpenConverter: () -> Void
    @State private var copied: Bool = false
    @State private var pickerMode: String = "BS" // "BS" or "AD"
    @State private var activeDropdown: ActiveDropdown? = nil
    @State private var showDateSelector: Bool = false
    
    // BS Years (2090 down to 2000)
    private var bsYears: [DropdownItem] {
        stride(from: 2090, through: 2000, by: -1).map {
            DropdownItem(id: $0, title: engine.formatNumber($0))
        }
    }
    
    // AD Years (2034 down to 1944)
    private var adYears: [DropdownItem] {
        stride(from: 2034, through: 1944, by: -1).map {
            DropdownItem(id: $0, title: "\($0)")
        }
    }
    
    // BS Months (1 to 12) - No bracket, clean name according to active language
    private var bsMonths: [DropdownItem] {
        PatroEngine.nepaliMonths.map {
            let mName = (engine.language == "English") ? $0.enName : $0.name
            return DropdownItem(id: $0.id, title: mName)
        }
    }
    
    // AD Months (1 to 12)
    private var adMonths: [DropdownItem] {
        PatroEngine.gregorianMonths.map {
            DropdownItem(id: $0.id, title: $0.name)
        }
    }
    
    // BS Days (1 to daysInCurrentMonth)
    private var bsDays: [DropdownItem] {
        let suffix = (engine.language == "English") ? "" : " गते"
        return (1...max(1, engine.daysInCurrentMonth)).map {
            DropdownItem(id: $0, title: "\(engine.formatNumber($0))\(suffix)")
        }
    }
    
    // AD Days (1 to 31)
    private var adDays: [DropdownItem] {
        (1...31).map {
            DropdownItem(id: $0, title: "\($0)")
        }
    }
    
    var body: some View {
        let currentADYear = engine.selectedDay?.gregorian.year ?? (engine.todayInfo?.gregorian.year ?? 2026)
        let currentADMonth = engine.selectedDay?.gregorian.month ?? (engine.todayInfo?.gregorian.month ?? 11)
        let currentADDay = engine.selectedDay?.gregorian.day ?? (engine.todayInfo?.gregorian.day ?? 6)
        
        VStack(spacing: 6) {
            // Month navigation bar
            HStack(alignment: .center) {
                // Clickable Month & Year Header to toggle Date Selector
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showDateSelector.toggle()
                        if !showDateSelector {
                            activeDropdown = nil
                        }
                    }
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Text(engine.currentMonth?.title ?? "")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Image(systemName: showDateSelector ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(showDateSelector ? Color.accentColor : Color.secondary.opacity(0.75))
                        }
                        
                        Text(engine.currentMonth?.gregorianSpan ?? "")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .help("मिति छान्ने विकल्प देखाउनुहोस् / लुकाउनुहोस् (Click to jump date)")
                
                Spacer()
                
                // Navigation buttons
                HStack(spacing: 4) {
                    Button(action: {
                        activeDropdown = nil
                        engine.previousYear()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("अघिल्लो वर्ष (Previous Year)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.previousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("अघिल्लो महिना (Previous Month)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.goToToday()
                    }) {
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
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.nextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .padding(6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("पछिल्लो महिना (Next Month)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.nextYear()
                    }) {
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
            .contentShape(Rectangle())
            .onTapGesture {
                if activeDropdown != nil {
                    withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
                }
            }
            
            // Direct Date Selector Bar (Select Year, Month, Day directly)
            // Hidden by default; toggled when the bold month/year title is clicked
            if showDateSelector {
                HStack(spacing: 6) {
                // Mode Toggle: [ वि.सं. | ई.सं. ] (or [ BS | AD ]) (fixed 88pt)
                ModeCapsuleToggle(pickerMode: $pickerMode, isEnglish: engine.language == "English") {
                    activeDropdown = nil
                }
                
                // Year Button (fixed 70pt) - Dropdown opens directly below Year button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activeDropdown = (activeDropdown == .year) ? nil : .year
                    }
                }) {
                    HStack(spacing: 3) {
                        let yearText = pickerMode == "BS"
                            ? engine.formatNumber(engine.viewYear)
                            : "\(currentADYear)"
                        Text(verbatim: yearText)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundColor(.primary)
                        Image(systemName: activeDropdown == .year ? "chevron.up" : "chevron.down")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 70, height: 26)
                    .background(Color.secondary.opacity(activeDropdown == .year ? 0.22 : 0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .help(pickerMode == "BS" ? "वर्ष छान्नुहोस्" : "Select Year")
                .overlay(alignment: .topLeading) {
                    if activeDropdown == .year {
                        let dWidth: CGFloat = 80
                        ScrollableDropdownMenu(
                            items: pickerMode == "BS" ? bsYears : adYears,
                            selectedId: pickerMode == "BS" ? engine.viewYear : currentADYear,
                            width: dWidth,
                            visibleRows: 10,
                            onSelect: { selectedId in
                                if pickerMode == "BS" {
                                    engine.jumpToBS(year: selectedId, month: engine.viewMonth, day: engine.selectedDay?.day)
                                } else {
                                    engine.jumpToAD(year: selectedId, month: currentADMonth, day: currentADDay)
                                }
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    activeDropdown = nil
                                }
                            }
                        )
                        .offset(y: 30)
                    }
                }
                
                // Month Button (fixed 86pt) - Dropdown opens directly below Month button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activeDropdown = (activeDropdown == .month) ? nil : .month
                    }
                }) {
                    HStack(spacing: 3) {
                        let monthText = pickerMode == "BS"
                            ? engine.currentMonthName
                            : ((currentADMonth >= 1 && currentADMonth <= 12) ? PatroEngine.gregorianMonths[currentADMonth - 1].shortName : "Nov")
                        Text(verbatim: monthText)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundColor(.primary)
                        Image(systemName: activeDropdown == .month ? "chevron.up" : "chevron.down")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 86, height: 26)
                    .background(Color.secondary.opacity(activeDropdown == .month ? 0.22 : 0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .help(pickerMode == "BS" ? "महिना छान्नुहोस्" : "Select Month")
                .overlay(alignment: .top) {
                    if activeDropdown == .month {
                        let dWidth: CGFloat = pickerMode == "BS" ? 120 : 106
                        ScrollableDropdownMenu(
                            items: pickerMode == "BS" ? bsMonths : adMonths,
                            selectedId: pickerMode == "BS" ? engine.viewMonth : currentADMonth,
                            width: dWidth,
                            visibleRows: 10,
                            onSelect: { selectedId in
                                if pickerMode == "BS" {
                                    engine.jumpToBS(year: engine.viewYear, month: selectedId, day: engine.selectedDay?.day)
                                } else {
                                    engine.jumpToAD(year: currentADYear, month: selectedId, day: currentADDay)
                                }
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    activeDropdown = nil
                                }
                            }
                        )
                        .offset(y: 30)
                    }
                }
                
                // Day Button (fixed 64pt) - Dropdown opens directly below Day button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        activeDropdown = (activeDropdown == .day) ? nil : .day
                    }
                }) {
                    HStack(spacing: 3) {
                        let daySuffix = (pickerMode == "BS" && engine.language != "English") ? " गते" : ""
                        let dayVal = engine.selectedDay?.day ?? 1
                        let dayText = pickerMode == "BS"
                            ? "\(engine.formatNumber(dayVal))\(daySuffix)"
                            : "\(currentADDay)"
                        Text(verbatim: dayText)
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .fixedSize()
                            .foregroundColor(.primary)
                        Image(systemName: activeDropdown == .day ? "chevron.up" : "chevron.down")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .frame(width: 64, height: 26)
                    .background(Color.secondary.opacity(activeDropdown == .day ? 0.22 : 0.12))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.15), lineWidth: 0.5)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .help(pickerMode == "BS" ? "गते छान्नुहोस्" : "Select Day")
                .overlay(alignment: .topTrailing) {
                    if activeDropdown == .day {
                        let dWidth: CGFloat = pickerMode == "BS" ? 82 : 68
                        ScrollableDropdownMenu(
                            items: pickerMode == "BS" ? bsDays : adDays,
                            selectedId: pickerMode == "BS" ? (engine.selectedDay?.day ?? 1) : currentADDay,
                            width: dWidth,
                            visibleRows: 10,
                            onSelect: { selectedId in
                                if pickerMode == "BS" {
                                    engine.selectDayNumber(selectedId)
                                } else {
                                    engine.jumpToAD(year: currentADYear, month: currentADMonth, day: selectedId)
                                }
                                withAnimation(.easeInOut(duration: 0.1)) {
                                    activeDropdown = nil
                                }
                            }
                        )
                        .offset(y: 30)
                    }
                }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 3)
                .zIndex(100) // Ensure dropdown overlays always float above calendar grid
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
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
                .contentShape(Rectangle())
                .onTapGesture {
                    if activeDropdown != nil {
                        withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
                    }
                }
                
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
                                        isSelected: (engine.selectedDay?.year == cell.year && engine.selectedDay?.month == cell.month && engine.selectedDay?.day == cell.day),
                                        showGregorian: engine.showGregorianInGrid
                                    )
                                    .onTapGesture {
                                        activeDropdown = nil
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
                .contentShape(Rectangle())
                .onTapGesture {
                    if activeDropdown != nil {
                        withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
                    }
                }
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
                    
                    let adYearText = String(format: "%d", gregYear)
                    let fullADText = "\(gregDay) \(gName) \(adYearText) AD (\(activeWeekday))"
                    Text(verbatim: fullADText)
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
            .contentShape(Rectangle())
            .onTapGesture {
                if activeDropdown != nil {
                    withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if activeDropdown != nil {
                withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
            }
        }
        .onAppear {
            engine.refreshToday()
            if engine.isViewingToday() {
                engine.selectToday()
            }
        }
    }
    
    private func isTodayCell(_ cell: DayCellData) -> Bool {
        guard let today = engine.todayInfo else { return false }
        return cell.year == today.year && cell.month == today.month && cell.day == today.day
    }
    
    private func copyDateInfo(dayText: String, weekday: String, gregDay: Int, gregMonth: Int, gregYear: Int, observance: String) {
        let gMonthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let gName = gMonthNames[max(0, min(11, gregMonth - 1))]
        let adYearText = String(format: "%d", gregYear)
        var text = "\(dayText) \(engine.currentMonth?.title ?? ""), \(weekday) (\(gregDay) \(gName) \(adYearText) AD)"
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
                .foregroundColor(
                    isToday ? Color.white :
                    (cell.isSaturday || cell.isHoliday) ? Color.red : Color.primary
                )
            
            // Clean Gregorian day number
            if showGregorian {
                Text(cell.gregorianDayText)
                    .font(.system(size: 9, weight: .regular))
                    .foregroundColor(
                        isToday ? Color.white.opacity(0.85) : Color.secondary.opacity(0.75)
                    )
            }
        }
        .frame(maxWidth: .infinity, minHeight: showGregorian ? 36 : 28)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isToday ? Color.accentColor :
                    isSelected ? Color.accentColor.opacity(0.18) :
                    isHovered ? Color.secondary.opacity(0.1) : Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    (!isToday && isSelected) ? Color.accentColor : Color.clear,
                    lineWidth: 1.5
                )
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
