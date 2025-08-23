package com.bikecheck.android.ui

import android.content.Intent
import android.content.SharedPreferences
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bikecheck.android.ui.home.HomeActivity
import com.bikecheck.android.ui.login.LoginActivity
import com.bikecheck.android.ui.onboarding.OnboardingActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {

    private val viewModel: MainViewModel by viewModels()
    
    @Inject
    lateinit var sharedPreferences: SharedPreferences

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Handle deep links first
        if (handleDeepLink()) {
            return
        }
        
        // Check if this is the first launch
        val isFirstLaunch = sharedPreferences.getBoolean("is_first_launch", true)
        
        if (isFirstLaunch) {
            // Show onboarding for first-time users
            startActivity(Intent(this, OnboardingActivity::class.java))
            finish()
            return
        }
        
        // Check authentication status and navigate accordingly for returning users
        lifecycleScope.launch {
            val isSignedIn = viewModel.isSignedIn.first()
            val targetActivity = if (isSignedIn) {
                HomeActivity::class.java
            } else {
                LoginActivity::class.java
            }
            
            startActivity(Intent(this@MainActivity, targetActivity))
            finish()
        }
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleDeepLink()
    }
    
    private fun handleDeepLink(): Boolean {
        val data = intent.data
        if (data != null && data.scheme == "bikecheck") {
            when (data.host) {
                "service-interval" -> {
                    val serviceIntervalId = data.pathSegments.firstOrNull()
                    if (!serviceIntervalId.isNullOrEmpty()) {
                        val intent = Intent(this, com.bikecheck.android.ui.serviceinterval.AddServiceIntervalActivity::class.java).apply {
                            putExtra("service_interval_id", serviceIntervalId)
                        }
                        startActivity(intent)
                        finish()
                        return true
                    }
                }
                "bike" -> {
                    val bikeId = data.pathSegments.firstOrNull()
                    if (!bikeId.isNullOrEmpty()) {
                        val intent = Intent(this, com.bikecheck.android.ui.bikedetail.BikeDetailActivity::class.java).apply {
                            putExtra("bike_id", bikeId)
                        }
                        startActivity(intent)
                        finish()
                        return true
                    }
                }
            }
        }
        return false
    }
}