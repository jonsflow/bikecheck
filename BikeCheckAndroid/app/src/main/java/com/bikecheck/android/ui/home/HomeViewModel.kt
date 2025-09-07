package com.bikecheck.android.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bikecheck.android.data.database.dao.ActivityDao
import com.bikecheck.android.data.database.dao.AthleteDao
import com.bikecheck.android.data.database.dao.BikeDao
import com.bikecheck.android.data.database.dao.ServiceIntervalDao
import com.bikecheck.android.data.database.dao.TokenInfoDao
import com.bikecheck.android.data.database.entities.ActivityEntity
import com.bikecheck.android.data.database.entities.AthleteEntity
import com.bikecheck.android.data.database.entities.BikeEntity
import com.bikecheck.android.data.database.entities.ServiceIntervalEntity
import com.bikecheck.android.data.database.entities.ServiceIntervalWithBike
import com.bikecheck.android.data.repository.StravaRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val stravaRepository: StravaRepository,
    private val athleteDao: AthleteDao,
    private val bikeDao: BikeDao,
    private val serviceIntervalDao: ServiceIntervalDao,
    private val activityDao: ActivityDao,
    private val tokenInfoDao: TokenInfoDao
) : ViewModel() {
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    val currentAthlete: Flow<AthleteEntity?> = athleteDao.getCurrentAthlete()
    val bikes: Flow<List<BikeEntity>> = bikeDao.getAllBikes()
    val serviceIntervals: Flow<List<ServiceIntervalWithBike>> = serviceIntervalDao.getAllServiceIntervalsWithBikes()
    val activities: Flow<List<ActivityEntity>> = activityDao.getAllActivities()
    
    fun refreshData() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                stravaRepository.syncDataFromStrava()
            } catch (e: Exception) {
                // Handle error silently or emit error state
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    fun signOut() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                // Clear all data to sign out
                clearAllData()
            } finally {
                _isLoading.value = false
            }
        }
    }
    
    private suspend fun clearAllData() {
        serviceIntervalDao.deleteAllServiceIntervals()
        bikeDao.deleteAllBikes()
        athleteDao.deleteAllAthletes()
        // Clear tokens to sign out
        tokenInfoDao.deleteAllTokens()
    }
}