package com.bikecheck.android.ui.login

import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.activity.viewModels
import androidx.appcompat.app.AppCompatActivity
import androidx.browser.customtabs.CustomTabsIntent
import androidx.core.app.ActivityCompat
import com.bikecheck.android.databinding.ActivityLoginBinding
import com.bikecheck.android.ui.home.HomeActivity
import com.bikecheck.android.utils.Constants
import dagger.hilt.android.AndroidEntryPoint
import android.Manifest

@AndroidEntryPoint
class LoginActivity : AppCompatActivity() {

    private lateinit var binding: ActivityLoginBinding
    private val viewModel: LoginViewModel by viewModels()

    companion object {
        private const val POST_NOTIFICATIONS_REQUEST_CODE = 101
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityLoginBinding.inflate(layoutInflater)
        setContentView(binding.root)

        setupObservers()
        setupClickListeners()

        // Handle OAuth callback
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        val uri = intent.data
        if (uri != null && uri.toString().startsWith(Constants.STRAVA_REDIRECT_URI)) {
            uri.getQueryParameter("code")?.let { code ->
                viewModel.authenticate(code)
            }
        }
    }

    private fun setupObservers() {
        viewModel.isLoading.observe(this) { isLoading ->
            binding.progressBar.visibility = if (isLoading) View.VISIBLE else View.GONE
            binding.buttonStravaLogin.isEnabled = !isLoading
            binding.buttonTestData.isEnabled = !isLoading
        }

        viewModel.authenticationResult.observe(this) { result ->
            result.onSuccess {
                android.util.Log.d("LoginActivity", "=== AUTHENTICATION SUCCESS ===")
                android.util.Log.d("LoginActivity", "=== NAVIGATING TO HOME ===")
                
                requestNotificationPermission()
                startActivity(Intent(this, HomeActivity::class.java))
                finish()
            }.onFailure { error ->
                android.util.Log.e("LoginActivity", "Authentication failed: ${error.message}")
                Toast.makeText(this, "Authentication failed: ${error.message}", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun setupClickListeners() {
        binding.buttonStravaLogin.setOnClickListener {
            launchStravaAuth()
        }

        binding.buttonTestData.setOnClickListener {
            viewModel.insertTestData()
        }
    }

    private fun launchStravaAuth() {
        val authUrl = Uri.parse("https://www.strava.com/oauth/mobile/authorize")
            .buildUpon()
            .appendQueryParameter("client_id", Constants.STRAVA_CLIENT_ID)
            .appendQueryParameter("redirect_uri", Constants.STRAVA_REDIRECT_URI)
            .appendQueryParameter("response_type", "code")
            .appendQueryParameter("prompt", "consent")
            .appendQueryParameter("scope", Constants.STRAVA_SCOPE)
            .build()

        android.util.Log.d("LoginActivity", "Strava Auth URL: $authUrl")

        val customTabsIntent = CustomTabsIntent.Builder().build()
        customTabsIntent.launchUrl(this, authUrl)
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    POST_NOTIFICATIONS_REQUEST_CODE
                )
            }
        }
    }
}