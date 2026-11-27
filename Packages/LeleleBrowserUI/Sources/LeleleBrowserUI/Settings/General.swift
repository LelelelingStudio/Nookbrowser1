// Licensed under GPL-3.0. See LICENSE.
//
//  General.swift
//  LeleleBrowser
//
//  Created by Maciek Bagiński on 07/12/2025.
//

import SwiftUI
import LeleleBrowserDesign
import LeleleBrowserSettings
import LeleleBrowserWeb

public struct SettingsGeneralTab: View {
    @Environment(TabsController.self) private var tabs
    @Environment(LeleleBrowserSettingsService.self) var leleleSettings
    @State private var showingAddSite = false
    @State private var showingAddEngine = false

    public init() {}

    private var versionString: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    /// The provider list, shared by both platforms' spellings of the row.
    @ViewBuilder
    private func searchEnginePicker(_ settings: LeleleBrowserSettingsService) -> some View {
        @Bindable var settings = settings
        Picker("Default search engine", selection: $settings.searchEngineId) {
            ForEach(SearchProvider.allCases) { provider in
                Text(provider.displayName).tag(provider.rawValue)
            }
            ForEach(leleleSettings.customSearchEngines) { engine in
                Text(engine.name).tag(engine.id.uuidString)
            }
        }
    }

    public var body: some View {
        @Bindable var settings = leleleSettings
        Form {
            Section {
                Picker("Language", selection: Binding(
                    get: { leleleSettings.appLanguage },
                    set: { leleleSettings.appLanguage = $0 }
                )) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
            } header: {
                Text(L("Language"))
            } footer: {
                Text(L("Lelele Browser follows your system language by default. You can override it here."))
            }

            Section(L("About")) {
                LabeledContent(L("Version"), value: versionString)
                Link(destination: URL(string: "https://leleleling.site")!) {
                    Text("leleleling.site")
                }
            }

            #if os(macOS)
            // Quitting and Sparkle updates are both macOS-only concepts.
            Section {
                Toggle("Warn before quitting Lelele Browser", isOn: $settings.askBeforeQuit)
                Toggle("Automatically update Lelele Browser", isOn: .constant(true))
                    .disabled(true)
            }

            Section {
                Toggle("Keep videos playing in the sidebar", isOn: $settings.autoPictureInPicture)
            } footer: {
                Text("Leaving a tab with a playing video moves it into a small window above the sidebar media controls.")
            }
            #endif

            Section {
                Toggle("Nest tabs opened from links", isOn: $settings.nestTabsFromLinks)
            } footer: {
                Text("A tab opened from a link sits under the page that opened it, and Back returns to that page.")
            }

            Section {
                Picker(L("Tab Management"), selection: Binding(
                    get: { leleleSettings.tabManagementMode },
                    set: { leleleSettings.tabManagementMode = $0 }
                )) {
                    ForEach(TabManagementMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Toggle(L("Automatic Memory Saver"), isOn: $settings.memorySaverOnLowPower)

                Picker(L("On Startup"), selection: Binding(
                    get: { leleleSettings.startupLoadMode },
                    set: { leleleSettings.startupLoadMode = $0 }
                )) {
                    ForEach(StartupLoadMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }

                Button(L("Unload All Inactive Tabs")) {
                    tabs.unloadAllHidden()
                }
            } header: {
                Text(L("Performance"))
            } footer: {
                VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.xs) {
                    Label(
                        leleleSettings.tabManagementMode.description,
                        systemImage: leleleSettings.tabManagementMode.icon
                    )
                    Label(
                        String(format: L("Loaded tabs: %lld"), tabs.loadedPageCount),
                        systemImage: "memorychip"
                    )
                    Label(
                        L("Switch to Memory Saver automatically when Low Power Mode is active."),
                        systemImage: "battery.25"
                    )
                    Label(leleleSettings.startupLoadMode.description, systemImage: "power")
                }
            }

            Section {
                Picker("Archive tabs after", selection: $settings.archiveAfter) {
                    Text("12 hours").tag(12)
                    Text("24 hours").tag(24)
                    Text("7 days").tag(168)
                    Text("30 days").tag(720)
                    Text("Never").tag(0)
                }
            } footer: {
                Text("Tabs you haven't opened in that long move to the Archive. Pinned tabs and favorites stay put.")
            }

            Section {
                #if os(macOS)
                LabeledContent("Default search engine") {
                    HStack(spacing: LeleleBrowserDesign.Spacing.md) {
                        searchEnginePicker(settings)
                            .labelsHidden()

                        Button {
                            showingAddEngine = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                #else
                // A picker inside a LabeledContent's trailing slot gets squeezed
                // to "G...gle" at phone width. The Form's own picker row does not,
                // so the add button takes a row of its own.
                searchEnginePicker(settings)
                Button("Add Search Engine…") { showingAddEngine = true }
                #endif

                if let selected = leleleSettings.customSearchEngines.first(where: { $0.id.uuidString == leleleSettings.searchEngineId }) {
                    LabeledContent {
                        Button("Remove") {
                            leleleSettings.customSearchEngines.removeAll { $0.id == selected.id }
                            leleleSettings.searchEngineId = SearchProvider.google.rawValue
                        }
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                    } label: {
                        Text(selected.name)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Search")
            }

            Section {
                ForEach(leleleSettings.siteSearchEntries) { entry in
                    LabeledContent {
                        HStack(spacing: LeleleBrowserDesign.Spacing.md) {
                            Text(entry.domain)
                                .foregroundStyle(.secondary)
                            Button {
                                leleleSettings.siteSearchEntries.removeAll { $0.id == entry.id }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    } label: {
                        Label {
                            Text(entry.name)
                        } icon: {
                            Circle()
                                .fill(entry.color)
                                .frame(
                                    width: LeleleBrowserDesign.Size.statusDot,
                                    height: LeleleBrowserDesign.Size.statusDot
                                )
                        }
                    }
                }

                Button {
                    showingAddSite = true
                } label: {
                    Label("Add Site", systemImage: "plus")
                }

                Button("Reset to Defaults") {
                    leleleSettings.siteSearchEntries = SiteSearchEntry.defaultSites
                }
            } header: {
                Text("Site Search")
            } footer: {
                Text("Type a prefix in the command palette and press Tab to search a site directly.")
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showingAddSite) {
            SiteSearchEntryEditor(entry: nil) { newEntry in
                leleleSettings.siteSearchEntries.append(newEntry)
            }
        }
        .sheet(isPresented: $showingAddEngine) {
            CustomSearchEngineEditor { newEngine in
                leleleSettings.customSearchEngines.append(newEngine)
            }
        }
    }
}

// MARK: - Custom Search Engine Editor

struct CustomSearchEngineEditor: View {
    let onSave: (CustomSearchEngine) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var urlTemplate: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: LeleleBrowserDesign.Spacing.xl) {
            Text("Add Custom Search Engine")
                .font(LeleleBrowserDesign.Font.heading)

            Form {
                Section {
                    TextField("Name (e.g. Startpage)", text: $name)
                    TextField("URL Template (use %@ for query)", text: $urlTemplate)
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.bordered)
                Button("Save") {
                    let engine = CustomSearchEngine(
                        name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                        urlTemplate: urlTemplate.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    onSave(engine)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || urlTemplate.isEmpty)
            }
        }
        .padding(LeleleBrowserDesign.Spacing.xxl)
        .frame(width: LeleleBrowserDesign.Size.sheetSmallWidth)
    }
}
