package com.bikecheck.android.ui.activities

import android.os.Bundle
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bikecheck.android.databinding.ActivityActivitiesBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class ActivitiesActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityActivitiesBinding
    private val viewModel: ActivitiesViewModel by viewModels()
    private lateinit var activitiesAdapter: ActivitiesAdapter
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityActivitiesBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        setupToolbar()
        setupRecyclerView()
        setupObservers()
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.setDisplayHomeAsUpEnabled(true)
        supportActionBar?.title = "Activities"
    }
    
    private fun setupRecyclerView() {
        activitiesAdapter = ActivitiesAdapter()
        binding.recyclerViewActivities.apply {
            layoutManager = LinearLayoutManager(this@ActivitiesActivity)
            adapter = activitiesAdapter
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.activities.collect { activities ->
                activitiesAdapter.submitList(activities)
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
    
    override fun onSupportNavigateUp(): Boolean {
        onBackPressed()
        return true
    }
}