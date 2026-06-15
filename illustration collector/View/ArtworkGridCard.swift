//
//  ArtworkGridCard.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//


import SwiftUI

// MARK: - 自作イラスト用のグリッドカード
struct ArtworkGridCard: View {
    let artwork: ArtWork
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 📸 イラスト画像エリア
            ZStack(alignment: .bottomTrailing) {
                // 💡 安全対策：Dataが空っぽではない場合のみUIImageのデコードを試みる
                if !artwork.originalImageData.isEmpty, let uiImage = UIImage(data: artwork.originalImageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    // 画像データが無い、または空（プレビュー時など）の安全なプレースホルダー
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
            
            // 📝 テキスト情報エリア
            VStack(alignment: .leading, spacing: 4) {
                Text(artwork.title.isEmpty ? "無題の作品" : artwork.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                HStack {
                    // 描いた日
                    Text(artwork.creationDate, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // タグの1つ目を表示
                    if let firstTag = artwork.tags.first {
                        Text(firstTag.name)
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.indigo.opacity(0.1))
                            .foregroundColor(.indigo)
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}
