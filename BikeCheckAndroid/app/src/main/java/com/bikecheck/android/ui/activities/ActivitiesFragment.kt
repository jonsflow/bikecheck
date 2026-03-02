package com.bikecheck.android.ui.activities

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bikecheck.android.databinding.FragmentActivitiesBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class ActivitiesFragment : Fragment() {
    
    private var _binding: FragmentActivitiesBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: ActivitiesViewModel by viewModels()
    private lateinit var activitiesAdapter: ActivitiesAdapter
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentActivitiesBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        setupObservers()
    }
    
    private fun setupRecyclerView() {
        activitiesAdapter = ActivitiesAdapter()
        binding.recyclerViewActivities.apply {
            layoutManager = LinearLayoutManager(requireContext())
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
                    View.VISIBLE else View.GONE
            }
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}