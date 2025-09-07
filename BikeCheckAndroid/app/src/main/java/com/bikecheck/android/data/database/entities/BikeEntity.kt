package com.bikecheck.android.data.database.entities

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "bikes",
    foreignKeys = [
        ForeignKey(
            entity = AthleteEntity::class,
            parentColumns = ["id"],
            childColumns = ["athleteId"],
            onDelete = ForeignKey.CASCADE
        )
    ],
    indices = [Index("athleteId")]
)
data class BikeEntity(
    @PrimaryKey
    val id: String,
    val name: String,
    val distance: Double,
    val athleteId: Long,
    val type: String? = null
)
