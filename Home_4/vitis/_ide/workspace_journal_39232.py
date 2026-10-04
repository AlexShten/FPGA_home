# 2026-10-03T22:53:28.695972900
import vitis

client = vitis.create_client()
client.set_workspace(path="Home_4_MB")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../Home_4/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

comp = client.create_app_component(name="app_component",platform = "$COMPONENT_LOCATION/../platform/export/platform/platform.xpfm",domain = "standalone_microblaze_0")

platform = client.get_component(name="platform")
status = platform.build()

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

vitis.dispose()

