package com.helpyy.helpyy

import android.Manifest
import android.app.Activity
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class BackgroundChannel(
    private val app: HelpyyApplication,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    var activity: MainActivity? = null

    private val notifications = app.getSystemService(NotificationManager::class.java)

    init {
        MethodChannel(messenger, "helpyy/background").setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                askForNotifications()
                ListeningService.start(app)
                result.success(null)
            }
            "stop" -> {
                ListeningService.stop(app)
                result.success(null)
            }
            "showIncomingCall" -> {
                if (!app.isInForeground) showIncomingCall(call.argument<String>("callerName") ?: "")
                result.success(null)
            }
            "endIncomingCall" -> {
                notifications.cancel(CALL_NOTIFICATION_ID)
                activity?.showOverLockScreen(false)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    private fun askForNotifications() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        val activity: Activity = activity ?: return
        if (activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        activity.requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), PERMISSION_REQUEST)
    }

    private fun showIncomingCall(callerName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notifications.createNotificationChannel(
                NotificationChannel(CALL_CHANNEL, "Escape calls", NotificationManager.IMPORTANCE_HIGH).apply {
                    description = "The fake call when helpyy is in the background"
                    enableVibration(true)
                    vibrationPattern = longArrayOf(0, 800, 600, 800)
                    setSound(null, null)
                },
            )
        }
        val intent = Intent(app, MainActivity::class.java)
            .putExtra(MainActivity.EXTRA_INCOMING_CALL, true)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        val open = PendingIntent.getActivity(
            app,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(app, CALL_CHANNEL)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(app).setPriority(Notification.PRIORITY_MAX)
        }
        val notification = builder
            .setSmallIcon(android.R.drawable.sym_call_incoming)
            .setContentTitle(callerName)
            .setContentText("Incoming call")
            .setCategory(Notification.CATEGORY_CALL)
            .setOngoing(true)
            .setContentIntent(open)
            .setFullScreenIntent(open, true)
            .build()
        notifications.notify(CALL_NOTIFICATION_ID, notification)
    }

    private companion object {
        const val CALL_CHANNEL = "calls"
        const val CALL_NOTIFICATION_ID = 2
        const val PERMISSION_REQUEST = 4722
    }
}
