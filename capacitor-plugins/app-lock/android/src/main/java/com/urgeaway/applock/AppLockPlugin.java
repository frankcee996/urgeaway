package com.urgeaway.applock;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.drawable.Drawable;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Base64;
import android.util.Log;
import android.view.accessibility.AccessibilityManager;

import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * AppLockPlugin — "Lock In Mode" for UrgeAway.
 *
 * IMPORTANT — why this isn't PackageManager#setComponentEnabledSetting():
 * that call can only toggle components the CALLING app owns. A normal,
 * non-rooted, non-Device-Owner app cannot use it (or any other public API)
 * to disable another app's launcher icon. What this plugin actually does
 * instead: manage a list of "locked" packages + unlock timestamps, and rely
 * on AppLockAccessibilityService (a standard, user-granted Accessibility
 * Service) to send the person back to Home whenever a locked package comes
 * to the foreground. The icon stays visible; the app becomes unreachable
 * for the duration. See AppLockAccessibilityService for the enforcement
 * logic and AppLockStore for where the lock list actually lives.
 *
 * By design, there is no method here to lift a lock early. Lock In Mode is
 * meant as a real commitment device — once set, UrgeAway itself won't
 * shorten it. The person's one honest way out before time's up is Android's
 * own Accessibility settings, which this code never hides, blocks, or
 * discourages using.
 */
@CapacitorPlugin(name = "AppLock")
public class AppLockPlugin extends Plugin {

    private static final String TAG = "AppLockPlugin";

    // Never lockable, regardless of what the caller sends: locking Settings
    // would strand the person unable to reach Accessibility settings at all,
    // and locking UrgeAway itself would strand them unable to manage locks.
    private static final String PACKAGE_SETTINGS = "com.android.settings";

    @PluginMethod
    public void getInstalledApps(PluginCall call) {
        Context context = getContext();
        PackageManager pm = context.getPackageManager();
        Intent launcherIntent = new Intent(Intent.ACTION_MAIN);
        launcherIntent.addCategory(Intent.CATEGORY_LAUNCHER);
        List<ResolveInfo> resolved = pm.queryIntentActivities(launcherIntent, 0);

        String selfPackage = context.getPackageName();
        JSArray apps = new JSArray();
        java.util.Set<String> seen = new java.util.HashSet<>();
        for (ResolveInfo info : resolved) {
            String pkg = info.activityInfo.packageName;
            if (pkg.equals(selfPackage) || pkg.equals(PACKAGE_SETTINGS)) continue;
            if (!seen.add(pkg)) continue; // some apps expose more than one launcher activity
            JSObject app = new JSObject();
            app.put("packageName", pkg);
            app.put("appName", String.valueOf(info.loadLabel(pm)));
            String icon = iconToBase64(info.loadIcon(pm));
            if (icon != null) app.put("icon", icon);
            apps.put(app);
        }
        JSObject ret = new JSObject();
        ret.put("apps", apps);
        call.resolve(ret);
    }

    @PluginMethod
    public void getLockedApps(PluginCall call) {
        JSONObject locks = AppLockStore.pruneExpired(getContext());
        Log.d(TAG, "getLockedApps: " + locks.length() + " active lock(s) after pruning: " + locks.toString());
        PackageManager pm = getContext().getPackageManager();
        JSArray out = new JSArray();
        Iterator<String> keys = locks.keys();
        while (keys.hasNext()) {
            String pkg = keys.next();
            long unlockAt = locks.optLong(pkg, 0);
            JSObject entry = new JSObject();
            entry.put("packageName", pkg);
            entry.put("unlockAt", unlockAt);
            entry.put("appName", labelFor(pm, pkg));
            out.put(entry);
        }
        JSObject ret = new JSObject();
        ret.put("locks", out);
        call.resolve(ret);
    }

