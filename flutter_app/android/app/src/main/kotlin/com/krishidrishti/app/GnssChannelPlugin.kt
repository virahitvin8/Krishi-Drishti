package com.krishidrishti.app

import android.annotation.SuppressLint
import android.content.Context
import android.location.GnssStatus
import android.location.LocationManager
import android.location.LocationManager.OnNmeaMessageListener
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel

/**
 * GNSS Native Plugin - communicates real Android GnssStatus.Callback data to Flutter
 * via EventChannel. Falls back to simulation in Dart if native channel is unavailable.
 *
 * Channels:
 * - com.krishidrishti/gnss_satellites  → streams List<Map> of satellite data
 * - com.krishidrishti/gnss_nmea        → streams List<String> of NMEA sentences
 * - com.krishidrishti/gnss_constellations → streams Map<String, Int> constellation counts
 */
class GnssChannelPlugin(private val context: Context) {

    companion object {
        const val SATELLITE_CHANNEL = "com.krishidrishti/gnss_satellites"
        const val NMEA_CHANNEL = "com.krishidrishti/gnss_nmea"
        const val CONSTELLATION_CHANNEL = "com.krishidrishti/gnss_constellations"

        private const val CONSTELLATION_GPS = 1
        private const val CONSTELLATION_SBAS = 2
        private const val CONSTELLATION_GLONASS = 3
        private const val CONSTELLATION_QZSS = 4
        private const val CONSTELLATION_BEIDOU = 5
        private const val CONSTELLATION_GALILEO = 6
        private const val CONSTELLATION_NAVIC = 7
    }

    private var locationManager: LocationManager? = null
    private var gnssCallback: GnssStatus.Callback? = null
    private var nmeaListener: OnNmeaMessageListener? = null

    // Event sinks
    private var satelliteSink: EventChannel.EventSink? = null
    private var nmeaSink: EventChannel.EventSink? = null
    private var constellationSink: EventChannel.EventSink? = null

    // Last known data for caching
    private val lastSatellites = mutableListOf<Map<String, Any?>>()
    private val lastNmea = mutableListOf<String>()

    /**
     * Register all EventChannels on the given FlutterEngine.
     * Call this from MainActivity.configureFlutterEngine().
     */
    fun registerChannels(flutterEngine: FlutterEngine) {
        // Satellite stream
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SATELLITE_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                satelliteSink = events
                // Send cached data immediately if available
                if (lastSatellites.isNotEmpty()) {
                    events?.success(lastSatellites.toList())
                }
                ensureMonitoringStarted()
            }

            override fun onCancel(arguments: Any?) {
                satelliteSink = null
                checkStopMonitoring()
            }
        })

        // NMEA stream
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            NMEA_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                nmeaSink = events
                if (lastNmea.isNotEmpty()) {
                    events?.success(lastNmea.toList())
                }
                ensureMonitoringStarted()
            }

            override fun onCancel(arguments: Any?) {
                nmeaSink = null
                checkStopMonitoring()
            }
        })

        // Constellation breakdown stream
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CONSTELLATION_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                constellationSink = events
                ensureMonitoringStarted()
            }

            override fun onCancel(arguments: Any?) {
                constellationSink = null
                checkStopMonitoring()
            }
        })
    }

    @SuppressLint("MissingPermission")
    private fun ensureMonitoringStarted() {
        if (locationManager != null) return // Already monitoring

        val lm = context.getSystemService(Context.LOCATION_SERVICE) as? LocationManager ?: return
        locationManager = lm

        // --- GnssStatus.Callback (API 24+) ---
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val callback = object : GnssStatus.Callback() {
                override fun onSatelliteStatusChanged(status: GnssStatus) {
                    val satellites = mutableListOf<Map<String, Any?>>()
                    val constellationCounts = mutableMapOf<String, Int>()

                    for (i in 0 until status.satelliteCount) {
                        val prn = status.getSvid(i)
                        val snr = status.getCn0DbHz(i)
                        val elevation = status.getElevationDegrees(i)
                        val azimuth = status.getAzimuthDegrees(i)
                        val usedInFix = status.usedInFix(i)
                        val hasAlmanac = status.hasAlmanacData(i)
                        val hasEphemeris = status.hasEphemerisData(i)
                        val constellationType = status.getConstellationType(i)
                        val constellationName = constellationTypeToName(constellationType)
                        val freqBand = if (constellationType == CONSTELLATION_GPS) "L1" else if (constellationType == CONSTELLATION_GALILEO) "E1" else "L1"

                        satellites.add(mapOf(
                            "prn" to prn,
                            "constellation" to constellationName,
                            "snr" to snr.toDouble(),
                            "elevation" to elevation.toDouble(),
                            "azimuth" to azimuth.toDouble(),
                            "usedInFix" to usedInFix,
                            "hasEphemeris" to hasEphemeris,
                            "hasAlmanac" to hasAlmanac,
                            "frequencyBand" to freqBand,
                        ))

                        constellationCounts[constellationName] =
                            (constellationCounts[constellationName] ?: 0) + 1
                    }

                    lastSatellites.clear()
                    lastSatellites.addAll(satellites)

                    satelliteSink?.success(satellites)
                    constellationSink?.success(constellationCounts)
                }

                override fun onStarted() {
                    // GNSS engine started
                }

                override fun onStopped() {
                    // GNSS engine stopped
                }

                override fun onFirstFix(ttffMillis: Int) {
                    // First fix acquired
                }
            }

            gnssCallback = callback
            try {
                lm.registerGnssStatusCallback(callback, Handler(Looper.getMainLooper()))
            } catch (e: SecurityException) {
                // Location permission not granted
            }
        }

        // --- NMEA Listener (API 24+) ---
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val listener = OnNmeaMessageListener { nmea: String, _: Long ->
                val sentences = lastNmea.toMutableList()
                sentences.add(nmea)
                if (sentences.size > 20) {
                    sentences.removeAt(0)
                }
                lastNmea.clear()
                lastNmea.addAll(sentences)
                nmeaSink?.success(sentences)
            }

            nmeaListener = listener
            try {
                lm.addNmeaListener(listener, Handler(Looper.getMainLooper()))
            } catch (e: SecurityException) {
                // Location permission not granted
            }
        }
    }

    private fun checkStopMonitoring() {
        // Keep monitoring if any sink is still active
        if (satelliteSink != null || nmeaSink != null || constellationSink != null) return

        stopMonitoring()
    }

    private fun stopMonitoring() {
        val lm = locationManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            gnssCallback?.let { lm.unregisterGnssStatusCallback(it) }
            nmeaListener?.let { listener ->
                try {
                    lm.removeNmeaListener(listener)
                } catch (_: Exception) {}
            }
        }
        locationManager = null
        gnssCallback = null
        nmeaListener = null
    }

    private fun constellationTypeToName(type: Int): String {
        return when (type) {
            CONSTELLATION_GPS -> "GPS"
            CONSTELLATION_SBAS -> "SBAS"
            CONSTELLATION_GLONASS -> "GLONASS"
            CONSTELLATION_QZSS -> "QZSS"
            CONSTELLATION_BEIDOU -> "BeiDou"
            CONSTELLATION_GALILEO -> "Galileo"
            CONSTELLATION_NAVIC -> "NavIC"
            else -> "Unknown"
        }
    }

    fun dispose() {
        stopMonitoring()
        satelliteSink = null
        nmeaSink = null
        constellationSink = null
    }
}
