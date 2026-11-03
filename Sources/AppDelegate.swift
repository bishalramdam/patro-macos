import Cocoa
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 360, height: 440)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: PatroView())
        
        // Setup status item in the macOS menu bar
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.target = self
            button.action = #selector(handleStatusBarClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Observe PatroEngine changes to update status item text
        PatroEngine.shared.$todayInfo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)
        
        PatroEngine.shared.$barFormat
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemTitle()
            }
            .store(in: &cancellables)
            
        updateStatusItemTitle()
        
        // Setup timer to refresh every minute
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            PatroEngine.shared.refreshToday()
            self?.updateStatusItemTitle()
        }
        
        // Listen to system calendar day changed notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDateChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(systemDateChanged),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        // Check for calendar updates in background
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 4.0) {
            PatroUpdateManager.shared.checkForUpdates(manual: false)
        }
    }
    
    @objc private func systemDateChanged() {
        PatroEngine.shared.refreshToday()
        updateStatusItemTitle()
    }
    
    private func updateStatusItemTitle() {
        guard let button = statusItem.button else { return }
        // Clean title without any flag or prefix
        button.title = PatroEngine.shared.menuBarTitle()
    }
    
    @objc private func handleStatusBarClick(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            // Right-click: cycle format
            cycleFormat()
        } else {
            // Left-click: toggle popover
            togglePopover()
        }
    }
    
    private func cycleFormat() {
        let formats = ["Year", "Full", "WithGregorian", "Numeric"]
        let current = PatroEngine.shared.barFormat
        if let idx = formats.firstIndex(of: current) {
            let next = formats[(idx + 1) % formats.count]
            PatroEngine.shared.barFormat = next
        } else {
            PatroEngine.shared.barFormat = "Year"
        }
    }
    
    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            PatroEngine.shared.refreshToday()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
