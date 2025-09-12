package com.example.motion_sensor_app

import io.flutter.plugin.common.EventChannel
import android.os.Handler
import android.os.Looper

class SensorStreamHandler(private val sensorManager: SensorManager) : EventChannel.StreamHandler {
    private var eventSink: EventChannel.EventSink? = null
    private val handler = Handler(Looper.getMainLooper())
    
    private val sensorDataListener: (SensorManager.SensorData) -> Unit = { sensorData ->
        handler.post {
            eventSink?.let { sink ->
                val data = mapOf(
                    "sensorType" to sensorData.sensorType,
                    "timestamp" to sensorData.timestamp,
                    "values" to sensorData.values.toList(),
                    "accuracy" to sensorData.accuracy
                )
                sink.success(data)
            }
        }
    }
    
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        sensorManager.addDataListener(sensorDataListener)
    }
    
    override fun onCancel(arguments: Any?) {
        sensorManager.removeDataListener(sensorDataListener)
        eventSink = null
    }
}

