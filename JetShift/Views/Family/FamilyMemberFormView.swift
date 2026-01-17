//
//  FamilyMemberFormView.swift
//  JetShift
//
//  Created by Rob Graham on 17/01/2026.
//

import SwiftUI
import SwiftData

struct FamilyMemberFormView: View {
    enum Mode {
        case add
        case edit(FamilyMember)
        
        var title: String {
            switch self {
            case .add: return "Add Family Member"
            case .edit: return "Edit Family Member"
            }
        }
        
        var buttonTitle: String {
            switch self {
            case .add: return "Add Member"
            case .edit: return "Save Changes"
            }
        }
    }
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: Mode
    
    @State private var name: String = ""
    @State private var age: Int = 30
    @State private var bedtime: Date = Date()
    @State private var wakeTime: Date = Date()
    @State private var hasWakeConstraint: Bool = true
    @State private var wakeByTime: Date = Date()
    
    @State private var showValidationError = false
    @State private var didSave = false
    
    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && age >= 0 && age <= 120
    }
    
    init(mode: Mode) {
        self.mode = mode
        
        if case .edit(let member) = mode {
            _name = State(initialValue: member.name)
            _age = State(initialValue: member.age)
            _bedtime = State(initialValue: member.currentBedtime)
            _wakeTime = State(initialValue: member.currentWakeTime)
            _hasWakeConstraint = State(initialValue: member.hasWakeConstraint)
            _wakeByTime = State(initialValue: member.wakeByTime)
        } else {
            _bedtime = State(initialValue: FamilyMember.suggestedBedtime(for: 30))
            _wakeTime = State(initialValue: FamilyMember.suggestedWakeTime(for: 30))
            _wakeByTime = State(initialValue: FamilyMember.defaultWakeByTime(for: 30))
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    Picker("Age", selection: $age) {
                        ForEach(0...120, id: \.self) { age in
                            Text("\(age) years").tag(age)
                        }
                    }
                    .onChange(of: age) { oldValue, newValue in
                        // Only update suggested times when adding, not editing
                        if case .add = mode {
                            withAnimation(.smooth) {
                                bedtime = FamilyMember.suggestedBedtime(for: newValue)
                                wakeTime = FamilyMember.suggestedWakeTime(for: newValue)
                                wakeByTime = FamilyMember.defaultWakeByTime(for: newValue)
                            }
                        }
                    }
                }
                
                Section("Sleep Schedule") {
                    DatePicker(
                        "Bedtime",
                        selection: $bedtime,
                        displayedComponents: .hourAndMinute
                    )
                    
                    DatePicker(
                        "Wake Time",
                        selection: $wakeTime,
                        displayedComponents: .hourAndMinute
                    )
                }
                
                Section {
                    Toggle("Has Work/School Schedule", isOn: $hasWakeConstraint.animation(.smooth))
                    
                    if hasWakeConstraint {
                        DatePicker(
                            "Must Wake By",
                            selection: $wakeByTime,
                            displayedComponents: .hourAndMinute
                        )
                        
                        Text("Schedule adjustments before and after the trip will respect this wake time constraint.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Wake Constraint")
                } footer: {
                    if !hasWakeConstraint {
                        Text("Enable if this person has work or school that requires waking by a certain time.")
                    }
                }
                
                Section {
                    Text("Recommended sleep: \(FamilyMember(name: "", age: age, currentBedtime: Date(), currentWakeTime: Date()).recommendedSleepHours.lowerBound)-\(FamilyMember(name: "", age: age, currentBedtime: Date(), currentWakeTime: Date()).recommendedSleepHours.upperBound) hours")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("Adjustment increment: \(FamilyMember(name: "", age: age, currentBedtime: Date(), currentWakeTime: Date()).adjustmentIncrement) minutes/day")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(mode.buttonTitle) {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
        .sensoryFeedback(.success, trigger: didSave)
        .sensoryFeedback(.error, trigger: showValidationError)
    }
    
    private func save() {
        guard isValid else {
            showValidationError.toggle()
            return
        }
        
        switch mode {
        case .add:
            let member = FamilyMember(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                age: age,
                currentBedtime: bedtime,
                currentWakeTime: wakeTime,
                hasWakeConstraint: hasWakeConstraint,
                wakeByTime: wakeByTime
            )
            modelContext.insert(member)
            
        case .edit(let member):
            member.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            member.age = age
            member.currentBedtime = bedtime
            member.currentWakeTime = wakeTime
            member.hasWakeConstraint = hasWakeConstraint
            member.wakeByTime = wakeByTime
        }
        
        didSave.toggle()
        dismiss()
    }
}

#Preview("Add") {
    FamilyMemberFormView(mode: .add)
        .modelContainer(for: FamilyMember.self, inMemory: true)
}
