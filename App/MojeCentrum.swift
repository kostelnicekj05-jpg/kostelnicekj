import AppIntents
import EventKit
import SwiftUI
import UIKit

@main
struct MojeCentrumApp: App {
    @State private var selection = 0
    @State private var agenda = Agenda()

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selection) {
                TodayView(agenda: agenda)
                    .tabItem { Label("Dnes", systemImage: "calendar") }.tag(0)
                NotesView()
                    .tabItem { Label("Zápis O2", systemImage: "mic") }.tag(1)
                SportView()
                    .tabItem { Label("Sport", systemImage: "figure.run") }.tag(2)
            }
            .tint(.teal)
            .onOpenURL { url in
                guard url.scheme == "mojecentrum" else { return }
                switch url.host {
                case "dnes": selection = 0
                case "zapis": selection = 1
                case "sport": selection = 2
                default: break
                }
            }
        }
    }
}

struct OpenTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Otevřít přehled dne"
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let url = URL(string: "mojecentrum://dnes") else { return .result() }
        _ = await UIApplication.shared.open(url)
        return .result()
    }
}

@MainActor @Observable
final class Agenda {
    private let store = EKEventStore()
    private(set) var events: [EKEvent] = []
    private(set) var reminders: [EKReminder] = []
    private(set) var calendarAccess = false
    private(set) var reminderAccess = false
    var notice: String?

    func grant(_ type: EKEntityType) async {
        do {
            if type == .event {
                _ = try await store.requestFullAccessToEvents()
            } else {
                _ = try await store.requestFullAccessToReminders()
            }
        } catch {
            notice = error.localizedDescription
        }
        await refresh()
        let granted = type == .event ? calendarAccess : reminderAccess
        if !granted && notice == nil {
            notice = "Přístup můžeš povolit v Nastavení iPhonu."
        }
    }

    func refresh() async {
        calendarAccess = EKEventStore.authorizationStatus(for: .event) == .fullAccess
        reminderAccess = EKEventStore.authorizationStatus(for: .reminder) == .fullAccess
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        events = calendarAccess
            ? store.events(matching: store.predicateForEvents(withStart: today, end: tomorrow, calendars: nil))
                .sorted { $0.startDate < $1.startDate }
            : []
        reminders = []
        if reminderAccess {
            let predicate = store.predicateForIncompleteReminders(
                withDueDateStarting: today, ending: tomorrow, calendars: nil)
            reminders = await withCheckedContinuation { continuation in
                store.fetchReminders(matching: predicate) { items in
                    continuation.resume(returning: items ?? [])
                }
            }
        }
    }
}

struct TodayView: View {
    let agenda: Agenda
    @Environment(\.scenePhase) private var phase

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide)
                        .locale(Locale(identifier: "cs_CZ"))))
                        .font(.title2.bold())
                    if let notice = agenda.notice { Text(notice).foregroundStyle(.secondary) }
                }
                Section("Kalendář") {
                    if !agenda.calendarAccess {
                        Button("Povolit Kalendář") { Task { await agenda.grant(.event) } }
                    } else if agenda.events.isEmpty {
                        Text("Na dnešek nejsou naplánované žádné události.")
                    }
                    ForEach(Array(agenda.events.enumerated()), id: \.offset) { _, event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title ?? "Událost").fontWeight(.medium)
                            if event.isAllDay {
                                Text("Celý den").foregroundStyle(.secondary)
                            } else {
                                Text(event.startDate, format: .dateTime.hour().minute())
                                    .foregroundStyle(.secondary)
                            }
                            if let location = event.location, !location.isEmpty {
                                Text(location).font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Úkoly na dnes") {
                    if !agenda.reminderAccess {
                        Button("Povolit Připomínky") { Task { await agenda.grant(.reminder) } }
                    } else if agenda.reminders.isEmpty {
                        Text("Na dnešek nejsou otevřené žádné připomínky.")
                    }
                    ForEach(agenda.reminders, id: \.calendarItemIdentifier) { reminder in
                        Text(reminder.title ?? "Připomínka")
                    }
                }
            }
            .navigationTitle("Dnes")
            .task(id: phase) { if phase == .active { await agenda.refresh() } }
            .refreshable { await agenda.refresh() }
        }
    }
}

struct NotesView: View {
    @State private var notes = ""
    @State private var copied = false

    private let instructions = """
    Z následujících poznámek připrav stručný zápis do CRM. Struktura:
    Současné služby
    Potřeba zákazníka
    Co jsme domluvili
    Další krok
    Zachovej fakta. Pokud mám domluvený follow-up, uveď zvlášť jeho termín a úkol. Chybějící údaje nedoplňuj.
    """

    var body: some View {
        NavigationStack {
            Form {
                Section("Poznámky ze schůzky") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 170)
                        .accessibilityLabel("Poznámky ze schůzky")
                    Text("K diktování použij mikrofon na české klávesnici.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section {
                    Button(copied ? "Zkopírováno" : "Zkopírovat zadání pro ChatGPT") {
                        UIPasteboard.general.setItems(
                            [["public.utf8-plain-text": instructions + "\n\nMoje poznámky:\n" + notes]],
                            options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(600)]
                        )
                        copied = true
                    }
                    .disabled(notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                } footer: {
                    Text("Použij anonymizované poznámky. Zadání vložíš do ChatGPT ručně.")
                }
            }
            .onChange(of: notes) { _, _ in copied = false }
            .navigationTitle("Zápis O2")
        }
    }
}

struct SportView: View {
    @AppStorage("sigmaPlan") private var sigmaPlan = ""
    @AppStorage("gymPlan") private var gymPlan = "Upper A\nLower A\nStředa – lehký běh 25–35 min\nUpper B"

    var body: some View {
        NavigationStack {
            Form {
                Section("Sigma U10") {
                    TextEditor(text: $sigmaPlan)
                        .frame(minHeight: 110)
                        .accessibilityLabel("Plán Sigmy U10")
                    Text("Téma, počet hráčů, skupiny a minutáž.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Section("Můj trénink") {
                    TextEditor(text: $gymPlan)
                        .frame(minHeight: 130)
                        .accessibilityLabel("Můj tréninkový plán")
                    Text("Přidej fotbal a zápasy podle týdne.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Sport")
        }
    }
}
