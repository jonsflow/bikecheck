package com.bikecheck.android.data.database.entities

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "token_info",
    indices = [Index("athleteId")]
)
data class TokenInfoEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val accessToken: String,
    val refreshToken: String,
    val expiresAt: Long,
    val athleteId: Long?
)
