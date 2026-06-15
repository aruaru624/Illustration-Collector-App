//
//  HomeView.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//


import SwiftUI
import SwiftData


struct HomeView: View {
    // 💡 シンプルに全件取得するだけ
    @Query(sort: \ArtWork.creationDate, order: .reverse) private var artworks: [ArtWork]
    @Query(sort: \Reference.registrationDate, order: .reverse) private var references: [Reference]
    
    // タブ切り替え用の状態管理（0: 自作イラスト, 1: 参考イラスト）
    @State private var selectionTab: Int = 0
    
    @Environment(\.horizontalSizeClass) var sizeClass
    
    private var columns: [GridItem] {
        let count = (sizeClass == .regular) ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 16), count: count)
    }
    
    var body: some View {
        TabView(selection: $selectionTab) {
            
            // 🎨 【タブ1：アトリエ（自作イラスト全件一覧）】
            NavigationStack {
                ScrollView {
                    // データが空のときの安全処理
                    if artworks.isEmpty {
                        emptyStateView(message: "作品がまだありません")
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(artworks) { artwork in
                                NavigationLink(value: artwork) {
                                    ArtworkGridCard(artwork: artwork)
                                }
                            }
                        }
                        .padding()
                    }
                }
                .navigationTitle("マイアトリエ")
                .background(Color(.systemGroupedBackground).opacity(0.2))
                .navigationDestination(for: ArtWork.self) { artwork in
                    Text("自作詳細画面へ: \(artwork.title)")
                }
            }
            .tabItem {
                Label("アトリエ", systemImage: "paintpalette.fill")
            }
            .tag(0)
            
            // 📚 【タブ2：資料室（参考イラスト全件一覧）】
            NavigationStack {
                ScrollView {
                    // データが空のときの安全処理
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
                        .padding()
                    }
                }
                .navigationTitle("研究資料室")
                .background(Color(.systemGroupedBackground).opacity(0.2))
                .navigationDestination(for: Reference.self) { reference in
                    Text("参考詳細画面へ: \(reference.creatorName)さんの作品")
                }
            }
            .tabItem {
                Label("資料室", systemImage: "books.vertical.fill")
            }
            .tag(1)
        } // ➔ TabViewの終わり
    } 
    
    // 💡 補助関数：データが1件もないときのプレースホルダー表示（bodyの外側へ）
    private func emptyStateView(message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.largeTitle)
                .foregroundColor(.gray)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(minHeight: 300)
    }
}



// MARK: - Preview Support

#Preview {
    // 💡 1. プレビュー用コンテナを完全に独立して作成
    let schema = Schema([
        ArtworkTag.self,
        ArtWork.self,
        Reference.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let context = container.mainContext
    
    // 💡 2. システム画像（SF Symbols）から安全にDataを作る処理
    let defaultImage = UIImage(systemName: "paintpalette")
    let mockImageData: Data = defaultImage?.pngData() ?? Data()
    
    // 💡 3. 自作イラストの作成（★引数を修正後の3つに変更！）
    let art1 = ArtWork(
        title: "初夏のひまわり",
        originalImageData: mockImageData,
        pencilKitData: mockImageData
    )
    
    let art2 = ArtWork(
        title: "ポーズの練習",
        originalImageData: mockImageData,
        pencilKitData: mockImageData
    )
    
    // 💡 4. 参考イラストの作成と配列データの安全な流し込み
    let ref1 = Reference(creatorName: "山田太郎", referenceImageData: mockImageData, analysisKitData: mockImageData)
    let palette1: [String] = ["#FF5733", "#C70039", "#900C3F"]
    ref1.hexColorPalette = palette1
    
    let ref2 = Reference(creatorName: "John Doe", referenceImageData: mockImageData, analysisKitData: mockImageData)
    ref2.hexColorPalette = palette1
    
    // 💡 5. コンテキストへの追加順序を整理
    context.insert(art1)
    context.insert(art2)
    context.insert(ref1)
    context.insert(ref2)
    
    // 💡 6. 最後に確実にコンテナを付与したViewを明示的にreturn
    return HomeView()
        .modelContainer(container)
}
