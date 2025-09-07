package com.bikecheck.android.utils

import com.bikecheck.android.BuildConfig

object Constants {
    const val STRAVA_BASE_URL = "https://www.strava.com/"
    const val STRAVA_CLIENT_ID = BuildConfig.STRAVA_CLIENT_ID
    const val STRAVA_CLIENT_SECRET = BuildConfig.STRAVA_CLIENT_SECRET
    const val STRAVA_REDIRECT_URI = "bikecheck://bikecheck-callback"
    const val STRAVA_SCOPE = "read,profile:read_all,activity:read_all"
}