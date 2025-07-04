package com.example.mopro_flutter_example

import android.content.Intent
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink

class MainActivity: FlutterActivity() {
    private var eventSink: EventSink? = null
    private val eventChannel = "com.example.moprowallet/events"
    private val TAG = "MoproWallet"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup EventChannel for deep links
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannel).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventSink?) {
                    Log.d(TAG, "EventChannel listener registered")
                    eventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    Log.d(TAG, "EventChannel listener cancelled")
                    eventSink = null
                }
            }
        )
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "MainActivity onCreate")
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d(TAG, "MainActivity onNewIntent")
        setIntent(intent) // Important: Update the intent
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        val data = intent?.data
        if (data != null) {
            Log.d(TAG, "Received deep link: $data")
            eventSink?.success(data.toString())
        } else {
            Log.d(TAG, "No deep link data in intent")
        }
    }
}
