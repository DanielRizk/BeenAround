package org.daniel.been_around

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.OutputStreamWriter

class MainActivity : FlutterActivity() {

    private val CHANNEL = "been_around/saf_save"
    private val REQ_CREATE_DOCUMENT = 9911

    private var pendingText: String? = null
    private var pendingMime: String? = null
    private var pendingSuggestedName: String? = null
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveTextFile" -> {
                        // Prevent parallel calls
                        if (pendingResult != null) {
                            result.success("Save already in progress.")
                            return@setMethodCallHandler
                        }

                        val suggestedName =
                            call.argument<String>("suggestedName") ?: "export.json"
                        val mimeType =
                            call.argument<String>("mimeType") ?: "application/json"
                        val text =
                            call.argument<String>("text") ?: ""

                        pendingText = text
                        pendingMime = mimeType
                        pendingSuggestedName = suggestedName
                        pendingResult = result

                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = mimeType
                            putExtra(Intent.EXTRA_TITLE, suggestedName)
                        }

                        // Classic Activity result flow (works with FlutterActivity)
                        startActivityForResult(intent, REQ_CREATE_DOCUMENT)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != REQ_CREATE_DOCUMENT) return

        val result = pendingResult
        val text = pendingText

        // Clear pending state no matter what
        pendingResult = null
        pendingText = null
        pendingMime = null
        pendingSuggestedName = null

        if (result == null) return

        if (resultCode != Activity.RESULT_OK) {
            result.success("Save canceled.")
            return
        }

        val uri: Uri? = data?.data
        if (uri == null || text == null) {
            result.success("Save failed: no URI returned.")
            return
        }

        try {
            contentResolver.openOutputStream(uri)?.use { os ->
                OutputStreamWriter(os, Charsets.UTF_8).use { writer ->
                    writer.write(text)
                }
            }
            result.success("Saved successfully.")
        } catch (e: Exception) {
            result.success("Save failed: ${e.message}")
        }
    }
}
