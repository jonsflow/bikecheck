package com.bikecheck.android.data.network.models

import com.google.gson.annotations.SerializedName

data class AthleteResponse(
    @SerializedName("id")
    val id: Long,
    @SerializedName("firstname")
    val firstname: String,
    @SerializedName("profile")
    val profile: String?,
    @SerializedName("bikes")
    val bikes: List<BikeResponse>?
)