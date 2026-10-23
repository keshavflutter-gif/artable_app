package com.artable

import android.content.ClipData
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.artable/whatsapp_share"

    private fun getInstalledWhatsAppPackage(): String? {
        val candidates = listOf("com.whatsapp", "com.whatsapp.w4b")
        for (pkg in candidates) {
            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                type = "video/*"
                setPackage(pkg)
            }
            if (packageManager.queryIntentActivities(sendIntent, 0).isNotEmpty()) {
                return pkg
            }
            try {
                packageManager.getPackageInfo(pkg, 0)
                return pkg
            } catch (_: Exception) {}
        }
        return null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "shareVideoToWhatsApp") {
                val filePath = call.argument<String>("filePath")
                val text = call.argument<String>("text")
                if (filePath.isNullOrBlank()) {
                    result.error("INVALID_PATH", "File path is null or empty", null)
                    return@setMethodCallHandler
                }
                val file = File(filePath)
                if (!file.exists() || file.length() <= 0) {
                    result.error("FILE_NOT_FOUND", "File does not exist or is empty: $filePath", null)
                    return@setMethodCallHandler
                }

                try {
                    file.setReadable(true, false)

                    val uri: Uri = FileProvider.getUriForFile(
                        this,
                        "${applicationContext.packageName}.artable_provider",
                        file
                    )

                    val mimeType = when {
                        file.name.endsWith(".mov", true) -> "video/quicktime"
                        file.name.endsWith(".webm", true) -> "video/webm"
                        file.name.endsWith(".3gp", true) -> "video/3gpp"
                        else -> "video/mp4"
                    }

                    val targetPkg = getInstalledWhatsAppPackage()

                    if (targetPkg != null) {
                        try {
                            grantUriPermission(
                                targetPkg,
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                        } catch (e: Exception) {
                            android.util.Log.w("ArtableShare", "grantUriPermission warning: ${e.message}")
                        }
                    }

                    // Strictly NO URLs in video caption for WhatsApp
                    val cleanCaption = text?.trim()?.let {
                        if (it.contains("http://") || it.contains("https://") || it.contains("artable.app") || it.contains(".r2.dev")) {
                            null
                        } else {
                            it
                        }
                    }

                    val sendIntent = Intent(Intent.ACTION_SEND).apply {
                        type = mimeType
                        putExtra(Intent.EXTRA_STREAM, uri)
                        clipData = ClipData.newUri(contentResolver, "Video", uri)
                        if (!cleanCaption.isNullOrBlank()) {
                            putExtra(Intent.EXTRA_TEXT, cleanCaption)
                        }
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        if (targetPkg != null) {
                            setPackage(targetPkg)
                        }
                    }

                    var launched = false
                    try {
                        startActivity(sendIntent)
                        launched = true
                        android.util.Log.i("ArtableShare", "Directly launched WhatsApp ($targetPkg) with video: ${file.name}")
                    } catch (e: Exception) {
                        android.util.Log.w("ArtableShare", "Failed direct WhatsApp launch: ${e.message}")
                        // Fallback: system chooser with video file
                        try {
                            val chooserIntent = Intent(Intent.ACTION_SEND).apply {
                                type = mimeType
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = ClipData.newUri(contentResolver, "Video", uri)
                                if (!cleanCaption.isNullOrBlank()) {
                                    putExtra(Intent.EXTRA_TEXT, cleanCaption)
                                }
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            val chooser = Intent.createChooser(chooserIntent, "Share Video")
                            startActivity(chooser)
                            launched = true
                            android.util.Log.i("ArtableShare", "Launched system chooser fallback with video file")
                        } catch (ex: Exception) {
                            android.util.Log.e("ArtableShare", "Fallback chooser error: ${ex.message}", ex)
                        }
                    }

                    result.success(launched)
                } catch (e: Exception) {
                    android.util.Log.e("ArtableShare", "Error preparing video share: ${e.message}", e)
                    result.error("SHARE_ERROR", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
