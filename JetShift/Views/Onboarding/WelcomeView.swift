//
//  WelcomeView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI

struct WelcomeView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showDescription = false
    @State private var showButton = false
    @State private var didTapGetStarted = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.2),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App icon
                VStack(spacing: 16) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                        .symbolEffect(.bounce, value: showIcon)
                        .scaleEffect(showIcon ? 1 : 0.5)
                        .opacity(showIcon ? 1 : 0)
                    
                    Text("JetShift")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .scaleEffect(showIcon ? 1 : 0.8)
                        .opacity(showIcon ? 1 : 0)
                }
                
                // Title and description
                VStack(spacing: 12) {
                    Text("Help your family beat jet lag")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .opacity(showTitle ? 1 : 0)
                        .offset(y: showTitle ? 0 : 20)
                    
                    Text("Create personalized sleep adjustment schedules for every family member based on your travel plans.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(showDescription ? 1 : 0)
                        .offset(y: showDescription ? 0 : 20)
                }
                
                Spacer()
                
                // Features list
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "person.3.fill",
                        title: "Family Profiles",
                        description: "Age-specific schedules for everyone"
                    )
                    .opacity(showDescription ? 1 : 0)
                    .offset(x: showDescription ? 0 : -20)
                    
                    FeatureRow(
                        icon: "clock.arrow.circlepath",
                        title: "Gradual Adjustment",
                        description: "Gentle daily sleep shifts"
                    )
                    .opacity(showDescription ? 1 : 0)
                    .offset(x: showDescription ? 0 : -20)
                    
                    FeatureRow(
                        icon: "calendar",
                        title: "Visual Timeline",
                        description: "Easy-to-follow 6-day plan"
                    )
                    .opacity(showDescription ? 1 : 0)
                    .offset(x: showDescription ? 0 : -20)
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Get Started button
                Button {
                    didTapGetStarted = true
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
                .scaleEffect(showButton ? 1 : 0.9)
                .opacity(showButton ? 1 : 0)
                .sensoryFeedback(.success, trigger: didTapGetStarted)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
            showIcon = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            showTitle = true
        }
        
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            showDescription = true
        }
        
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.0)) {
            showButton = true
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    WelcomeView(hasCompletedOnboarding: .constant(false))
}
