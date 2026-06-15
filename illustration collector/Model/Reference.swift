//
//  Reference.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import Foundation
import SwiftData

@Model 
final class ReferenceNode {
    @Attribute(.unique) var id: UUID // IDをユニークキーに指定（マルチデバイスでの重複防止）
    var creatorName: String          // 描いた人（神絵師の名前など）
    var referenceUrlString: String?   // 参考資料のSNSやWebサイトのURL
    var registrationDate: Date       // クリップした日
    var lastModifiedDate: Date //自動書き込みにする
    
    // 大容量データ（画像、PencilKit）は、iCloud同期のパフォーマンスを落とさないよう外部保存を指定
    @Attribute(.externalStorage) var referenceImageData: Data
    @Attribute(.externalStorage) var analysisKitData: Data
    
    // カラーパレット（手動スポイトした16進数カラーコード [#FFFFFF] の配列）
    var hexColorPalette: [String]
    
    // 分析テキスト（カラーペンごとに自動分類されたテキストリスト）
    var Points: [String]
    
    // 初期化（イニシャライザ）
    init(creatorName: String, referenceImageData: Data, analysisKitData: Data, referenceUrlString: String? = nil) {
        self.id = UUID()
        self.creatorName = creatorName
        self.referenceUrlString = referenceUrlString
        self.registrationDate = Date()
        self.lastModifiedDate = Date()
        self.referenceImageData = referenceImageData
        self.analysisKitData = analysisKitData
        self.hexColorPalette = []
        self.Points = []
    }
    
}
