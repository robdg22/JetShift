# Product Requirements Document: JetShift Family MVP

## Product Overview

**Product Name:** JetShift Family

**Version:** 1.0 (MVP)

**Platform:** iOS (Native Swift/SwiftUI)

**Minimum iOS Version:** iOS 17.0+

**Target Users:** Families traveling across multiple time zones who want to minimize jet lag for all family members

## Problem Statement

Families traveling internationally struggle with jet lag, particularly when traveling with children who have different sleep needs and less flexible schedules than adults. Existing jet lag apps focus on solo travelers and don't address the complexity of coordinating sleep schedules for multiple family members with varying ages, bedtimes, and constraints.

## Product Goals

### Primary Goals
1. Enable families to create personalized jet lag prevention plans for all family members
2. Provide day-by-day sleep schedule recommendations based on circadian rhythm science
3. Visualize the adjustment plan in an intuitive, scannable format
4. Support age-specific sleep recommendations for children, teens, and adults

### Success Metrics (Future)
- User creates a complete family profile and flight plan
- User views the generated schedule timeline
- User reports reduced jet lag symptoms (post-MVP)

## User Personas

### Primary Persona: Planning Parent
- Age: 30-45
- Has 1-4 children of varying ages
- Plans family international travel 1-4 times per year
- Values family wellbeing and wants kids to enjoy the trip
- Comfortable with iOS apps
- Willing to invest time in preparation to avoid travel chaos

### Secondary Users: Family Members
- Children (ages 0-12): Different sleep needs, less flexible schedules (naps, early bedtimes)
- Teens (ages 13-17): Later bedtimes, more flexible but still developing circadian rhythms
- Partners/Adults: Standard adult sleep patterns

## Core Features (MVP Scope)

### 1. Family Profile Management

**1.1 Add Family Members**
- Input fields:
  - Name (text field)
  - Age (number picker or text field)
  - Current bedtime (time picker, 12-hour format)
  - Current wake time (time picker, 12-hour format)
- Support for 1-8 family members
- Data stored locally using SwiftData
- Ability to edit and delete family members

**1.2 Age-Based Defaults**
- Suggested sleep durations based on age:
  - 0-2 years: 11-14 hours
  - 3-5 years: 10-13 hours
  - 6-12 years: 9-12 hours
  - 13-17 years: 8-10 hours
  - 18+ years: 7-9 hours
- Pre-populate typical bedtimes when age is entered (user can override)

### 2. Flight Information Entry

**2.1 Flight Details Form**
- Departure city (text field with timezone lookup)
- Arrival city (text field with timezone lookup)
- Departure date (date picker)
- Departure time (time picker)
- Arrival date (date picker, auto-calculated if same day)
- Arrival time (time picker)

