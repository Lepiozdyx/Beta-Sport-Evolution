import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import UIKit

struct SettingsView: View {
    @Environment(AppStore.self) private var store
    @State private var shareURL: URL?
    @State private var showingImporter = false
    @State private var showingDeletePhotos = false
    @State private var showingReset = false
    @State private var afterPhotoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Settings & Privacy").font(.largeTitle.bold())

                    Panel {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Units").font(.title3.bold())
                            if let unit = store.profile?.unitSystem {
                                SegmentedPill(values: UnitSystem.allCases, selection: Binding(
                                    get: { unit },
                                    set: { store.updateUnitSystem($0) }
                                ), title: \.title)
                            }
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Privacy", systemImage: "shield")
                                .font(.title3.bold())
                                .foregroundStyle(AppTheme.mint)
                            Text("Photos and measurements are stored locally on this device. No data is uploaded to external servers.")
                                .foregroundStyle(AppTheme.secondary)
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Progress Photos").font(.title3.bold())
                            PhotosPicker(selection: $afterPhotoItem, matching: .images) {
                                settingsRow("Add After Photo", symbol: "photo.badge.plus", color: AppTheme.blue)
                            }
                            Button { showingDeletePhotos = true } label: {
                                settingsRow("Delete All Photos", symbol: "trash", color: .red)
                            }
                        }
                    }

                    Panel {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Data Management").font(.title3.bold())
                            Button(action: exportReport) { settingsRow("Export PDF Report", symbol: "arrow.down.doc", color: AppTheme.blue) }
                            Button(action: backup) { settingsRow("Backup Data as JSON", symbol: "square.and.arrow.up", color: AppTheme.cyan) }
                            Button { showingImporter = true } label: { settingsRow("Restore JSON Backup", symbol: "square.and.arrow.down", color: AppTheme.mint) }
                        }
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("Danger Zone").font(.title3.bold()).foregroundStyle(.red)
                        Text("This permanently deletes all local data and restarts your journey.")
                            .foregroundStyle(AppTheme.secondary)
                        Button(role: .destructive) { showingReset = true } label: {
                            Label("Start New Beta Version", systemImage: "arrow.counterclockwise")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.red))
                        }
                    }
                    .padding(20)
                    .background(Color.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 24))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.red.opacity(0.7)))
                }
                .padding(24)
            }
            .navigationBarHidden(true)
            .sheet(item: $shareURL) { ShareSheet(items: [$0]) }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json]) { result in
                do { try store.restoreData(from: result.get()) }
                catch { store.lastError = "The backup could not be restored: \(error.localizedDescription)" }
            }
            .confirmationDialog("Delete all local photos?", isPresented: $showingDeletePhotos, titleVisibility: .visible) {
                Button("Delete All Photos", role: .destructive) {
                    do { try store.deletePhotos() }
                    catch { store.lastError = "Photos could not be deleted: \(error.localizedDescription)" }
                }
            } message: {
                Text("Measurements and workout history will remain.")
            }
            .alert("Start a new beta version?", isPresented: $showingReset) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    do { try store.resetAllData() }
                    catch { store.lastError = "Local data could not be reset: \(error.localizedDescription)" }
                }
            } message: {
                Text("All measurements, workouts, custom exercises, achievements and photos will be permanently deleted.")
            }
            .onChange(of: afterPhotoItem) { _, item in
                guard let item else { return }
                Task {
                    do {
                        guard let bytes = try await item.loadTransferable(type: Data.self), let image = UIImage(data: bytes) else {
                            throw StoreError.photoEncoding
                        }
                        _ = try store.savePhoto(image, kind: "after")
                    } catch {
                        store.lastError = error.localizedDescription
                    }
                }
            }
        }
        .appScreen()
    }

    private func settingsRow(_ title: String, symbol: String, color: Color) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(color).frame(width: 26)
            Text(title).foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(AppTheme.secondary)
        }
        .padding(16)
        .background(AppTheme.field, in: RoundedRectangle(cornerRadius: 16))
    }

    private func exportReport() {
        do {
            shareURL = try store.exportReport()
            store.markReportShared()
        } catch {
            store.lastError = "The PDF report could not be created: \(error.localizedDescription)"
        }
    }

    private func backup() {
        do { shareURL = try store.backupData() }
        catch { store.lastError = "The backup could not be created: \(error.localizedDescription)" }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
