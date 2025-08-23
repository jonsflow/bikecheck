package com.bikecheck.android.ui.components

import android.content.Context
import android.util.AttributeSet
import android.view.LayoutInflater
import androidx.constraintlayout.widget.ConstraintLayout
import com.bikecheck.android.databinding.ViewAdContainerBinding

class AdContainerView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : ConstraintLayout(context, attrs, defStyleAttr) {
    
    private val binding: ViewAdContainerBinding
    
    init {
        binding = ViewAdContainerBinding.inflate(
            LayoutInflater.from(context),
            this,
            true
        )
        
        setupView()
    }
    
    private fun setupView() {
        binding.textViewAdTitle.text = "Your Ad Here"
        binding.textViewAdDescription.text = "Promote your cycling business or product"
        binding.textViewAdLabel.text = "Advertisement"
    }
}