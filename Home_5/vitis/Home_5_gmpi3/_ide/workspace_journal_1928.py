# 2026-09-30T22:57:28.210691200
import vitis

client = vitis.create_client()
client.set_workspace(path="Home_5_gmpi3")

platform = client.get_component(name="platform")
status = platform.build()

comp = client.get_component(name="app_component")
comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

status = platform.build()

comp.build()

vitis.dispose()

vitis.dispose()

