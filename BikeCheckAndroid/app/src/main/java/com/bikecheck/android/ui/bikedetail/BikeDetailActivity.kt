package com.bikecheck.android.ui.bikedetail

import android.content.Intent
import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bikecheck.android.databinding.ActivityBikeDetailBinding
import com.bikecheck.android.ui.serviceinterval.AddServiceIntervalActivity
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class BikeDetailActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityBikeDetailBinding
    private val viewModel: BikeDetailViewModel by viewModels()
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityBikeDetailBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        val bikeId = intent.getStringExtra("bike_id")
        if (bikeId.isNullOrEmpty()) {
            finish()
            return
        }
        
        setupToolbar()
        setupObservers()
        setupClickListeners()
        
        viewModel.loadBike(bikeId)
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = "Bike Details"
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.bike.collect { bike ->
                bike?.let {
                    binding.textViewBikeName.text = it.name
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.mileage.collect { mileage ->
                binding.textViewMileage.text = "${String.format("%.1f", mileage)} miles"
            }
        }
        
        lifecycleScope.launch {
            viewModel.totalRideTime.collect { rideTime ->
                binding.textViewRideTime.text = "${String.format("%.1f", rideTime)} hrs"
            }
        }
        
        lifecycleScope.launch {
            viewModel.activityCount.collect { count ->
                binding.textViewActivityCount.text = "$count activities"
            }
        }
        
        lifecycleScope.launch {
            viewModel.isLoading.collect { isLoading ->
                binding.progressBar.visibility = if (isLoading) 
                    android.view.View.VISIBLE else android.view.View.GONE
            }
        }
        
        lifecycleScope.launch {
            viewModel.deleteResult.collect { result ->
                result?.let {
                    if (it.isSuccess) {
                        finish()
                    } else {
                        AlertDialog.Builder(this@BikeDetailActivity)
                            .setTitle("Error")
                            .setMessage("Failed to delete bike")
                            .setPositiveButton("OK", null)
                            .show()
                    }
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.defaultIntervalsCreated.collect { created ->
                if (created) {
                    AlertDialog.Builder(this@BikeDetailActivity)
                        .setTitle("Service Intervals Created")
                        .setMessage("Default service intervals have been created for this bike")
                        .setPositiveButton("OK") { _, _ ->
                            // Navigate back to service intervals tab
                            finish()
                        }
                        .show()
                }
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.buttonCreateDefaultIntervals.setOnClickListener {
            viewModel.createDefaultServiceIntervals()
        }
        
        binding.buttonAddServiceInterval.setOnClickListener {
            val intent = Intent(this, AddServiceIntervalActivity::class.java)
            startActivity(intent)
        }
        
        binding.buttonDeleteBike.setOnClickListener {
            AlertDialog.Builder(this)
                .setTitle("Confirm Deletion")
                .setMessage("Are you sure you want to delete this bike? (If it's a Strava bike, it will be re-imported on the next sync)")
                .setPositiveButton("Delete") { _, _ ->
                    viewModel.deleteBike()
                }
                .setNegativeButton("Cancel", null)
                .show()
        }
    }
    
    override fun onSupportNavigateUp(): Boolean {
        onBackPressed()
        return true
    }
}