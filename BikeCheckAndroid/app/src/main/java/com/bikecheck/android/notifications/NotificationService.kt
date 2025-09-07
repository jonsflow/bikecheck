package com.bikecheck.android.notifications

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.bikecheck.android.R
import com.bikecheck.android.data.database.entities.ServiceIntervalEntity
import com.bikecheck.android.ui.MainActivity
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class NotificationService @Inject constructor(
    private val context: Context
) {
    companion object {
        const val SERVICE_REMINDER_CHANNEL_ID = "service_reminders"
        const val SERVICE_REMINDER_NOTIFICATION_ID = 1001
    }
    
    init {
        createNotificationChannels()
    }
    
    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                SERVICE_REMINDER_CHANNEL_ID,
                "Service Reminders",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for bike service interval reminders"
                enableVibration(true)
                setShowBadge(true)
            }
            
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(serviceChannel)
        }
    }
    
    fun sendServiceReminderNotification(
        serviceInterval: ServiceIntervalEntity,
        bikeName: String
    ) {
        if (!hasNotificationPermission()) {
            return
        }
        
        // Create deep link intent
        val deepLinkIntent = Intent(
            Intent.ACTION_VIEW,
            Uri.parse("bikecheck://service-interval/${serviceInterval.id}")
        ).apply {
            setClass(context, MainActivity::class.java)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            serviceInterval.id.hashCode(),
            deepLinkIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val notification = NotificationCompat.Builder(context, SERVICE_REMINDER_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_bike_placeholder)
            .setContentTitle("$bikeName Service Reminder")
            .setContentText("It's time to service your ${serviceInterval.part}")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("Your ${serviceInterval.part} on $bikeName needs service. Tap to view details.")
            )
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()
        
        val notificationId = "service-interval-${serviceInterval.id}".hashCode()
        
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
        }
    }
    
    fun hasNotificationPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            NotificationManagerCompat.from(context).areNotificationsEnabled()
        }
    }
    
    fun cancelServiceReminderNotification(serviceIntervalId: String) {
        val notificationId = "service-interval-$serviceIntervalId".hashCode()
        NotificationManagerCompat.from(context).cancel(notificationId)
    }
}