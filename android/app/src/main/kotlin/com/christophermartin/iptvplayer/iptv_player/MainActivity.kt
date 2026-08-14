package com.christophermartin.iptvplayer.iptv_player

import android.app.PictureInPictureParams
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bruecke fuer Picture-in-Picture: der Video-Player (Dart-Seite) ruft
 * "enterPip" auf, wenn der Nutzer den PiP-Button antippt. Echtes PiP muss
 * nativ ueber die Android-Activity ausgeloest werden, dafuer gibt es keinen
 * Flutter-Plugin-Standardweg.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "iptv_player/pip"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> result.success(enterPip())
                else -> result.notImplemented()
            }
        }
    }

    private fun enterPip(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(Rational(16, 9))
                .build()
            return enterPictureInPictureMode(params)
        }
        return false
    }
}
