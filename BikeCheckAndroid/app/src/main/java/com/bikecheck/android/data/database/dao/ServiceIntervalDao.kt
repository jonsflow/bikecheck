package com.bikecheck.android.data.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import com.bikecheck.android.data.database.entities.ServiceIntervalEntity
import com.bikecheck.android.data.database.entities.ServiceIntervalWithBike
import kotlinx.coroutines.flow.Flow

@Dao
interface ServiceIntervalDao {
    @Query("SELECT * FROM service_intervals ORDER BY startTime ASC")
    fun getAllServiceIntervals(): Flow<List<ServiceIntervalEntity>>
    
    @Transaction
    @Query("SELECT * FROM service_intervals ORDER BY startTime ASC")
    fun getAllServiceIntervalsWithBikes(): Flow<List<ServiceIntervalWithBike>>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertServiceInterval(serviceInterval: ServiceIntervalEntity)
    
    @Query("DELETE FROM service_intervals")
    suspend fun deleteAllServiceIntervals()

    @Query("DELETE FROM service_intervals WHERE id = :id")
    suspend fun deleteServiceIntervalById(id: String)

    @Query("UPDATE service_intervals SET lastNotificationDate = :date WHERE id = :id")
    suspend fun updateLastNotificationDate(id: String, date: Long)

    @Query("SELECT * FROM service_intervals WHERE bikeId = :bikeId")
    fun getServiceIntervalsByBike(bikeId: String): Flow<List<ServiceIntervalEntity>>
}
