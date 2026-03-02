package com.bikecheck.android.ui.service

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bikecheck.android.data.database.entities.ServiceIntervalWithBike
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
    private var selectedFilters: Set<String> = setOf("All")
    private var allIntervals: List<ServiceIntervalWithBike> = emptyList()
    private var allActivities: List<com.bikecheck.android.data.database.entities.ActivityEntity> = emptyList()

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
        setupChips()
        setupObservers()
    }

    private fun setupRecyclerView() {
        serviceIntervalAdapter = ServiceIntervalAdapter()
        binding.recyclerViewServiceIntervals.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = serviceIntervalAdapter
        }
    }

    private fun setupChips() {
        binding.chipAll.setOnCheckedChangeListener { _, checked ->
            if (checked) {
                selectedFilters = setOf("All")
                applyFilter()
            }
        }

        binding.chipOverdue.setOnCheckedChangeListener { _, checked ->
            updateSelectedFilters("Overdue", checked)
        }

        binding.chipSoon.setOnCheckedChangeListener { _, checked ->
            updateSelectedFilters("Soon", checked)
        }

        binding.chipGood.setOnCheckedChangeListener { _, checked ->
            updateSelectedFilters("Good", checked)
        }
    }

    private fun updateSelectedFilters(filter: String, isChecked: Boolean) {
        // If "All" is checked, uncheck it and remove it from filters
        if (binding.chipAll.isChecked) {
            binding.chipAll.isChecked = false
        }

        selectedFilters = if (isChecked) {
            selectedFilters + filter
        } else {
            selectedFilters - filter
        }

        // If no filters are selected, revert to "All"
        if (selectedFilters.isEmpty()) {
            binding.chipAll.isChecked = true
            selectedFilters = setOf("All")
        }

        applyFilter()
    }

    private fun applyFilter() {
        if (selectedFilters.contains("All")) {
            serviceIntervalAdapter.submitList(allIntervals)
        } else {
            val filteredIntervals = allIntervals.filter { interval ->
                val status = getIntervalStatus(interval)
                selectedFilters.contains(status)
            }
            serviceIntervalAdapter.submitList(filteredIntervals)
        }
        binding.textViewServiceIntervalsCount.text = "${serviceIntervalAdapter.itemCount} intervals"
    }

    private fun getIntervalStatus(interval: ServiceIntervalWithBike): String {
        val totalSeconds = allActivities
            .filter { it.gearId == interval.bikeId }
            .sumOf { it.movingTime }
        val hoursRidden = totalSeconds / 3600.0
        val usageSinceStart = hoursRidden - interval.startTime
        val fractionUsed = if (interval.intervalTime > 0) usageSinceStart / interval.intervalTime else 0.0

        return when {
            fractionUsed >= 1.0 -> "Overdue"
            fractionUsed >= 0.9 -> "Soon"
            else -> "Good"
        }
    }

    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.serviceIntervals.collect { intervals ->
                allIntervals = intervals
                applyFilter()
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
                allActivities = activities
                serviceIntervalAdapter.updateActivities(activities)
                applyFilter()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
