package com.dirisujesse.speech_recognizer

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.util.Locale

class SpeechRecognizerPlugin : FlutterPlugin, ActivityAware, MethodCallHandler, RecognitionListener, PluginRegistry.RequestPermissionsResultListener {
    private lateinit var channel: MethodChannel
    private var speechRecognizer: SpeechRecognizer? = null
    private var activity: Activity? = null
    private val RECORD_AUDIO_PERMISSION_REQUEST_CODE = 1

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.dirisujesse.speech_recognizer/methods")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopListening()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        activity = null
        stopListening()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "startTranscription" -> startListening(result)
            "stopTranscription" -> stopListening(result)
            else -> result.notImplemented()
        }
    }

    private fun hasAudioPermission(): Boolean {
        return ContextCompat.checkSelfPermission(activity!!, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
    }

    private fun requestAudioPermission() {
        ActivityCompat.requestPermissions(activity!!, arrayOf(Manifest.permission.RECORD_AUDIO), RECORD_AUDIO_PERMISSION_REQUEST_CODE)
    }

    private fun startListening(result: Result? = null) {
        if (activity == null) {
            channel.invokeMethod("onSpeechError", "Activity not available")
            return
        }

        if (!hasAudioPermission()) {
            requestAudioPermission()
            return
        }

        if (speechRecognizer == null) {
            speechRecognizer = SpeechRecognizer.createSpeechRecognizer(activity)
            speechRecognizer?.setRecognitionListener(this)
        }

        val locale = Locale.getDefault()

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
        intent.putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toLanguageTag())
        speechRecognizer?.startListening(intent)
        channel.invokeMethod("onSpeechReady", true)
//        result.sucess(null)
    }

    private fun stopListening(result: Result? = null) {
        speechRecognizer?.stopListening()
        speechRecognizer?.destroy()
        speechRecognizer = null
        channel.invokeMethod("onSpeechReady", false)
        result?.success(null)
    }

    override fun onReadyForSpeech(params: Bundle?) {}

    override fun onBeginningOfSpeech() {}

    override fun onRmsChanged(rmsdB: Float) {}

    override fun onBufferReceived(buffer: ByteArray?) {}

    override fun onEndOfSpeech() {}

    override fun onError(error: Int) {
        channel.invokeMethod("onSpeechError", "Error code: $error")
    }

    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (matches != null && matches.isNotEmpty()) {
            channel.invokeMethod("onSpeechResult", matches[0])
        }
        stopListening()
    }

    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (matches != null && matches.isNotEmpty()) {
            channel.invokeMethod("onPartialSpeechResult", matches[0])
        }
    }

    override fun onEvent(eventType: Int, params: Bundle?) {}

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray): Boolean {
        if (requestCode == RECORD_AUDIO_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                startListening()
            } else {
                channel.invokeMethod("onSpeechError", "Permission denied")
            }
            return true
        }
        return false
    }
}
