//
//  AnimatedTabView.swift
//  JetShift
//
//  Created by Rob Graham on 19/01/2026.
//

import SwiftUI

/// Helper view to extract UIImageViews from the TabBar for animations
struct ExtractTabBarImageViews: UIViewRepresentable {
    var result: ([Int: UIImageView]) -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            extractImageViews(from: view)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            extractImageViews(from: uiView)
        }
    }
    
    private func extractImageViews(from view: UIView) {
        guard let tabBar = findTabBar(from: view) else { return }
        
        var imageViews: [Int: UIImageView] = [:]
        
        // Get all tab bar buttons and their image views
        let buttons = tabBar.subviews
            .filter { String(describing: type(of: $0)).contains("Button") }
            .sorted { $0.frame.minX < $1.frame.minX }
        
        for (index, button) in buttons.enumerated() {
            if let imageView = findImageView(in: button) {
                imageViews[index] = imageView
            }
        }
        
        if !imageViews.isEmpty {
            result(imageViews)
        }
    }
    
    private func findTabBar(from view: UIView) -> UITabBar? {
        if let tabBar = view as? UITabBar {
            return tabBar
        }
        
        if let superview = view.superview {
            return findTabBar(from: superview)
        }
        
        // Try to find it in the window
        if let window = view.window {
            return findTabBarInHierarchy(window)
        }
        
        return nil
    }
    
    private func findTabBarInHierarchy(_ view: UIView) -> UITabBar? {
        if let tabBar = view as? UITabBar {
            return tabBar
        }
        
        for subview in view.subviews {
            if let tabBar = findTabBarInHierarchy(subview) {
                return tabBar
            }
        }
        
        return nil
    }
    
    private func findImageView(in view: UIView) -> UIImageView? {
        if let imageView = view as? UIImageView,
           imageView.image != nil {
            return imageView
        }
        
        for subview in view.subviews {
            if let imageView = findImageView(in: subview) {
                return imageView
            }
        }
        
        return nil
    }
}
