# ServiceInterval List Filtering - Design Recommendations

## Overview
Research and design recommendations for implementing iOS-native filtering patterns in the ServiceInterval list view. Currently, the ServiceView shows a smart-filtered subset (overdue + next upcoming per bike) but lacks user transparency and control.

## iOS Filtering Best Practices Research

### Native iOS Patterns
- **`.searchable()` Modifier**: Primary SwiftUI filtering method
  - Requires NavigationStack/NavigationView container
  - Search bar appears in navigation area
  - Real-time filtering with computed properties
  
- **Platform-Specific Controls**:
  - **Segmented Controls**: Apple's preferred for 2-5 related options
  - **Picker Controls**: For longer option lists
  - **Action Sheets**: Modal filter selection
  - **Bottom Sheets**: Touch-friendly mobile pattern

### iOS Design Guidelines
- **Accessibility**: 44pt minimum touch targets, clear labels
- **Consistency**: Predictable placement (top bars, sticky filters)
- **Feedback**: Clear visual indication of active filters
- **Reset Options**: Easy "Clear All" functionality
- **Performance**: Use computed properties, avoid expensive operations

## Current State Analysis
- **Current Behavior**: Smart filtering shows overdue + next upcoming per bike
- **Problem**: "Black box" experience - users can't see or control filtering logic
- **Opportunity**: Add transparency and user control while maintaining smart defaults

## Proposed Filter Dimensions

### 1. Status-Based Filtering (Primary)
- ✅ **Overdue** (current usage ≥ interval time)
- ⚠️ **Due Soon** (90%+ of interval time) 
- ✅ **Good** (< 90% of interval time)
- 📊 **All** (show everything)

### 2. Component-Based Filtering (Secondary)
- 🔗 **Chain** components
- 🔧 **Fork** components
- ⚡ **Shock** components  
- 🔩 **Other** components

### 3. Bike-Based Filtering (Secondary)
- 🚲 **Specific bike** selection
- 🏔️ **All bikes** (current default)

### 4. Time-Based Filtering (Future Enhancement)
- ⏰ **Next 30 days**
- ⏱️ **Next 7 days**
- 📅 **Custom date range**

## Recommended Implementation

### Phase 1: Status Filtering (Segmented Control)
```
[ Overdue | Due Soon | Good | All ]
```
- **Why**: Perfect for 4 status options, very iOS-native
- **Placement**: Top of list, always visible
- **Behavior**: Immediate filtering, no "Apply" button needed
- **Default**: "Overdue" to maintain current smart filtering UX

### Phase 2: Search Integration
- **Search Bar**: `.searchable()` for component name/bike name filtering
- **Placement**: Search in navigation bar
- **Behavior**: Real-time text filtering combined with status filter

### Phase 3: Advanced Filters (Component Type)
- **Filter Button**: iOS-native menu button for component type filtering
- **Placement**: Toolbar or navigation bar trailing position
- **Options**: Chain, Fork, Shock, Other, All

## User Experience Benefits

### Transparency
- Users understand what they're seeing
- Clear control over data presentation  
- No "hidden" filtering logic

### Efficiency
- Quick access to overdue items for urgent action
- Focused view for specific maintenance categories
- Search for specific components across all bikes

### Scalability
- Works with growing number of service intervals
- Accommodates multiple bikes
- Supports different component types

## Technical Implementation Notes

### SwiftUI Pattern
```swift
@State private var selectedStatus: ServiceStatus = .overdue
@State private var searchText = ""

var filteredServiceIntervals: [ServiceInterval] {
    serviceIntervals
        .filter { interval in
            // Status filtering
            switch selectedStatus {
            case .overdue: return isOverdue(interval)
            case .dueSoon: return isDueSoon(interval)
            case .good: return isGood(interval)
            case .all: return true
            }
        }
        .filter { interval in
            // Search filtering
            searchText.isEmpty || 
            interval.part.localizedCaseInsensitiveContains(searchText) ||
            interval.bike.name.localizedCaseInsensitiveContains(searchText)
        }
}
```

### Navigation Structure
- Ensure ServiceView is properly embedded in NavigationStack
- Add `.searchable(text: $searchText)` modifier
- Use computed properties for real-time filtering performance

## Design Considerations

### Mobile Optimization
- **Touch Targets**: Minimum 44pt for all interactive elements
- **Thumb Accessibility**: Important controls in easy-reach zones
- **Visual Feedback**: Active filter states clearly indicated

### Performance
- Use computed properties for filtering (not expensive operations)
- Consider pagination for large datasets
- Maintain responsive UI during filtering operations

## Future Enhancements

### Advanced Features
- **Filter Presets**: Save commonly used filter combinations
- **Filter History**: Recent filter selections
- **Smart Suggestions**: Auto-complete for search terms
- **Export Filtered Results**: Share filtered service interval lists

### Analytics Opportunities
- Track most-used filter combinations
- Identify common search patterns
- Optimize default filter states based on usage

## Implementation Priority

1. **High Priority**: Status-based segmented control filtering
2. **Medium Priority**: Search functionality with `.searchable()`
3. **Low Priority**: Component-type filtering menu
4. **Future**: Time-based and advanced filtering options

## Success Metrics

- **User Engagement**: Increased time spent in ServiceView
- **Task Completion**: Faster identification of overdue services
- **User Satisfaction**: Reduced "can't find what I'm looking for" feedback
- **Performance**: Sub-100ms filter response times

---

*Last Updated: October 8, 2025*
*Status: Research Complete - Ready for Implementation*