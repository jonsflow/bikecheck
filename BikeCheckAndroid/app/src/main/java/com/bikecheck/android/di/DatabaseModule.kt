package com.bikecheck.android.di

import android.content.Context
import androidx.room.Room
import com.bikecheck.android.data.database.AppDatabase
import com.bikecheck.android.data.database.dao.*
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        return Room.databaseBuilder(
            context.applicationContext,
            AppDatabase::class.java,
            "bikecheck_database"
        ).fallbackToDestructiveMigration().build()
    }

    @Provides
    fun provideAthleteDao(database: AppDatabase): AthleteDao = database.athleteDao()

    @Provides
    fun provideTokenInfoDao(database: AppDatabase): TokenInfoDao = database.tokenInfoDao()

    @Provides
    fun provideBikeDao(database: AppDatabase): BikeDao = database.bikeDao()

    @Provides
    fun provideActivityDao(database: AppDatabase): ActivityDao = database.activityDao()

    @Provides
    fun provideServiceIntervalDao(database: AppDatabase): ServiceIntervalDao = database.serviceIntervalDao()
}