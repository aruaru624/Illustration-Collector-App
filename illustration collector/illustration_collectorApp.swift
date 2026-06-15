//
//  illustration_collectorApp.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/14.
//

import SwiftUI
import SwiftData // 💡 SwiftDataをインポート

@main
struct illustration_collectorApp: App {
    
    // 💡 アプリ全体で共有する本番用のデータベースコンテナ（箱）を作成
    let sharedModelContainer: ModelContainer = {
        // 保存したいモデル（テーブル構造）のスキーマを定義
        let schema = Schema([
            ArtworkTag.self,
            ArtWork.self,
            Reference.self
        ])
        // 本番用なので、デバイスのストレージに永続保存する設定（デフォルト）
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
                // 💡 アプリのルート画面（HomeView）に対して、作ったコンテナを注入する
                .modelContainer(sharedModelContainer)
        }
    }
}
