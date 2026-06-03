package com.krishidrishti.app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {

    private var gnssPlugin: GnssChannelPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize GNSS native plugin for real satellite data
        gnssPlugin = GnssChannelPlugin(this)
        gnssPlugin?.registerChannels(flutterEngine)
    }

    override fun onDestroy() {
        gnssPlugin?.dispose()
        gnssPlugin = null
        super.onDestroy()
    }
}
