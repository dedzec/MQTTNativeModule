package com.mqttnativemodule

import com.facebook.react.TurboReactPackage
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.module.model.ReactModuleInfo
import com.facebook.react.module.model.ReactModuleInfoProvider

class MQTTPackage : TurboReactPackage() {

    override fun getModule(name: String, reactContext: ReactApplicationContext): NativeModule? {
        return if (name == MQTTModule.NAME) MQTTModule(reactContext) else null
    }

    override fun getReactModuleInfoProvider(): ReactModuleInfoProvider {
        return ReactModuleInfoProvider {
            mapOf(
                MQTTModule.NAME to ReactModuleInfo(
                    MQTTModule.NAME,
                    MQTTModule.NAME,
                    false,
                    false,
                    false,
                    true
                )
            )
        }
    }
}
