package com.bikecheck.android.ui.serviceinterval

import android.os.Bundle
import android.widget.ArrayAdapter
import androidx.activity.viewModels
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import com.bikecheck.android.databinding.ActivityAddServiceIntervalBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class AddServiceIntervalActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityAddServiceIntervalBinding
    private val viewModel: AddServiceIntervalViewModel by viewModels()
    private var isEditMode = false
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityAddServiceIntervalBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        // Check if editing existing service interval
        val serviceIntervalId = intent.getStringExtra("service_interval_id")
        isEditMode = !serviceIntervalId.isNullOrEmpty()
        
        setupToolbar()
        setupObservers()
        setupClickListeners()
        
        // Show the computed "Time until service" only in edit mode
        binding.layoutTimeUntilService.visibility = if (isEditMode) android.view.View.VISIBLE else android.view.View.GONE

        if (isEditMode && serviceIntervalId != null) {
            viewModel.loadServiceInterval(serviceIntervalId)
        } else {
            viewModel.loadBikes()
        }
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.apply {
            setDisplayHomeAsUpEnabled(true)
            title = if (isEditMode) "Edit Service Interval" else "Add Service Interval"
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.bikes.collect { bikes ->
                val bikeNames = bikes.map { it.name }
                val adapter = ArrayAdapter(
                    this@AddServiceIntervalActivity,
                    android.R.layout.simple_spinner_item,
                    bikeNames
                )
                adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
                binding.spinnerBike.adapter = adapter
                
                // Disable bike selection in edit mode
                binding.spinnerBike.isEnabled = !isEditMode
            }
        }
        
        lifecycleScope.launch {
            viewModel.selectedBike.collect { bike ->
                bike?.let {
                    val bikes = viewModel.bikes.value
                    val index = bikes.indexOf(it)
                    if (index >= 0) {
                        binding.spinnerBike.setSelection(index)
                    }
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.part.collect { part ->
                if (binding.editTextPart.text.toString() != part) {
                    binding.editTextPart.setText(part)
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.intervalTime.collect { intervalTime ->
                val intervalText = if (intervalTime > 0) intervalTime.toString() else ""
                if (binding.editTextIntervalTime.text.toString() != intervalText) {
                    binding.editTextIntervalTime.setText(intervalText)
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.notify.collect { notify ->
                binding.switchNotify.isChecked = notify
            }
        }
        
        lifecycleScope.launch {
            viewModel.timeUntilService.collect { timeUntilService ->
                if (isEditMode) {
                    binding.textViewTimeUntilService.text = "${timeUntilService.toInt()} hrs"
                    // Use app primary text color to respect light/dark mode
                    binding.textViewTimeUntilService.setTextColor(getColor(com.bikecheck.android.R.color.primary_text))
                }
            }
        }
        
        lifecycleScope.launch {
            viewModel.isLoading.collect { isLoading ->
                binding.progressBar.visibility = if (isLoading) 
                    android.view.View.VISIBLE else android.view.View.GONE
            }
        }
        
        lifecycleScope.launch {
            viewModel.saveResult.collect { result ->
                result?.let {
                    if (it.isSuccess) {
                        finish()
                    } else {
                        AlertDialog.Builder(this@AddServiceIntervalActivity)
                            .setTitle("Error")
                            .setMessage("Failed to save service interval")
                            .setPositiveButton("OK", null)
                            .show()
                    }
                }
            }
        }
    }
    
    private fun setupClickListeners() {
        binding.buttonSave.setOnClickListener {
            val selectedBikeIndex = binding.spinnerBike.selectedItemPosition
            val part = binding.editTextPart.text.toString()
            val intervalTimeText = binding.editTextIntervalTime.text.toString()
            val notify = binding.switchNotify.isChecked
            
            viewModel.saveServiceInterval(selectedBikeIndex, part, intervalTimeText, notify)
        }
        
        if (isEditMode) {
            binding.buttonReset.visibility = android.view.View.VISIBLE
            binding.buttonDelete.visibility = android.view.View.VISIBLE
            
            binding.buttonReset.setOnClickListener {
                AlertDialog.Builder(this)
                    .setTitle("Confirm Reset")
                    .setMessage("Are you sure you want to reset this service interval?")
                    .setPositiveButton("Reset") { _, _ ->
                        viewModel.resetInterval()
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
            }
            
            binding.buttonDelete.setOnClickListener {
                AlertDialog.Builder(this)
                    .setTitle("Confirm Deletion")
                    .setMessage("Are you sure you want to delete this service interval?")
                    .setPositiveButton("Delete") { _, _ ->
                        viewModel.deleteInterval()
                        finish()
                    }
                    .setNegativeButton("Cancel", null)
                    .show()
            }
        }
    }
    
    override fun onSupportNavigateUp(): Boolean {
        onBackPressed()
        return true
    }
}