**2.2 Timezone Handling**
- Use iOS TimeZone API for timezone detection
- Support major cities (use bundled JSON or Apple's timezone database)
- Display timezone offset (e.g., "London (GMT+0)", "New York (GMT-5)")
- Calculate timezone difference automatically

### 3. Jet Lag Algorithm

**3.1 Core Calculation Logic**

**Inputs:**
- Current timezone
- Destination timezone
- Timezone difference (hours)
- Departure date
- Each family member's current sleep schedule
- Each family member's age

**Algorithm Parameters:**
- Adjustment period: 3 days before departure (fixed for MVP)
- Adjustment increment: 30 minutes per day (conservative, achievable with kids)
- Post-arrival adjustment: 2 days after arrival
- Total plan: 6 days (3 pre-flight + 1 travel day + 2 post-arrival)

**Calculation Method:**

For **Eastward travel** (advance circadian clock):
- Shift bedtime and wake time 30 minutes EARLIER each day
- Example: 8pm bedtime → 7:30pm → 7pm → 6:30pm over 3 days
- Maximum pre-flight shift: 90 minutes (3 days × 30 min)

For **Westward travel** (delay circadian clock):
- Shift bedtime and wake time 30 minutes LATER each day
- Example: 8pm bedtime → 8:30pm → 9pm → 9:30pm over 3 days
- Maximum pre-flight shift: 90 minutes

**Age-Specific Adjustments:**
- Children 0-5: 20-minute increments (gentler)
- Children 6-12: 25-minute increments
- Teens/Adults: 30-minute increments

**Sleep Duration Maintenance:**
- Maintain each person's typical sleep duration throughout adjustment
- If child normally sleeps 11 hours, maintain 11-hour sleep blocks

**Travel Day Handling:**
- Show recommended sleep times in destination timezone
- Note: "Travel day - adjust to destination schedule"

**Post-Arrival:**
- Days 1-2: Continue to destination timezone schedule
- Maintain destination bedtime/wake times

**3.2 Output Data Structure**

For each family member, generate array of daily schedules:
```
Day -3 (3 days before): Bedtime: 7:30pm, Wake: 6:30am
Day -2 (2 days before): Bedtime: 7:00pm, Wake: 6:00am
Day -1 (1 day before): Bedtime: 6:30pm, Wake: 5:30am
Day 0 (travel day): Bedtime: 9:00pm (destination), Wake: 7:00am (destination)
Day +1 (arrival +1): Bedtime: 9:00pm, Wake: 7:00am
Day +2 (arrival +2): Bedtime: 9:00pm, Wake: 7:00am
```

### 4. Schedule Timeline View

**4.1 Main Timeline Display**

**Layout:**
- Vertical scrolling list
- One row per family member
- Each row shows 6-day timeline
- Days displayed as horizontal cards/blocks

**Day Card Components:**
- Day label: "3 days before", "2 days before", "Travel Day", "Day 1", "Day 2"
- Bedtime (displayed prominently)
- Wake time (displayed prominently)
- Visual indicator: Color-coded by adjustment stage
  - Pre-flight days: Light blue gradient
  - Travel day: Gold/amber
  - Post-arrival days: Green gradient

**Family Member Row:**
- Family member name and age at left
- Timeline cards arranged horizontally (scrollable if needed)
- Age indicator icon (optional: baby, child, teen, adult emoji)

**Visual Hierarchy:**
- Today's date highlighted with special border/background
- Past dates slightly dimmed
- Future dates at full opacity

**4.2 Interaction Design**
- Tap on any day card to see detailed view (future enhancement - not MVP)
- Horizontal scroll within each family member's timeline if needed
- Vertical scroll to see all family members

**4.3 Empty States**
- No family members: "Add family members to get started"
- No flight: "Add flight details to generate your schedule"
- Both missing: Guide user through setup flow

### 5. Navigation & App Structure

**5.1 App Architecture**

Three main screens (tab-based navigation):

**Tab 1: Family**
- List of family members
- "Add Family Member" button
- Edit/delete actions on each member
- Form sheet for adding/editing members

**Tab 2: Flight**
- Display current flight details (if set)
- "Add Flight" or "Edit Flight" button
- Form sheet for flight input
- Show timezone difference calculated

**Tab 3: Schedule**
- Main timeline view (described above)
- Only accessible when family + flight data exists
- Export/share functionality (future - not MVP)

**5.2 Onboarding Flow** (First Launch)
- Welcome screen: "Help your family beat jet lag"
- Brief explanation (1-2 sentences)
- CTA: "Get Started"
- Direct to Family tab to add first member

### 6. Data Model (SwiftData)

**FamilyMember Model:**
```swift
@Model
class FamilyMember {
    var id: UUID
    var name: String
    var age: Int
    var currentBedtime: Date // Time component only
    var currentWakeTime: Date // Time component only
    var createdAt: Date
}
```

**Flight Model:**
```swift
@Model
class Flight {
    var id: UUID
    var departureCity: String
    var departureTimezone: String // e.g., "America/New_York"
    var arrivalCity: String
    var arrivalTimezone: String // e.g., "Europe/London"
    var departureDate: Date
    var departureTime: Date // Time component only
    var arrivalDate: Date
    var arrivalTime: Date // Time component only
    var createdAt: Date
}
```

**DailySchedule (Computed, not stored):**
```swift
struct DailySchedule {
    var date: Date
    var dayLabel: String // "3 days before", "Travel Day", etc.
    var bedtime: Date
    var wakeTime: Date
    var isToday: Bool
    var stage: ScheduleStage // .preAdjustment, .travelDay, .postArrival
}

enum ScheduleStage {
    case preAdjustment
    case travelDay
    case postArrival
}
```

### 7. UI/UX Specifications

**7.1 Design Principles**
- Clean, uncluttered interface
- Family-friendly aesthetics (warm colors, friendly typography)
- Scannable information hierarchy
- Minimize text, maximize visual clarity

**7.2 Color Palette**
- Primary: Soft blue (#4A90E2)
- Secondary: Warm amber (#F5A623)
- Success/Arrival: Soft green (#7ED321)
- Background: System background (white/dark mode support)
- Text: System primary/secondary labels

**7.3 Typography**
- SF Pro (system font)
- Headings: SF Pro Bold
- Body: SF Pro Regular
- Time displays: SF Pro Medium, slightly larger

**7.4 Components**
- Use native SwiftUI components (List, Form, TextField, DatePicker, etc.)
- Custom timeline card component
- Standard iOS navigation patterns

### 8. Technical Requirements

**8.1 Technology Stack**
- SwiftUI (declarative UI)
- SwiftData (local persistence)
- iOS 17.0+ minimum
- No external dependencies (use native iOS frameworks)

**8.2 Device Support**
- iPhone only (MVP)
- Support iPhone SE (3rd gen) through iPhone 15 Pro Max
- Portrait orientation only
- Light and Dark mode support

**8.3 Performance**
- App launch: < 2 seconds
- Schedule calculation: < 1 second
- Smooth 60fps scrolling
- Efficient data loading (minimal database queries)

**8.4 Data & Privacy**
- All data stored locally (no cloud sync in MVP)
- No analytics or tracking
- No account/authentication required
- Data persists across app launches

### 9. Out of Scope (Post-MVP)

**Explicitly NOT included in MVP:**
- CloudKit/iCloud syncing between devices
- Push notifications or reminders
- Light exposure guidance
- Melatonin recommendations
- Multiple trips/trip history
- Calendar integration
- Export to PDF/sharing
- iPad support
- Widget support
- Apple Watch companion
- Travel day flight tracking
- In-app onboarding tutorial (beyond welcome screen)
- Settings/preferences customization
- Feedback mechanism
- App Store rating prompts

### 10. User Flows

**10.1 Primary Happy Path Flow**

1. User launches app (first time)
2. Sees welcome screen → Taps "Get Started"
3. Lands on Family tab
4. Taps "Add Family Member"
5. Fills in: Name "Sarah", Age "7", Bedtime "8:00 PM", Wake "7:00 AM"
6. Taps "Save"
7. Repeats for other family members (Mom, Dad, Brother age 4)
8. Switches to Flight tab
9. Taps "Add Flight"
10. Enters: NYC → London, departure date/time, arrival date/time
11. App auto-detects timezones
12. Taps "Save"
13. Switches to Schedule tab
14. Sees timeline with all 4 family members
15. Reviews 6-day schedule for each person
16. Uses plan over next week to adjust family sleep times

**10.2 Edit Flow**
1. User wants to change flight time
2. Goes to Flight tab
3. Taps "Edit Flight"
4. Updates arrival time
5. Taps "Save"
6. Schedule tab automatically recalculates
7. User sees updated timeline

**10.3 Error Handling**
- Missing required fields: Inline validation errors
- Invalid times: Show error message
- City not found: Allow manual timezone selection
- No internet (if needed for timezone data): Use bundled fallback data

### 11. Acceptance Criteria

**For MVP to be considered complete:**

✅ User can add/edit/delete family members
✅ User can input complete flight information
✅ App correctly calculates timezone difference
✅ Algorithm generates 6-day schedule for each family member
✅ Schedule accounts for age-specific adjustment rates
✅ Timeline view displays all family members with daily schedules
✅ UI is clean, readable, and navigable
✅ Data persists across app restarts
✅ App runs on iOS 17+ without crashes
✅ Light and dark mode both supported
✅ All time displays use 12-hour format with AM/PM

### 12. Development Phases

**Phase 1: Foundation** (Day 1)
- Project setup with SwiftData
- Data models: FamilyMember, Flight
- Basic navigation structure (TabView)

**Phase 2: Family Management** (Day 1-2)
- Family member list view
- Add/edit member forms
- Validation and persistence

**Phase 3: Flight Input** (Day 2)
- Flight input form
- Timezone detection/selection
- Validation and persistence

**Phase 4: Algorithm** (Day 3)
- Core jet lag calculation logic
- Generate DailySchedule structs
- Age-specific adjustments
- East/west travel handling

**Phase 5: Timeline View** (Day 3-4)
- Timeline UI components
- Family member rows
- Day cards with bedtime/wake time
- Color coding and today highlighting

**Phase 6: Polish** (Day 4-5)
- Dark mode refinement
- Empty states
- Error handling
- Testing edge cases
- Welcome screen

### 13. Test Cases

**Critical Test Scenarios:**

1. **Eastward travel (NYC → London, 5 hour advance)**
   - Family: Adult (age 35), Child (age 6)
   - Verify 30min adult shifts, 25min child shifts
   - Verify bedtimes move earlier each day

2. **Westward travel (London → LA, 8 hour delay)**
   - Family: Teen (age 14), Toddler (age 2)
   - Verify 30min teen shifts, 20min toddler shifts
   - Verify bedtimes move later each day

3. **Same timezone (London → Dublin, 0 hour difference)**
   - Should show minimal/no adjustment
   - Edge case handling

4. **Multiple family members (4+ people)**
   - Verify timeline scrolls smoothly
   - Each member has independent schedule

5. **Data persistence**
   - Add data, close app, reopen
   - Verify all data restored

6. **Form validation**
   - Missing name: Error shown
   - Invalid age (negative): Error shown
   - Missing flight city: Error shown

### 14. Design References

**Visual Style Inspiration:**
- Apple Health app (clean timelines, health data)
- Apple Calendar (date selection, clean forms)
- Simple, iOS-native aesthetic

**Timeline Reference:**
- Horizontal scrolling cards similar to App Store "Today" tab
- Clear typography hierarchy
- Generous padding and spacing

### 15. Implementation Notes for LLM

**Key Architecture Decisions:**

1. **Use SwiftData for persistence** - Modern, simple API, no Core Data complexity
2. **Compute schedules on-demand** - Don't store DailySchedule, calculate from Flight + FamilyMember data
3. **Single source of truth** - Flight and FamilyMembers are stored; everything else derived
4. **Pure Swift/SwiftUI** - No external packages, no CocoaPods, no SPM dependencies
5. **MVVM-lite** - ViewModels for complex logic, but keep it simple
6. **Timezone handling** - Use Foundation's TimeZone, avoid date math errors

**Code Quality Standards:**
- Clear variable names
- Comments for complex logic (especially algorithm)
- Separate concerns (views, models, calculation logic)
- Reusable components where it makes sense
- Handle nil/optional values safely

**Specific Technical Guidance:**

- Use `@Query` in SwiftUI views to fetch SwiftData
- Use `@Environment(\.modelContext)` for data operations
- Time-only values: Store as Date but only use time components
- Timezone math: Use Calendar with explicit timezones
- Color coding: Define as Color extensions for consistency

### 16. Future Considerations (Not MVP, but design with in mind)

- API for sharing schedules between family devices
- Notification scheduling
- Multiple trips
- Historical trip tracking
- Settings for adjustment aggressiveness

**Design so these are possible later:**
- Use proper models (don't hack shortcuts that prevent scaling)
- Keep calculation logic separate from UI
- Use standard iOS patterns

---

## Appendix A: Algorithm Pseudocode

```
function calculateSchedule(familyMember, flight):
    
    timezoneDiff = flight.arrivalTimezone.offset - flight.departureTimezone.offset
    direction = timezoneDiff > 0 ? "east" : "west"
    
    adjustmentDays = 3 // Fixed for MVP
    travelDay = flight.departureDate
    
    // Determine increment based on age
    if familyMember.age <= 5:
        increment = 20 minutes
    else if familyMember.age <= 12:
        increment = 25 minutes
    else:
        increment = 30 minutes
    
    schedules = []
    
    // Pre-flight adjustment (3 days)
    for day in -3 to -1:
        if direction == "east":
            bedtime = familyMember.currentBedtime - (increment * abs(day))
            waketime = familyMember.currentWakeTime - (increment * abs(day))
        else:
            bedtime = familyMember.currentBedtime + (increment * abs(day))
            waketime = familyMember.currentWakeTime + (increment * abs(day))
        
        schedules.append(DailySchedule(
            date: travelDay + day,
            dayLabel: "\(abs(day)) days before",
            bedtime: bedtime,
            wakeTime: waketime,
            stage: .preAdjustment
        ))
    
    // Travel day (Day 0)
    // Convert to destination timezone
    destinationBedtime = convert(familyMember.currentBedtime, to: flight.arrivalTimezone)
    destinationWakeTime = convert(familyMember.currentWakeTime, to: flight.arrivalTimezone)
    
    schedules.append(DailySchedule(
        date: travelDay,
        dayLabel: "Travel Day",
        bedtime: destinationBedtime,
        wakeTime: destinationWakeTime,
        stage: .travelDay
    ))
    
    // Post-arrival (Days 1-2)
    for day in 1 to 2:
        schedules.append(DailySchedule(
            date: travelDay + day,
            dayLabel: "Day \(day)",
            bedtime: destinationBedtime,
            wakeTime: destinationWakeTime,
            stage: .postArrival
        ))
    
    return schedules
```

## Appendix B: Example Cities and Timezones

Include a bundled JSON or hardcoded dictionary with common cities:

```json
{
  "cities": [
    {"name": "New York", "timezone": "America/New_York"},
    {"name": "Los Angeles", "timezone": "America/Los_Angeles"},
    {"name": "London", "timezone": "Europe/London"},
    {"name": "Paris", "timezone": "Europe/Paris"},
    {"name": "Tokyo", "timezone": "Asia/Tokyo"},
    {"name": "Sydney", "timezone": "Australia/Sydney"},
    {"name": "Dubai", "timezone": "Asia/Dubai"},
    {"name": "Singapore", "timezone": "Asia/Singapore"},
    {"name": "Hong Kong", "timezone": "Asia/Hong_Kong"},
    {"name": "Mumbai", "timezone": "Asia/Kolkata"},
    {"name": "Toronto", "timezone": "America/Toronto"},
    {"name": "Chicago", "timezone": "America/Chicago"},
    {"name": "San Francisco", "timezone": "America/Los_Angeles"},
    {"name": "Boston", "timezone": "America/New_York"},
    {"name": "Miami", "timezone": "America/New_York"},
    {"name": "Berlin", "timezone": "Europe/Berlin"},
    {"name": "Rome", "timezone": "Europe/Rome"},
    {"name": "Madrid", "timezone": "Europe/Madrid"},
    {"name": "Amsterdam", "timezone": "Europe/Amsterdam"},
    {"name": "Bangkok", "timezone": "Asia/Bangkok"},
    {"name": "Beijing", "timezone": "Asia/Shanghai"},
    {"name": "Seoul", "timezone": "Asia/Seoul"},
    {"name": "Melbourne", "timezone": "Australia/Melbourne"}
  ]
}
```

---

**END OF PRD**
