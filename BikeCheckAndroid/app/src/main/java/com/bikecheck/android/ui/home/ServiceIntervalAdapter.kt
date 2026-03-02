package com.bikecheck.android.ui.home

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bikecheck.android.data.database.entities.ActivityEntity
import com.bikecheck.android.data.database.entities.ServiceIntervalWithBike
import com.bikecheck.android.databinding.ItemServiceIntervalBinding

class ServiceIntervalAdapter : ListAdapter<ServiceIntervalWithBike, ServiceIntervalAdapter.ServiceIntervalViewHolder>(ServiceIntervalDiffCallback()) {

    private var activities: List<ActivityEntity> = emptyList()

    fun updateActivities(newActivities: List<ActivityEntity>) {
        activities = newActivities
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ServiceIntervalViewHolder {
        val binding = ItemServiceIntervalBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ServiceIntervalViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ServiceIntervalViewHolder, position: Int) {
        holder.bind(getItem(position), activities)
    }

    class ServiceIntervalViewHolder(private val binding: ItemServiceIntervalBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(serviceInterval: ServiceIntervalWithBike, activities: List<ActivityEntity>) {
            binding.textViewBikeName.text = serviceInterval.bikeName
            binding.textViewPartName.text = serviceInterval.part

            val ctx = binding.root.context

            // Compute time until service based on activities
            val totalSeconds = activities.asSequence()
                .filter { it.gearId == serviceInterval.bikeId }
                .sumOf { it.movingTime }
            val totalRideHours = totalSeconds / 3600.0
            val timeUsedSinceStart = totalRideHours - serviceInterval.startTime
            val timeRemaining = serviceInterval.intervalTime - timeUsedSinceStart
            val fractionUsed = if (serviceInterval.intervalTime > 0) {
                timeUsedSinceStart / serviceInterval.intervalTime
            } else {
                0.0
            }

            // Determine status color and label
            val (statusColor, statusLabel) = when {
                fractionUsed >= 1.0 -> android.graphics.Color.RED to "Now"
                fractionUsed >= 0.9 -> android.graphics.Color.parseColor("#FF9800") to "Soon"
                else -> android.graphics.Color.parseColor("#4CAF50") to "Good"
            }

            binding.textViewStatus.text = statusLabel
            binding.textViewStatus.setTextColor(statusColor)

            // Set status icon color
            binding.statusIcon.setBackgroundColor(statusColor)

            // DUE IN value: show non-negative hours
            val dueHours = if (timeRemaining < 0.0) 0.0 else timeRemaining
            binding.textViewDueValue.setTextColor(statusColor)
            binding.textViewDueValue.text = "${String.format("%.2f", dueHours)} hrs"

            // Update wear bar: fill segments based on remaining life
            val segmentViews = listOf(
                binding.wearSegment1,
                binding.wearSegment2,
                binding.wearSegment3,
                binding.wearSegment4,
                binding.wearSegment5
            )
            val emptyColor = ctx.getColor(com.bikecheck.android.R.color.secondary_text)
            val filledSegments = (5 * (1.0 - fractionUsed.coerceIn(0.0, 1.0))).toInt()
            segmentViews.forEachIndexed { index, segment ->
                segment.setBackgroundColor(if (index < filledSegments) statusColor else emptyColor)
            }

            binding.root.setOnClickListener {
                val context = binding.root.context
                val intent = android.content.Intent(context, com.bikecheck.android.ui.serviceinterval.AddServiceIntervalActivity::class.java).apply {
                    putExtra("service_interval_id", serviceInterval.id)
                }
                context.startActivity(intent)
            }
        }
    }

    private class ServiceIntervalDiffCallback : DiffUtil.ItemCallback<ServiceIntervalWithBike>() {
        override fun areItemsTheSame(oldItem: ServiceIntervalWithBike, newItem: ServiceIntervalWithBike): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: ServiceIntervalWithBike, newItem: ServiceIntervalWithBike): Boolean {
            return oldItem == newItem
        }
    }
}
