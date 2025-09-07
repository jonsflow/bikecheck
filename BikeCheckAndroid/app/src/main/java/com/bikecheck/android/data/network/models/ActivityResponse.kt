package com.bikecheck.android.data.network.models

import com.google.gson.annotations.SerializedName

data class ActivityResponse(
    @SerializedName("id")
    val id: Long,
    @SerializedName("gear_id")
    val gearId: String?,
    @SerializedName("name")
    val name: String,
    @SerializedName("type")
    val type: String,
    @SerializedName("moving_time")
    val movingTime: Long,
    @SerializedName("start_date")
    val startDate: String,
    @SerializedName("distance")
    val distance: Double,
    @SerializedName("average_speed")
    val averageSpeed: Double
)