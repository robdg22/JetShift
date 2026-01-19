//
//  AnimatedTabView.swift
//  JetShift
//
//  Created by Rob Graham on 19/01/2026.
//

import SwiftUI

/// Helper view to extract UIImageViews from the TabBar for animations
/// Based on the technique of traversing the tab bar view hierarchy to find UIImageViews
struct ExtractTabBarImageViews: UIViewRepresentable {
    var result: ([Int: UIImageView]) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = HelperView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        view.onWindowAttach = { [result] in
            Self.extractImageViews(from: view, completion: result)
        }
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        Self.extractImageViews(from: uiView, completion: result)
    }
    
    private static func extractImageViews(from view: UIView, completion: @escaping ([Int: UIImageView]) -> Void) {
        // Try multiple times with increasing delays
        let delays: [Double] = [0.1, 0.3, 0.5, 1.0]
        
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                guard let window = view.window else { return }
                guard let tabBar = findTabBar(in: window) else { return }
                
                var imageViews: [Int: UIImageView] = [:]
                
                // Find all tab bar item views
                let tabBarButtons = tabBar.subviews
                    .filter { isTabBarButton($0) }
                    .sorted { $0.frame.midX < $1.frame.midX }
                
                for (index, button) in tabBarButtons.enumerated() {
                    if let imageView = findFirstImageView(in: button) {
                        imageViews[index] = imageView
                    }
                }
                
                if !imageViews.isEmpty {
                    completion(imageViews)
                }
            }
        }
    }
    
    /// Check if a view is a tab bar button
    private static func isTabBarButton(_ view: UIView) -> Bool {
        let className = String(describing: type(of: view))
        return className.contains("Button") || view is UIControl
    }
    
    /// Recursively search for UITabBar in view hierarchy
    private static func findTabBar(in view: UIView) -> UITabBar? {
        if let tabBar = view as? UITabBar {
            return tabBar
        }
        
        for subview in view.subviews {
            if let tabBar = findTabBar(in: subview) {
                return tabBar
            }
        }
        
        return nil
    }
    
    /// Find the first UIImageView in the view hierarchy
    private static func findFirstImageView(in view: UIView) -> UIImageView? {
        for subview in view.subviews {
            if let imageView = subview as? UIImageView, imageView.image != nil {
                return imageView
            }
            
            if let imageView = findFirstImageView(in: subview) {
                return imageView
            }
        }
        
        return nil
    }
    
    /// Helper UIView that notifies when it's attached to a window
    private class HelperView: UIView {
        var onWindowAttach: (() -> Void)?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            if window != nil {
                onWindowAttach?()
            }
        }
    }
}
