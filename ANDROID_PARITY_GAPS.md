# Android Feature Parity Gaps

## Overview

The iOS app (`bikecheck/`) has received substantial feature development over multiple releases, while the Android app (`BikeCheckAndroid/`) was recently added as a baseline implementation. This document catalogs all identified gaps between the two platforms, organized by priority and category.

**Total identified gaps: 20+** across core UX, data/logic, features, service history, and polish.

---

## Feature Comparison at a Glance

| Category | iOS | Android | Status |
|---|---|---|---|
| **Service Interval Filters** | ✅ Multi-select chips (All/Overdue/Soon/Good) | ❌ No filtering | Gap |
| **Service Interval Card UI** | ✅ Rich (icon, status dot, label, wear bar) | ❌ Text-only | Gap |
| **Bikes Tab Card UI** | ✅ Expandable with status | ❌ Simple card | Gap |
| **Profile Tab & Stats** | ✅ Full screen, 7 stats, 2-column grid | ❌ No profile screen | Gap |
| **Background Sync Worker** | ✅ Functional BGTaskScheduler (2 tasks, 24h cycle) | ❌ Stub only | Gap |
| **Token Refresh** | ✅ Auto-refresh before API calls | ❌ Disabled | Gap |
| **Notification Throttling** | ✅ 7-day throttle per interval | ❌ No throttle | Gap |
| **Bike Deletion** | ✅ Actually deletes from storage | ❌ Stub only | Gap |
| **Smart Bike Detection** | ✅ 3-stage matching + confidence badge | ❌ Manual spinner only | Gap |
| **Preset Confirmation Flow** | ✅ 2-step sheet (parts + date) | ❌ Immediate creation | Gap |
| **Bike Type Selection Modal** | ✅ Full-screen modal with descriptions | ❌ Inline spinner | Gap |
| **Batch Date Update** | ✅ "Set All" toolbar action | ❌ Not implemented | Gap |
| **Part Templates** | ✅ 17 across 5 categories | ❌ 3–5 per type | Gap |
| **Hierarchical Part Picker** | ✅ Grouped by category | ❌ Free-text only | Gap |
| **Service History** | ✅ Full ServiceRecord log | ❌ No history table | Gap |
| **Reset Flow** | ✅ Date picker + note sheet | ❌ Immediate reset | Gap |
| **Add Note Action** | ✅ Note-only records | ❌ Not implemented | Gap |
| **Profile Nav Tap** | ✅ Tappable photo → profile | ❌ Photo present, not tappable | Gap |
| **Onboarding State Persistence** | ✅ Keychain survives reinstall | ❌ SharedPreferences cleared | Gap |
| **Onboarding Bypass** | ✅ Correct routing | ❌ Hardcoded bypass | Gap |
| **Ad Container Placement** | ✅ In multiple screens | ❌ Defined but not placed | Gap |

---

## 🔴 High Priority — Core UX Differences

### 1. Service Interval Status Filter Chips

**iOS Implementation:**
- Multi-select chip filter in service interval list
- Chips: All, Overdue, Soon, Good
- Toggles to filter displayed intervals in real-time

**Android Current State:**
- No filter UI at all
- Shows all intervals unfiltered

**What Needs Building:**
- Filter chip row above interval list in `ServiceIntervalListFragment`
- Selected state management in ViewModel
- Filter logic to hide/show intervals based on status
- Part of: `service_interval_list.xml`, `ServiceIntervalViewModel`

---

### 2. Service Interval Card Richness

**iOS Implementation:**
- Part icon (from `PartTemplate`)
- Color-coded status dot (🟢 Good / 🟡 Soon / 🔴 Overdue)
- Status label ("Good", "Soon", "Now")
- 5-segment `WearIndicator` bar showing wear progression

**Android Current State:**
- Text-only card
- "DUE IN X hours" countdown only
- No visual status indicators

**What Needs Building:**
- Icon rendering from part template
- Status dot and label in card layout
- Wear indicator bar (can be custom View or custom Canvas draw)
- Update: `service_interval_card.xml`, `ServiceIntervalAdapter`

