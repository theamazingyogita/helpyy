package com.helpyy.helpyy

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

class HelpyyApplication : Application() {
    lateinit var ringtones: RingtoneChannel
        private set
    lateinit var background: BackgroundChannel
        private set

    var isInForeground = false

    override fun onCreate() {
        super.onCreate()
        val engine = FlutterEngine(this)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
        val messenger = engine.dartExecutor.binaryMessenger
        ringtones = RingtoneChannel(this, messenger)
        background = BackgroundChannel(this, messenger)
    }

    companion object {
        const val ENGINE_ID = "main"
    }
}
