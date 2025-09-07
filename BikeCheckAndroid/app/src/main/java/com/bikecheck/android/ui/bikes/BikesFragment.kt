package com.bikecheck.android.ui.bikes

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import androidx.recyclerview.widget.LinearLayoutManager
import com.bikecheck.android.databinding.FragmentBikesBinding
import com.bikecheck.android.ui.home.BikeAdapter
import com.bikecheck.android.ui.home.HomeViewModel
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class BikesFragment : Fragment() {
    
    private var _binding: FragmentBikesBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: HomeViewModel by viewModels()
    private lateinit var bikeAdapter: BikeAdapter
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentBikesBinding.inflate(inflater, container, false)
        return binding.root
    }
    
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        setupRecyclerView()
        setupObservers()
    }
    
    private fun setupRecyclerView() {
        bikeAdapter = BikeAdapter()
        binding.recyclerViewBikes.apply {
            layoutManager = LinearLayoutManager(requireContext())
            adapter = bikeAdapter
        }
    }
    
    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.bikes.collect { bikes ->
                bikeAdapter.submitList(bikes)
                binding.textViewBikesCount.text = "${bikes.size} bikes"
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