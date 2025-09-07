package com.bikecheck.android.ui.service

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bikecheck.android.databinding.FragmentServiceBinding
import com.bikecheck.android.ui.home.HomeViewModel
import com.bikecheck.android.ui.home.ServiceIntervalAdapter
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class ServiceFragment : Fragment() {
    
    private var _binding: FragmentServiceBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: HomeViewModel by viewModels()
    private lateinit var serviceIntervalAdapter: ServiceIntervalAdapter
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentServiceBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        setupObservers()
    }
    
    private fun setupRecyclerView() {
        serviceIntervalAdapter = ServiceIntervalAdapter()
        binding.recyclerViewServiceIntervals.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = serviceIntervalAdapter
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.serviceIntervals.collect { intervals ->
                serviceIntervalAdapter.submitList(intervals)
                binding.textViewServiceIntervalsCount.text = "${intervals.size} intervals"
            }
        }
        
        lifecycleScope.launch {
            viewModel.isLoading.collect { isLoading ->
                binding.progressBar.visibility = if (isLoading) 
                    View.VISIBLE else View.GONE
            }
        }

        lifecycleScope.launch {
            viewModel.activities.collect { activities ->
                serviceIntervalAdapter.updateActivities(activities)
            }
        }
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
