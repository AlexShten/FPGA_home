# 2026-10-07T18:45:49.818498500
import vitis

client = vitis.create_client()
client.set_workspace(path="Home_6_MB")

client.delete_component(name="platform")

client.delete_component(name="componentName")

platform = client.create_platform_component(name = "platform",hw_design = "$COMPONENT_LOCATION/../../Home_6/design_1_wrapper.xsa",os = "standalone",cpu = "microblaze_0",domain_name = "standalone_microblaze_0",compiler = "gcc")

platform = client.get_component(name="platform")
status = platform.build()

status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.build()

comp.build()

vitis.dispose()

vitis.dispose()

