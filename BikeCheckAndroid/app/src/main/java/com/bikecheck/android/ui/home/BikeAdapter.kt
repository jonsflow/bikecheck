package com.bikecheck.android.ui.home

import android.content.Intent
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bikecheck.android.data.database.entities.ActivityEntity
import com.bikecheck.android.data.database.entities.BikeWithServiceIntervals
import com.bikecheck.android.databinding.ItemBikeBinding
import com.bikecheck.android.ui.bikedetail.BikeDetailActivity

class BikeAdapter : ListAdapter<BikeWithServiceIntervals, BikeAdapter.BikeViewHolder>(BikeDiffCallback()) {

    private val expandedBikeIds: MutableSet<String> = mutableSetOf()
    private var activities: List<ActivityEntity> = emptyList()

    fun updateActivities(newActivities: List<ActivityEntity>) {
        activities = newActivities
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BikeViewHolder {
        val binding = ItemBikeBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return BikeViewHolder(binding, expandedBikeIds, activities)
    }

    override fun onBindViewHolder(holder: BikeViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class BikeViewHolder(
        private val binding: ItemBikeBinding,
        private val expandedBikeIds: MutableSet<String>,
        private val activities: List<ActivityEntity>
    ) : RecyclerView.ViewHolder(binding.root) {

        fun bind(bikeWithIntervals: BikeWithServiceIntervals) {
            val bike = bikeWithIntervals.bike
            binding.textViewBikeName.text = bike.name
            binding.textViewBikeDistance.text = "${String.format("%.1f", bike.distance / 1000)} km"

            // Compute worst interval status
            val worstColor = computeWorstStatus(bikeWithIntervals.serviceIntervals)
            binding.statusDot.setBackgroundColor(worstColor)

            // Set up expand/collapse
            val isExpanded = expandedBikeIds.contains(bike.id)
            binding.expandableSection.visibility = if (isExpanded) View.VISIBLE else View.GONE
            binding.chevronIcon.rotation = if (isExpanded) 180f else 0f

            // Populate mini intervals when expanded
            if (isExpanded) {
                binding.expandableSection.removeAllViews()
                bikeWithIntervals.serviceIntervals.forEach { interval ->
                    val status = computeIntervalStatus(interval, activities)
                    addMiniIntervalRow(binding.expandableSection, interval.part, status)
                }
            }

            binding.chevronIcon.setOnClickListener {
                if (expandedBikeIds.contains(bike.id)) {
                    expandedBikeIds.remove(bike.id)
                } else {
                    expandedBikeIds.add(bike.id)
                }
                // Trigger re-bind
                itemView.post {
                    val pos = adapterPosition
                    if (pos != RecyclerView.NO_POSITION) {
                        (itemView.parent as? RecyclerView)?.adapter?.notifyItemChanged(pos)
                    }
                }
            }

            binding.root.setOnClickListener {
                val context = binding.root.context
                val intent = Intent(context, BikeDetailActivity::class.java).apply {
                    putExtra("bike_id", bike.id)
                }
                context.startActivity(intent)
            }
        }

        private fun computeWorstStatus(intervals: List<com.bikecheck.android.data.database.entities.ServiceIntervalEntity>): Int {
            var worstColor = Color.parseColor("#4CAF50") // Green
            intervals.forEach { interval ->
                val status = computeIntervalStatus(interval, activities)
                worstColor = when {
                    status == "Now" -> Color.RED
                    status == "Soon" && worstColor != Color.RED -> Color.parseColor("#FF9800")
                    else -> worstColor
                }
            }
            return worstColor
        }

        private fun computeIntervalStatus(
            interval: com.bikecheck.android.data.database.entities.ServiceIntervalEntity,
            activities: List<ActivityEntity>
        ): String {
            val totalSeconds = activities
                .filter { it.gearId == interval.bikeId }
                .sumOf { it.movingTime }
            val hoursRidden = totalSeconds / 3600.0
            val usageSinceStart = hoursRidden - interval.startTime
            val fractionUsed = if (interval.intervalTime > 0) usageSinceStart / interval.intervalTime else 0.0

            return when {
                fractionUsed >= 1.0 -> "Now"
                fractionUsed >= 0.9 -> "Soon"
                else -> "Good"
            }
        }

        private fun addMiniIntervalRow(container: ViewGroup, partName: String, status: String) {
            val row = android.widget.LinearLayout(container.context).apply {
                layoutParams = ViewGroup.LayoutParams(
                    ViewGroup.LayoutParams.MATCH_PARENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                )
                orientation = android.widget.LinearLayout.HORIZONTAL
                setPadding(0, 4, 0, 4)
            }

            val partText = android.widget.TextView(container.context).apply {
                text = partName
                textSize = 12f
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    0,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )
            }

            val statusText = android.widget.TextView(container.context).apply {
                text = status
                textSize = 12f
                val statusColor = when (status) {
                    "Now" -> Color.RED
                    "Soon" -> Color.parseColor("#FF9800")
                    else -> Color.parseColor("#4CAF50")
                }
                setTextColor(statusColor)
                layoutParams = android.widget.LinearLayout.LayoutParams(
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                    android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }

            row.addView(partText)
            row.addView(statusText)
            container.addView(row)
        }
    }

    private class BikeDiffCallback : DiffUtil.ItemCallback<BikeWithServiceIntervals>() {
        override fun areItemsTheSame(oldItem: BikeWithServiceIntervals, newItem: BikeWithServiceIntervals): Boolean {
            return oldItem.bike.id == newItem.bike.id
        }

        override fun areContentsTheSame(oldItem: BikeWithServiceIntervals, newItem: BikeWithServiceIntervals): Boolean {
            return oldItem == newItem
        }
    }
}