---

### 3. Bikes Tab Card Richness

**iOS Implementation:**
- Main card shows bike name + type + distance
- **Expandable rows** showing mini service interval cards within the bike card
- Status dot in card header (🟢 Good / 🔴 Needs Service)

**Android Current State:**
- Simple card with bike name + type + distance
- No expansion capability
- No status indicator

**What Needs Building:**
- Expandable/collapsible row for each bike's intervals
- Status dot calculation (all intervals good → green, any overdue → red)
- Expanded view layout with mini interval cards
- Update: `bikes_list.xml`, `BikeAdapter`

---

### 4. Profile Tab & Bike Nerd Stats

**iOS Implementation:**
- Dedicated `ProfileView` accessible from nav bar profile photo
- Displays 7 stats in a 2-column stat tile grid:
  - Bikes (count)
  - Miles (total distance)
  - Hours (total ride time)
  - Activities (from Strava)
  - Parts Tracked (distinct parts across all intervals)
  - Overdue (count of overdue intervals)
  - Services Logged (count of service records)
- Profile photo tappable from any tab nav bar
- "Demo Mode Active" badge when in demo

**Android Current State:**
- **No profile screen at all**
- No stats display
- No profile tab

**What Needs Building:**
- New `ProfileFragment` with layout
- Stats calculation in `ProfileViewModel` (queries all data)
- 2-column grid layout for stat tiles
- Profile screen accessible from bottom nav
- Profile photo tap in nav bar → ProfileFragment
- Demo mode badge in profile
- Files: `ProfileFragment.kt`, `ProfileViewModel.kt`, `profile_fragment.xml`, `profile_stat_tile.xml`

---

## 🔴 High Priority — Data / Logic Gaps

### 5. Background Sync Worker (Currently a Stub)

**iOS Implementation:**
- Fully functional `BGTaskScheduler` setup with 2 tasks:
  1. `checkServiceInterval`: Detects overdue intervals, sends notifications (24h cycle)
  2. `fetchActivities`: Refreshes Strava data (24h cycle)
- Both run every ~24 hours (OS-permitting)
- Respects notification throttling (7-day per interval)

**Android Current State:**
- `SyncDataWorker.kt` exists but is a stub:
  ```kotlin
  override suspend fun doWork(): Result {
      return Result.success()  // Does nothing!
  }
  ```

**What Needs Building:**
- Implement actual sync logic in `SyncDataWorker.doWork()`:
  1. Fetch overdue service intervals from Room database
  2. Check throttle on each (compare current time to `lastNotificationDate`)
  3. Send local notifications via `NotificationService`
  4. Fetch Strava activities via `StravaRepository`
  5. Update `lastNotificationDate` after sending
- Ensure worker is scheduled in `MainActivity` or `Application` class
- Files: `SyncDataWorker.kt`, `NotificationService.kt`, `StravaRepository.kt`

---

### 6. Token Refresh Logic

**iOS Implementation:**
- Before every API call, checks if access token is expired
- If expired (or close to expiry), automatically refreshes via `refreshToken`
- Seamless retry of original request post-refresh

**Android Current State:**
- Token expiry check is **disabled** (hardcoded `false` or condition always skipped)
- Always uses existing token regardless of expiry
- No refresh logic wired up

**What Needs Building:**
- Uncomment/enable expiry check in API call interceptor or pre-call logic
- Implement token refresh call: POST to refresh endpoint with `refreshToken`
- Update `accessToken` + `expiresAt` in `TokenManager` or `UserPreferences`
- Retry failed request after refresh
- Files: `StravaRepository.kt`, `TokenManager.kt`, or OkHttp interceptor

---

### 7. Notification Throttling (7-Day Per Interval)

**iOS Implementation:**
- Each `ServiceInterval` has a `lastNotificationDate` field
- Before sending notification, checks: `now - lastNotificationDate >= 7 days`
- If throttle period hasn't elapsed, skips notification
- Updates `lastNotificationDate` after sending

