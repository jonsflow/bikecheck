package com.bikecheck.android.ui.activities

import androidx.lifecycle.ViewModel
import com.bikecheck.android.data.database.dao.ActivityDao
import com.bikecheck.android.data.database.entities.ActivityEntity
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject

@HiltViewModel
class ActivitiesViewModel @Inject constructor(
    private val activityDao: ActivityDao
) : ViewModel() {
    
    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading
    
    val activities: Flow<List<ActivityEntity>> = activityDao.getAllActivities()
}