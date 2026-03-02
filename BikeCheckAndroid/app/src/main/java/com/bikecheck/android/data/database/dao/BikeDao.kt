package com.bikecheck.android.data.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Upsert
import androidx.room.Query
import androidx.room.Transaction
import com.bikecheck.android.data.database.entities.BikeEntity
import com.bikecheck.android.data.database.entities.BikeWithServiceIntervals
import kotlinx.coroutines.flow.Flow

@Dao
interface BikeDao {
    @Query("SELECT * FROM bikes ORDER BY name ASC")
    fun getAllBikes(): Flow<List<BikeEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBikes(bikes: List<BikeEntity>)

    @Upsert
    suspend fun upsertBikes(bikes: List<BikeEntity>)
    
    @Query("DELETE FROM bikes")
    suspend fun deleteAllBikes()

    @Query("DELETE FROM bikes WHERE id = :id")
    suspend fun deleteBikeById(id: String)

    @Query("SELECT * FROM bikes WHERE id = :id")
    suspend fun getBikeById(id: String): BikeEntity?

    @Transaction
    @Query("SELECT * FROM bikes ORDER BY name ASC")
    fun getAllBikesWithServiceIntervals(): Flow<List<BikeWithServiceIntervals>>
}
