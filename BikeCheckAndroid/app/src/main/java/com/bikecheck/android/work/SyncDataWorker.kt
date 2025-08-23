package com.bikecheck.android.work

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.bikecheck.android.data.repository.StravaRepository
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject

@HiltWorker
class SyncDataWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val stravaRepository: StravaRepository
) : CoroutineWorker(context, workerParams) {
    
    override suspend fun doWork(): Result {
        return try {
            // In a real implementation, you would sync data from Strava API here
            // For this demo, we'll just indicate success
            Result.success()
        } catch (exception: Exception) {
            Result.failure()
        }
    }
    
    companion object {
        const val WORK_NAME = "sync_data_work"
    }
}