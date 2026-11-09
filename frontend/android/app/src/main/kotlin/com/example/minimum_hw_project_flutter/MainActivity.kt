package com.example.minimum_hw_project_flutter

import android.app.Activity
import android.content.Intent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingSave: MethodChannel.Result? = null
    private var pendingFile: File? = null
    private val saveRequest = 6166

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutbeat/files")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setRecordingActive" -> {
                        if (call.arguments == true) window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        else window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        result.success(null)
                    }
                    "saveFile" -> {
                        if (pendingSave != null) {
                            result.error("busy", "A save dialog is already open.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val path = call.argument<String>("path") ?: error("Missing file")
                            val file = File(path).canonicalFile
                            require(file.path.startsWith(cacheDir.canonicalPath + File.separator) && file.isFile)
                            val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                                addCategory(Intent.CATEGORY_OPENABLE)
                                type = call.argument<String>("mimeType") ?: "application/octet-stream"
                                putExtra(Intent.EXTRA_TITLE, call.argument<String>("name") ?: file.name)
                            }
                            pendingFile = file
                            pendingSave = result
                            startActivityForResult(intent, saveRequest)
                        } catch (e: Exception) {
                            pendingFile = null
                            pendingSave = null
                            result.error("save_failed", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Used for the Storage Access Framework result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != saveRequest) return
        val callback = pendingSave ?: return
        val source = pendingFile
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null || source == null) {
            pendingSave = null
            pendingFile = null
            callback.success(false)
            return
        }
        Thread {
            try {
                contentResolver.openOutputStream(uri, "w").use { output ->
                    checkNotNull(output) { "Cannot open the selected destination." }
                    source.inputStream().use { it.copyTo(output) }
                }
                runOnUiThread {
                    pendingSave = null
                    pendingFile = null
                    callback.success(true)
                }
            } catch (e: Exception) {
                runOnUiThread {
                    pendingSave = null
                    pendingFile = null
                    callback.error("save_failed", e.message, null)
                }
            }
        }.start()
    }
}
