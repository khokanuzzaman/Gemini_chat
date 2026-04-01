import org.gradle.api.Project

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

subprojects {
    plugins.withId("com.android.library") {
        configureAndroidNamespace()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

fun Project.configureAndroidNamespace() {
    val androidExtension = extensions.findByName("android") ?: return
    val getNamespace = androidExtension.javaClass.methods.firstOrNull {
        it.name == "getNamespace" && it.parameterCount == 0
    }
    val setNamespace = androidExtension.javaClass.methods.firstOrNull {
        it.name == "setNamespace" && it.parameterCount == 1
    }
    val currentNamespace = getNamespace?.invoke(androidExtension) as? String

    if (currentNamespace.isNullOrBlank()) {
        setNamespace?.invoke(androidExtension, project.group.toString())
    }
}
