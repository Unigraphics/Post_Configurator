#############################################################################################
#
#	Customer Data
#
#	Company         :
#	Address         :
#	Contact person  :
#	Phone           :
#	Fax             :
#	Mail            :
#
#############################################################################################
#
#	Copyright 2014-2020 Siemens Product Lifecycle Management Software Inc.
#				All Rights Reserved.
#	Copyright (c) 2012-2020 Siemens Industry Software GmbH & Co. KG
#
#	Die Quellcodes der Programme sind urheberrechtlich geschuetzt und
#	duerfen ohne Zustimmung von Siemens Industry Software GmbH & Co. KG weder kopiert noch
#	fuer andere Zwecke weiterverwendet werden.
#
#	The source of the programs is protected by Copyright.
#	You are not allowed to make any copies or modifications
#	without consent of Siemens Industry Software GmbH & Co. KG.
#
#	Le contenu de ces programmes sont protégés par copyright et ne
#	peuvent pas être copiés ou réutilisés sans l'agrément de Siemens Industry Software GmbH & Co. KG
#
#############################################################################################
#____________________________________________________________________________________________
#
# Procedure debugger
#____________________________________________________________________________________________
#

set lib_ge_debug(on) 0
set lib_ge_debug(proc_watch_list) "MOM* PPLIB* PROC*"
set lib_ge_debug(var_write_trace_list) "mom_group_name"
set lib_ge_debug(proc_watch_exclude_list) "MOM_SMART* MOM_evaluate_arg MOM_before_each_add_var MOM_before_load_address"
#____________________________________________________________________________________________
set lib_debug_source_of_proc_list 		""

if {![info exists lib_ge_platform]} {
	if {[string match "*windows*" $tcl_platform(platform)]} {
		set lib_ge_platform 1
		set lib_ge_slash "\\"
		if {[info exists env(TEMP)]} {
			set lib_ge_temppath $env(TEMP)
		} elseif {[info exists env(TMP)]} {
			set lib_ge_temppath $env(TMP)
		}
	} else {
		set lib_ge_platform 0
		set lib_ge_slash "/"
		if {[info exists env(TMPDIR)]} {
			set lib_ge_temppath $env(TMPDIR)
		}
		if {![string length $lib_ge_temppath]} {
			set lib_ge_temppath "${lib_ge_slash}var${lib_ge_slash}tmp"
		}
	}
}
if {![info exists lib_ge_env(tmp_dir)]} {
	set lib_ge_env(tmp_dir)		[MOM_ask_env_var "UGII_TMP_DIR"]
}
if {![string length $lib_ge_env(tmp_dir)]} {
	set lib_ge_env(tmp_dir) $lib_ge_temppath
}

