package com.bikecheck.android.work

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.bikecheck.android.data.database.dao.ActivityDao
import com.bikecheck.android.data.database.dao.BikeDao
import com.bikecheck.android.data.database.dao.ServiceIntervalDao
import com.bikecheck.android.data.repository.StravaRepository
import com.bikecheck.android.notifications.NotificationService
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.flow.first

@HiltWorker
class SyncDataWorker @AssistedInject constructor(
    @Assisted context: Context,
    @Assisted workerParams: WorkerParameters,
    private val stravaRepository: StravaRepository,
    private val serviceIntervalDao: ServiceIntervalDao,
    private val activityDao: ActivityDao,
    private val bikeDao: BikeDao,
    private val notificationService: NotificationService
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            // 1. Refresh Strava data
            stravaRepository.syncDataFromStrava()

            // 2. Check for overdue service intervals and send throttled notifications
            val intervals = serviceIntervalDao.getAllServiceIntervals().first()
            val activities = activityDao.getAllActivities().first()

            intervals.filter { it.notify }.forEach { interval ->
                val totalSeconds = activities
                    .filter { it.gearId == interval.bikeId }
                    .sumOf { it.movingTime }
                val hoursRidden = totalSeconds / 3600.0
                val usageSinceStart = hoursRidden - interval.startTime
                val fractionUsed = if (interval.intervalTime > 0) usageSinceStart / interval.intervalTime else 0.0

                if (fractionUsed >= 1.0) {
                    // Check 7-day throttle (604_800_000 ms)
                    val now = System.currentTimeMillis()
                    val lastNotified = interval.lastNotificationDate ?: 0L
                    if (now - lastNotified >= 604_800_000L) {
                        val bike = bikeDao.getBikeById(interval.bikeId)
                        if (bike != null) {
                            notificationService.sendServiceReminderNotification(interval, bike.name)
                            serviceIntervalDao.updateLastNotificationDate(interval.id, now)
                        }
                    }
                }
            }
            Result.success()
        } catch (exception: Exception) {
            android.util.Log.e("SyncDataWorker", "Error during sync", exception)
            Result.failure()
        }
    }

    companion object {
        const val WORK_NAME = "sync_data_work"
    }
}