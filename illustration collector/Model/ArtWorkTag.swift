//
//  ArtWorkTag.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import Foundation
import SwiftData

@Model
final class ArtworkTag {
    @Attribute(.unique) var id: UUID
    var name: String          // ユーザーが決めたタグ名（例：「厚塗り」「水彩風」）
    var registrationDate: Date // タグを作った日
    
    // 💡 リレーション：このタグが付けられている自作イラストたち
    @Relationship(inverse: \ArtWork.tags)
    var artworks: [ArtWork]
    
    init(name: String) {
        self.id = UUID()
        self.name = name
        self.registrationDate = Date()
        self.artworks = []
    }
}
