package com.bikecheck.android.services

import androidx.work.*
import com.bikecheck.android.work.SyncDataWorker
import java.util.concurrent.TimeUnit
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SyncService @Inject constructor(
    private val workManager: WorkManager
) {
    
    fun scheduleDailySync() {
        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .setRequiresBatteryNotLow(true)
            .build()
        
        val syncWorkRequest = PeriodicWorkRequestBuilder<SyncDataWorker>(
            repeatInterval = 24,
            repeatIntervalTimeUnit = TimeUnit.HOURS
        )
            .setConstraints(constraints)
            .setBackoffCriteria(
                BackoffPolicy.EXPONENTIAL,
                PeriodicWorkRequest.MIN_BACKOFF_MILLIS,
                TimeUnit.MILLISECONDS
            )
            .build()
        
        workManager.enqueueUniquePeriodicWork(
            SyncDataWorker.WORK_NAME,
            ExistingPeriodicWorkPolicy.KEEP,
            syncWorkRequest
        )
    }
    
    fun cancelSync() {
        workManager.cancelUniqueWork(SyncDataWorker.WORK_NAME)
    }
    
    fun triggerImmediateSync() {
        val syncWorkRequest = OneTimeWorkRequestBuilder<SyncDataWorker>()
            .setConstraints(
                Constraints.Builder()
                    .setRequiredNetworkType(NetworkType.CONNECTED)
                    .build()
            )
            .build()
        
        workManager.enqueue(syncWorkRequest)
    }
}