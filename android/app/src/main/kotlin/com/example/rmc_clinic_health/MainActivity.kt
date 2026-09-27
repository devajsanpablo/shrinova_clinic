package com.example.rmc_clinic_health

import android.app.DownloadManager
import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "clinic/app_updates"
    private val preferencesName = "clinic_app_update_download"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "startDownload" -> {
                            val url = call.argument<String>("url") ?: error("Missing APK URL")
                            val build = call.argument<Int>("build") ?: error("Missing build number")
                            startDownload(url, build)
                            result.success(null)
                        }
                        "downloadStatus" -> result.success(downloadStatus())
                        "canInstallPackages" -> result.success(canInstallPackages())
                        "installDownloadedApk" -> result.success(installDownloadedApk())
                        else -> result.notImplemented()
                    }
                } catch (exception: Exception) {
                    result.error("APP_UPDATE", exception.message ?: "Update failed", null)
                }
            }
    }

    private val manager: DownloadManager
        get() = getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    private val preferences
        get() = getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun downloadFile(build: Int) = File(
        getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS),
        "clinic-update-$build.apk"
    )

    private fun startDownload(url: String, build: Int) {
        val uri = Uri.parse(url)
        require(uri.scheme == "https" && uri.host == "firebasestorage.googleapis.com") {
            "The APK URL must be a Firebase Storage HTTPS download URL"
        }
        require(build > 0) { "Invalid update build number" }

        val previousId = preferences.getLong("download_id", -1)
        val sameRelease = preferences.getInt("build", -1) == build &&
            preferences.getString("url", null) == url
        if (sameRelease && previousId >= 0) {
            val state = downloadStatus()["state"]
            if (state == "running" || state == "complete") return
        }
        if (previousId >= 0) manager.remove(previousId)

        val file = downloadFile(build)
        if (file.exists()) file.delete()
        val request = DownloadManager.Request(uri)
            .setTitle("Clinic System update")
            .setDescription("Downloading version update")
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
            .setDestinationInExternalFilesDir(
                this,
                Environment.DIRECTORY_DOWNLOADS,
                file.name
            )
        val id = manager.enqueue(request)
        preferences.edit().putLong("download_id", id).putInt("build", build)
            .putString("url", url).apply()
    }

    private fun downloadStatus(): Map<String, Any> {
        val id = preferences.getLong("download_id", -1)
        if (id < 0) return mapOf("state" to "missing", "progress" to 0)
        manager.query(DownloadManager.Query().setFilterById(id)).use { cursor ->
            if (!cursor.moveToFirst()) return mapOf("state" to "missing", "progress" to 0)
            val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
            val downloaded = cursor.getLong(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)
            )
            val total = cursor.getLong(
                cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES)
            )
            val progress = if (total > 0) (downloaded * 100 / total).toInt().coerceIn(0, 100) else 0
            val state = when (status) {
                DownloadManager.STATUS_SUCCESSFUL -> "complete"
                DownloadManager.STATUS_FAILED -> "failed"
                DownloadManager.STATUS_PAUSED -> "paused"
                else -> "running"
            }
            return mapOf("state" to state, "progress" to progress)
        }
    }

    private fun canInstallPackages(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun installDownloadedApk(): String {
        if (downloadStatus()["state"] != "complete") error("The APK has not finished downloading")
        val build = preferences.getInt("build", -1)
        val file = downloadFile(build)
        if (!file.isFile || file.length() == 0L) error("The downloaded APK is missing")

        val archive = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageArchiveInfo(
                file.absolutePath,
                PackageManager.PackageInfoFlags.of(0)
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageArchiveInfo(file.absolutePath, 0)
        } ?: error("The downloaded file is not a valid APK")
        val archiveBuild = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            archive.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            archive.versionCode.toLong()
        }
        val installedBuild = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getPackageInfo(
                packageName,
                PackageManager.PackageInfoFlags.of(0)
            ).longVersionCode
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, 0).longVersionCode
        }
        require(archive.packageName == packageName && archiveBuild == build.toLong() &&
            archiveBuild > installedBuild) {
            "The APK package or build number does not match this app"
        }

        if (!canInstallPackages()) {
            val settings = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName")
            )
            startActivity(settings)
            return "settings"
        }

        val id = preferences.getLong("download_id", -1)
        val contentUri = manager.getUriForDownloadedFile(id)
            ?: error("Android could not open the downloaded APK")
        val install = Intent(Intent.ACTION_VIEW)
            .setDataAndType(contentUri, "application/vnd.android.package-archive")
        install.clipData = ClipData.newRawUri("Clinic System update", contentUri)
        install.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        startActivity(install)
        return "launched"
    }
}
