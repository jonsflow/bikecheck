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
import coil.load
import coil.transform.CircleCropTransformation
import coil.imageLoader
import coil.request.ImageRequest
import androidx.lifecycle.lifecycleScope
import kotlinx.coroutines.launch

@AndroidEntryPoint
class HomeActivity : AppCompatActivity() {
    companion object {
        const val EXTRA_SELECT_TAB = "select_tab"
        const val TAB_SERVICE = "service"
        const val TAB_BIKES = "bikes"
        const val TAB_ACTIVITIES = "activities"
    }
    
    private lateinit var binding: ActivityHomeWithNavBinding
    private lateinit var serviceFragment: ServiceFragment
    private lateinit var bikesFragment: BikesFragment
    private lateinit var activitiesFragment: ActivitiesFragment
    private lateinit var homeViewModel: HomeViewModel
    private var profileImageView: android.widget.ImageView? = null
    private var latestProfileUrl: String? = null
    
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

        // Handle initial intent tab selection
        handleSelectTabIntent(intent)
    }
    
    private fun setupToolbar() {
        setSupportActionBar(binding.toolbar)
        supportActionBar?.title = "BikeCheck"
        // Set popup theme programmatically for visible menu text
        binding.toolbar.popupTheme = androidx.appcompat.R.style.ThemeOverlay_AppCompat_Light
        // Menu is provided via onCreateOptionsMenu
        // Ensure overflow menu icon is visible
        binding.toolbar.overflowIcon?.setTint(getColor(android.R.color.white))
        
        // Set up toolbar menu click listener
        binding.toolbar.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                R.id.action_refresh -> {
                    homeViewModel.refreshData()
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

        lifecycleScope.launch {
            homeViewModel.currentAthlete.collect { athlete ->
                latestProfileUrl = athlete?.profile
                applyProfileImage()
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
        // Use navigation icon area for profile on the left
        binding.toolbar.setNavigationOnClickListener {
            // Placeholder: settings/profile
        }
        applyProfileImage()
        return true
    }
    
    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            R.id.action_refresh -> {
                homeViewModel.refreshData()
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

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        if (intent != null) handleSelectTabIntent(intent)
    }

    private fun handleSelectTabIntent(intent: Intent) {
        when (intent.getStringExtra(EXTRA_SELECT_TAB)) {
            TAB_SERVICE -> binding.bottomNavigation.selectedItemId = R.id.navigation_service
            TAB_BIKES -> binding.bottomNavigation.selectedItemId = R.id.navigation_bikes
            TAB_ACTIVITIES -> binding.bottomNavigation.selectedItemId = R.id.navigation_activities
        }
    }

    private fun applyProfileImage() {
        val data: Any = latestProfileUrl?.takeUnless { it.isBlank() }
            ?: R.drawable.profile_placeholder_circle
        val request = ImageRequest.Builder(this)
            .data(data)
            .crossfade(true)
            .transformations(CircleCropTransformation())
            .target(
                onSuccess = { drawable ->
                    binding.toolbar.navigationIcon = drawable
                    // Avoid tinting the profile image (clear any applied tint)
                    // try { binding.toolbar.navigationIcon?.setTintList(null) } catch (_: Exception) {}
                },
                onError = { drawable ->
                    binding.toolbar.navigationIcon = drawable
                    //try { binding.toolbar.navigationIcon?.setTintList(null) } catch (_: Exception) {}
                }
            )
            .build()
        this.imageLoader.enqueue(request)
    }
}
