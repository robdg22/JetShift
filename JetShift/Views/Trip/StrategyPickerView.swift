//
//  StrategyPickerView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI

struct StrategyPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var selectedStrategy: TripStrategy
    let daysAtDestination: Int
    let timezoneOffset: Int
    let familyMembers: [FamilyMember]
    
    @State private var selectionChanged = false
    
    private var recommendedStrategy: TripStrategy {
        TripRecommendationEngine.recommendStrategy(
            daysAtDestination: daysAtDestination,
            timezoneOffset: timezoneOffset,
            familyMembers: familyMembers
        )
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Context banner
                    contextBanner
                        .padding(.horizontal)
                    
                    // Strategy cards
                    ForEach(TripStrategy.allMainTypes, id: \.self) { strategy in
                        StrategyCard(
                            strategy: strategy,
                            isSelected: strategiesMatch(selectedStrategy, strategy),
                            isRecommended: strategiesMatch(recommendedStrategy, strategy),
                            daysAtDestination: daysAtDestination,
                            timezoneOffset: timezoneOffset
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedStrategy = strategy
                                selectionChanged.toggle()
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Partial adjustment slider
                    if case .partialAdjustment = selectedStrategy {
                        partialAdjustmentSlider
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Choose Strategy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sensoryFeedback(.selection, trigger: selectionChanged)
    }
    
    private var contextBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(daysAtDestination) days • \(abs(timezoneOffset)) hour \(timezoneOffset > 0 ? "east" : "west")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !familyMembers.isEmpty {
                    let ages = familyMembers.map { "\($0.age)y" }.joined(separator: ", ")
                    Text("Family: \(ages)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var partialAdjustmentSlider: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adjustment Level")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if case .partialAdjustment(let percentage) = selectedStrategy {
                HStack {
                    Text("50%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { percentage },
                            set: { selectedStrategy = .partialAdjustment(percentage: $0) }
                        ),
                        in: 0.5...0.8,
                        step: 0.1
                    )
                    
                    Text("80%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text("Current: \(Int(percentage * 100))% adjustment")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func strategiesMatch(_ a: TripStrategy, _ b: TripStrategy) -> Bool {
        switch (a, b) {
        case (.fullAdjustment, .fullAdjustment):
            return true
        case (.partialAdjustment, .partialAdjustment):
            return true
        case (.minimizeTotal, .minimizeTotal):
            return true
        case (.noAdjustment, .noAdjustment):
            return true
        default:
            return false
        }
    }
}

struct StrategyCard: View {
    let strategy: TripStrategy
    let isSelected: Bool
    let isRecommended: Bool
    let daysAtDestination: Int
    let timezoneOffset: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Image(systemName: strategy.icon)
                        .font(.title2)
                        .foregroundStyle(strategy.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(strategy.displayName)
                                .font(.headline)
                                .foregroundStyle(.primary)
                            
                            if isRecommended {
                                Text("Recommended")
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.green)
                                    .foregroundStyle(.white)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(strategy.shortDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isSelected ? strategy.color : .secondary)
                }
                
                Divider()
                
                // Pros
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(strategy.pros.prefix(2), id: \.self) { pro in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundStyle(.green)
                            Text(pro)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Cons
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(strategy.cons.prefix(1), id: \.self) { con in
                        HStack(spacing: 6) {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundStyle(.red)
                            Text(con)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(strategy.color, lineWidth: 2)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StrategyPickerView(
        selectedStrategy: .constant(.partialAdjustment(percentage: 0.6)),
        daysAtDestination: 7,
        timezoneOffset: 5,
        familyMembers: []
    )
}
