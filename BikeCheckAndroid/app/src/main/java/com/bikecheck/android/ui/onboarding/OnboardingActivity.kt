package com.bikecheck.android.ui.onboarding

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bikecheck.android.databinding.ActivityOnboardingBinding
import com.bikecheck.android.models.OnboardingStep
import com.bikecheck.android.ui.home.HomeActivity
import com.bikecheck.android.ui.login.LoginActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class OnboardingActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityOnboardingBinding
    private val viewModel: OnboardingViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityOnboardingBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupUI()
        setupObservers()
        setupClickListeners()
        
        // Start onboarding automatically
        viewModel.startOnboarding()
    }
    
    private fun setupUI() {
        val step = OnboardingStep.WELCOME
        binding.textViewTitle.text = step.title
        binding.textViewSubtitle.text = step.subtitle
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.showOnboarding.collect { showOnboarding ->
                if (!showOnboarding && !viewModel.showTour.value) {
                    // If onboarding is dismissed and no tour, go to login
                    startActivity(Intent(this@OnboardingActivity, LoginActivity::class.java))
                    finish()
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.showTour.collect { showTour ->
                if (showTour) {
                    // If tour is started, go to home with test data
                    startActivity(Intent(this@OnboardingActivity, HomeActivity::class.java))
                    finish()
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.isLoadingTestData.collect { isLoading ->
                binding.progressBar.visibility = if (isLoading) 
                    android.view.View.VISIBLE else android.view.View.GONE
                binding.buttonTakeTour.isEnabled = !isLoading
                binding.buttonSkipTour.isEnabled = !isLoading
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.buttonSkipTour.setOnClickListener {
            viewModel.skipTour()
        }
        
        binding.buttonTakeTour.setOnClickListener {
            viewModel.startTour()
        }
    }
}