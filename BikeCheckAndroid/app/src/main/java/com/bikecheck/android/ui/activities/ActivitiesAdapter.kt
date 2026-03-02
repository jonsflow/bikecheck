package com.bikecheck.android.ui.activities

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bikecheck.android.data.database.entities.ActivityEntity
import com.bikecheck.android.databinding.ItemActivityBinding
import java.text.SimpleDateFormat
import java.util.*

class ActivitiesAdapter : ListAdapter<ActivityEntity, ActivitiesAdapter.ActivityViewHolder>(ActivityDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ActivityViewHolder {
        val binding = ItemActivityBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ActivityViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ActivityViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class ActivityViewHolder(private val binding: ItemActivityBinding) : RecyclerView.ViewHolder(binding.root) {
        private val dateFormatter = SimpleDateFormat("MMM dd, yyyy", Locale.getDefault())
        
        fun bind(activity: ActivityEntity) {
            binding.textViewActivityName.text = activity.name
            binding.textViewActivityDate.text = dateFormatter.format(activity.startDate)
            binding.textViewActivityDistance.text = "${String.format("%.1f", activity.distance / 1000)} km"
            binding.textViewActivityTime.text = formatTime(activity.movingTime)
            binding.textViewActivitySpeed.text = "${String.format("%.1f", activity.averageSpeed * 3.6)} km/h"
        }
        
        private fun formatTime(seconds: Long): String {
            val hours = seconds / 3600
            val minutes = (seconds % 3600) / 60
            return if (hours > 0) {
                "${hours}h ${minutes}m"
            } else {
                "${minutes}m"
            }
        }
    }

    private class ActivityDiffCallback : DiffUtil.ItemCallback<ActivityEntity>() {
        override fun areItemsTheSame(oldItem: ActivityEntity, newItem: ActivityEntity): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: ActivityEntity, newItem: ActivityEntity): Boolean {
            return oldItem == newItem
        }
    }
}