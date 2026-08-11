package com.philipreese.chorebuddy.widget

import android.content.Intent
import android.widget.RemoteViewsService

class ChoreWidgetService : RemoteViewsService() {
  override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
    return ChoreWidgetRemoteViewsFactory(applicationContext)
  }
}
