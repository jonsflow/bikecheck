package com.bikecheck.android.ui.serviceinterval

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
class AddServiceIntervalViewModel @Inject constructor(
    private val bikeDao: BikeDao,
    private val serviceIntervalDao: ServiceIntervalDao,
    private val activityDao: ActivityDao
) : ViewModel() {
    
    private val _bikes = MutableStateFlow<List<BikeEntity>>(emptyList())
    val bikes: StateFlow<List<BikeEntity>> = _bikes
    
    private val _selectedBike = MutableStateFlow<BikeEntity?>(null)
    val selectedBike: StateFlow<BikeEntity?> = _selectedBike
    
    private val _part = MutableStateFlow("")
    val part: StateFlow<String> = _part
    
    private val _intervalTime = MutableStateFlow(0.0)
    val intervalTime: StateFlow<Double> = _intervalTime
    
    private val _notify = MutableStateFlow(true)
    val notify: StateFlow<Boolean> = _notify
    
    private val _timeUntilService = MutableStateFlow(0.0)
    val timeUntilService: StateFlow<Double> = _timeUntilService
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    private val _saveResult = MutableStateFlow<Result<Boolean>?>(null)
    val saveResult: StateFlow<Result<Boolean>?> = _saveResult
    
    private var currentServiceInterval: ServiceIntervalEntity? = null
    
    fun loadBikes() {
        viewModelScope.launch {
            _bikes.value = bikeDao.getAllBikes().first()
            if (_bikes.value.isNotEmpty() && _selectedBike.value == null) {
                _selectedBike.value = _bikes.value.first()
            }
        }
    }
    
    fun loadServiceInterval(serviceIntervalId: String) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // Load bikes first
                loadBikes()
                
                // Find and load the service interval
                val allIntervals = serviceIntervalDao.getAllServiceIntervals().first()
                val serviceInterval = allIntervals.find { it.id == serviceIntervalId }
                
                serviceInterval?.let { interval ->
                    currentServiceInterval = interval
                    _part.value = interval.part
                    _intervalTime.value = interval.intervalTime
                    _notify.value = interval.notify
                    
                    // Find and set the associated bike
                    val bike = _bikes.value.find { it.id == interval.bikeId }
                    _selectedBike.value = bike
                    
                    // Calculate time until service
                    calculateTimeUntilService(interval)
                }
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    private suspend fun calculateTimeUntilService(serviceInterval: ServiceIntervalEntity) {
        // Get bike's current ride time from activities
        val activities = activityDao.getAllActivities().first()
        val bikeActivities = activities.filter { it.gearId == serviceInterval.bikeId }
        val totalRideTimeHours = bikeActivities.sumOf { it.movingTime.toDouble() } / 3600.0
        
        val timeUsedSinceService = totalRideTimeHours - serviceInterval.startTime
        val timeUntilService = serviceInterval.intervalTime - timeUsedSinceService
        
        _timeUntilService.value = timeUntilService
    }
    
    fun saveServiceInterval(
        selectedBikeIndex: Int,
        part: String,
        intervalTimeText: String,
        notify: Boolean
    ) {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val selectedBike = if (selectedBikeIndex >= 0 && selectedBikeIndex < _bikes.value.size) {
                    _bikes.value[selectedBikeIndex]
                } else {
                    _bikes.value.firstOrNull()
                }
                
                if (selectedBike == null || part.isBlank()) {
                    _saveResult.value = Result.failure(Exception("Please fill in all required fields"))
                    return@launch
                }
                
                val intervalTime = intervalTimeText.toDoubleOrNull()
                if (intervalTime == null || intervalTime <= 0) {
                    _saveResult.value = Result.failure(Exception("Please enter a valid interval time"))
                    return@launch
                }
                
                // Calculate current ride time for start time
                val activities = activityDao.getAllActivities().first()
                val bikeActivities = activities.filter { it.gearId == selectedBike.id }
                val currentRideTime = bikeActivities.sumOf { it.movingTime.toDouble() } / 3600.0
                
                val serviceInterval = if (currentServiceInterval != null) {
                    // Update existing
                    currentServiceInterval!!.copy(
                        part = part,
                        intervalTime = intervalTime,
                        notify = notify,
                        bikeId = selectedBike.id
                    )
                } else {
                    // Create new
                    ServiceIntervalEntity(
                        id = UUID.randomUUID().toString(),
                        part = part,
                        startTime = currentRideTime,
                        intervalTime = intervalTime,
                        notify = notify,
                        bikeId = selectedBike.id
                    )
                }
                
                serviceIntervalDao.insertServiceInterval(serviceInterval)
                _saveResult.value = Result.success(true)
            } catch (e: Exception) {
                _saveResult.value = Result.failure(e)
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun resetInterval() {
        currentServiceInterval?.let { interval ->
            viewModelScope.launch {
                // Calculate current ride time
                val activities = activityDao.getAllActivities().first()
                val bikeActivities = activities.filter { it.gearId == interval.bikeId }
                val currentRideTime = bikeActivities.sumOf { it.movingTime.toDouble() } / 3600.0
                
                val resetInterval = interval.copy(startTime = currentRideTime)
                serviceIntervalDao.insertServiceInterval(resetInterval)
                
                // Recalculate time until service
                calculateTimeUntilService(resetInterval)
            }
        }
    }
    
    fun deleteInterval() {
        currentServiceInterval?.let { interval ->
            viewModelScope.launch {
                serviceIntervalDao.deleteServiceIntervalById(interval.id)
                _saveResult.value = Result.success(true)
            }
        }
    }
}
