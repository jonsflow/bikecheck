package com.bikecheck.android.data.network.models

import com.google.gson.annotations.SerializedName

data class BikeResponse(
    @SerializedName("id")
    val id: String,
    @SerializedName("name")
    val name: String,
    @SerializedName("distance")
    val distance: Double,
    @SerializedName("primary")
    val primary: Boolean? = false
)