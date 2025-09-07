package com.bikecheck.android.ui

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bikecheck.android.ui.home.HomeActivity
import com.bikecheck.android.ui.login.LoginActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : AppCompatActivity() {

    private val viewModel: MainViewModel by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        android.util.Log.d("MainActivity", "onCreate started")
        
        // Handle deep links first
        if (handleDeepLink()) {
            android.util.Log.d("MainActivity", "Deep link handled, returning early")
            return
        }
        
        android.util.Log.d("MainActivity", "Skipping onboarding, going directly to authentication check")
        
        // Simply check if token exists in database and launch appropriate activity
        lifecycleScope.launch {
            val tokenCount = viewModel.getTokenCount()
            val hasToken = tokenCount > 0
            android.util.Log.d("MainActivity", "Token count: $tokenCount, hasToken: $hasToken")
            
            val targetActivity = if (hasToken) {
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