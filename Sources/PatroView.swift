import SwiftUI
import AppKit

enum PatroThemeColor: String, CaseIterable, Identifiable {
    case blue = "Blue"
    case green = "Green"
    case teal = "Teal"
    case purple = "Purple"
    case orange = "Orange"
    case red = "Red"
    
    var id: String { rawValue }
    
    static func resolve(_ name: String) -> Color {
        switch name {
        case "Green": return .green
        case "Teal": return .teal
        case "Purple": return .purple
        case "Orange": return .orange
        case "Red": return .red
        default: return .accentColor
        }
    }
    
    var swatchColor: Color {
        switch self {
        case .blue: return .blue
        case .green: return .green
        case .teal: return .teal
        case .purple: return .purple
        case .orange: return .orange
        case .red: return .red
        }
    }
}

struct PatroView: View {
    @ObservedObject var engine = PatroEngine.shared
    @State private var selectedTab: Int = 0 // 0: Calendar, 1: Settings
    
    var body: some View {
        let isEnglish = engine.language == "English"
        let themeColor = PatroThemeColor.resolve(engine.accentColorName)
        
        VStack(spacing: 0) {
            // Top Tab Header
            HStack(spacing: 8) {
                TabButton(
                    title: isEnglish ? "Calendar" : "क्यालेन्डर",
                    icon: "calendar",
                    isSelected: selectedTab == 0,
                    themeColor: themeColor
                ) {
                    selectedTab = 0
                }
                TabButton(
                    title: isEnglish ? "Settings" : "सेटिङ",
                    icon: "gearshape",
                    isSelected: selectedTab == 1,
                    themeColor: themeColor
                ) {
                    selectedTab = 1
                }
                
                Spacer()
                
                // Quit button
                Button(action: {
                    NSApp.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                .contentShape(Circle())
                .help(isEnglish ? "Quit Calendar" : "क्यालेन्डर बन्द गर्नुहोस् (Quit Calendar)")
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 8)
            
            Divider()
                .opacity(0.5)
            
            // Content Body based on selected Tab
            Group {
                if selectedTab == 0 {
                    CalendarTabView(engine: engine, themeColor: themeColor)
                } else {
                    SettingsTabView(engine: engine, themeColor: themeColor)
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

// Tab button component with full-pill clickable area & fixed width
struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let themeColor: Color
    let action: () -> Void
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11.5, weight: .semibold))
                Text(title)
                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
            }
            .frame(width: 96, height: 30)
            .background(
                RoundedRectangle(cornerRadius: 7)
                    .fill(
                        isSelected ? themeColor.opacity(0.18) :
                        isHovered ? Color.secondary.opacity(0.12) : Color.clear
                    )
            )
            .foregroundColor(isSelected ? themeColor : .primary.opacity(0.85))
            .contentShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onHover { hovering in
            isHovered = hovering
        }
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
    var themeColor: Color = .accentColor
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
                    .background(pickerMode == "BS" ? themeColor : Color.clear)
                    .cornerRadius(4)
                    .contentShape(Rectangle())
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
                    .background(pickerMode == "AD" ? themeColor : Color.clear)
                    .cornerRadius(4)
                    .contentShape(Rectangle())
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
    var themeColor: Color = .accentColor
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
                            themeColor: themeColor,
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
    var themeColor: Color = .accentColor
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
                isSelected ? themeColor :
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
    var themeColor: Color = .accentColor
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
        let isEnglish = engine.language == "English"
        
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
                                .font(.system(size: 17, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .foregroundColor(.primary)
                            
                            Image(systemName: showDateSelector ? "chevron.up" : "chevron.down")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(showDateSelector ? themeColor : Color.secondary.opacity(0.75))
                        }
                        
                        Text(engine.currentMonth?.gregorianSpan ?? "")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 36, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .help(isEnglish ? "Show / hide date selector" : "मिति छान्ने विकल्प देखाउनुहोस् / लुकाउनुहोस् (Click to jump date)")
                
                Spacer(minLength: 4)
                
                // Navigation buttons
                HStack(spacing: 4) {
                    Button(action: {
                        activeDropdown = nil
                        engine.previousYear()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 9))
                            .frame(width: 22, height: 24)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isEnglish ? "Previous Year" : "अघिल्लो वर्ष (Previous Year)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.previousMonth()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 22, height: 24)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isEnglish ? "Previous Month" : "अघिल्लो महिना (Previous Month)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.goToToday()
                    }) {
                        Text(isEnglish ? "Today" : "आज")
                            .font(.system(size: 11, weight: .semibold))
                            .lineLimit(1)
                            .frame(width: 48, height: 24)
                            .background(engine.isViewingToday() ? themeColor : Color.secondary.opacity(0.15))
                            .foregroundColor(engine.isViewingToday() ? .white : .primary)
                            .cornerRadius(5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isEnglish ? "Go to Today" : "आजको मितिमा जानुहोस् (Today)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.nextMonth()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .frame(width: 22, height: 24)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isEnglish ? "Next Month" : "पछिल्लो महिना (Next Month)")
                    
                    Button(action: {
                        activeDropdown = nil
                        engine.nextYear()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 9))
                            .frame(width: 22, height: 24)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help(isEnglish ? "Next Year" : "पछिल्लो वर्ष (Next Year)")
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
                ModeCapsuleToggle(pickerMode: $pickerMode, isEnglish: isEnglish, themeColor: themeColor) {
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
                            themeColor: themeColor,
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
                            themeColor: themeColor,
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
                            themeColor: themeColor,
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
                            .lineLimit(1)
                            .foregroundColor(wd.isSaturday ? Color.red.opacity(0.9) : Color.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 16)
                .padding(.horizontal, 10)
                .padding(.top, 2)
                .contentShape(Rectangle())
                .onTapGesture {
                    if activeDropdown != nil {
                        withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
                    }
                }
                
                // Clean Calendar Days Grid (always reserve 6 rows so navigating months never resizes the popover)
                let cellHeight: CGFloat = engine.showGregorianInGrid ? 36 : 28
                let gridHeight: CGFloat = 6 * cellHeight + 5 * 3
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
                                        showGregorian: engine.showGregorianInGrid,
                                        themeColor: themeColor
                                    )
                                    .onTapGesture {
                                        activeDropdown = nil
                                        engine.selectedDay = cell
                                    }
                                } else {
                                    // Fixed-height empty padding cell (prevents row 1 & last row vertical gap)
                                    Color.clear
                                        .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
                                }
                            }
                        }
                        .frame(height: cellHeight)
                    }
                }
                .frame(height: gridHeight, alignment: .top)
                .padding(.horizontal, 10)
                .contentShape(Rectangle())
                .onTapGesture {
                    if activeDropdown != nil {
                        withAnimation(.easeInOut(duration: 0.1)) { activeDropdown = nil }
                    }
                }
            }
            
            Divider()
                .padding(.vertical, 3)
            
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
                        .frame(height: 28)
                        .foregroundColor(isSatOrHol ? Color.red : themeColor)
                    Text(activeWeekday)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                        .frame(height: 14)
                        .foregroundColor(.secondary)
                }
                .frame(width: 58)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(activeDay) \(engine.currentMonth?.title ?? "")")
                        .font(.system(size: 13, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    
                    let adYearText = String(format: "%d", gregYear)
                    let fullADText = "\(gregDay) \(gName) \(adYearText) AD (\(activeWeekday))"
                    Text(verbatim: fullADText)
                        .font(.system(size: 11, weight: .regular))
                        .lineLimit(1)
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
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .help(isEnglish ? "Copy date to clipboard" : "मिति क्लिपबोर्डमा कपी गर्नुहोस्")
            }
            .frame(height: 50)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
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
            if engine.isTrackingToday || engine.isViewingToday() {
                engine.goToToday()
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
    var themeColor: Color = .accentColor
    
    @State private var isHovered: Bool = false
    
    var body: some View {
        let cellHeight: CGFloat = showGregorian ? 36 : 28
        
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
        .frame(maxWidth: .infinity, minHeight: cellHeight, maxHeight: cellHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    isToday ? themeColor :
                    isSelected ? themeColor.opacity(0.18) :
                    isHovered ? Color.secondary.opacity(0.1) : Color.clear
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(
                    (!isToday && isSelected) ? themeColor : Color.clear,
                    lineWidth: 1.5
                )
        )
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Settings Tab View
struct SettingsTabView: View {
    @ObservedObject var engine: PatroEngine
    var themeColor: Color = .accentColor
    
    var body: some View {
        let isEnglish = engine.language == "English"
        
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
                Text(isEnglish ? "Settings & Preferences" : "सेटिङ तथा प्राथमिकताहरू")
                    .font(.system(size: 14, weight: .bold))
                    .frame(height: 18, alignment: .leading)
                    .padding(.top, 10)
                
                // Menu bar label format
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEnglish ? "Menu Bar Format:" : "मेनु बार फर्म्याट (Menu Bar Format):")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(height: 14, alignment: .leading)
                    
                    Picker("", selection: $engine.barFormat) {
                        Text(isEnglish ? "With Year (17 Kartik 2083)" : "वर्षसहित (१७ कात्तिक २०८३)").tag("Year")
                        Text(isEnglish ? "Full (Tuesday, 17 Kartik 2083)" : "विस्तृत (मङ्गलबार, १७ कात्तिक २०८३)").tag("Full")
                        Text(isEnglish ? "With Gregorian (17 Kartik 2083, 3 Nov)" : "अंग्रेजी मितिसहित (१७ कात्तिक २०८३, 3 Nov)").tag("WithGregorian")
                        Text(isEnglish ? "Numeric Only (2083-07-17)" : "अङ्क मात्र (२०८३-०७-१७)").tag("Numeric")
                    }
                    .labelsHidden()
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 322, height: 22, alignment: .leading)
                }
                
                // Numerals Style
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEnglish ? "Numerals:" : "अङ्कको लिपि (Numerals):")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(height: 14, alignment: .leading)
                    
                    Picker("", selection: $engine.numerals) {
                        Text(isEnglish ? "Devanagari (०–९)" : "देवनागरी (०–९)").tag("Devanagari")
                        Text(isEnglish ? "Latin (0–9)" : "ल्याटिन (0–9)").tag("Latin")
                    }
                    .labelsHidden()
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 322, height: 22)
                }
                
                // Language
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEnglish ? "Language:" : "भाषा (Language):")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(height: 14, alignment: .leading)
                    
                    Picker("", selection: $engine.language) {
                        Text("नेपाली (Nepali)").tag("Nepali")
                        Text("English").tag("English")
                    }
                    .labelsHidden()
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 322, height: 22)
                }
                
                // Theme Color
                VStack(alignment: .leading, spacing: 5) {
                    Text(isEnglish ? "Theme Color:" : "रङ्ग (Theme Color):")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(height: 14, alignment: .leading)
                    
                    HStack(spacing: 10) {
                        ForEach(PatroThemeColor.allCases) { option in
                            let isSelected = engine.accentColorName == option.rawValue
                            Button(action: {
                                engine.accentColorName = option.rawValue
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(option.swatchColor)
                                        .frame(width: 20, height: 20)
                                    if isSelected {
                                        Circle()
                                            .stroke(Color.primary, lineWidth: 1.8)
                                            .frame(width: 25, height: 25)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .frame(width: 26, height: 26)
                                .contentShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                            .help(option.rawValue)
                        }
                        Spacer()
                    }
                }
                
                // Grid Toggles
                Toggle(
                    isEnglish ? "Show Gregorian date in grid (AD)" : "क्यालेन्डर कोठामा अंग्रेजी मिति (AD in Grid)",
                    isOn: $engine.showGregorianInGrid
                )
                .font(.system(size: 12))
                .lineLimit(1)
                .frame(width: 322, height: 20, alignment: .leading)
                
                Divider()
                
                // Auto-Update & GitHub Sync Section
                CalendarSyncSection(isEnglish: isEnglish, themeColor: themeColor)
                
                Divider()
                
                // About App
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calendar for macOS")
                        .font(.system(size: 12, weight: .bold))
                    Text("Bikram Sambat 2000–2090 BS (Clean Date Calendar)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 10)
            }
            .padding(.horizontal, 14)
            .frame(width: 350, alignment: .topLeading)
        }
        .frame(width: 350, height: 425, alignment: .top)
    }
}

