package com.philipreese.chorebuddy.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews
import android.widget.RemoteViewsService.RemoteViewsFactory
import com.philipreese.chorebuddy.R
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

private const val WIDGET_DATA_KEY = "widget_chores_json"

private data class ChoreWidgetItem(
    val id: Int,
    val name: String,
    val dueLabel: String,
    val overdue: Boolean,
)

/**
 * Backs the widget's chore ListView. Reads the JSON WidgetSyncService (Dart
 * side) wrote to the shared `home_widget` SharedPreferences and renders one
 * row per chore -- no db access, no Flutter engine, just plain Android.
 */
class ChoreWidgetRemoteViewsFactory(private val context: Context) : RemoteViewsFactory {
  private var chores: List<ChoreWidgetItem> = emptyList()

  override fun onCreate() {}

  override fun onDestroy() {
    chores = emptyList()
  }

  // Called by the widget host whenever notifyAppWidgetViewDataChanged
  // fires (i.e. every HomeWidget.updateWidget() call from Dart) before the
  // list re-reads getCount()/getViewAt() -- this is the actual data refresh
  // point, not onCreate.
  override fun onDataSetChanged() {
    val prefs = HomeWidgetPlugin.getData(context)
    val raw = prefs.getString(WIDGET_DATA_KEY, null)
    chores = if (raw == null) emptyList() else parseChores(raw)
  }

  override fun getCount(): Int = chores.size

  override fun getViewAt(position: Int): RemoteViews {
    val item = chores[position]
    val views = RemoteViews(context.packageName, R.layout.widget_chore_item)
    views.setTextViewText(R.id.chore_item_name, item.name)
    views.setTextViewText(R.id.chore_item_due, item.dueLabel)
    views.setTextColor(
        R.id.chore_item_due,
        context.getColor(if (item.overdue) R.color.widget_overdue else R.color.widget_muted),
    )

    val completeIntent = Intent()
    completeIntent.data = Uri.parse("chorebuddy://complete/${item.id}")
    views.setOnClickFillInIntent(R.id.chore_item_checkbox, completeIntent)

    val openIntent = Intent()
    openIntent.data = Uri.parse("chorebuddy://open/${item.id}")
    views.setOnClickFillInIntent(R.id.chore_item_root, openIntent)

    return views
  }

  override fun getLoadingView(): RemoteViews? = null

  override fun getViewTypeCount(): Int = 1

  override fun getItemId(position: Int): Long = chores[position].id.toLong()

  override fun hasStableIds(): Boolean = true

  private fun parseChores(raw: String): List<ChoreWidgetItem> {
    val result = mutableListOf<ChoreWidgetItem>()
    val array = JSONArray(raw)
    for (i in 0 until array.length()) {
      val obj = array.getJSONObject(i)
      result.add(
          ChoreWidgetItem(
              id = obj.getInt("id"),
              name = obj.getString("name"),
              dueLabel = obj.getString("dueLabel"),
              overdue = obj.getBoolean("overdue"),
          )
      )
    }
    return result
  }
}
