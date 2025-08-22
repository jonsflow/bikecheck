package com.bikecheck.android.models

enum class OnboardingStep(val title: String, val subtitle: String, val shouldLoadTestData: Boolean) {
    WELCOME(
        title = "Welcome to BikeCheck!",
        subtitle = "Track your bike maintenance effortlessly. Ready to explore? Choose how you'd like to get started.",
        shouldLoadTestData = false
    )
}

enum class TourStep(val title: String, val description: String) {
    BIKES_OVERVIEW(
        title = "Your Bikes",
        description = "Here you can see all your bikes imported from Strava or added manually."
    ),
    SERVICE_INTERVALS(
        title = "Service Intervals", 
        description = "Track maintenance schedules for different bike components like chains, brakes, and more."
    ),
    ACTIVITIES(
        title = "Recent Activities",
        description = "View your latest rides and track how they affect your maintenance schedules."
    ),
    NOTIFICATIONS(
        title = "Stay Updated",
        description = "Get notified when it's time to service your bike components."
    )
}