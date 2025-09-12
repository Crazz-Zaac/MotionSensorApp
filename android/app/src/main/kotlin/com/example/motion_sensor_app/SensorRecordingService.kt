package com.example.motion_sensor_app

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import androidx.core.app.NotificationCompat
import kotlinx.coroutines.*
import java.util.*

class SensorRecordingService : Service(), TextToSpeech.OnInitListener {
    companion object {
        const val CHANNEL_ID = "SensorRecordingChannel"
        const val NOTIFICATION_ID = 1
        
        // Intent extras
        const val EXTRA_ACTIVITY_SEQUENCE = "activity_sequence"
        const val EXTRA_PRE_NOTICE_MODE = "pre_notice_mode"
        const val EXTRA_PRE_NOTICE_VALUE = "pre_notice_value"
        const val EXTRA_TTS_ENABLED = "tts_enabled"
    }
    
    private lateinit var sensorManager: SensorManager
    private var textToSpeech: TextToSpeech? = null
    private var isRecording = false
    private var isTTSReady = false
    
    // Activity sequence management
    private var activitySequence: List<Map<String, Any>> = emptyList()
    private var currentActivityIndex = 0
    private var recordingStartTime = 0L
    private var activityJob: Job? = null
    
    // TTS settings
    private var ttsEnabled = true
    private var preNoticeMode = true // true for percentage, false for fixed seconds
    private var preNoticeValue = 50.0 // percentage or seconds
    
    override fun onCreate() {
        super.onCreate()
        sensorManager = SensorManager(this)
        textToSpeech = TextToSpeech(this, this)
        createNotificationChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Extract parameters from intent
        intent?.let {
            activitySequence = it.getSerializableExtra(EXTRA_ACTIVITY_SEQUENCE) as? List<Map<String, Any>> ?: emptyList()
            preNoticeMode = it.getBooleanExtra(EXTRA_PRE_NOTICE_MODE, true)
            preNoticeValue = it.getDoubleExtra(EXTRA_PRE_NOTICE_VALUE, 50.0)
            ttsEnabled = it.getBooleanExtra(EXTRA_TTS_ENABLED, true)
        }
        
        startForeground(NOTIFICATION_ID, createNotification("Preparing to record..."))
        
        if (activitySequence.isNotEmpty()) {
            startRecordingSequence()
        }
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        super.onDestroy()
        stopRecordingSequence()
        sensorManager.stopSensors()
        textToSpeech?.shutdown()
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            textToSpeech?.let { tts ->
                tts.language = Locale.getDefault()
                tts.setSpeechRate(1.0f)
                tts.setPitch(1.0f)
                
                // Set up utterance progress listener
                tts.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {}
                    override fun onDone(utteranceId: String?) {}
                    override fun onError(utteranceId: String?) {}
                })
                
                isTTSReady = true
            }
        }
    }
    
    private fun startRecordingSequence() {
        if (activitySequence.isEmpty()) return
        
        isRecording = true
        recordingStartTime = System.currentTimeMillis()
        currentActivityIndex = 0
        
        // Start sensor recording
        sensorManager.startRecording(activitySequence)
        
        // Announce start of first activity
        val firstActivity = activitySequence[0]
        val activityName = firstActivity["name"] as? String ?: "Unknown"
        val duration = firstActivity["duration"] as? Int ?: 10
        
        speakText("Get ready to $activityName for $duration seconds")
        sensorManager.setCurrentActivity(activityName)
        updateNotification("Recording: $activityName")
        
        // Schedule activity progression
        scheduleActivityProgression()
    }
    
    private fun stopRecordingSequence() {
        isRecording = false
        activityJob?.cancel()
        
        val filePath = sensorManager.stopRecording()
        speakText("End of recording")
        
        updateNotification("Recording completed")
        
        // Stop the service after a short delay
        CoroutineScope(Dispatchers.Main).launch {
            delay(3000)
            stopSelf()
        }
    }
    
    private fun scheduleActivityProgression() {
        activityJob = CoroutineScope(Dispatchers.Main).launch {
            for (i in activitySequence.indices) {
                if (!isRecording) break
                
                val activity = activitySequence[i]
                val activityName = activity["name"] as? String ?: "Unknown"
                val duration = (activity["duration"] as? Int ?: 10) * 1000L // Convert to milliseconds
                
                // Set current activity
                sensorManager.setCurrentActivity(activityName)
                updateNotification("Recording: $activityName (${i + 1}/${activitySequence.size})")
                
                // Calculate pre-notice timing
                val preNoticeDelay = if (preNoticeMode) {
                    // Percentage mode
                    (duration * preNoticeValue / 100.0).toLong()
                } else {
                    // Fixed seconds mode
                    duration - (preNoticeValue * 1000).toLong()
                }.coerceAtLeast(1000L) // At least 1 second
                
                // Schedule pre-notice for next activity
                if (i < activitySequence.size - 1) {
                    delay(preNoticeDelay)
                    if (isRecording) {
                        val nextActivity = activitySequence[i + 1]
                        val nextActivityName = nextActivity["name"] as? String ?: "Unknown"
                        speakText("Get ready to $nextActivityName")
                    }
                    
                    // Wait for remaining time
                    val remainingTime = duration - preNoticeDelay
                    if (remainingTime > 0) {
                        delay(remainingTime)
                    }
                    
                    // Announce start of next activity
                    if (isRecording && i < activitySequence.size - 1) {
                        val nextActivity = activitySequence[i + 1]
                        val nextActivityName = nextActivity["name"] as? String ?: "Unknown"
                        speakText("Start $nextActivityName now")
                    }
                } else {
                    // Last activity - just wait for completion
                    delay(duration)
                }
            }
            
            // All activities completed
            if (isRecording) {
                stopRecordingSequence()
            }
        }
    }
    
    fun speakText(text: String) {
        if (ttsEnabled && isTTSReady) {
            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, UUID.randomUUID().toString())
        }
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Sensor Recording Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Channel for sensor recording service"
                setSound(null, null)
                enableVibration(false)
            }
            
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
    
    private fun createNotification(text: String = "Recording sensor data"): Notification {
        val notificationIntent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, notificationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Motion Sensor Recording")
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    fun updateNotification(text: String) {
        val notification = createNotification(text)
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, notification)
    }
    
    // Public methods for external control
    fun getCurrentActivity(): String {
        return if (currentActivityIndex < activitySequence.size) {
            activitySequence[currentActivityIndex]["name"] as? String ?: "Unknown"
        } else {
            "Completed"
        }
    }
    
    fun getElapsedTime(): Long {
        return if (isRecording) {
            System.currentTimeMillis() - recordingStartTime
        } else {
            0L
        }
    }
    
    fun getRemainingTime(): Long {
        if (!isRecording || activitySequence.isEmpty()) return 0L
        
        val totalDuration = activitySequence.sumOf { (it["duration"] as? Int ?: 0) * 1000L }
        val elapsed = getElapsedTime()
        return (totalDuration - elapsed).coerceAtLeast(0L)
    }
}

