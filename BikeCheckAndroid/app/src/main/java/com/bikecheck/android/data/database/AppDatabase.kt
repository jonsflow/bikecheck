package com.bikecheck.android.data.database

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.bikecheck.android.data.database.dao.*
import com.bikecheck.android.data.database.entities.*
import com.bikecheck.android.utils.DateConverter

@Database(
    entities = [
        AthleteEntity::class,
        TokenInfoEntity::class,
        BikeEntity::class,
        ActivityEntity::class,
        ServiceIntervalEntity::class
    ],
    version = 1,
    exportSchema = true
)
@TypeConverters(DateConverter::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun athleteDao(): AthleteDao
    abstract fun tokenInfoDao(): TokenInfoDao
    abstract fun bikeDao(): BikeDao
    abstract fun activityDao(): ActivityDao
    abstract fun serviceIntervalDao(): ServiceIntervalDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AppDatabase::class.java,
                    "bikecheck_database"
                ).build()
                INSTANCE = instance
                instance
            }
        }
    }
}