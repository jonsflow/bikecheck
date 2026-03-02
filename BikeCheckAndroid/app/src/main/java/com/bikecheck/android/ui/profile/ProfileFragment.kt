package com.bikecheck.android.ui.profile

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.GridLayout
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.lifecycleScope
import coil.imageLoader
import coil.request.ImageRequest
import coil.transform.CircleCropTransformation
import com.bikecheck.android.R
import com.bikecheck.android.databinding.FragmentProfileBinding
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.launch

@AndroidEntryPoint
class ProfileFragment : Fragment() {

    private var _binding: FragmentProfileBinding? = null
    private val binding get() = _binding!!

    private val viewModel: ProfileViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentProfileBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        setupObservers()
    }

    private fun setupObservers() {
        lifecycleScope.launch {
            viewModel.athlete.collect { athlete ->
                if (athlete != null) {
                    binding.athleteName.text = athlete.firstname

                    // Load profile image
                    val data: Any = athlete.profile?.takeUnless { it.isBlank() }
                        ?: R.drawable.profile_placeholder_circle
                    val request = ImageRequest.Builder(requireContext())
                        .data(data)
                        .crossfade(true)
                        .transformations(CircleCropTransformation())
                        .target { drawable ->
                            binding.profileImage.setImageDrawable(drawable)
                        }
                        .build()
                    requireContext().imageLoader.enqueue(request)
                }
            }
        }

        lifecycleScope.launch {
            viewModel.stats.collect { stats ->
                updateStatsGrid(stats)
            }
        }
    }

    private fun updateStatsGrid(stats: ProfileViewModel.Stats) {
        binding.statsGrid.removeAllViews()

        val statItems = listOf(
            StatItem("Total Bikes", stats.bikeCount.toString(), R.drawable.ic_bike_placeholder),
            StatItem("Total KM", String.format("%.0f", stats.totalKm), R.drawable.ic_bike_placeholder),
            StatItem("Total Hours", String.format("%.1f", stats.totalHours), R.drawable.ic_bike_placeholder),
            StatItem("Activities", stats.activityCount.toString(), R.drawable.ic_bike_placeholder),
            StatItem("Parts Tracked", stats.partsTracked.toString(), R.drawable.ic_bike_placeholder),
            StatItem("Overdue", stats.overdueCount.toString(), R.drawable.ic_bike_placeholder)
        )

        statItems.forEach { item ->
            val tileView = LayoutInflater.from(requireContext())
                .inflate(R.layout.item_stat_tile, binding.statsGrid, false)

            val layoutParams = GridLayout.LayoutParams().apply {
                columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                rowSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
                width = 0
                height = GridLayout.LayoutParams.WRAP_CONTENT
                setMargins(4, 4, 4, 4)
            }

            tileView.findViewById<android.widget.ImageView>(R.id.statIcon).setImageResource(item.iconRes)
            tileView.findViewById<android.widget.TextView>(R.id.statValue).text = item.value
            tileView.findViewById<android.widget.TextView>(R.id.statLabel).text = item.label

            binding.statsGrid.addView(tileView, layoutParams)
        }
    }

    private data class StatItem(val label: String, val value: String, val iconRes: Int)

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
