package com.dirisujesse.speech_recognizer

import android.content.Context
import android.content.Intent
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import java.util.Locale

/**
 * Manages Android SpeechRecognizer lifecycle and intent setup.
 */
class SpeechRecognizerManager(
    context: Context,
    private val listener: RecognitionListener,
    private val localeTag: String?,
) {

    private val TAG = "SpeechRecognizerManager"
    private var speechRecognizer: SpeechRecognizer? = null
    private val speechRecognizerIntent: Intent

    init {
        if (!SpeechRecognizer.isRecognitionAvailable(context)) {
            Log.e(TAG, "Speech recognition is not available on this device.")
            throw UnsupportedOperationException("Speech recognition not available")
        }

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(context)
        speechRecognizer?.setRecognitionListener(listener)

        val locale = localeTag?.let { Locale.forLanguageTag(it) } ?: Locale.getDefault()
        speechRecognizerIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale.toLanguageTag())
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 1)
        }
        Log.d(TAG, "SpeechRecognizerManager initialized with locale: ${locale.toLanguageTag()}")
    }

    /**
     * Starts listening for speech input.
     */
    fun startListening() {
        speechRecognizer?.startListening(speechRecognizerIntent)
        Log.d(TAG, "Started listening")
    }

    /**
     * Stops listening for speech input.
     */
    fun stopListening() {
        speechRecognizer?.stopListening()
        Log.d(TAG, "Stopped listening")
    }

    /**
     * Releases resources held by SpeechRecognizer.
     */
    fun destroy() {
        speechRecognizer?.destroy()
        speechRecognizer = null
        Log.d(TAG, "SpeechRecognizer destroyed")
    }
}