**Android Current State:**
- No throttle logic
- Notifications re-sent every sync cycle (potentially multiple times per day)
- `ServiceIntervalEntity` has no `lastNotificationDate` field

**What Needs Building:**
- Add `lastNotificationDate: Long?` field to `ServiceIntervalEntity`
- Update `ServiceIntervalDao` migrations to add column
- Check throttle in `SyncDataWorker` before sending notification:
  ```kotlin
  val now = System.currentTimeMillis()
  val lastNotified = interval.lastNotificationDate ?: 0
  if (now - lastNotified >= 7 * 24 * 60 * 60 * 1000) {
      sendNotification(interval)
      updateLastNotificationDate(interval.id, now)
  }
  ```
- Files: `ServiceIntervalEntity.kt`, `ServiceIntervalDao.kt`, `SyncDataWorker.kt`

---

### 8. Bike Deletion (Functional)

**iOS Implementation:**
- Tapping delete on a bike removes it from Core Data
- Cascading delete removes associated service intervals + records

**Android Current State:**
- `BikeRepository.deleteBike()` returns `Result.success(true)` without deleting
- Bike persists in Room database

**What Needs Building:**
- Implement actual delete in `BikeDao.delete()` or `BikeRepository.deleteBike()`
- Cascade delete to `ServiceIntervalEntity` records (Room should handle via foreign key constraints, or manual delete)
- Verify Room schema has cascade delete configured on foreign key
- Files: `BikeDao.kt`, `BikeRepository.kt`, `BikeEntity.kt`

---

## 🟡 Medium Priority — Missing Features

### 9. Smart Bike Detection (3-Stage Matching)

**iOS Implementation:**
- Uploads bike name/info to detection service
- **Stage 1**: Fuzzy match against `BikePresets.yaml` (12+ manufacturers, 80+ models) → high confidence
- **Stage 2**: Model-only match if name incomplete → medium-high confidence
- **Stage 3**: Lookup in `BikeDatabase.json` (220+ bikes) → medium confidence
- Returns best match + confidence percentage badge
- User can accept or manually select

**Android Current State:**
- No detection
- User manually selects bike type via spinner (Road/Gravel/Hardtail/Full Suspension)

**What Needs Building:**
- Port `BikeDetectionService` logic (or equivalent detection algorithm) from iOS
- Load `BikePresets.yaml` and `BikeDatabase.json` into Android app (in `raw/` resources)
- Implement 3-stage matching logic
- Display confidence badge in detection result
- Add UI to show detection result + allow override
- Files: `BikeDetectionService.kt`, `bike_detection_result.xml`, update `AddBikeActivity.kt`

---

### 10. Preset Confirmation Flow (Parts + Date Picker)

**iOS Implementation:**
- After detection (or manual selection), shows a 2-step sheet:
  1. Part checklist with pre-selections (from detection/presets)
     - User can toggle parts on/off
     - Provides context for what will be tracked
  2. Graphical date picker for "Last Service Date"
     - User sets when they last serviced the bike
     - Pre-fills service intervals' `startTime`

**Android Current State:**
- "Create Default Service Intervals" button creates intervals immediately
- No part selection
- No date picker
- Hardcoded: creates chain, fork lowers, shock only

**What Needs Building:**
- 2-step confirmation sheet/dialog:
  1. CheckBox list of available parts (from presets)
  2. Date picker for last service date
- Flow: Detection/Manual Select → Parts Sheet → Date Sheet → Create Intervals
- Update: `AddBikeActivity.kt`, new `ConfirmPresetsFragment.kt` or sheet dialog, layouts

---

### 11. Bike Type Selection Modal

**iOS Implementation:**
- Full-screen modal (`BikeTypeSelectionView`) when user needs to pick type
- Shows descriptions for each type (Road/Gravel/Hardtail/Full Suspension)
- Provides context to help user make informed choice

**Android Current State:**
- Inline spinner in add bike screen
- No descriptions or context

