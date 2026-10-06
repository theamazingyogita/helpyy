package com.helpyy.helpyy

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private val app get() = application as HelpyyApplication

    override fun getCachedEngineId() = HelpyyApplication.ENGINE_ID

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        app.ringtones.activity = this
        app.background.activity = this
        showOverLockScreen(intent.getBooleanExtra(EXTRA_INCOMING_CALL, false))
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        if (intent.getBooleanExtra(EXTRA_INCOMING_CALL, false)) showOverLockScreen(true)
    }

    override fun onResume() {
        super.onResume()
        app.isInForeground = true
    }

    override fun onPause() {
        app.isInForeground = false
        super.onPause()
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (!app.ringtones.onPickerResult(requestCode, resultCode, data)) {
            super.onActivityResult(requestCode, resultCode, data)
        }
    }

    override fun onDestroy() {
        if (app.ringtones.activity === this) app.ringtones.activity = null
        if (app.background.activity === this) app.background.activity = null
        super.onDestroy()
    }

    fun showOverLockScreen(show: Boolean) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(show)
            setTurnScreenOn(show)
        } else {
            @Suppress("DEPRECATION")
            val flags = WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            if (show) window.addFlags(flags) else window.clearFlags(flags)
        }
    }

    companion object {
        const val EXTRA_INCOMING_CALL = "incoming_call"
    }
}
