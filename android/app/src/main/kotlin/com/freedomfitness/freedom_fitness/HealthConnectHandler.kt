package com.freedomfitness.freedom_fitness

import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.ActiveCaloriesBurnedRecord
import androidx.health.connect.client.records.HeartRateRecord
import androidx.health.connect.client.records.RestingHeartRateRecord
import androidx.health.connect.client.records.StepsRecord
import androidx.health.connect.client.records.TotalCaloriesBurnedRecord
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class HealthConnectHandler(private val activity: ComponentActivity) {
    companion object {
        const val CHANNEL = "freedom_fitness/health_connect"
        private const val TAG = "FreedomHealthConnect"
    }

    private var permissionsLauncher: ActivityResultLauncher<Set<String>>? = null
    private var channel: MethodChannel? = null

    fun setupChannel(flutterEngine: FlutterEngine) {
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestPermissions" -> requestPermissions(result)
                "checkAvailability" -> checkAvailability(result)
                else -> result.notImplemented()
            }
        }

        val contract = PermissionController.createRequestPermissionResultContract()
        permissionsLauncher = activity.registerForActivityResult(contract) { granted ->
            Log.i(TAG, "Permissions granted: ${granted.size}")
            channel?.invokeMethod("permissionsResult", granted.isNotEmpty())
        }
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        try {
            Log.i(TAG, "Requesting Health Connect permissions...")
            val client = HealthConnectClient.getOrCreate(activity)
            Log.i(TAG, "HealthConnectClient created: $client")
            val perms = setOf<String>(
                HealthPermission.getReadPermission(ActiveCaloriesBurnedRecord::class),
                HealthPermission.getReadPermission(TotalCaloriesBurnedRecord::class),
                HealthPermission.getReadPermission(HeartRateRecord::class),
                HealthPermission.getReadPermission(RestingHeartRateRecord::class),
                HealthPermission.getReadPermission(StepsRecord::class),
            )
            Log.i(TAG, "Launching permission request with ${perms.size} permissions")
            permissionsLauncher?.launch(perms)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to launch permissions: ${e.message}", e)
            result.success(false)
        }
    }

    private fun checkAvailability(result: MethodChannel.Result) {
        try {
            val status = HealthConnectClient.getSdkStatus(activity)
            val available = status == HealthConnectClient.SDK_AVAILABLE
            Log.i(TAG, "HealthConnect SDK status: $status, available: $available")
            result.success(available)
        } catch (e: Exception) {
            Log.e(TAG, "HealthConnect check failed: ${e.message}", e)
            result.success(false)
        }
    }
}
