package com.example.motion_sensor_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity: FlutterActivity() {
    private val SENSOR_CHANNEL = "motion_sensor_app/sensors"
    private val SENSOR_STREAM = "motion_sensor_app/sensor_stream"
    private val SERVICE_CHANNEL = "motion_sensor_app/service"
    private val DATA_CHANNEL = "motion_sensor_app/data"
    
    private lateinit var sensorManager: SensorManager
    private lateinit var sensorStreamHandler: SensorStreamHandler
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize sensor manager
        sensorManager = SensorManager(this)
        sensorStreamHandler = SensorStreamHandler(sensorManager)
        
        // Set up MethodChannel for sensor control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startSensors" -> {
                    val samplingRates = call.argument<Map<String, Int>>("samplingRates") ?: mapOf()
                    sensorManager.startSensors(samplingRates)
                    result.success(true)
                }
                "stopSensors" -> {
                    sensorManager.stopSensors()
                    result.success(true)
                }
                "getSensorList" -> {
                    result.success(sensorManager.getAvailableSensors())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up EventChannel for sensor data streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, SENSOR_STREAM).setStreamHandler(sensorStreamHandler)
        
        // Set up MethodChannel for service control
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SERVICE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    val activitySequence = call.argument<List<Map<String, Any>>>("activitySequence") ?: emptyList()
                    val preNoticeMode = call.argument<Boolean>("preNoticeMode") ?: true
                    val preNoticeValue = call.argument<Double>("preNoticeValue") ?: 50.0
                    val ttsEnabled = call.argument<Boolean>("ttsEnabled") ?: true
                    
                    val intent = Intent(this, SensorRecordingService::class.java).apply {
                        putExtra(SensorRecordingService.EXTRA_ACTIVITY_SEQUENCE, ArrayList(activitySequence))
                        putExtra(SensorRecordingService.EXTRA_PRE_NOTICE_MODE, preNoticeMode)
                        putExtra(SensorRecordingService.EXTRA_PRE_NOTICE_VALUE, preNoticeValue)
                        putExtra(SensorRecordingService.EXTRA_TTS_ENABLED, ttsEnabled)
                    }
                    startForegroundService(intent)
                    result.success(true)
                }
                "stopService" -> {
                    val intent = Intent(this, SensorRecordingService::class.java)
                    stopService(intent)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Set up MethodChannel for data recording and file management
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DATA_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startRecording" -> {
                    val activitySequence = call.argument<List<Map<String, Any>>>("activitySequence") ?: emptyList()
                    val success = sensorManager.startRecording(activitySequence)
                    result.success(success)
                }
                "stopRecording" -> {
                    val filePath = sensorManager.stopRecording()
                    result.success(filePath)
                }
                "setCurrentActivity" -> {
                    val activity = call.argument<String>("activity") ?: "Unknown"
                    sensorManager.setCurrentActivity(activity)
                    result.success(true)
                }
                "getRecordingFiles" -> {
                    val files = sensorManager.getRecordingFiles()
                    result.success(files)
                }
                "deleteRecording" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val success = sensorManager.deleteRecording(filePath)
                    result.success(success)
                }
                "exportRecording" -> {
                    val filePath = call.argument<String>("filePath") ?: ""
                    val targetPath = call.argument<String>("targetPath") ?: ""
                    val success = sensorManager.exportRecording(filePath, targetPath)
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        sensorManager.stopSensors()
    }
}

