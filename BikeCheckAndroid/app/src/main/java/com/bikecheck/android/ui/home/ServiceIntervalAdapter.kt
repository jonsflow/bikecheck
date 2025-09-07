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
            // Compute time until service based on activities
            val totalSeconds = activities.asSequence()
                .filter { it.gearId == serviceInterval.bikeId }
                .sumOf { it.movingTime }
            val totalRideHours = totalSeconds / 3600.0
            val timeUsedSinceStart = totalRideHours - serviceInterval.startTime
            val timeRemaining = serviceInterval.intervalTime - timeUsedSinceStart

            val ctx = binding.root.context
            val color = com.bikecheck.android.R.color.primary_text
            // Part shown above in bold; no italics
            // DUE IN value: show non-negative hours
            val dueHours = if (timeRemaining < 0.0) 0.0 else timeRemaining
            binding.textViewDueValue.setTextColor(ctx.getColor(color))
            binding.textViewDueValue.text = "${String.format("%.2f", dueHours)} hrs"
            
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
