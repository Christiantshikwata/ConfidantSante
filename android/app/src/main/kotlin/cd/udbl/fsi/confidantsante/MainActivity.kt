
package cd.udbl.fsi.confidantsante

import android.content.ComponentName
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (et non FlutterActivity) est requis par local_auth
// pour afficher l'invite biométrique (empreinte / Face).
class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "cd.udbl.fsi.confidantsante/icon"

    // Liste de tous les alias définis dans AndroidManifest.xml
    private val TOUS_ALIASES = listOf(
        "cd.udbl.fsi.confidantsante.MainActivity",
        "cd.udbl.fsi.confidantsante.MainActivityCalculatrice",
        "cd.udbl.fsi.confidantsante.MainActivityMeteo",
        "cd.udbl.fsi.confidantsante.MainActivityNotes",
        "cd.udbl.fsi.confidantsante.MainActivityMinuteur"
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "changerIcone" -> {
                    val aliasTarget = call.argument<String>("alias")

                    if (aliasTarget == null) {
                        result.error("INVALID_ARGUMENT", "Alias manquant", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val packageManager = applicationContext.packageManager
                        val packageName = applicationContext.packageName

                        // Désactive tous les alias
                        for (alias in TOUS_ALIASES) {
                            val component = ComponentName(packageName, alias)
                            packageManager.setComponentEnabledSetting(
                                component,
                                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                                PackageManager.DONT_KILL_APP
                            )
                        }

                        // Active uniquement l'alias cible
                        val targetComponent = ComponentName(packageName, aliasTarget)
                        packageManager.setComponentEnabledSetting(
                            targetComponent,
                            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                            PackageManager.DONT_KILL_APP
                        )

                        result.success(true)

                    } catch (e: Exception) {
                        result.error(
                            "ICON_CHANGE_FAILED",
                            "Impossible de changer l'icône: ${e.message}",
                            null
                        )
                    }
                }

                "getAliasActif" -> {
                    try {
                        val packageManager = applicationContext.packageManager
                        val packageName = applicationContext.packageName
                        var aliasActif = "normal"

                        for (alias in TOUS_ALIASES) {
                            val component = ComponentName(packageName, alias)
                            val state = packageManager.getComponentEnabledSetting(component)
                            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) {
                                aliasActif = alias
                                break
                            }
                        }

                        result.success(aliasActif)
                    } catch (e: Exception) {
                        result.success("normal")
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}