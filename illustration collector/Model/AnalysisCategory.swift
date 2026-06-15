//
//  AnalysisCategory.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import Foundation
import SwiftData

@Model
final class AnalysisCategory {
    @Attribute(.unique) var id: UUID
    var name: String          // ユーザーが決めた分類名（例：「エフェクト」「背景」）
    var hexColor: String      // 分類に対応するペンの色（16進数コード）
    var order: Int            // 画面に並べる順番
    
    // 💡 リレーション：このカテゴリに属する分析ポイントたち　（消えたら何もしない）
    @Relationship(deleteRule: .noAction, inverse: \AnalysisPoint.category)
    var points: [AnalysisPoint]
    
    init(name: String, hexColor: String, order: Int) {
        self.id = UUID()
        self.name = name
        self.hexColor = hexColor
        self.order = order
        self.points = []
    }
}
