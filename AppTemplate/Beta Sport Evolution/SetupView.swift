import PhotosUI
import SwiftUI
import UIKit

struct SetupView: View {
    @Environment(AppStore.self) private var store
    @State private var unitSystem: UnitSystem = .metric
    @State private var currentText = Dictionary(uniqueKeysWithValues: BodyMetric.allCases.map { ($0, "") })
    @State private var goalText = Dictionary(uniqueKeysWithValues: BodyMetric.allCases.map { ($0, "") })
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var showingCamera = false
    @State private var validationMessage: String?
    @FocusState private var focusedMetric: BodyMetric?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Text("Initialize Your Beta Version")
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                        Image(systemName: "person")
                            .font(.system(size: 44))
                            .frame(width: 96, height: 96)
                            .background(AppTheme.gradient, in: Circle())
                            .shadow(color: AppTheme.blue.opacity(0.5), radius: 16)
                        SegmentedPill(values: UnitSystem.allCases, selection: $unitSystem, title: \.title)
                            .frame(maxWidth: 220)
                    }

                    measurementSection(title: "Current Measurements", values: $currentText, required: true)
                    photoSection
                    measurementSection(title: "Target Goals (Optional)", values: $goalText, required: false)

                    if let validationMessage {
                        Label(validationMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.yellow)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button(store.profile == nil ? "Launch Beta Test" : "Save Measurements") {
                        submit()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedMetric = nil }
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker(image: $photoImage)
                    .ignoresSafeArea()
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let bytes = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: bytes) {
                        photoImage = image
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .appScreen()
    }

    private func measurementSection(title: String, values: Binding<[BodyMetric: String]>, required: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title2.bold())
            ForEach(BodyMetric.allCases) { metric in
                HStack(spacing: 14) {
                    Image(systemName: metric.symbol)
                        .foregroundStyle(required ? AppTheme.blue : .yellow)
                        .frame(width: 44, height: 44)
                        .background((required ? AppTheme.blue : .yellow).opacity(0.15), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text(metric.title).font(.caption).foregroundStyle(AppTheme.secondary)
                        TextField(required ? "Required" : "Optional", text: Binding(
                            get: { values.wrappedValue[metric] ?? "" },
                            set: { values.wrappedValue[metric] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .focused($focusedMetric, equals: metric)
                        .accessibilityLabel("\(title), \(metric.title)")
                    }
                    Text(metric == .weight ? unitSystem.weightUnit : unitSystem.lengthUnit)
                        .foregroundStyle(AppTheme.secondary)
                }
                .padding(16)
                .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 22))
                .overlay(RoundedRectangle(cornerRadius: 22).stroke(required ? AppTheme.border : Color.yellow.opacity(0.18)))
            }
        }
    }

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Before Photo (Optional)").font(.title2.bold())
            Panel {
                VStack(spacing: 18) {
                    if let photoImage {
                        Image(uiImage: photoImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        Image(systemName: "photo")
                            .font(.system(size: 54))
                            .foregroundStyle(AppTheme.blue)
                            .frame(height: 110)
                    }
                    Text("Photos are stored only on your device.")
                        .font(.footnote)
                        .foregroundStyle(AppTheme.secondary)
                    HStack {
                        Button { showingCamera = true } label: { Label("Camera", systemImage: "camera") }
                            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                        Spacer()
                        PhotosPicker(selection: $photoItem, matching: .images) {
                            Label("Gallery", systemImage: "photo")
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }

    private func submit() {
        var current = BodyValues()
        var goals = BodyValues()
        for metric in BodyMetric.allCases {
            guard let text = currentText[metric],
                  let value = parsePositive(text) else {
                validationMessage = "Enter a positive value for \(metric.title.lowercased())."
                return
            }
            current[metric] = store.canonicalValue(metric, displayValue: value, system: unitSystem)
            if let text = goalText[metric], !text.isEmpty {
                guard let value = parsePositive(text) else {
                    validationMessage = "The optional \(metric.title.lowercased()) goal must be positive."
                    return
                }
                goals[metric] = store.canonicalValue(metric, displayValue: value, system: unitSystem)
            }
        }

        var profile = UserProfile(unitSystem: unitSystem, starting: current, goals: goals)
        if let photoImage {
            do {
                store.createProfile(profile, firstMeasurement: .init(values: current))
                let filename = try store.savePhoto(photoImage, kind: "before")
                profile.beforePhotoFilename = filename
            } catch {
                store.lastError = error.localizedDescription
            }
        } else {
            store.createProfile(profile, firstMeasurement: .init(values: current))
        }
    }

    private func parsePositive(_ text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value > 0, value < 10_000 else { return nil }
        return value
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
