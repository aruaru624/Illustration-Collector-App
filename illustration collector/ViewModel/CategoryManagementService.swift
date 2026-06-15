//
//  CategoryManagementService.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import Foundation
import SwiftData

@MainActor
class CategoryManagementService {
    
    /// カテゴリを削除し、属していた分析ポイントを「その他」へ移行する関数
    func deleteCategory(_ categoryToDelete: AnalysisCategory, in context: ModelContext) {
        // ⚠️ 「その他」カテゴリ自体は削除させない
        if categoryToDelete.name == "その他" { return }
        
        // 1. 「その他」カテゴリを探す。なければその場で作る
        let fetchDescriptor = FetchDescriptor<AnalysisCategory>(
            predicate: #Predicate { $0.name == "その他" }
        )
        
        let otherCategory: AnalysisCategory
        if let fetched = try? context.fetch(fetchDescriptor).first {
            otherCategory = fetched
        } else {
            // 万が一「その他」がなければ新規作成
            otherCategory = AnalysisCategory(name: "その他", hexColor: "#8E8E93", order: 999)
            context.insert(otherCategory)
        }
        
        // 2. 削除されるカテゴリに属しているすべての分析ポイントを取得
        let pointsToMigrate = categoryToDelete.points
        
        // 3. 安全に引っ越し（リレーションの付け替え）
        for point in pointsToMigrate {
            point.category = otherCategory // 「その他」に所属を変更
            otherCategory.points.append(point)
            
            // 親の参考イラスト（ReferenceNode）の最終更新日も合わせてトリガー
            point.referenceNode?.lastModifiedDate = Date()
        }
        
        // 4. 引っ越しが完了したら、元のカテゴリをデータベースから削除
        context.delete(categoryToDelete)
        
        // 5. データの整合性を保つため、即時保存（iCloudへの同期キューに入れる）
        try? context.save()
    }
}
