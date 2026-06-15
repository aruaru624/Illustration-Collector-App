//
//  DrawingCanvas.swift
//  illustration collector
//
//  Created by tanaka niko on 2026/06/15.
//

import SwiftUI
import PencilKit

struct DrawingCanvas: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let bgImage: UIImage?
    
    // 💡 リアルタイムに線が更新されたことをEditViewに伝えるためのクロージャーを追加
    var onDrawingChanged: (() -> Void)? = nil

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        
        // 💡 自身をデリゲートに設定
        canvasView.delegate = context.coordinator
        
        if let image = bgImage {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            canvasView.insertSubview(imageView, at: 0)
            
            if let drawingView = canvasView.subviews.first(where: { type(of: $0).description().contains("Canvas") }) {
                canvasView.bringSubviewToFront(drawingView)
            }
            context.coordinator.imageView = imageView
        }
        
        canvasView.isScrollEnabled = false
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // 更新時にクロージャーをコーディネーターに同期しておく
        context.coordinator.onDrawingChanged = onDrawingChanged
        
        DispatchQueue.main.async {
            if let imageView = context.coordinator.imageView {
                imageView.frame = uiView.bounds
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // 💡 PencilKitの動きを監視するコ・オーディネータークラス
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var imageView: UIImageView?
        var onDrawingChanged: (() -> Void)?
        
        // ★【重要】ユーザーがペンを離して、1本の線（ストローク）が描き終わった瞬間にOSが自動で呼び出す関数
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // EditView側のリアルタイム処理を起こす
            onDrawingChanged?()
        }
    }
}
