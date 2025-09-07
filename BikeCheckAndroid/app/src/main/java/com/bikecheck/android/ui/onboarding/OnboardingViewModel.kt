package com.bikecheck.android.ui.onboarding

import android.content.SharedPreferences
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bikecheck.android.data.repository.StravaRepository
import com.bikecheck.android.models.TourStep
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class OnboardingViewModel @Inject constructor(
    private val stravaRepository: StravaRepository,
    private val sharedPreferences: SharedPreferences
) : ViewModel() {
    
    private val _showOnboarding = MutableStateFlow(false)
    val showOnboarding: StateFlow<Boolean> = _showOnboarding
    
    private val _showTour = MutableStateFlow(false)
    val showTour: StateFlow<Boolean> = _showTour
    
    private val _currentTourStep = MutableStateFlow(0)
    val currentTourStep: StateFlow<Int> = _currentTourStep
    
    private val _isLoadingTestData = MutableStateFlow(false)
    val isLoadingTestData: StateFlow<Boolean> = _isLoadingTestData
    
    fun startOnboarding() {
        _showOnboarding.value = true
    }
    
    fun loadTestDataIfNeeded() {
        if (_isLoadingTestData.value) return
        
        _isLoadingTestData.value = true
        viewModelScope.launch {
            try {
                stravaRepository.insertTestData()
            } finally {
                _isLoadingTestData.value = false
            }
        }
    }
    
    fun startTour() {
        _showOnboarding.value = false
        _showTour.value = true
        _currentTourStep.value = 0
        
        // Load test data when starting tour
        loadTestDataIfNeeded()
    }
    
    fun skipTour() {
        _showOnboarding.value = false
        _showTour.value = false
        markOnboardingComplete()
        clearTestData()
    }
    
    fun nextTourStep() {
        val tourSteps = TourStep.values()
        if (_currentTourStep.value < tourSteps.size - 1) {
            _currentTourStep.value += 1
        } else {
            completeTour()
        }
    }
    
    fun previousTourStep() {
        if (_currentTourStep.value > 0) {
            _currentTourStep.value -= 1
        }
    }
    
    fun completeTour() {
        _showTour.value = false
        _currentTourStep.value = 0
        
        // Mark onboarding as complete
        markOnboardingComplete()
        
        // Clear test data when tour completes
        clearTestData()
    }
    
    private fun markOnboardingComplete() {
        sharedPreferences.edit()
            .putBoolean("is_first_launch", false)
            .apply()
    }
    
    private fun clearTestData() {
        viewModelScope.launch {
            // In a full implementation, you would clear test data here
            // For now, we'll leave the test data in place
        }
    }
    
    fun getCurrentTourStep(): TourStep? {
        val tourSteps = TourStep.values()
        return if (_currentTourStep.value < tourSteps.size) {
            tourSteps[_currentTourStep.value]
        } else {
            null
        }
    }
}