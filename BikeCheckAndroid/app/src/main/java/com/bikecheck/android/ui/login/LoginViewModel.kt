package com.bikecheck.android.ui.login

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bikecheck.android.data.repository.StravaRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class LoginViewModel @Inject constructor(
    private val stravaRepository: StravaRepository
) : ViewModel() {
    
    private val _isLoading = MutableLiveData<Boolean>()
    val isLoading: LiveData<Boolean> = _isLoading
    
    private val _authenticationResult = MutableLiveData<Result<Boolean>>()
    val authenticationResult: LiveData<Result<Boolean>> = _authenticationResult
    
    fun authenticate(authCode: String) {
        _isLoading.value = true
        viewModelScope.launch {
            val result = stravaRepository.authenticate(authCode)
            _authenticationResult.value = result
            _isLoading.value = false
        }
    }
    
    fun insertTestData() {
        _isLoading.value = true
        viewModelScope.launch {
            val result = stravaRepository.insertTestData()
            _authenticationResult.value = result
            _isLoading.value = false
        }
    }
}