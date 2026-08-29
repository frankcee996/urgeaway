package com.urgeaway.applock;

import android.accessibilityservice.AccessibilityService;
import android.content.Intent;
import android.util.Log;
import android.view.accessibility.AccessibilityEvent;

/**
 * AppLockAccessibilityService — the entire enforcement mechanism behind
 * Lock In Mode.
 *
 * Android tells every running AccessibilityService when the foreground
 * window changes (TYPE_WINDOW_STATE_CHANGED), including which package it
 * belongs to. That's all this reads — never the on-screen content itself
 * (canRetrieveWindowContent is off in the service config). If the package
 * that just came to the front has an active lock, it calls the same
 * documented performGlobalAction(GLOBAL_ACTION_HOME) any accessibility
 * service is allowed to call, which is the standard "press the Home
 * button" action — not a private API, not a permission escalation.
 *
 * This is a commitment device: UrgeAway itself never exposes a "cancel
 * this lock early" button (see AppLockPlugin). The one honest way out
 * before time's up is the same as anywhere else Android grants a
 * permission — the person can go to Settings -> Accessibility and turn
 * this service off themselves. Nothing here tries to prevent, hide, or
 * discourage that; it's simply not a shortcut this code offers from
 * inside the app.
 */
public class AppLockAccessibilityService extends AccessibilityService {

    private static final String TAG = "AppLockService";
    private String lastBlockedPackage = null;
    private long lastBlockedAt = 0L;

    @Override
    protected void onServiceConnected() {
        super.onServiceConnected();
        // If this line never shows up in logcat, Android never actually
        // bound the service — that points at the permission toggle itself
        // (Restricted Settings still blocking it, or it got turned back
        // off), not at anything in the lock list/write path.
        Log.d(TAG, "Lock In Mode accessibility service connected and running");
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null || event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return;
        CharSequence pkgCs = event.getPackageName();
        if (pkgCs == null) return;
        final String packageName = pkgCs.toString();

        if (packageName.equals(getPackageName())) return; // never block UrgeAway itself
        // Android's own system UI (home launcher, notification shade, recents,
        // permission dialogs, etc.) must never be sent "home" — that would
        // just fight the OS. Only ever act on a package with an actual lock.
        Long unlockAt = AppLockStore.getUnlockAtIfLocked(this, packageName);
        if (unlockAt == null) return;

        Log.d(TAG, "Blocking locked package " + packageName + " (unlocks at " + unlockAt + ")");

        // Debounce rapid retries so the same app can't trigger a flood of
        // lock screens while the user is still trying to escape the
        // foreground launch.
        long now = System.currentTimeMillis();
        if (packageName.equals(lastBlockedPackage) && now - lastBlockedAt < 4000) {
            return;
        }
        lastBlockedPackage = packageName;
        lastBlockedAt = now;

        // Launch the blocker immediately and then send the user back Home.
        // A delayed launch leaves a visible window where the user can still
        // see the locked app for a split second; the blocker must be on top
        // before the home action is processed. We also strip animations to
        // avoid an obvious flicker during the same event burst.
        final long unlockAtFinal = unlockAt;
        Intent blockIntent = new Intent(AppLockAccessibilityService.this, LockInBlockActivity.class);
        blockIntent.putExtra(LockInBlockActivity.EXTRA_PACKAGE_NAME, packageName);
        blockIntent.putExtra(LockInBlockActivity.EXTRA_UNLOCK_AT, unlockAtFinal);
        blockIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                | Intent.FLAG_ACTIVITY_CLEAR_TOP
                | Intent.FLAG_ACTIVITY_SINGLE_TOP
                | Intent.FLAG_ACTIVITY_NO_ANIMATION
                | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        try {
            startActivity(blockIntent);
        } catch (Exception e) {
            Log.e(TAG, "Failed to launch LockInBlockActivity for " + packageName, e);
        }

        // Home is still the safe fallback once the blocker has been raised,
        // but it should not be the only thing that tries to stop the app from
        // staying in foreground.
        performGlobalAction(GLOBAL_ACTION_HOME);
    }

    @Override
    public void onInterrupt() {
        // Required override; no cleanup needed — AppLockStore has no
        // in-memory state and nothing here holds a resource to release.
    }
}
