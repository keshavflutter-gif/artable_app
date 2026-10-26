allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
//test
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

// image_cropper 9.1.0 hardcodes compileSdk 33. Its AndroidX dependencies
// require 34+, so the debug build fails in :image_cropper:checkDebugAarMetadata.
// Raise only that library module's compile SDK. App targetSdk and minSdk stay as they are.
subprojects {
    val subproject = this
    subproject.plugins.withId("com.android.library") {
        if (subproject.name != "image_cropper") {
            return@withId
        }
        val androidComponents =
            subproject.extensions.findByName("androidComponents") ?: return@withId
        val finalizeDsl = androidComponents.javaClass.methods.first { method ->
            method.name == "finalizeDsl" &&
                method.parameterCount == 1 &&
                method.parameterTypes[0].name == "org.gradle.api.Action"
        }
        val raiseCompileSdk = object : Action<Any> {
            override fun execute(extension: Any) {
                val current = extension.javaClass.methods
                    .firstOrNull { it.name == "getCompileSdk" && it.parameterCount == 0 }
                    ?.invoke(extension) as? Int
                if (current != null && current >= 34) {
                    return
                }
                extension.javaClass.methods
                    .first { it.name == "setCompileSdk" && it.parameterCount == 1 }
                    .invoke(extension, 36)
            }
        }
        finalizeDsl.invoke(androidComponents, raiseCompileSdk)
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
