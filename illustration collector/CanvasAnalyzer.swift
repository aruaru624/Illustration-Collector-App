//
//  HomePenRecognizer.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/16.
//


import Foundation
import PencilKit
import Vision

// 抽出した2種類のテキストをまとめる構造体
struct AnalyzedText {
    var reflections: String // 反省（赤）
    var praises: String     // 褒め（青・金）
}

@MainActor
final class CanvasAnalyzer {
    
    // 🔴 赤ペンの判定（色相が0.0付近、または1.0付近のもの）
    static func isReflectionPen(color: UIColor) -> Bool {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return false }
        return (h <= 0.05 || h >= 0.90) && s > 0.4
    }
    
    // 🔵🟡 ほめペンの判定（青・水色・黄色・ゴールド）
    static func isPraisePen(color: UIColor) -> Bool {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard color.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return false }
        let isYellowOrGold = (h >= 0.10 && h <= 0.20) && s > 0.3
        let isBlue = (h >= 0.50 && h <= 0.70) && s > 0.3
        return isYellowOrGold || isBlue
    }
    
    /// 💡 キャンバス全体から赤と青/金の文字を同時に解析する
    static func analyzeLiveText(from drawing: PKDrawing) async -> AnalyzedText {
        // 1. ストロークを色ごとに2つのグループに分ける
        let reflectionStrokes = drawing.strokes.filter { isReflectionPen(color: $0.ink.color) }
        let praiseStrokes = drawing.strokes.filter { isPraisePen(color: $0.ink.color) }
        
        // 2. 2つのOCRタスクを「同時に（並列で）」走らせて超高速化
        async let refText = recognize(strokes: reflectionStrokes)
        async let praiseText = recognize(strokes: praiseStrokes)
        
        return await AnalyzedText(reflections: refText, praises: praiseText)
    }
    
    // 共通のOCR処理関数
    private static func recognize(strokes: [PKStroke]) async -> String {
        guard !strokes.isEmpty else { return "" }
        let strokeDrawing = PKDrawing(strokes: strokes)
        
        // 文字の周りを少し余裕を持たせて切り抜く
        let imageRect = strokeDrawing.bounds.insetBy(dx: -20, dy: -20)
        guard imageRect.width > 0 && imageRect.height > 0 else { return "" }
        
        // 3倍の高画質でレンダリング
        let strokeImage = strokeDrawing.image(from: imageRect, scale: 3.0)
        
        return await withCheckedContinuation { continuation in
            guard let cgImage = strokeImage.cgImage else {
                continuation.resume(returning: "")
                return
            }
            
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: "")
                    return
                }
                
                let strings = observations.compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: strings.joined(separator: "\n"))
            }
            
            request.recognitionLanguages = ["ja-JP", "en-US"]
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                try? handler.perform([request])
            }
        }
    }
}
