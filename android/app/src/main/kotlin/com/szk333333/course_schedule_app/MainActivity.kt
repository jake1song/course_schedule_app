package com.szk333333.course_schedule_app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private fun openUnknownAppSourceSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val intent = Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES).apply {
            data = Uri.parse("package:$packageName")
        }
        startActivity(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.szk333333.course_schedule_app/installer")
            .setMethodCallHandler { call, result ->
                if (call.method == "install") {
                    val path = call.argument<String>("path") ?: ""
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("NOT_FOUND", "APK file not found", null)
                        return@setMethodCallHandler
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                        !packageManager.canRequestPackageInstalls()
                    ) {
                        try {
                            openUnknownAppSourceSettings()
                        } catch (e: Exception) {
                            result.error(
                                "INSTALL_PERMISSION_REQUIRED",
                                e.message ?: "Please allow this app to install unknown apps",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        result.error(
                            "INSTALL_PERMISSION_REQUIRED",
                            "Please allow this app to install unknown apps, then tap download update again.",
                            null
                        )
                        return@setMethodCallHandler
                    }

                    val apkUri: Uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        FileProvider.getUriForFile(
                            this,
                            "${packageName}.fileprovider",
                            file
                        )
                    } else {
                        Uri.fromFile(file)
                    }

                    val intent = Intent(Intent.ACTION_VIEW).apply {
                        setDataAndType(apkUri, "application/vnd.android.package-archive")
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }

                    try {
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message ?: "Unknown error", null)
                    }
                } else {
                    result.notImplemented()
                }
            }
    }
}
