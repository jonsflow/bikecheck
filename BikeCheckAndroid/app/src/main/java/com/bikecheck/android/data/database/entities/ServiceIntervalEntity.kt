package com.bikecheck.android.data.database.entities

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import java.util.UUID

@Entity(
    tableName = "service_intervals",
    foreignKeys = [
        ForeignKey(
            entity = BikeEntity::class,
            parentColumns = ["id"],
            childColumns = ["bikeId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("bikeId")]
)
data class ServiceIntervalEntity(
    @PrimaryKey
    val id: String = UUID.randomUUID().toString(),
    val part: String,
    val startTime: Double,
    val intervalTime: Double,
    val notify: Boolean,
    val bikeId: String,
    val lastNotificationDate: Long? = null
)