    @PluginMethod
    public void lockApps(PluginCall call) {
        // Deliberately NOT using call.getArray()/call.getDouble() here.
        // Those typed getters were seen returning null on a real device
        // even when the on-screen debug dump of call.getData() showed
        // "packages" and "unlockAt" present and well-formed in the raw
        // payload — so we read straight off the raw JSObject instead,
        // using plain org.json accessors, which matches exactly what the
        // debug dump already proved is there.
        JSObject rawData = call.getData();
        org.json.JSONArray packagesArr = null;
        Long unlockAtLong = null;
        try {
            if (rawData != null && rawData.has("packages")) {
                packagesArr = rawData.getJSONArray("packages");
            }
        } catch (JSONException ignored) {
            packagesArr = null;
        }
        try {
            if (rawData != null && rawData.has("unlockAt")) {
                unlockAtLong = rawData.getLong("unlockAt");
            }
        } catch (JSONException ignored) {
            unlockAtLong = null;
        }

        if (packagesArr == null || packagesArr.length() == 0 || unlockAtLong == null) {
            String rawDump;
            try {
                rawDump = String.valueOf(rawData);
            } catch (Exception dumpEx) {
                rawDump = "<could not read raw call data: " + dumpEx + ">";
            }
            Log.e(TAG, "lockApps rejected: missing packages or unlockAt (packagesArr=" + packagesArr + ", unlockAt=" + unlockAtLong + ", raw=" + rawDump + ")");
            call.reject("packages (non-empty array) and unlockAt (epoch millis) are required. Raw call data received: " + rawDump);
            return;
        }
        long unlockAt = unlockAtLong;
        if (unlockAt <= System.currentTimeMillis()) {
            Log.e(TAG, "lockApps rejected: unlockAt " + unlockAt + " is not in the future (now=" + System.currentTimeMillis() + ")");
            call.reject("unlockAt must be in the future");
            return;
        }
        String selfPackage = getContext().getPackageName();
        List<String> packages = new ArrayList<>();
        try {
            for (int i = 0; i < packagesArr.length(); i++) {
                String pkg = packagesArr.getString(i);
                if (TextUtils.isEmpty(pkg)) continue;
                if (pkg.equals(selfPackage) || pkg.equals(PACKAGE_SETTINGS)) continue;
                packages.add(pkg);
            }
        } catch (JSONException e) {
            Log.e(TAG, "lockApps rejected: invalid packages array", e);
            call.reject("Invalid packages array", e);
            return;
        }
        Log.d(TAG, "lockApps: locking " + packages.size() + " package(s) until " + unlockAt + ": " + packages);
        AppLockStore.lock(getContext(), packages, unlockAt);
        JSObject ret = new JSObject();
        ret.put("locked", packages.size());
        call.resolve(ret);
    }

    @PluginMethod
    public void isAccessibilityEnabled(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("enabled", isServiceEnabled());
        call.resolve(ret);
    }

    @PluginMethod
    public void openAccessibilitySettings(PluginCall call) {
        try {
            Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Could not open Accessibility settings", e);
        }
    }

    // On Android 13+, a sideloaded (non-Play-Store) install has this app's
    // sensitive permissions — Accessibility included — locked behind
    // "Restricted settings" until the person visits this exact screen and
    // taps through App info's overflow menu themselves. No app, this one
    // included, can skip or automate that tap; it's deliberately manual.
    // This method just gets them to the right screen to do it.
    @PluginMethod
    public void openAppInfoSettings(PluginCall call) {
        try {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.setData(android.net.Uri.parse("package:" + getContext().getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            getContext().startActivity(intent);
            call.resolve();
        } catch (Exception e) {
            call.reject("Could not open App info settings", e);
        }
    }

    private boolean isServiceEnabled() {
        Context context = getContext();
        AccessibilityManager am = (AccessibilityManager) context.getSystemService(Context.ACCESSIBILITY_SERVICE);
        if (am == null) return false;
        List<AccessibilityServiceInfo> enabledServices =
                am.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK);
        String targetId = context.getPackageName() + "/" + AppLockAccessibilityService.class.getName();
        for (AccessibilityServiceInfo info : enabledServices) {
            if (targetId.equals(info.getId())) return true;
        }
        return false;
    }

    private String labelFor(PackageManager pm, String packageName) {
        try {
            ApplicationInfo ai = pm.getApplicationInfo(packageName, 0);
            return String.valueOf(pm.getApplicationLabel(ai));
        } catch (PackageManager.NameNotFoundException e) {
            return packageName;
        }
    }

    private String iconToBase64(Drawable drawable) {
        if (drawable == null) return null;
        try {
            int size = 96;
            Bitmap bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
            Canvas canvas = new Canvas(bitmap);
            drawable.setBounds(0, 0, size, size);
            drawable.draw(canvas);
            ByteArrayOutputStream stream = new ByteArrayOutputStream();
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream);
            bitmap.recycle();
            return "data:image/png;base64," + Base64.encodeToString(stream.toByteArray(), Base64.NO_WRAP);
        } catch (Exception e) {
            return null;
        }
    }
}
