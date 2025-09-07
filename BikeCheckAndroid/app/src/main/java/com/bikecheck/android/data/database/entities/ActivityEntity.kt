package com.bikecheck.android.data.database.entities

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.Date

@Entity(
    tableName = "activities",
    indices = [Index("gearId")]
)
data class ActivityEntity(
    @PrimaryKey
    val id: Long,
    val gearId: String?,
    val name: String,
    val type: String,
    val movingTime: Long,
    val startDate: Date,
    val distance: Double,
    val averageSpeed: Double,
    val processed: Boolean = false
)