**What Needs Building (Optional):**
- Full-screen dialog or fragment showing bike types with descriptions
- Or enhance spinner with popup that shows descriptions
- Improves UX but lower priority than detection flow
- Files: `BikeTypeSelectionDialog.kt`, layout

---

### 12. Batch "Set Last Service Date for All" Action

**iOS Implementation:**
- Toolbar action on bike detail view
- Opens graphical date picker
- Updates `lastServiceDate` on **every interval** for that bike at once
- Useful for bulk-updating a bike's service history

**Android Current State:**
- Not implemented

**What Needs Building:**
- "Set All Service Dates" button in bike detail screen
- Date picker dialog
- Bulk update in `BikeRepository.updateAllServiceDates(bikeId, date)`
- Update all `ServiceIntervalEntity` rows for bike
- Files: `BikePictureViewModel.kt`, `bike_detail.xml`, update `BikeRepository.kt`

---

### 13. Part Template Richness (17 Templates in 5 Categories)

**iOS Implementation:**
- 17 templates across 5 categories:
  - **Drivetrain** (6): Chain, Cassette, Chainring, Bottom Bracket, Derailleur Hanger, Cables & Housing
  - **Suspension** (3): Fork Lowers, Fork Seals, Shock
  - **Wheels & Hubs** (3): Rim Brake Pads, Disc Brake Pads, Tire
  - **Brakes** (2): Brake Fluid, Hydraulic Hose
  - **Cockpit** (3): Handlebar Tape, Grips, Stem
- Each with icon, description, and default notify value

**Android Current State:**
- `service_templates.json` has only 3–5 templates per type
- Basic structure (name, icon) but limited coverage
- Templates: chain, fork lowers, shock (maybe a few others)

**What Needs Building:**
- Expand `service_templates.json` to include all 17 templates
- Organize into 5 categories
- Add descriptions and notify defaults
- Update icon references in template
- Update `ServiceTemplate` data class if needed
- Files: `service_templates.json`, `ServiceTemplate.kt`

---

### 14. Hierarchical Part Picker (Category-Grouped)

**iOS Implementation:**
- In `AddServiceIntervalView`, parts are grouped by category
- Selecting a template auto-fills:
  - Part name
  - Default hours/km interval
  - Notify defaults
- Clean, organized UI

**Android Current State:**
- `AddServiceIntervalActivity` has a free-text field for part name
- User types manually
- No templates or categories

**What Needs Building:**
- Replace free-text with a categorized picker (can use ExpandableListView, RecyclerView with sections, or dialog with grouped items)
- Load templates from `service_templates.json`
- On selection, auto-fill:
  - Part name
  - Suggested hours/km
  - Notify defaults
- Files: `AddServiceIntervalActivity.kt`, `add_service_interval.xml`, `PartTemplateAdapter.kt` (new)

---

## 🟡 Medium Priority — Service History

### 15. ServiceRecord Log (History Table)

**iOS Implementation:**
- Every `ServiceInterval` has a scrollable history
- Records include:
  - **Service reset** (wrench icon): date + note, auto-created when `reset()` called
  - **Manual note** (note icon): text-only record, user can add via "Add Note" button
- Visible in interval edit view

**Android Current State:**
- **No service history table at all**
- No `ServiceRecordEntity`
- No history display in UI

**What Needs Building:**
- New `ServiceRecordEntity` Room entity with fields:
  - `id`, `serviceIntervalId`, `date`, `type` (reset/note), `note`
- New `ServiceRecordDao` with insert + query methods
- Update database migration
- UI: History section in service interval detail/edit screen with list of records
- Files: `ServiceRecordEntity.kt`, `ServiceRecordDao.kt`, database migration, update UI layout

---

### 16. Reset Interval Flow (Date Picker + Note Sheet)

**iOS Implementation:**
- Tapping reset/wrench icon opens a sheet
- User picks new service start date (graphical picker)
- Optional note field (e.g., "Replaced chain", "Full service")
- Confirms → resets `startTime` + creates `ServiceRecord`

