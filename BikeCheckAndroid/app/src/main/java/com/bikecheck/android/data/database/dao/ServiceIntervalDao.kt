package com.bikecheck.android.data.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bikecheck.android.data.database.entities.ServiceIntervalEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface ServiceIntervalDao {
    @Query("SELECT * FROM service_intervals ORDER BY startTime ASC")
    fun getAllServiceIntervals(): Flow<List<ServiceIntervalEntity>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertServiceInterval(serviceInterval: ServiceIntervalEntity)
    
    @Query("DELETE FROM service_intervals")
    suspend fun deleteAllServiceIntervals()
}