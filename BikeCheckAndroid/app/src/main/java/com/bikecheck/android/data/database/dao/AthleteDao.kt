package com.bikecheck.android.data.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bikecheck.android.data.database.entities.AthleteEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface AthleteDao {
    @Query("SELECT * FROM athletes LIMIT 1")
    fun getCurrentAthlete(): Flow<AthleteEntity?>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAthlete(athlete: AthleteEntity)
    
    @Query("DELETE FROM athletes")
    suspend fun deleteAllAthletes()
}