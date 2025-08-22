package com.bikecheck.android.ui.home

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bikecheck.android.databinding.ActivityHomeBinding
import com.bikecheck.android.ui.activities.ActivitiesActivity
import com.bikecheck.android.ui.activities.ActivitiesAdapter
import com.bikecheck.android.ui.login.LoginActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class HomeActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityHomeBinding
    private val viewModel: HomeViewModel by viewModels()
    private lateinit var bikeAdapter: BikeAdapter
    private lateinit var serviceIntervalAdapter: ServiceIntervalAdapter
    private lateinit var activitiesAdapter: ActivitiesAdapter
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityHomeBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupRecyclerViews()
        setupObservers()
        setupClickListeners()
    }
    
    private fun setupRecyclerViews() {
        bikeAdapter = BikeAdapter()
        serviceIntervalAdapter = ServiceIntervalAdapter()
        activitiesAdapter = ActivitiesAdapter()
        
        binding.recyclerViewBikes.apply {
            layoutManager = LinearLayoutManager(this@HomeActivity)
            adapter = bikeAdapter
        }
        
        binding.recyclerViewServiceIntervals.apply {
            layoutManager = LinearLayoutManager(this@HomeActivity)
            adapter = serviceIntervalAdapter
        }
        
        binding.recyclerViewActivities.apply {
            layoutManager = LinearLayoutManager(this@HomeActivity)
            adapter = activitiesAdapter
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.currentAthlete.collect { athlete ->
                binding.textViewWelcome.text = if (athlete != null) {
                    "Welcome back, ${athlete.firstname}!"
                } else {
                    "Welcome to BikeCheck!"
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.bikes.collect { bikes ->
                bikeAdapter.submitList(bikes)
                binding.textViewBikesCount.text = "${bikes.size} bikes"
            }
        }
        
        lifecycleScope.launch {
            viewModel.serviceIntervals.collect { intervals ->
                serviceIntervalAdapter.submitList(intervals)
                binding.textViewServiceIntervalsCount.text = "${intervals.size} service intervals"
            }
        }
        
        lifecycleScope.launch {
            viewModel.activities.collect { activities ->
                // Show only the first 3 activities on home screen
                val recentActivities = activities.take(3)
                activitiesAdapter.submitList(recentActivities)
                binding.textViewActivitiesCount.text = "${activities.size} activities"
            }
        }
        
        lifecycleScope.launch {
            viewModel.isLoading.collect { isLoading ->
                binding.progressBar.visibility = if (isLoading) 
                    android.view.View.VISIBLE else android.view.View.GONE
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.buttonSignOut.setOnClickListener {
            viewModel.signOut()
            startActivity(Intent(this, LoginActivity::class.java))
            finish()
        }
        
        binding.buttonViewAllActivities.setOnClickListener {
            startActivity(Intent(this, ActivitiesActivity::class.java))
        }
    }
}