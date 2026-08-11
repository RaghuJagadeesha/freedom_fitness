package com.freedomfitness.freedom_fitness

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var healthConnectHandler: HealthConnectHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        healthConnectHandler = HealthConnectHandler(this)
        healthConnectHandler?.setupChannel(flutterEngine)
    }
}
