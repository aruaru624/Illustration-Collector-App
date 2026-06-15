//
//  ArtWork.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import Foundation
import SwiftData

@Model
final class ArtworkNode {
    @Attribute(.unique) var id: UUID // IDをユニークキーに指定
    var title: String
    var creationDate: Date //これは入力可、一旦自動書き込み
    var lastModifiedDate: Date //自動書き込みにする
    
    
    // 大容量データ（画像など）は、メモリを圧迫しないよう外部保存（External Storage）を指定
    @Attribute(.externalStorage) var originalImageData: Data
    @Attribute(.externalStorage) var pencilKitData: Data
    
    var artworkType: String
    
    var regrets: [String] //反省
    var achievements: [String] //褒め
    var notes: String //メモ
    
    // カラーパレット（手動スポイトした16進数カラーコード [#FFFFFF] の配列）
    var hexColorPalette: [String]
    
    var relatedReferenceID: [UUID]? //参考イラスト
    
    init(title: String, originalImageData: Data, pencilKitData: Data, artworkType: String) {
        self.id = UUID()
        self.title = title
        self.creationDate = Date()
        self.lastModifiedDate = Date()
        self.originalImageData = originalImageData
        self.pencilKitData = pencilKitData
        self.artworkType = artworkType
        self.hexColorPalette = []
        self.regrets = []
        self.achievements = []
        self.notes = ""
    }

    
}
