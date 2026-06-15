//
//  AnalysisPoints.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import Foundation
import SwiftData

@Model
final class AnalysisPoint {
    @Attribute(.unique) var id: UUID
    var text: String              // 分析したテキスト内容
    
    // ★ どのカテゴリに属しているかのリレーション（オプショナル型にして安全性を確保）
    var category: AnalysisCategory?
    
    // 親となる参考イラスト（ReferenceNode）への逆参照
    var referenceNode: Reference?
    
    init(text: String, category: AnalysisCategory? = nil) {
        self.id = UUID()
        self.text = text
        self.category = category
    }
}
