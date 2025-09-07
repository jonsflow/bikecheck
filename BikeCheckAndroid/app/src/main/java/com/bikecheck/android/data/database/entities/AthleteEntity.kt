package com.bikecheck.android.data.database.entities

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "athletes")
data class AthleteEntity(
    @PrimaryKey
    val id: Long,
    val firstname: String,
    val profile: String?
)