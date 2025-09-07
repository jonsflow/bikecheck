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
        setupTypeDropdown()
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
                    // Update spinner selection when bike changes
                    updateTypeSelection(it.type)
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
                            // Navigate back to Home and switch to Service tab
                            val intent = Intent(this@BikeDetailActivity, com.bikecheck.android.ui.home.HomeActivity::class.java).apply {
                                putExtra(com.bikecheck.android.ui.home.HomeActivity.EXTRA_SELECT_TAB, com.bikecheck.android.ui.home.HomeActivity.TAB_SERVICE)
                                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                            }
                            startActivity(intent)
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

    private var isInitializingType = false
    private fun setupTypeDropdown() {
        val types = listOf("Road", "Gravel", "Hardtail", "Full Suspension")
        val adapter = android.widget.ArrayAdapter(
            this,
            android.R.layout.simple_spinner_item,
            types
        )
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        binding.spinnerBikeType.adapter = adapter
        
        binding.spinnerBikeType.onItemSelectedListener = object : android.widget.AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: android.widget.AdapterView<*>, view: android.view.View?, position: Int, id: Long) {
                if (isInitializingType) return
                val selectedDisplay = types[position]
                val selectedValue = when (selectedDisplay) {
                    "Road" -> "road"
                    "Gravel" -> "gravel"
                    "Hardtail" -> "hardtail"
                    "Full Suspension" -> "full suspension"
                    else -> null
                }
                selectedValue?.let { viewModel.updateBikeType(it) }
            }
            override fun onNothingSelected(parent: android.widget.AdapterView<*>) { /* no-op */ }
        }
    }

    private fun updateTypeSelection(type: String?) {
        val types = listOf("Road", "Gravel", "Hardtail", "Full Suspension")
        val valueToIndex = mapOf(
            "road" to 0,
            "gravel" to 1,
            "hardtail" to 2,
            "full suspension" to 3
        )
        val index = valueToIndex[type?.lowercase()] ?: -1
        if (index >= 0) {
            if (binding.spinnerBikeType.selectedItemPosition != index) {
                isInitializingType = true
                binding.spinnerBikeType.setSelection(index)
                isInitializingType = false
            }
        } else {
            // Default to Road when type is unset or unrecognized
            val defaultIndex = 0
            if (binding.spinnerBikeType.selectedItemPosition != defaultIndex) {
                isInitializingType = true
                binding.spinnerBikeType.setSelection(defaultIndex)
                isInitializingType = false
            }
            viewModel.updateBikeType("road")
        }
    }
    
    override fun onSupportNavigateUp(): Boolean {
        onBackPressed()
        return true
    }
}
