//
//  ReferenceGridCard.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import SwiftUI

// MARK: - 参考イラスト用のグリッドカード
struct ReferenceGridCard: View {
    let reference: Reference
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 📸 参考イラスト画像エリア
            ZStack(alignment: .topTrailing) {
                // 💡 安全対策：Dataが空っぽではない場合のみUIImageのデコードを試みる
                if !reference.referenceImageData.isEmpty, let uiImage = UIImage(data: reference.referenceImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // 安全なプレースホルダー
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 160)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
            }
            
            // 📝 テキスト＆カラーパレット情報
            VStack(alignment: .leading, spacing: 6) {
                Text("\(reference.creatorName) 氏")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // 🎨 スポイトしたカラーパレットの並び表示
                if !reference.hexColorPalette.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(reference.hexColorPalette.prefix(5), id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                                )
                        }
                        
                        if reference.hexColorPalette.count > 5 {
                            Text("+\(reference.hexColorPalette.count - 5)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                } else {
                    Text("パレット未登録")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(height: 16)
                }
                
                // 分析ノートの蓄積数をバッジ表示
                HStack(spacing: 4) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.caption2)
                    Text("\(reference.points.count) 個の分析")
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
