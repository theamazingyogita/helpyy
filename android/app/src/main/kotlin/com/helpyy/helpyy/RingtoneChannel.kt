package com.helpyy.helpyy

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Backs lib/ringtone/ringtone_player.dart. */
class RingtoneChannel(
    private val context: Context,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    /** Needed only to open the picker. Ringing works without it, in the background too. */
    var activity: Activity? = null

    private val channel = MethodChannel(messenger, "helpyy/ringtone")
    private var player: MediaPlayer? = null
    private var pendingPick: MethodChannel.Result? = null

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "play" -> play(call.argument<String>("id"), call.argument<Boolean>("loop") ?: true, result)
            "stop" -> {
                stop()
                result.success(null)
            }
            "pick" -> pick(call.argument<String>("id"), result)
            else -> result.notImplemented()
        }
    }

    private fun play(id: String?, loop: Boolean, result: MethodChannel.Result) {
        stop()
        // A tone picked earlier can be deleted or moved since, so fall back to
        // the phone's default rather than ringing silently.
        val uris = listOfNotNull(id?.let(Uri::parse), Settings.System.DEFAULT_RINGTONE_URI)
        for (uri in uris) {
            try {
                player = MediaPlayer().apply {
                    setDataSource(context, uri)
                    setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build(),
                    )
                    isLooping = loop
                    prepare()
                    start()
                }
                result.success(null)
                return
            } catch (e: Exception) {
                stop()
            }
        }
        result.error("UNAVAILABLE", "No ringtone could be played", null)
    }

    fun stop() {
        player?.run {
            if (isPlaying) stop()
            release()
        }
        player = null
    }

    private fun pick(id: String?, result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("BUSY", "The ringtone picker is already open", null)
            return
        }
        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
            putExtra(RingtoneManager.EXTRA_RINGTONE_TYPE, RingtoneManager.TYPE_RINGTONE)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
            putExtra(
                RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                id?.let(Uri::parse) ?: Settings.System.DEFAULT_RINGTONE_URI,
            )
        }
        val activity = activity
        if (activity == null) {
            result.error("NO_ACTIVITY", "helpyy is not on screen", null)
            return
        }
        pendingPick = result
        try {
            activity.startActivityForResult(intent, PICK_REQUEST)
        } catch (e: Exception) {
            pendingPick = null
            result.error("UNAVAILABLE", "This phone has no ringtone picker", null)
        }
    }

    /** True when [requestCode] was the picker's, so the activity can skip it. */
    fun onPickerResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != PICK_REQUEST) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val uri = if (resultCode == Activity.RESULT_OK) pickedUri(data) else null
        if (uri == null) {
            result.success(null)
            return true
        }
        val title = RingtoneManager.getRingtone(context, uri)?.getTitle(context) ?: "Ringtone"
        result.success(mapOf("id" to uri.toString(), "title" to title))
        return true
    }

    private fun pickedUri(data: Intent?): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
        }

    private companion object {
        const val PICK_REQUEST = 4721
    }
}
