package com.example.motion_sensor_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager as AndroidSensorManager
import android.os.Handler
import android.os.Looper
import java.util.concurrent.ConcurrentHashMap

class SensorManager(private val context: Context) : SensorEventListener {
    private val androidSensorManager = context.getSystemService(Context.SENSOR_SERVICE) as AndroidSensorManager
    private val handler = Handler(Looper.getMainLooper())
    private val dataRecorder = DataRecorder(context)
    
    // Sensor types we support
    private val supportedSensorTypes = mapOf(
        "accelerometer" to Sensor.TYPE_ACCELEROMETER,
        "gyroscope" to Sensor.TYPE_GYROSCOPE,
        "magnetometer" to Sensor.TYPE_MAGNETIC_FIELD,
        "rotation_vector" to Sensor.TYPE_ROTATION_VECTOR
    )
    
    // Active sensors and their sampling rates
    private val activeSensors = ConcurrentHashMap<String, Sensor>()
    private val samplingRates = ConcurrentHashMap<String, Int>()
    
    // Listeners for sensor data
    private val dataListeners = mutableListOf<(SensorData) -> Unit>()
    
    data class SensorData(
        val sensorType: String,
        val timestamp: Long,
        val values: FloatArray,
        val accuracy: Int
    )
    
    fun addDataListener(listener: (SensorData) -> Unit) {
        dataListeners.add(listener)
    }
    
    fun removeDataListener(listener: (SensorData) -> Unit) {
        dataListeners.remove(listener)
    }
    
    fun getAvailableSensors(): List<String> {
        val availableSensors = mutableListOf<String>()
        for ((name, type) in supportedSensorTypes) {
            val sensor = androidSensorManager.getDefaultSensor(type)
            if (sensor != null) {
                availableSensors.add(name)
            }
        }
        return availableSensors
    }
    
    fun startSensors(sensorSamplingRates: Map<String, Int>) {
        stopSensors() // Stop any existing sensors first
        
        for ((sensorName, samplingRate) in sensorSamplingRates) {
            val sensorType = supportedSensorTypes[sensorName]
            if (sensorType != null) {
                val sensor = androidSensorManager.getDefaultSensor(sensorType)
                if (sensor != null) {
                    // Convert sampling rate from Hz to microseconds
                    val samplingPeriodUs = if (samplingRate > 0) {
                        (1_000_000 / samplingRate).coerceAtLeast(1000) // Min 1ms
                    } else {
                        AndroidSensorManager.SENSOR_DELAY_NORMAL
                    }
                    
                    val success = androidSensorManager.registerListener(
                        this,
                        sensor,
                        samplingPeriodUs
                    )
                    
                    if (success) {
                        activeSensors[sensorName] = sensor
                        samplingRates[sensorName] = samplingRate
                    }
                }
            }
        }
    }
    
    fun stopSensors() {
        androidSensorManager.unregisterListener(this)
        activeSensors.clear()
        samplingRates.clear()
    }
    
    fun startRecording(activitySequence: List<Map<String, Any>>): Boolean {
        return dataRecorder.startRecording(activitySequence)
    }
    
    fun stopRecording(): String? {
        return dataRecorder.stopRecording()
    }
    
    fun setCurrentActivity(activity: String) {
        dataRecorder.setCurrentActivity(activity)
    }
    
    fun getRecordingFiles(): List<Map<String, Any>> {
        return dataRecorder.getRecordingFiles().mapNotNull { file ->
            dataRecorder.getRecordingInfo(file.absolutePath)
        }
    }
    
    fun deleteRecording(filePath: String): Boolean {
        return dataRecorder.deleteRecording(filePath)
    }
    
    fun exportRecording(filePath: String, targetPath: String): Boolean {
        return dataRecorder.exportRecording(filePath, targetPath)
    }
    
    override fun onSensorChanged(event: SensorEvent?) {
        event?.let { sensorEvent ->
            val sensorName = getSensorName(sensorEvent.sensor.type)
            if (sensorName != null && activeSensors.containsKey(sensorName)) {
                val sensorData = SensorData(
                    sensorType = sensorName,
                    timestamp = System.currentTimeMillis(),
                    values = sensorEvent.values.clone(),
                    accuracy = sensorEvent.accuracy
                )
                
                // Record data if recording is active
                dataRecorder.addSensorData(sensorData)
                
                // Notify all listeners
                handler.post {
                    dataListeners.forEach { listener ->
                        try {
                            listener(sensorData)
                        } catch (e: Exception) {
                            // Handle listener errors gracefully
                        }
                    }
                }
            }
        }
    }
    
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Handle accuracy changes if needed
    }
    
    private fun getSensorName(sensorType: Int): String? {
        return supportedSensorTypes.entries.find { it.value == sensorType }?.key
    }
    
    fun getSensorInfo(): Map<String, Any> {
        val info = mutableMapOf<String, Any>()
        for ((name, sensor) in activeSensors) {
            info[name] = mapOf(
                "name" to sensor.name,
                "vendor" to sensor.vendor,
                "version" to sensor.version,
                "maxRange" to sensor.maximumRange,
                "resolution" to sensor.resolution,
                "power" to sensor.power,
                "samplingRate" to (samplingRates[name] ?: 0)
            )
        }
        return info
    }
}

