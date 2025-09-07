package com.bikecheck.android.ui.onboarding

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bikecheck.android.databinding.ActivityTourOverlayBinding
import com.bikecheck.android.ui.login.LoginActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class TourOverlayActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityTourOverlayBinding
    private val viewModel: OnboardingViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityTourOverlayBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupObservers()
        setupClickListeners()
        updateTourStep()
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.showTour.collect { showTour ->
                if (!showTour) {
                    // Tour completed, go to login
                    startActivity(Intent(this@TourOverlayActivity, LoginActivity::class.java))
                    finish()
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.currentTourStep.collect { 
                updateTourStep()
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.buttonNext.setOnClickListener {
            viewModel.nextTourStep()
        }
        
        binding.buttonPrevious.setOnClickListener {
            viewModel.previousTourStep()
        }
        
        binding.buttonSkip.setOnClickListener {
            viewModel.completeTour()
        }
        
        // Allow tapping outside to dismiss
        binding.overlay.setOnClickListener {
            viewModel.nextTourStep()
        }
    }
    
    private fun updateTourStep() {
        val currentStep = viewModel.getCurrentTourStep()
        
        if (currentStep != null) {
            binding.textViewTitle.text = currentStep.title
            binding.textViewDescription.text = currentStep.description
            
            // Update button visibility
            binding.buttonPrevious.visibility = if (viewModel.currentTourStep.value > 0) 
                android.view.View.VISIBLE else android.view.View.INVISIBLE
                
            val isLastStep = viewModel.currentTourStep.value >= com.bikecheck.android.models.TourStep.values().size - 1
            binding.buttonNext.text = if (isLastStep) "Finish" else "Next"
        }
    }
}