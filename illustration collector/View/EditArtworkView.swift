//
//  EditArtworkView.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/16.
//

import SwiftUI
import SwiftData
import PencilKit

struct EditArtworkView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let artworkToEdit: ArtWork?
    
    @State private var title: String = ""
    @State private var selectedUIImage: UIImage? = nil
    @State private var notes: String = ""
    
    // ✨ 新しいリアルタイム抽出の状態管理（赤と青で分ける）
    @State private var extractedReflections: String = "" // 赤（反省）
    @State private var extractedPraises: String = ""     // 青・金（褒め）
    @State private var isAnalyzing: Bool = false
    
    @State private var canvasView = PKCanvasView()
    @State private var toolPicker = PKToolPicker()
    @State private var isShowingTextLayer = true
    
    @State private var isShowingNoteModalForPhone = false
    @State private var ocrTask: Task<Void, Never>? = nil
    
    init(artwork: ArtWork? = nil, initialImage: UIImage? = nil) {
        self.artworkToEdit = artwork
        if let artwork = artwork {
            _title = State(initialValue: artwork.title)
            _notes = State(initialValue: artwork.notes)
            
            // 💡 データベースから過去の赤ペン・青ペンの結果を復元
            _extractedReflections = State(initialValue: artwork.regrets.joined(separator: "\n"))
            _extractedPraises = State(initialValue: artwork.achievements.joined(separator: "\n"))
            
            if !artwork.originalImageData.isEmpty, let uiImage = UIImage(data: artwork.originalImageData) {
                _selectedUIImage = State(initialValue: uiImage)
            }
        } else if let initialImage = initialImage {
            _selectedUIImage = State(initialValue: initialImage)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if horizontalSizeClass == .regular {
                    HStack(spacing: 0) {
                        leftCanvasArea.ignoresSafeArea()
                        Divider()
                        VStack(spacing: 0) {
                            HStack {
                                Button("キャンセル", role: .cancel) { dismiss() }.foregroundColor(.red)
                                Spacer()
                                Text(title.isEmpty ? "添削ノート" : title).font(.headline).lineLimit(1)
                                Spacer()
                                Button("保存") { saveOrUpdateArtwork() }.bold()
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            
                            Divider()
                            rightNotePanelArea
                        }
                        .frame(width: 360)
                        .background(Color(.systemGroupedBackground))
                    }
                    .toolbar(.hidden, for: .navigationBar)
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        leftCanvasArea.ignoresSafeArea(edges: .bottom)
                        
                        Button {
                            isShowingNoteModalForPhone = true
                        } label: {
                            ZStack {
                                Image(systemName: "pencil.and.list.clipboard")
                                    .font(.title2).foregroundColor(.white)
                                if isAnalyzing {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(1.2)
                                }
                            }
                            .padding(18).background(Color.accentColor).clipShape(Circle()).shadow(radius: 6)
                        }
                        .padding(24)
                    }
                    .navigationTitle(title.isEmpty ? "添削ノート" : title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                        ToolbarItem(placement: .confirmationAction) { Button("保存") { saveOrUpdateArtwork() } }
                    }
                }
            }
            .onAppear { setupPencilKit() }
            .sheet(isPresented: $isShowingNoteModalForPhone) {
                NavigationStack {
                    rightNotePanelArea
                        .navigationTitle("研究ノート")
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("完了") { isShowingNoteModalForPhone = false } } }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    private var leftCanvasArea: some View {
        ZStack {
            Color(.systemGray6)
            if let uiImage = selectedUIImage {
                Image(uiImage: uiImage)
                    .resizable().scaledToFit()
                    .overlay {
                        DrawingCanvas(canvasView: $canvasView, bgImage: nil, onDrawingChanged: {
                            triggerLiveOCR()
                        })
                        .opacity(isShowingTextLayer ? 1.0 : 0.0)
                    }
                    .padding(horizontalSizeClass == .regular ? 40 : 20)
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
                
                VStack {
                    Spacer()
                    HStack {
                        Toggle(isOn: $isShowingTextLayer) {
                            Label("添削レイヤー", systemImage: isShowingTextLayer ? "eye.fill" : "eye.slash.fill")
                                .font(.caption).bold()
                        }
                        .toggleStyle(.button).padding(12).background(Color(.systemBackground).opacity(0.9)).cornerRadius(8).shadow(radius: 2)
                        Spacer()
                    }
                    .padding(24)
                }
            }
        }
    }
    
    private var rightNotePanelArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // ℹ️ 基本設定
                VStack(alignment: .leading, spacing: 12) {
                    TextField("作品名を入力", text: $title).font(.headline).textFieldStyle(.roundedBorder)
                    HStack { Text("描いた日"); Spacer(); Text(artworkToEdit?.creationDate ?? Date(), style: .date).foregroundColor(.secondary) }.font(.subheadline)
                }
                .padding().background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
                
                HStack {
                    Text("研究ノート").font(.headline)
                    Spacer()
                    if isAnalyzing { ProgressView().scaleEffect(0.8) }
                }
                
                // 🔴 【反省点（赤ペン抽出）】
                VStack(alignment: .leading, spacing: 8) {
                    Label("改善点・反省", systemImage: "exclamationmark.triangle.fill")
                        .font(.subheadline).bold().foregroundColor(.red)
                    
                    if extractedReflections.isEmpty {
                        Text("キャンバスに赤ペンで書き込むと、ここに自動でリスト化されます。")
                            .font(.caption2).foregroundColor(.gray).padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(extractedReflections.components(separatedBy: "\n"), id: \.self) { line in
                                if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("・").foregroundColor(.red).bold()
                                        Text(line).font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Color.red.opacity(0.05)).cornerRadius(8)
                    }
                }
                .padding().background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
                
                // 🔵 【頑張ったところ（青・金ペン抽出）】
                VStack(alignment: .leading, spacing: 8) {
                    Label("上手く描けたところ", systemImage: "star.fill")
                        .font(.subheadline).bold().foregroundColor(.blue)
                    
                    if extractedPraises.isEmpty {
                        Text("青やゴールドのペンで書き込むと、ここに自動でリスト化されます。")
                            .font(.caption2).foregroundColor(.gray).padding(.vertical, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(extractedPraises.components(separatedBy: "\n"), id: \.self) { line in
                                if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    HStack(alignment: .top, spacing: 6) {
                                        Text("✨").font(.caption)
                                        Text(line).font(.subheadline)
                                    }
                                }
                            }
                        }
                        .padding(10).frame(maxWidth: .infinity, alignment: .leading).background(Color.blue.opacity(0.05)).cornerRadius(8)
                    }
                }
                .padding().background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
                
                // 📝 自由入力メモ
                VStack(alignment: .leading, spacing: 8) {
                    Text("その他メモ").font(.subheadline).bold()
                    TextEditor(text: $notes)
                        .frame(minHeight: 80).padding(4).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(.systemGray4), lineWidth: 1))
                }
                .padding().background(Color(.secondarySystemGroupedBackground)).cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - 🛠️ ロジック
    private func triggerLiveOCR() {
        ocrTask?.cancel()
        ocrTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            
            await MainActor.run { isAnalyzing = true }
            
            // 💡 新しい CanvasAnalyzer で赤と青を同時解析！
            let currentDrawing = canvasView.drawing
            let result = await CanvasAnalyzer.analyzeLiveText(from: currentDrawing)
            
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.extractedReflections = result.reflections
                self.extractedPraises = result.praises
                self.isAnalyzing = false
            }
        }
    }
    
    private func setupPencilKit() {
        toolPicker.addObserver(canvasView)
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
        if let artwork = artworkToEdit, let drawing = try? PKDrawing(data: artwork.pencilKitData) {
            canvasView.drawing = drawing
            triggerLiveOCR()
        }
    }
    
    private func saveOrUpdateArtwork() {
        guard let uiImage = selectedUIImage, let imageData = uiImage.pngData() else { return }
        let pencilData = canvasView.drawing.dataRepresentation()
        
        let regretsArray = extractedReflections.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let achievementsArray = extractedPraises.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        
        if let existingArtwork = artworkToEdit {
            existingArtwork.title = title.isEmpty ? "無題の作品" : title
            existingArtwork.notes = notes
            existingArtwork.regrets = regretsArray         // 🔴 保存
            existingArtwork.achievements = achievementsArray // 🔵 保存
            existingArtwork.pencilKitData = pencilData
            existingArtwork.lastModifiedDate = Date()
        } else {
            let newArtwork = ArtWork(title: title.isEmpty ? "無題の作品" : title, originalImageData: imageData, pencilKitData: pencilData)
            newArtwork.notes = notes
            newArtwork.regrets = regretsArray         // 🔴 保存
            newArtwork.achievements = achievementsArray // 🔵 保存
            modelContext.insert(newArtwork)
        }
        dismiss()
    }
}
