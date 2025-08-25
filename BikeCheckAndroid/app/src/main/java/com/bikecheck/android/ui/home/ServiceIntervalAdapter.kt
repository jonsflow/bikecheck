package com.bikecheck.android.ui.home

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.bikecheck.android.data.database.entities.ServiceIntervalWithBike
import com.bikecheck.android.databinding.ItemServiceIntervalBinding

class ServiceIntervalAdapter : ListAdapter<ServiceIntervalWithBike, ServiceIntervalAdapter.ServiceIntervalViewHolder>(ServiceIntervalDiffCallback()) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ServiceIntervalViewHolder {
        val binding = ItemServiceIntervalBinding.inflate(
            LayoutInflater.from(parent.context),
            parent,
            false
        )
        return ServiceIntervalViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ServiceIntervalViewHolder, position: Int) {
        holder.bind(getItem(position))
    }

    class ServiceIntervalViewHolder(private val binding: ItemServiceIntervalBinding) : RecyclerView.ViewHolder(binding.root) {
        fun bind(serviceInterval: ServiceIntervalWithBike) {
            binding.textViewBikeName.text = serviceInterval.bikeName
            binding.textViewPartName.text = serviceInterval.part
            binding.textViewInterval.text = "${serviceInterval.intervalTime.toInt()} hours"
            binding.textViewNotifications.text = if (serviceInterval.notify) "Notifications: ON" else "Notifications: OFF"
            
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