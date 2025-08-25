package com.bikecheck.android.ui.home

import android.content.Intent
import android.os.Bundle
import android.view.Menu
import android.view.MenuItem
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.Fragment
import androidx.lifecycle.ViewModelProvider
import com.bikecheck.android.R
import com.bikecheck.android.databinding.ActivityHomeWithNavBinding
import com.bikecheck.android.ui.activities.ActivitiesFragment
import com.bikecheck.android.ui.bikes.BikesFragment
import com.bikecheck.android.ui.login.LoginActivity
import com.bikecheck.android.ui.service.ServiceFragment
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class HomeActivity : AppCompatActivity() {
    
    private lateinit var binding: ActivityHomeWithNavBinding
    private lateinit var serviceFragment: ServiceFragment
    private lateinit var bikesFragment: BikesFragment
    private lateinit var activitiesFragment: ActivitiesFragment
    private lateinit var homeViewModel: HomeViewModel
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding = ActivityHomeWithNavBinding.inflate(layoutInflater)
        setContentView(binding.root)
        
        homeViewModel = ViewModelProvider(this)[HomeViewModel::class.java]
        
        setupToolbar()
        setupFragments()
        setupBottomNavigation()
        
        // Show service fragment by default
        if (savedInstanceState == null) {
            showFragment(serviceFragment)
            binding.bottomNavigation.selectedItemId = R.id.navigation_service
        }
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.title = "BikeCheck"
        // Set popup theme programmatically for visible menu text
        binding.toolbar.popupTheme = androidx.appcompat.R.style.ThemeOverlay_AppCompat_Light
        // Inflate menu programmatically to avoid XML namespace issues
        binding.toolbar.inflateMenu(R.menu.home_menu)
        // Ensure overflow menu icon is visible
        binding.toolbar.overflowIcon?.setTint(getColor(android.R.color.white))
        
        // Set up toolbar menu click listener
        binding.toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_refresh -> {
                    // Handle refresh action
                    true
                }
                R.id.action_logout -> {
                    homeViewModel.signOut()
                    startActivity(Intent(this, LoginActivity::class.java))
                    finish()
                    true
                }
                else -> false
            }
        }
    }
    
    private fun setupFragments() {
        serviceFragment = ServiceFragment()
        bikesFragment = BikesFragment()
        activitiesFragment = ActivitiesFragment()
    }
    
    private fun setupBottomNavigation() {
        binding.bottomNavigation.setOnItemSelectedListener { item ->
            when (item.itemId) {
                R.id.navigation_service -> {
                    showFragment(serviceFragment)
                    supportActionBar?.title = "Service"
                    true
                }
                R.id.navigation_bikes -> {
                    showFragment(bikesFragment)
                    supportActionBar?.title = "Bikes"
                    true
                }
                R.id.navigation_activities -> {
                    showFragment(activitiesFragment)
                    supportActionBar?.title = "Activities"
                    true
                }
                else -> false
            }
        }
        
        // Set the menu for the bottom navigation
        binding.bottomNavigation.menu.clear()
        binding.bottomNavigation.inflateMenu(R.menu.bottom_navigation_menu)
        
        // Set colors
        binding.bottomNavigation.itemIconTintList = getColorStateList(R.color.bikecheck_black)
        binding.bottomNavigation.itemTextColor = getColorStateList(R.color.bikecheck_black)
    }
    
    private fun showFragment(fragment: Fragment) {
        supportFragmentManager.beginTransaction()
            .replace(R.id.nav_host_fragment, fragment)
            .commit()
    }
    
    fun switchToActivitiesTab() {
        binding.bottomNavigation.selectedItemId = R.id.navigation_activities
    }
    
    override fun onCreateOptionsMenu(menu: Menu?): Boolean {
        menuInflater.inflate(R.menu.home_menu, menu)
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_refresh -> {
                // Handle refresh action
                true
            }
            R.id.action_logout -> {
                homeViewModel.signOut()
                startActivity(Intent(this, LoginActivity::class.java))
                finish()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
}