package com.philipreese.chorebuddy.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import com.philipreese.chorebuddy.MainActivity
import com.philipreese.chorebuddy.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Renders the chore list widget: a header (app name + "add chore" button)
 * and a RemoteViewsService-backed list of up to a handful of overdue/due-
 * today chores. Row content comes from ChoreWidgetRemoteViewsFactory, which
 * reads the JSON the Dart-side WidgetSyncService last wrote to widgetData --
 * this class never touches the chore database directly.
 */
class ChoreWidgetProvider : HomeWidgetProvider() {
  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    for (widgetId in appWidgetIds) {
      val views = RemoteViews(context.packageName, R.layout.widget_chore)

      views.setOnClickPendingIntent(
          R.id.widget_header,
          HomeWidgetLaunchIntent.getActivity(
              context,
              MainActivity::class.java,
              Uri.parse("chorebuddy://open"),
          ),
      )
      views.setOnClickPendingIntent(
          R.id.widget_add_button,
          HomeWidgetLaunchIntent.getActivity(
              context,
              MainActivity::class.java,
              Uri.parse("chorebuddy://new"),
          ),
      )

      // Intent.filterEquals treats two RemoteViewsService intents with the
      // same extras as identical across widget instances, which would make
      // every pinned widget share one adapter's data; encoding the widget
      // id into the intent's data Uri (unused by the service itself) keeps
      // each instance's adapter distinct.
      val adapterIntent = Intent(context, ChoreWidgetService::class.java)
      adapterIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
      adapterIntent.data = Uri.parse("chorebuddy://widget-adapter/$widgetId")
      views.setRemoteAdapter(R.id.widget_chore_list, adapterIntent)
      views.setEmptyView(R.id.widget_chore_list, R.id.widget_empty_state)

      // RemoteViews collections only allow ONE pending-intent template per
      // list, shared by every row's fill-in intent (checkbox complete and
      // row-tap open alike) -- ChoreWidgetActionReceiver dispatches by the
      // fill-in intent's Uri host. The template's base PendingIntent must
      // stay mutable (no FLAG_IMMUTABLE) so the system can merge each row's
      // fill-in intent into it.
      val templateIntent = Intent(context, ChoreWidgetActionReceiver::class.java)
      var flags = PendingIntent.FLAG_UPDATE_CURRENT
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        flags = flags or PendingIntent.FLAG_MUTABLE
      }
      val templatePendingIntent =
          PendingIntent.getBroadcast(context, 0, templateIntent, flags)
      views.setPendingIntentTemplate(R.id.widget_chore_list, templatePendingIntent)

      appWidgetManager.updateAppWidget(widgetId, views)
      appWidgetManager.notifyAppWidgetViewDataChanged(widgetId, R.id.widget_chore_list)
    }
  }
}
