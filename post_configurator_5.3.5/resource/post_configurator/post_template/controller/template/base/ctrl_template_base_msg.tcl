lappend lib_config_data		[list "ctrl_template_base_msg" "Ctrl_Template_Base-MSG-Version 022"]
#############################################################################################
#
#	Copyright 2014-2020 Siemens Product Lifecycle Management Software Inc.
#				All Rights Reserved.
#
#############################################################################################
#
#       Last changes:	09.02.2019 - TJ  001 Initial Release and Installation
#			16.03.2019 - UR  002 Releaseversion 4.6.3
#			28.03.2019 - COE 003 Releaseversion 4.7
#			11.04.2019 - UR  004 Releaseversion 4.7.1
#			18.04.2019 - UR  005 Releaseversion 4.7.2
#			07.05.2019 - UR  006 Releaseversion 5.0
#			08.07.2019 - UR  007 Releaseversion 5.0.1
#			31.07.2019 - UR  008 Releaseversion 5.0.2
#			16.08.2019 - COE 009 Releaseversion 5.0.3
#			21.08.2019 - COE 010 Releaseversion 5.1.0
#			20.09.2019 - COE 011 Releaseversion 5.2.0
#			06.11.2019 - UR  012 Releaseversion 5.2.3
#			27.12.2019 - UR  013 Releaseversion 5.2.4
#			31.01.2020 - COE 014 Releaseversion 5.2.5
#			02.03.2020 - UR  015 Releaseversion 5.2.6
#			19.03.2020 - COE 016 Releaseversion 5.2.7
#			25.03.2020 - COE 017 Releaseversion 5.3.0
#			01.07.2020 - COE 018 Releaseversion 5.3.1
#			09.07.2020 - COE 019 Releaseversion 5.3.2
#			06.09.2020 - COE 020 Releaseversion 5.3.3
#			15.09.2020 - COE 021 Releaseversion 5.3.4
#			26.09.2020 - COE 022 Releaseversion 5.3.5
#
#
#
####G#E#N#E#R#A#L##D#E#S#C#R#I#P#T#I#O#N#####################################################
#
# In this function, the text in the appropriate language UGII_LANG is translated.
# Optional wildcards can be used in the example.
#
# Permitted languages:  braz_portuguese / french / german / italian / japanese /
#			korean / russian / simpl_chinese / spanish / trad_chinese...
#
# e.g.
# set message [LIB_GE_MSG "Configuration file does not exist"]
# set message [LIB_GE_MSG "File can not be copied from INS->xxx<- to INS->zzz<-"]
# set message [LIB_GE_MSG "File INS->C:\\Temp\\xxx.txt<- not found"]
#
# set message [LIB_GE_MSG "SURFACE COORDINATE" "core"]
#
# (It's for development only)
# set message [LIB_GE_MSG 0001] <-- Please, don't work with this solution
#
#############################################################################################

##############################################################################################
###  controller/machine/customer... translations
###  between the commas the text is selectable e.g. 0000,$lib_controller_message,xxx,english
##############################################################################################
set lib_msg(0000,$lib_controller_message,core)          "Please contact Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,czech)         "Kontaktujte společnost Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,danish)        "Kontakt Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,dutch)         "Neem contact op met Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,english)       "Please contact Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,finnish)       "Ota yhteyttä Siemens PLM -ohjelmistoon"
set lib_msg(0000,$lib_controller_message,french)        "S'il vous plaît contactez Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,german)        "Bitte Siemens PLM Software kontaktieren"
set lib_msg(0000,$lib_controller_message,hungarian)     "Kérjük, lépjen kapcsolatba a Siemens PLM szoftverrel"
set lib_msg(0000,$lib_controller_message,italian)       "Contattare Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,japanese)      "お問い合わせください Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,korean)        "문의하시기 바랍니다 Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,norwegian)     "Ta kontakt med Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,polish)        "Prosze o kontakt Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,portuguese)    "Entre em contato com a Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,russian)       "пожалуйста свяжитесь Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,simpl_chinese) "请联系 Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,slovak)        "Obráťte sa na spoločnosť Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,slovenian)     "Prosimo, pokličite programsko opremo Siemens PLM"
set lib_msg(0000,$lib_controller_message,spanish)       "Por favor, póngase en contacto con Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,swedish)       "Vänligen kontakta Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,trad_chinese)  "請聯繫 Siemens PLM Software"
set lib_msg(0000,$lib_controller_message,turkish)       "Lütfen Siemens PLM Yazılımına başvurun."

if {$tcl_version < 8.4} {
	array set lib_msg [LIB_GE_replace_special_characters [array get lib_msg] 4 0]
}
