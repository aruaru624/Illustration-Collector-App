//
//  HomeView.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/16.
//

import SwiftUI
import SwiftData
import PhotosUI // 💡 追加

struct HomeView: View {
    @Query(sort: \ArtWork.creationDate, order: .reverse) private var artworks: [ArtWork]
    @Query(sort: \Reference.registrationDate, order: .reverse) private var references: [Reference]
    
    @State private var selectionTab: Int = 0
    @Environment(\.horizontalSizeClass) var sizeClass
    
    // シートとダイアログの表示管理
    @State private var isShowingSelectionDialog = false
    @State private var isShowingAddArtworkSheet = false
    @State private var selectedArtworkForEdit: ArtWork? = nil
    
    // 💡 画像を「先選び」するための状態管理
    @State private var isShowingPhotoPicker = false
    @State private var newSelectedPhotoItem: PhotosPickerItem? = nil
    @State private var preloadedNewImage: UIImage? = nil
    
    private var columns: [GridItem] {
        let count = (sizeClass == .regular) ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            TabView(selection: $selectionTab) {
                // 🎨 【アトリエ】
                NavigationStack {
                    ScrollView {
                        if artworks.isEmpty {
                            emptyStateView(message: "作品がまだありません")
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(artworks) { artwork in
                                    Button {
                                        selectedArtworkForEdit = artwork
                                    } label: {
                                        ArtworkGridCard(artwork: artwork)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .navigationTitle("マイアトリエ")
                    .background(Color(.systemGroupedBackground).opacity(0.2))
                }
                .tabItem { Image(systemName: selectionTab == 0 ? "paintpalette.fill" : "paintpalette") }
                .tag(0)
                
                // 📚 【資料室】
                NavigationStack {
                    ScrollView {
                        if references.isEmpty {
                            emptyStateView(message: "参考資料がまだありません")
                        } else {
                            LazyVGrid(columns: columns, spacing: 20) {
                                ForEach(references) { reference in
                                    NavigationLink(value: reference) {
                                        ReferenceGridCard(reference: reference)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .navigationTitle("研究資料室")
                    .background(Color(.systemGroupedBackground).opacity(0.2))
                }
                .tabItem { Image(systemName: selectionTab == 1 ? "books.vertical.fill" : "books.vertical") }
                .tag(1)
            }
            
            floatingAddButton
        }
        .confirmationDialog("新規ノート作成", isPresented: $isShowingSelectionDialog, titleVisibility: .visible) {
            Button("🎨 自分のイラストを追加・添削") {
                // 💡 シートを開く前に、まずはフォトピッカーを起動する！
                isShowingPhotoPicker = true
            }
            Button("📚 神絵師の参考資料を追加") {
                // TODO: 後ほど
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("どちらのノートを新しく作成しますか？")
        }
        
        // 💡 隠しフォトピッカー：フラグがtrueになると画面に覆いかぶさって表示される
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $newSelectedPhotoItem, matching: .images)
        // 💡 ピッカーで画像が選ばれた瞬間の処理
        .onChange(of: newSelectedPhotoItem) { _, newItem in
            if let newItem = newItem {
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            // 画像を保持して、いざ編集画面をフルスクリーンで開く！
                            preloadedNewImage = uiImage
                            isShowingAddArtworkSheet = true
                            newSelectedPhotoItem = nil // リセット
                        }
                    }
                }
            }
        }
        
        // 💡 .sheet を .fullScreenCover に変更！（これでiPadの画面幅が正常に認識されます）
        .fullScreenCover(isPresented: $isShowingAddArtworkSheet) {
            // 新規のときは先選びした画像を渡す
            EditArtworkView(artwork: nil, initialImage: preloadedNewImage)
        }
        .fullScreenCover(item: $selectedArtworkForEdit) { artwork in
            // 編集のときは既存のデータを渡す
            EditArtworkView(artwork: artwork, initialImage: nil)
        }
    }
    
    private var floatingAddButton: some View {
        Button {
            isShowingSelectionDialog = true
        } label: {
            ZStack {
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.85)]), startPoint: .top, endPoint: .bottom))
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                Image(systemName: "plus").font(.system(size: 24, weight: .semibold)).foregroundColor(.white)
            }
        }
        .padding(.trailing, 20).padding(.bottom, 76)
    }
    
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled").font(.largeTitle).foregroundColor(.gray)
            Text(message).font(.subheadline).foregroundColor(.secondary)
            Spacer()
        }
        .frame(minHeight: 300)
    }
}
