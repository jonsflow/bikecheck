package com.bikecheck.android.data.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.bikecheck.android.data.database.entities.TokenInfoEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface TokenInfoDao {
    @Query("SELECT * FROM token_info LIMIT 1")
    suspend fun getToken(): TokenInfoEntity?
    
    @Query("SELECT COUNT(*) > 0 FROM token_info")
    fun hasTokens(): Flow<Boolean>
    
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertToken(token: TokenInfoEntity)
    
    @Query("DELETE FROM token_info")
    suspend fun deleteAllTokens()
}