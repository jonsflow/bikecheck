package com.bikecheck.android.ui.profile

import androidx.lifecycle.ViewModel
import com.bikecheck.android.data.database.dao.ActivityDao
import com.bikecheck.android.data.database.dao.AthleteDao
import com.bikecheck.android.data.database.dao.BikeDao
import com.bikecheck.android.data.database.dao.ServiceIntervalDao
import com.bikecheck.android.data.database.entities.AthleteEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import javax.inject.Inject

@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val bikeDao: BikeDao,
    private val serviceIntervalDao: ServiceIntervalDao,
    private val activityDao: ActivityDao,
    private val athleteDao: AthleteDao
) : ViewModel() {

    data class Stats(
        val bikeCount: Int,
        val totalKm: Double,
        val totalHours: Double,
        val activityCount: Int,
        val partsTracked: Int,
        val overdueCount: Int
    )

    val stats: Flow<Stats> = combine(
        bikeDao.getAllBikes(),
        serviceIntervalDao.getAllServiceIntervals(),
        activityDao.getAllActivities()
    ) { bikes, intervals, activities ->
        val totalMeters = bikes.sumOf { it.distance }
        val totalSeconds = activities.sumOf { it.movingTime }
        val overdueCount = intervals.count { interval ->
            val usedHours = activities.filter { it.gearId == interval.bikeId }.sumOf { it.movingTime } / 3600.0
            val remaining = interval.intervalTime - (usedHours - interval.startTime)
            remaining <= 0.0
        }
        Stats(
            bikeCount = bikes.size,
            totalKm = totalMeters / 1000.0,
            totalHours = totalSeconds / 3600.0,
            activityCount = activities.size,
            partsTracked = intervals.size,
            overdueCount = overdueCount
        )
    }

    val athlete: Flow<AthleteEntity?> = athleteDao.getCurrentAthlete()
}