**Android Current State:**
- Resets `startTime` immediately
- No date picker or note input
- No `ServiceRecord` created

**What Needs Building:**
- Add "Reset Interval" button/action to service interval detail
- Open dialog/sheet with:
  1. Date picker for new start date
  2. Text field for optional note
- On confirm:
  - Update `ServiceIntervalEntity.startTime`
  - Insert `ServiceRecordEntity` with type=reset, note from input
- Files: `ResetServiceIntervalDialog.kt`, update `ServiceIntervalViewModel.kt`, layout

---

### 17. Add Note Action (Note-Only Record)

**iOS Implementation:**
- "Add Note" button in history section
- Creates a `ServiceRecord` with `type=note` (doesn't reset timer)
- User enters note text
- Useful for logging maintenance milestones without resetting

**Android Current State:**
- Not implemented

**What Needs Building:**
- Add "Add Note" button in service interval detail history section
- Dialog to input note text
- On confirm: insert `ServiceRecordEntity` with type=note
- Refresh history display
- Files: `AddNoteDialog.kt`, update `ServiceIntervalViewModel.kt`, layout

---

## 🟢 Lower Priority — Polish

### 18. Profile Image Nav Bar Tap

**iOS Implementation:**
- Circular profile photo in every tab's nav bar
- Tappable → navigates to `ProfileView`

**Android Current State:**
- Circular profile photo exists in toolbar/nav bar
- **Not tappable** (no click listener)

**What Needs Building:**
- Add click listener to profile photo in `MainActivity` or relevant fragments
- Navigate to `ProfileFragment`
- Only minor wiring change
- Files: Update toolbar/nav bar setup, `MainActivity.kt`

---

### 19. Keychain-Based Onboarding State Persistence

**iOS Implementation:**
- `hasUsedApp` flag stored in Keychain
- Survives app reinstall (not tied to app data)
- Prevents showing onboarding on reinstall if user previously completed it

**Android Current State:**
- SharedPreferences only
- **Cleared on reinstall** (tied to app data)
- User sees onboarding every time they reinstall

**What Needs Building (Nice-to-have):**
- Switch from SharedPreferences to `EncryptedSharedPreferences` or Android `AccountManager`
- Or accept SharedPreferences behavior (acceptable for Android norm)
- Note: `hasUsedApp` flag should be set after onboarding completion
- Files: `OnboardingRepository.kt` or `TokenManager.kt`

---

### 20. Onboarding Routing

**iOS Implementation:**
- App checks `hasUsedApp` via Keychain
- First launch → shows `OnboardingView`
- Subsequent launches → skips onboarding

**Android Current State:**
- `MainActivity` **skips onboarding entirely** (hardcoded)
- `OnboardingActivity` never shown even on fresh install

**What Needs Building:**
- Fix routing in `MainActivity.onCreate()`:
  - Check `hasUsedApp` in SharedPreferences/AccountManager
  - If false → start `OnboardingActivity`
  - If true → show main nav
- Set `hasUsedApp = true` after onboarding completes
- Files: `MainActivity.kt`, `OnboardingActivity.kt`, `OnboardingRepository.kt`

---

### 21. Ad Container Placement

**iOS Implementation:**
- `AdContainerView` placed in multiple screen layouts:
  - Service interval list
  - Bikes list
  - Activities list
  - Service interval creation form

**Android Current State:**
- `AdContainerView` composable exists
- **Not placed in any screen layout**
- Ads not showing anywhere

**What Needs Building:**
- Add `AdContainerView()` calls to:
  - `ServiceIntervalListFragment` layout
  - `BikeListFragment` layout
  - `ActivitiesFragment` layout
  - `AddServiceIntervalActivity` layout
- Ensure correct placement (typically at bottom or in list item template)
- Files: Service interval/bike/activity layouts

---

### 22. Minor: Activities Distance Unit Consistency

**iOS Implementation:**
- Distance displayed in km
- No average speed

**Android Current State:**
- Distance displayed in km ✅
- **Also shows average speed** (not in iOS)

**Gap:**
- Minor inconsistency; Android has slightly richer data
- Low priority; acceptable to keep Android feature as enhancement
- Consider: iOS could add speed, or Android could remove it

---

### 23. Demo Mode Label (Resolved by Profile View)

**iOS Implementation:**
- "Demo Mode Active" label shown on `ProfileView` when in demo

**Android Current State:**
- No profile view = no demo label

**Gap:**
- Automatically resolved once `ProfileFragment` is built (#4)
- Add demo mode badge to profile stats section

---

## ✅ Already in Parity

These features exist and work in **both** iOS and Android:

- ✅ **Strava OAuth login** — Both apps authenticate with Strava, store tokens
- ✅ **Bike list** — Both display bikes with name, type, distance
- ✅ **Service intervals** — Basic create, read, update for intervals (though Android UI is simpler)
- ✅ **Service interval status** — Both calculate status (Good/Soon/Overdue) based on time/distance
- ✅ **Activities sync** — Both fetch from Strava and display (though history + distance unit differ slightly)
- ✅ **Onboarding tour** — Both have onboarding steps (though Android's routing is broken)
- ✅ **Notifications infrastructure** — Both have notification creation + sending capability (though Android worker is stub)
- ✅ **Demo mode** — Both support demo mode toggle + demo data
- ✅ **Deep links** — Both support deep link routing to detail screens

---

## Implementation Priority Roadmap

**Phase 1 (Critical — Core UX + Logic):**
1. Fix background sync worker (#5)
2. Add token refresh (#6)
3. Build ProfileFragment + stats (#4)
4. Add notification throttling (#7)

**Phase 2 (High — UX Polish):**
5. Service interval card richness (#2)
6. Service interval filter chips (#1)
7. Bikes tab card expansion (#3)
8. Bike deletion functional (#8)

**Phase 3 (Medium — Major Features):**
9. Smart bike detection (#9)
10. Preset confirmation flow (#10)
11. Service history table + UI (#15, #16, #17)
12. Part template expansion (#13)

**Phase 4 (Nice-to-Have):**
13. Hierarchical part picker (#14)
14. Batch date update (#12)
15. Bike type modal (#11)
16. Onboarding state persistence (#19)
17. Onboarding routing fix (#20)
18. Profile nav tap (#18)
19. Ad container placement (#21)

---

## Files Reference

**iOS Source** (reference only):
- `bikecheck/Views/` — UI components
- `bikecheck/ViewModels/` — state management
- `bikecheck/Services/BikeDetectionService.swift` — detection logic
- `bikecheck/Services/PartTemplateService.swift` — part templates
- `bikecheck/Services/NotificationService.swift` — notifications
- `bikecheck/Services/BackgroundTaskManager.swift` — background sync
- `bikecheck/Models/` — data models

**Android Source** (to be updated):
- `BikeCheckAndroid/app/src/main/java/com/bikecheck/android/ui/` — fragments/activities
- `BikeCheckAndroid/app/src/main/java/com/bikecheck/android/data/` — Room entities + DAOs
- `BikeCheckAndroid/app/src/main/java/com/bikecheck/android/work/SyncDataWorker.kt` — background sync (stub)
- `BikeCheckAndroid/app/src/main/java/com/bikecheck/android/notifications/NotificationService.kt` — notifications
- `BikeCheckAndroid/app/src/main/res/raw/service_templates.json` — part templates
- `BikeCheckAndroid/app/src/main/res/values/strings.xml` — localized strings

---

## Summary

The Android app requires **23 gaps** to be addressed to reach full feature parity with iOS. The highest-impact items are:
1. **Profile screen + stats** (flagship feature)
2. **Working background sync + notifications** (core functionality)
3. **Rich service interval UX** (main user interaction)
4. **Smart bike detection + setup flow** (onboarding experience)
5. **Service history** (tracking feature)

Estimated effort: ~8–12 weeks of focused development for all gaps. Prioritize Phase 1 + Phase 2 for an MVP-equivalent experience.