#____________________________________________________________________________________________
# <Documentation>
#
# Handling for the default environment variables
#
# <Example>
#
#____________________________________________________________________________________________
proc LIB_Shell_environment_handling {} {

	eval global [uplevel #0 info vars]

	# Language file and OS specific values
	if {![info exists lib_ge_slash]} {global lib_ge_slash}
	if {![info exists lib_ge_env]} {global lib_ge_env}

	set lib_ge_env(post_pool_dir) 		[LIB_Shell_format_path_names [MOM_ask_env_var "UGII_POST_POOL_DIR_NG"]]
	set lib_ge_env(cam_post_dir) 		[LIB_Shell_format_path_names [MOM_ask_env_var "UGII_CAM_POST_DIR"]]
	set lib_ge_env(tmp_dir)                 [LIB_Shell_format_path_names [MOM_ask_env_var "UGII_TMP_DIR"]]
	if {$lib_ge_env(tmp_dir) == ""} {set lib_ge_env(tmp_dir) $lib_ge_temppath}

	global lib_ge_installed_machines
	set lib_ge_installed_machines		[info script]
	set lib_ge_env(installed_machines_dir) 	[LIB_Shell_format_path_names [file dirname $lib_ge_installed_machines]]

	set lib_ge_env(installed_machines_dir,recursively) ""
	lappend lib_ge_env(installed_machines_dir,recursively) $lib_ge_env(installed_machines_dir)

	set current_dir [pwd]
	if {![catch {cd [lindex $lib_ge_env(installed_machines_dir,recursively) 0]}]} {
		if {![catch {set dir [string tolower [glob *]]}]} {
			foreach e {libraries controller bin} {
				set index [lsearch -exact $dir $e]
				if {$index > -1} {
					set directory [lindex $dir $index]
					set directory [string toupper [string index $directory 0]][string range $directory 1 end]
					lappend lib_ge_env(installed_machines_dir,recursively) [LIB_Shell_format_path_names "[lindex $lib_ge_env(installed_machines_dir,recursively) 0]$lib_ge_slash$directory"]
			        }
			}
		}
	}
	cd $current_dir

	if {![regexp -nocase -- {\w+} $lib_ge_env(post_pool_dir)]} {set lib_ge_env(post_pool_dir) $lib_ge_env(installed_machines_dir)}

	set lib_ge_env(version_bit)  		[MOM_ask_env_var "UGII_VERSION_BIT"]
	set lib_ge_env(base_dir)     		[MOM_ask_env_var "UGII_BASE_DIR"]

	set lib_ge_env(major_version)  		[MOM_ask_env_var "UGII_MAJOR_VERSION"]
	set lib_ge_env(minor_version)     	[MOM_ask_env_var "UGII_MINOR_VERSION"]
	set lib_ge_env(subminor_version)     	[MOM_ask_env_var "UGII_SUBMINOR_VERSION"]

	if {![info exists lib_ge_dll_version]} {global lib_ge_dll_version}
	if {$lib_ge_env(minor_version) > 0} {
		set lib_ge_dll_version "nx$lib_ge_env(major_version)$lib_ge_env(minor_version)"
	} else {
		set lib_ge_dll_version "nx$lib_ge_env(major_version)"
	}

	regsub -all "/" $lib_ge_env(base_dir) "\\" lib_ge_env(base_dir)

}

#____________________________________________________________________________________________
# <Internal Documentation>
#
# This procedure may be used to format pathnames from unix format in windows
# format and delete double backslash
#
# Output:
# D:\Temp\mom\debug.out or \\Server\Temp\mom\debug.out
#
# e.g.
# set error [LIB_Shell_format_path_names "D:/Temp/mom/debug.out"]
#
# <Example>
# set error [LIB_Shell_format_path_names "D:/Temp/mom/debug.out"]
#____________________________________________________________________________________________
proc LIB_Shell_format_path_names {pathname} {

	global lib_ge lib_ge_platform

	binary scan $pathname H* pathbin
	if {[info exists lib_ge(format_path,$pathbin,0,0,0)]} {
		return $lib_ge(format_path,$pathbin,0,0,0)
	}

	if {[regexp -nocase -- {^[\\\\]|^[\/\/]} $pathname]} {
		regsub -all "/" $pathname "\\" pathname
	}

	if {$lib_ge_platform} {
		regsub -all "/" $pathname "\\" pathname
		if {![regexp -nocase -- {^\\\\} $pathname]} {set unc 0} else {set unc 1}
			 while {[regsub -- "(?q)\\\\" $pathname "\\" pathname]} {}
		if {$unc} {set pathname "\\$pathname"}
	} elseif {!$lib_ge_platform} {
		regsub -all "\\\\" $pathname "/" pathname
		if {![regexp -nocase -- {^//} $pathname]} {set unc 0} else {set unc 1}
		while {[regsub -- "(?q)//" $pathname "/" pathname]} {}
		if {$unc} {set pathname "/$pathname"}
	}

	set lib_ge(format_path,$pathbin,0,0,0) [string trim $pathname]
	return $lib_ge(format_path,$pathbin,0,0,0)

}

#____________________________________________________________________________________________
# <Documentation>
#
# Handling for the main shell
#
# <Example>
#
#____________________________________________________________________________________________
proc LIB_Shell_main {} {

	global lib_ge_env lib_ge_slash
	global lib_cycle_path sourcefile

	LIB_Shell_environment_handling

	lappend ::lib_ge_monitored_files [LIB_Shell_format_path_names [info script]]

	if {[info commands LIB_GE_source] != "LIB_GE_source"} {
		set lib_cycle_path 0
		set searchpath $lib_ge_env(installed_machines_dir,recursively)
		lappend searchpath $lib_ge_env(post_pool_dir)
		foreach path $searchpath {
			if {$lib_cycle_path} {break}
			foreach ext {.tcl .tbc} {
				set sourcefile [LIB_Shell_format_path_names "$path${lib_ge_slash}lib_sourcing$ext"]
				if {[file exists $sourcefile]} {
					if {[string match ".tbc" $ext]} {
						MOM_output_to_listing_device "ByteCode Loader is not available, cannot process lib_sourcing$ext (Provid this file not encrypted)"
						MOM_log_message "ByteCode Loader is not available, cannot process lib_sourcing$ext (Provid this file not encrypted)"
						MOM_abort "ByteCode Loader is not available, cannot process lib_sourcing$ext (Provid this file not encrypted)"
					}
					uplevel #0 {

						if {$::tcl_version >= 8.6} {
							if {[catch {source -encoding utf-8 $sourcefile} err]} {
								set lib_source_error 1
							}
						} else {
							if {[catch {source $sourcefile} err]} {
								set lib_source_error 1
							}
						}

						if {[info exists lib_source_error] && $lib_source_error == 1} {
							if {[info exists ::errorInfo]} {MOM_output_to_listing_device "errorInfo $errorInfo"}
							MOM_output_to_listing_device "File lib_sourcing $err not loadable"
							MOM_log_message "File lib_sourcing $err not loadable"
							MOM_abort "File lib_sourcing not loadable"
						} else {
							set lib_ge_debug(lib_sourcing) "$sourcefile"
							lappend lib_ge_monitored_files "$sourcefile"
							lappend lib_ge_log_message "\n--> $sourcefile loaded"
							set lib_cycle_path 1 ; break
						}

					}
				}
			}
		}
		if {!$lib_cycle_path} {
			MOM_output_to_listing_device "File lib_sourcing not found"
			MOM_log_message "File lib_sourcing not found"
			MOM_abort "File lib_sourcing not found"
		}
	}

	LIB_Shell_init

}

#____________________________________________________________________________________________
# <Documentation>
#
# Handling for the default environment variables
#
# <Example>
#
#____________________________________________________________________________________________
proc LIB_Shell_defined_post_environment {} {

	global lib_pp_source_file lib_shell

	#____________________________________________________________________________________________
	#
	# NX Post, load files
	#____________________________________________________________________________________________
	#

	# There are different ways to source each files
	#
	# e.g. Befor LIB_GE_source call
	# lappend lib_pp_source_file "machine,UGII_CAM_POST_DIR"
	#
	# e.g. After LIB_GE_source call
	# LIB_GE_source "Test" "C:/Temp/;d:/tmp/"
	#
	# e.g. To define a searchpath
	# LIB_GE_source "" "C:/Temp/;UGII_CAM_POST_DIR"
	# Allowed is the direct path and/or variable

	# This is the call for PB post files
	# ** internal funktion / Don't remove this line **
	set lib_pp_source_file ""

	# This is the call the PB post LIB_GE files
	# ** internal funktion / Don't remove this line **
	lappend lib_pp_source_file "lib_msg" "lib_file_handling" "lib_standard_post_func" "lib_document"

	# If a XML-file with the same file name found, the referenced files will also loaded
	LIB_Shell_external_source

	if {![info exists lib_shell(load_loader)] || $lib_shell(load_loader)} {
		lappend lib_pp_source_file "[file tail [file rootname $::lib_ge_installed_machines]]_custom"
	} else {
		MOM_log_message "Custom level isn't loaded"
	}


	#############################################################################################

}

LIB_Shell_main

#############################################################################################



#############################################################################################

#############################################################################################
# This is to debug
#############################################################################################
if {[llength [info commands LIB_GE_debug]]} {LIB_GE_debug}
