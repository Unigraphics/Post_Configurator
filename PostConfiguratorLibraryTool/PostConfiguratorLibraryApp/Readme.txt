#############################################################################################
#
#	Copyright 2014-2020 Siemens Digital Industries Software
#				All Rights Reserved.
#
#############################################################################################
System Requirements:
- Windows based platform (Win10 recommended)
- NX1926 installation
- Post Configurator Full License (NX31440)

The application can only be started within NX as a NXOpen application.
To start in NX:
1) Open NX
2) press Ctrl+U
3) select the PostConfiguratorSourceTool.exe to start

It's also possible to add the application to hte ribbon bar. 
You can use the PCLST_icon.bmp as the standard icon.

The application contains the unencrypted commands from the Post Configurator Libraries. Be aware that those should be used only 
for taking a look into the source code. Copying the commands in your layer will work but can break
the update mechanism on a later point, e.g. Siemens update the library command and you already copy it
and changed in one of your layers. Post processors can be stop working then.

We recommend to keep them in a separate layer and checking those after an update if needed.
