package com.example.motion_sensor_app

import android.content.Context
import android.os.Environment
import java.io.*
import java.text.SimpleDateFormat
import java.util.*
import java.util.concurrent.ConcurrentLinkedQueue
import kotlinx.coroutines.*

class DataRecorder(private val context: Context) {
    private var isRecording = false
    private var currentFile: File? = null
    private var fileWriter: BufferedWriter? = null
    private val dataBuffer = ConcurrentLinkedQueue<String>()
    private var recordingJob: Job? = null
    private var currentActivity = "Unknown"
    
    companion object {
        private const val BUFFER_SIZE = 1000 // Number of lines to buffer before writing
        private const val WRITE_INTERVAL_MS = 1000L // Write to file every second
        private const val DIRECTORY_NAME = "MotionSensor"
    }
    
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
        timeZone = TimeZone.getTimeZone("UTC")
    }
    
    fun startRecording(activitySequence: List<Map<String, Any>>): Boolean {
        if (isRecording) return false
        
        try {
            val recordingDir = getRecordingDirectory()
            if (!recordingDir.exists()) {
                recordingDir.mkdirs()
            }
            
            val timestamp = SimpleDateFormat("yyyy_MM_dd_HH_mm_ss", Locale.US).format(Date())
            currentFile = File(recordingDir, "Recording_$timestamp.csv")
            
            fileWriter = BufferedWriter(FileWriter(currentFile!!))
            
            // Write CSV header
            val header = "timestamp,accelerometer_x,accelerometer_y,accelerometer_z," +
                    "gyroscope_x,gyroscope_y,gyroscope_z," +
                    "magnetometer_x,magnetometer_y,magnetometer_z," +
                    "rotation_vector_x,rotation_vector_y,rotation_vector_z,rotation_vector_w," +
                    "activity"
            fileWriter?.write(header)
            fileWriter?.newLine()
            fileWriter?.flush()
            
            isRecording = true
            startWritingJob()
            
            return true
        } catch (e: Exception) {
            e.printStackTrace()
            return false
        }
    }
    
    fun stopRecording(): String? {
        if (!isRecording) return null
        
        isRecording = false
        recordingJob?.cancel()
        
        // Write any remaining buffered data
        writeBufferedData()
        
        try {
            fileWriter?.close()
            val filePath = currentFile?.absolutePath
            currentFile = null
            fileWriter = null
            dataBuffer.clear()
            return filePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }
    
    fun addSensorData(sensorData: SensorManager.SensorData) {
        if (!isRecording) return
        
        val timestamp = dateFormat.format(Date(sensorData.timestamp))
        val values = sensorData.values
        
        // Create a map to store all sensor values
        val sensorValues = mutableMapOf<String, String>()
        
        when (sensorData.sensorType) {
            "accelerometer" -> {
                sensorValues["accelerometer_x"] = if (values.size > 0) values[0].toString() else "0"
                sensorValues["accelerometer_y"] = if (values.size > 1) values[1].toString() else "0"
                sensorValues["accelerometer_z"] = if (values.size > 2) values[2].toString() else "0"
            }
            "gyroscope" -> {
                sensorValues["gyroscope_x"] = if (values.size > 0) values[0].toString() else "0"
                sensorValues["gyroscope_y"] = if (values.size > 1) values[1].toString() else "0"
                sensorValues["gyroscope_z"] = if (values.size > 2) values[2].toString() else "0"
            }
            "magnetometer" -> {
                sensorValues["magnetometer_x"] = if (values.size > 0) values[0].toString() else "0"
                sensorValues["magnetometer_y"] = if (values.size > 1) values[1].toString() else "0"
                sensorValues["magnetometer_z"] = if (values.size > 2) values[2].toString() else "0"
            }
            "rotation_vector" -> {
                sensorValues["rotation_vector_x"] = if (values.size > 0) values[0].toString() else "0"
                sensorValues["rotation_vector_y"] = if (values.size > 1) values[1].toString() else "0"
                sensorValues["rotation_vector_z"] = if (values.size > 2) values[2].toString() else "0"
                sensorValues["rotation_vector_w"] = if (values.size > 3) values[3].toString() else "0"
            }
        }
        
        // Create CSV line with all sensor data (fill missing values with previous or default)
        val csvLine = buildString {
            append(timestamp)
            append(",")
            append(sensorValues["accelerometer_x"] ?: "0")
            append(",")
            append(sensorValues["accelerometer_y"] ?: "0")
            append(",")
            append(sensorValues["accelerometer_z"] ?: "0")
            append(",")
            append(sensorValues["gyroscope_x"] ?: "0")
            append(",")
            append(sensorValues["gyroscope_y"] ?: "0")
            append(",")
            append(sensorValues["gyroscope_z"] ?: "0")
            append(",")
            append(sensorValues["magnetometer_x"] ?: "0")
            append(",")
            append(sensorValues["magnetometer_y"] ?: "0")
            append(",")
            append(sensorValues["magnetometer_z"] ?: "0")
            append(",")
            append(sensorValues["rotation_vector_x"] ?: "0")
            append(",")
            append(sensorValues["rotation_vector_y"] ?: "0")
            append(",")
            append(sensorValues["rotation_vector_z"] ?: "0")
            append(",")
            append(sensorValues["rotation_vector_w"] ?: "0")
            append(",")
            append(currentActivity)
        }
        
        dataBuffer.offer(csvLine)
    }
    
    fun setCurrentActivity(activity: String) {
        currentActivity = activity
    }
    
    private fun startWritingJob() {
        recordingJob = CoroutineScope(Dispatchers.IO).launch {
            while (isRecording) {
                delay(WRITE_INTERVAL_MS)
                writeBufferedData()
            }
        }
    }
    
    private fun writeBufferedData() {
        try {
            val linesToWrite = mutableListOf<String>()
            
            // Collect buffered data
            while (dataBuffer.isNotEmpty() && linesToWrite.size < BUFFER_SIZE) {
                dataBuffer.poll()?.let { linesToWrite.add(it) }
            }
            
            // Write to file
            if (linesToWrite.isNotEmpty()) {
                fileWriter?.let { writer ->
                    for (line in linesToWrite) {
                        writer.write(line)
                        writer.newLine()
                    }
                    writer.flush()
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    
    private fun getRecordingDirectory(): File {
        return File(context.getExternalFilesDir(Environment.DIRECTORY_DOCUMENTS), DIRECTORY_NAME)
    }
    
    fun getRecordingFiles(): List<File> {
        val recordingDir = getRecordingDirectory()
        return if (recordingDir.exists()) {
            recordingDir.listFiles { file -> file.extension == "csv" }?.toList() ?: emptyList()
        } else {
            emptyList()
        }
    }
    
    fun deleteRecording(filePath: String): Boolean {
        return try {
            val file = File(filePath)
            file.delete()
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
    
    fun getRecordingInfo(filePath: String): Map<String, Any>? {
        return try {
            val file = File(filePath)
            if (file.exists()) {
                mapOf(
                    "name" to file.nameWithoutExtension,
                    "size" to formatFileSize(file.length()),
                    "timestamp" to file.lastModified(),
                    "path" to file.absolutePath
                )
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
    
    private fun formatFileSize(bytes: Long): String {
        val kb = bytes / 1024.0
        val mb = kb / 1024.0
        return when {
            mb >= 1.0 -> String.format("%.1f MB", mb)
            kb >= 1.0 -> String.format("%.1f KB", kb)
            else -> "$bytes B"
        }
    }
    
    fun exportRecording(filePath: String, targetPath: String): Boolean {
        return try {
            val sourceFile = File(filePath)
            val targetFile = File(targetPath)
            sourceFile.copyTo(targetFile, overwrite = true)
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }
}

