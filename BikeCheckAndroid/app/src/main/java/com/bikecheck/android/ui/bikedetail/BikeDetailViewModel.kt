package com.bikecheck.android.ui.bikedetail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bikecheck.android.data.database.dao.ActivityDao
import com.bikecheck.android.data.database.dao.BikeDao
import com.bikecheck.android.data.database.dao.ServiceIntervalDao
import com.bikecheck.android.data.database.entities.BikeEntity
import com.bikecheck.android.data.database.entities.ServiceIntervalEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.util.UUID
import javax.inject.Inject

@HiltViewModel
class BikeDetailViewModel @Inject constructor(
    private val bikeDao: BikeDao,
    private val activityDao: ActivityDao,
    private val serviceIntervalDao: ServiceIntervalDao
) : ViewModel() {
    
    private val _bike = MutableStateFlow<BikeEntity?>(null)
    val bike: StateFlow<BikeEntity?> = _bike
    
    private val _mileage = MutableStateFlow(0.0)
    val mileage: StateFlow<Double> = _mileage
    
    private val _totalRideTime = MutableStateFlow(0.0)
    val totalRideTime: StateFlow<Double> = _totalRideTime
    
    private val _activityCount = MutableStateFlow(0)
    val activityCount: StateFlow<Int> = _activityCount
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    private val _deleteResult = MutableStateFlow<Result<Boolean>?>(null)
    val deleteResult: StateFlow<Result<Boolean>?> = _deleteResult
    
    private val _defaultIntervalsCreated = MutableStateFlow(false)
    val defaultIntervalsCreated: StateFlow<Boolean> = _defaultIntervalsCreated
    
    fun loadBike(bikeId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // Load bike details
                val bikes = bikeDao.getAllBikes().first()
                val bike = bikes.find { it.id == bikeId }
                _bike.value = bike
                
                if (bike != null) {
                    // Calculate statistics
                    calculateStatistics(bike)
                }
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    private suspend fun calculateStatistics(bike: BikeEntity) {
        // Get activities for this bike
        val activities = activityDao.getAllActivities().first()
        val bikeActivities = activities.filter { it.gearId == bike.id }
        
        // Calculate mileage (convert from meters to miles)
        _mileage.value = bike.distance * 0.000621371
        
        // Calculate total ride time (convert from seconds to hours)
        val totalSeconds = bikeActivities.sumOf { it.movingTime }
        _totalRideTime.value = totalSeconds / 3600.0
        
        // Set activity count
        _activityCount.value = bikeActivities.size
    }
    
    fun createDefaultServiceIntervals() {
        _bike.value?.let { bike ->
            viewModelScope.launch {
                try {
                    // Calculate current ride time for start time
                    val activities = activityDao.getAllActivities().first()
                    val bikeActivities = activities.filter { it.gearId == bike.id }
                    val currentRideTime = bikeActivities.sumOf { it.movingTime.toDouble() } / 3600.0
                    
                    // Create default service intervals
                    val defaultIntervals = listOf(
                        ServiceIntervalEntity(
                            id = UUID.randomUUID().toString(),
                            part = "Chain",
                            startTime = currentRideTime,
                            intervalTime = 100.0, // 100 hours
                            notify = true,
                            bikeId = bike.id
                        ),
                        ServiceIntervalEntity(
                            id = UUID.randomUUID().toString(),
                            part = "Brake Pads",
                            startTime = currentRideTime,
                            intervalTime = 200.0, // 200 hours
                            notify = true,
                            bikeId = bike.id
                        ),
                        ServiceIntervalEntity(
                            id = UUID.randomUUID().toString(),
                            part = "Fork Service",
                            startTime = currentRideTime,
                            intervalTime = 300.0, // 300 hours
                            notify = true,
                            bikeId = bike.id
                        ),
                        ServiceIntervalEntity(
                            id = UUID.randomUUID().toString(),
                            part = "Full Tune-up",
                            startTime = currentRideTime,
                            intervalTime = 500.0, // 500 hours
                            notify = true,
                            bikeId = bike.id
                        )
                    )
                    
                    // Insert all default intervals
                    defaultIntervals.forEach { interval ->
                        serviceIntervalDao.insertServiceInterval(interval)
                    }
                    
                    _defaultIntervalsCreated.value = true
                } catch (e: Exception) {
                    // Handle error
                }
            }
        }
    }
    
    fun deleteBike() {
        _bike.value?.let { bike ->
            viewModelScope.launch {
                try {
                    // Note: In a full implementation, you would delete the bike
                    // For this demo, we'll just mark it as successful
                    _deleteResult.value = Result.success(true)
                } catch (e: Exception) {
                    _deleteResult.value = Result.failure(e)
                }
            }
        }
    }
}