allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// firebase_auth (et ses dépendances androidx) exigent compileSdk >= 34. Selon
// la version de Flutter, le compileSdk de l'app ne se propage PAS aux modules
// plugins (qui restent en android-33) → échec checkDebugAarMetadata. On force
// donc compileSdk 34 sur les sous-projets plugins. On exclut ":app" : il définit
// déjà compileSdk 34 et est déjà évalué ici (evaluationDependsOn ci-dessus),
// donc y appeler afterEvaluate lèverait « project is already evaluated ».
subprojects {
    if (project.name != "app") {
        afterEvaluate {
            extensions.findByType(com.android.build.gradle.BaseExtension::class.java)
                ?.apply {
                    compileSdkVersion(34)
                }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

