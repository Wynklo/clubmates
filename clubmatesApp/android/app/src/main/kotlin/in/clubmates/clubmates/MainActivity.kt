package `in`.clubmates.clubmates

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        applyDisplayRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        applyDisplayRefreshRate()
    }

    private fun applyDisplayRefreshRate() {
        val current = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay
        } ?: return
        val mode = current.supportedModes.maxByOrNull { it.refreshRate } ?: return
        val params = window.attributes
        params.preferredDisplayModeId = mode.modeId
        @Suppress("DEPRECATION")
        params.preferredRefreshRate = mode.refreshRate
        window.attributes = params
    }
}
