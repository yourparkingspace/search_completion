package com.yourparkingspace.search_completion

import android.content.Context
import com.google.android.libraries.places.api.Places
import com.google.android.libraries.places.api.model.AutocompletePrediction
import com.google.android.libraries.places.api.model.Place
import com.google.android.libraries.places.api.net.FindAutocompletePredictionsRequest
import com.google.android.libraries.places.api.net.PlacesClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*

class SearchCompletionPlugin: FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var context: Context
    private lateinit var placesClient: PlacesClient
    private var eventSink: EventChannel.EventSink? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "search_completion")
        channel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, "search_completion_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val apiKey = call.argument<String>("apiKey")
                if (apiKey != null) {
                    Places.initialize(context, apiKey)
                    placesClient = Places.createClient(context)
                    result.success(null)
                } else {
                    result.error("MISSING_API_KEY", "Google Places API key is required", null)
                }
            }
            "updateSearchTerm" -> {
                val searchTerm = call.argument<String>("searchTerm")
                if (searchTerm != null) {
                    performSearch(searchTerm)
                    result.success(null)
                }
            }
            "getCoordinates" -> {
                val placeId = call.argument<String>("placeId")
                if (placeId != null) {
                    getPlaceDetails(placeId, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun performSearch(query: String) {
        val request = FindAutocompletePredictionsRequest.builder()
            .setQuery(query)
            .build()

        placesClient.findAutocompletePredictions(request)
            .addOnSuccessListener { response ->
                val results = response.autocompletePredictions.map { prediction ->
                    mapOf(
                        "id" to prediction.placeId,
                        "title" to prediction.getPrimaryText(null).toString(),
                        "subtitle" to prediction.getSecondaryText(null).toString()
                    )
                }
                eventSink?.success(results)
            }
            .addOnFailureListener { exception ->
                eventSink?.error("SEARCH_ERROR", exception.message, null)
            }
    }

    private fun getPlaceDetails(placeId: String, result: MethodChannel.Result) {
        val placeFields = listOf(Place.Field.LAT_LNG)
        val request = com.google.android.libraries.places.api.net.FetchPlaceRequest
            .builder(placeId, placeFields)
            .build()

        placesClient.fetchPlace(request)
            .addOnSuccessListener { response ->
                val place = response.place
                val latLng = place.latLng
                if (latLng != null) {
                    result.success(mapOf(
                        "latitude" to latLng.latitude,
                        "longitude" to latLng.longitude
                    ))
                } else {
                    result.success(null)
                }
            }
            .addOnFailureListener { exception ->
                result.error("PLACE_ERROR", exception.message, null)
            }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
