package com.bikecheck.android.ui

import androidx.lifecycle.ViewModel
import com.bikecheck.android.data.repository.StravaRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject

@HiltViewModel
class MainViewModel @Inject constructor(
    private val stravaRepository: StravaRepository
) : ViewModel() {
    
    val isSignedIn: Flow<Boolean> = stravaRepository.isSignedIn
    
    suspend fun getTokenCount(): Int {
        return stravaRepository.getTokenCount()
    }
}