package com.bikecheck.android.ui.home

import android.content.Intent
import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bikecheck.android.data.database.entities.BikeEntity
import com.bikecheck.android.databinding.ItemBikeBinding
import com.bikecheck.android.ui.bikedetail.BikeDetailActivity

class BikeAdapter : ListAdapter<BikeEntity, BikeAdapter.BikeViewHolder>(BikeDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): BikeViewHolder {
        val binding = ItemBikeBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return BikeViewHolder(binding)
    }

    override fun onBindViewHolder(holder: BikeViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class BikeViewHolder(private val binding: ItemBikeBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(bike: BikeEntity) {
            binding.textViewBikeName.text = bike.name
            // Show type if available
            val typeText = bike.type?.let { it.trim() }.orEmpty()
            if (typeText.isNotEmpty()) {
                binding.textViewBikeType.visibility = android.view.View.VISIBLE
                binding.textViewBikeType.text = typeText.replaceFirstChar { c -> c.titlecase() }
            } else {
                binding.textViewBikeType.visibility = android.view.View.GONE
            }
            binding.textViewBikeDistance.text = "${String.format("%.1f", bike.distance / 1000)} km"
            
            binding.root.setOnClickListener {
                val context = binding.root.context
                val intent = Intent(context, BikeDetailActivity::class.java).apply {
                    putExtra("bike_id", bike.id)
                }
                context.startActivity(intent)
            }
        }
    }

    private class BikeDiffCallback : DiffUtil.ItemCallback<BikeEntity>() {
        override fun areItemsTheSame(oldItem: BikeEntity, newItem: BikeEntity): Boolean {
            return oldItem.id == newItem.id
        }

        override fun areContentsTheSame(oldItem: BikeEntity, newItem: BikeEntity): Boolean {
            return oldItem == newItem
        }
    }
}
