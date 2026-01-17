//
//  FamilyView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct FamilyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FamilyMember.createdAt) private var familyMembers: [FamilyMember]
    
    @State private var showingAddSheet = false
    @State private var memberToEdit: FamilyMember?
    @State private var showDeleteHaptic = false
    
    var body: some View {
        NavigationStack {
            Group {
                if familyMembers.isEmpty {
                    emptyState
                } else {
                    membersList
                }
            }
            .navigationTitle("Family")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .sensoryFeedback(.impact(weight: .light), trigger: showingAddSheet)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                FamilyMemberFormView(mode: .add)
            }
            .sheet(item: $memberToEdit) { member in
                FamilyMemberFormView(mode: .edit(member))
            }
        }
        .sensoryFeedback(.warning, trigger: showDeleteHaptic)
    }
    
    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Family Members", systemImage: "person.3")
        } description: {
            Text("Add family members to create personalized jet lag schedules for everyone.")
        } actions: {
            Button {
                showingAddSheet = true
            } label: {
                Text("Add Family Member")
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var membersList: some View {
        List {
            ForEach(familyMembers) { member in
                FamilyMemberRow(member: member)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        memberToEdit = member
                    }
            }
            .onDelete(perform: deleteMembers)
        }
        .listStyle(.insetGrouped)
        .animation(.smooth, value: familyMembers.count)
    }
    
    private func deleteMembers(offsets: IndexSet) {
        showDeleteHaptic.toggle()
        withAnimation(.smooth) {
            for index in offsets {
                modelContext.delete(familyMembers[index])
            }
        }
    }
}

struct FamilyMemberRow: View {
    let member: FamilyMember
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: member.ageGroupIcon)
                .font(.title2)
                .foregroundStyle(.secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.name)
                        .font(.headline)
                    
                    // Show work/school badge if has wake constraint
                    if member.hasWakeConstraint {
                        Image(systemName: "briefcase.fill")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                    
                    // Show custom strategy badge
                    if member.usesCustomStrategy, let strategy = member.customStrategy {
                        Image(systemName: strategy.icon)
                            .font(.caption2)
                            .foregroundStyle(strategy.color)
                    }
                }
                
                HStack(spacing: 4) {
                    Text("\(member.age) years old")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if member.usesCustomStrategy, let strategy = member.customStrategy {
                        Text("• \(strategy.displayName)")
                            .font(.caption)
                            .foregroundStyle(strategy.color)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text(member.formattedBedtime)
                        .font(.subheadline)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "sun.horizon.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text(member.formattedWakeTime)
                        .font(.subheadline)
                }
                
                // Show wake-by constraint if enabled
                if member.hasWakeConstraint {
                    HStack(spacing: 4) {
                        Image(systemName: "alarm.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                        Text("by \(member.formattedWakeByTime)")
                            .font(.caption)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FamilyView()
        .modelContainer(for: FamilyMember.self, inMemory: true)
}
