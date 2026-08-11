package com.philipreese.chorebuddy

import android.app.PendingIntent
import android.content.Intent
import android.os.Build
import android.service.quicksettings.TileService

/**
 * Quick-settings tile that launches the app straight to the new-chore form.
 *
 * Fires the same deep-link intent extra the `quick_actions` plugin reads off
 * MainActivity's launch/new intent for app shortcuts, so this tile and the
 * "New Mission" launcher shortcut are handled by the exact same Dart-side
 * code path -- no separate native-to-Dart channel needed here.
 */
class NewMissionTileService : TileService() {

    override fun onClick() {
        super.onClick()

        val intent = Intent(this, MainActivity::class.java).apply {
            action = Intent.ACTION_RUN
            putExtra(QUICK_ACTION_EXTRA, NEW_MISSION_ACTION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Apps targeting API 34+ must collapse via a PendingIntent; the
            // Intent overload throws on those targets.
            val pendingIntent = PendingIntent.getActivity(
                this,
                0,
                intent,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pendingIntent)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(intent)
        }
    }

    private companion object {
        // Must match QuickActions.EXTRA_ACTION in the quick_actions_android
        // plugin -- its MainActivity NewIntentListener reads this exact key
        // to route a launch/new intent back into the Dart shortcut handler.
        const val QUICK_ACTION_EXTRA = "some unique action key"

        // Must match AppShortcutAction.newMission.id on the Dart side.
        const val NEW_MISSION_ACTION = "new_mission"
    }
}