// Calendar Sync & GitHub Auto-Update Section
struct CalendarSyncSection: View {
    @ObservedObject var updater = PatroUpdateManager.shared
    var isEnglish: Bool
    var themeColor: Color = .accentColor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(isEnglish ? "Calendar Data & Sync" : "क्यालेन्डर डेटा तथा अद्यावधिक (Sync)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                Text(isEnglish ? "Verified: \(updater.publishedThrough)" : "प्रमाणित: \(updater.publishedThrough)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(themeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(themeColor.opacity(0.12))
                    .cornerRadius(4)
            }
            .frame(height: 18)
            
            Text(isEnglish ? "Update new year calendar data directly from yogeshojha/patro on GitHub without rebuilding:" : "GitHub को yogeshojha/patro बाट नयाँ वर्षको डेटा एप रिबिल्ड नगरी अपडेट गर्नुहोस्:")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .frame(height: 28, alignment: .topLeading)
            
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
                        Text(updater.isChecking ? (isEnglish ? "Checking..." : "जाँचिँदैछ...") : (isEnglish ? "Update from GitHub" : "GitHub बाट अपडेट"))
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(themeColor.opacity(0.15))
                    .foregroundColor(themeColor)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
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
                        Text(isEnglish ? "Local Folder" : "स्थानीय फोल्डर")
                            .font(.system(size: 11, weight: .medium))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color.secondary.opacity(0.12))
                    .foregroundColor(.primary)
                    .cornerRadius(6)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                .help(isEnglish ? "Sync calendar data from local patro/ folder" : "स्थानीय patro/ फोल्डरबाट नयाँ फाइल सिङ्क गर्नुहोस्")
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
