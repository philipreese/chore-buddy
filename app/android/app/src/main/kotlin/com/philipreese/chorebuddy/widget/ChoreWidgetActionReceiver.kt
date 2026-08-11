package com.philipreese.chorebuddy.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.philipreese.chorebuddy.MainActivity
import es.antonborri.home_widget.HomeWidgetBackgroundWorker
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import io.flutter.FlutterInjector

/**
 * Single pending-intent template target for every row in the chore
 * RemoteViews list (see ChoreWidgetProvider.setPendingIntentTemplate) --
 * Android collections only allow one template per list, so this dispatches
 * by the tapped row's fill-in-intent Uri instead of using two templates:
 *  - `chorebuddy://complete/<id>` (checkbox tap): hands off to the same
 *    WorkManager-backed dispatch `HomeWidgetBackgroundReceiver` uses, which
 *    runs the registered Dart interactivity callback on a background
 *    isolate.
 *  - anything else (row tap, header, "+"): opens MainActivity with the Uri
 *    as launch data, exactly like HomeWidgetLaunchIntent's own PendingIntent
 *    would -- reproduced here because that helper only builds an Activity
 *    PendingIntent, and this receiver's single component can't also target
 *    an Activity.
 */
class ChoreWidgetActionReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent) {
    val uri = intent.data ?: return
    if (uri.host == "complete") {
      val flutterLoader = FlutterInjector.instance().flutterLoader()
      flutterLoader.startInitialization(context)
      flutterLoader.ensureInitializationComplete(context, null)
      HomeWidgetBackgroundWorker.enqueueWork(context, intent)
      return
    }

    val launchIntent = Intent(context, MainActivity::class.java)
    launchIntent.action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
    launchIntent.data = uri
    launchIntent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    context.startActivity(launchIntent)
  }
}
