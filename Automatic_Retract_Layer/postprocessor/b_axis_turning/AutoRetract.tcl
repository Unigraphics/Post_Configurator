#############################################################################################
#
#	Auto Retract Layer
#
#############################################################################################
#
#	Copyright 2020 Siemens Digital Industries Software
#				All Rights Reserved.
#
#############################################################################################
# Description
# This automatic rectract layer enables to perform automatically a retract, tool change,
# and re-engage sequence when the maximum cutting time of a tool is reached. Import the layer
# in an existing post processor by the Layer Import option from Post Configurator.
# This layer only works for NX1899 and later versions.
#############################################################################################
# History
# 13 July 2020   XY   Initial version
##############################################################################################
#
#
#____________________________________________________________________________________________
# Content
#
# 1.  Modified Buffers/ Buffer extensions
# 2.  Global variable definitions
# 3.  Advanced Turbo mode procedures
# 4.  Event handler procedures
# 5.  Additional UI groups definition for auto retract
# 6.  Additional UI properties definition for auto retract
# 
#____________________________________________________________________________________________
#

#____________________________________________________________________________________________
# <Documentation>
# 1.
# Modified Buffers/ Buffer extensions
#
# <Example>
#
#____________________________________________________________________________________________
LIB_GE_command_buffer_edit_append MOM_start_of_program_LIB MOM_start_of_program_LIB_ENTRY_start InitAutoRetract _InitAutoRetractParameters
LIB_GE_command_buffer_edit_append MOM_start_of_program_LIB MOM_start_of_program_LIB_ENTRY_start ActivateAdvancedCallbacks _ActivateAdditionalTurboModeOptions


#____________________________________________________________________________________________
# <Documentation>
# 2.
# Global variable definitions
#
# <Example>
#
#____________________________________________________________________________________________
lappend ::mom_sys_turbo_global_add_vars_list mom_motion_distance
CONF_CTRL_setting set turbo_mode 3


#____________________________________________________________________________________________
# <Documentation>
# 3.
# Advanced Turbo mode procedures
#
# <Example>
#
#____________________________________________________________________________________________

#------------------------------------------------------------
proc ActivateAdvancedCallbacks {} {
#------------------------------------------------------------
    MOM_set_adv_turbo_callback {$mom_motion_distance>0} AutoRetract
    LIB_GE_command_buffer_edit_prepend MOM_before_motion MOM_before_motion_ENTRY_start AutoRetract _AutoRetract
}

#____________________________________________________________________________________________
# <Documentation>
# 4.
# Event handler procedure
#
# <Example>
#
#___________________________________________________________________________________________
proc AutoRetract {} {

	global lib_flag
    global mom_event_number
	global mom_event_time
    global mom_motion_type
    global mom_sys_current_cutting_time
    global mom_sys_max_cut_time_per_tool
    global mom_sys_min_cut_time_per_tool
    global mom_sys_cut_motion_types
    global mom_sys_tool_change_motion_types

    if {![info exists lib_flag(event_number_for_tool_change)]} {
        set lib_flag(event_number_for_tool_change) -1
    }

	if {$lib_flag(event_number_for_tool_change) != $mom_event_number} {
		if {![info exists mom_sys_current_cutting_time]} {set mom_sys_current_cutting_time 0.0}

		set ix [lsearch -exact $mom_sys_cut_motion_types $mom_motion_type]

		if {$ix > -1} {
			set mom_sys_current_cutting_time [expr $mom_sys_current_cutting_time  + $mom_event_time]
		}

		set ix [lsearch -exact $mom_sys_tool_change_motion_types $mom_motion_type]

		if { $mom_sys_max_cut_time_per_tool < $mom_sys_current_cutting_time || \
			($ix < 0 && $mom_sys_min_cut_time_per_tool < $mom_sys_current_cutting_time)} {
			
			RetractHandler

			set lib_flag(event_number_for_tool_change) $mom_event_number
		}
	}

}

proc RetractHandler {} {
    global mom_sys_current_cutting_time
    global mom_kin_4th_axis_type
    global mom_sys_automatic_retract_distance
    global mom_sys_automatic_reengage_distance
    global mom_sys_automatic_reengage_feedrate
    global mom_pos
    global mom_prev_pos
    global mom_prev_tool_axis
    global mom_motion_event
    global feed
    global mom_tool_number
    global mom_sys_tool_number
    global mom_sys_next_tool_number 

    set mom_sys_current_cutting_time 0.0

    if {[info exists mom_kin_4th_axis_type] && ![string compare "Table" $mom_kin_4th_axis_type] } {
        set vec(0) 0.0
        set vec(1) 0.0
        set vec(2) 1.0
    } else {
        set vec(0) $mom_prev_tool_axis(0)
        set vec(1) $mom_prev_tool_axis(1)
        set vec(2) $mom_prev_tool_axis(2)
    }

    for {set i 0} {$i < 3} {incr i} {
        set sav_pos($i) $mom_pos($i)
        set mom_pos($i) [expr $mom_prev_pos($i) + $mom_sys_automatic_retract_distance*$vec($i)]
    }

    MOM_force once Z
    MOM_rapid_move

    if {![info exists mom_sys_next_tool_number]} {set mom_sys_next_tool_number 0}

    set mom_tool_number [lindex $mom_sys_tool_number $mom_sys_next_tool_number]
    MOM_tool_change
    incr mom_sys_next_tool_number

    if {$mom_sys_next_tool_number >= [llength $mom_sys_tool_number]} {
        set mom_sys_next_tool_number 0
    }

    #
    # The following commands will force out all active data.  Add or remove 
    # words that are not applicable
    #
    # coordinate data
    MOM_force once X Y Z 

    # g code
    MOM_force once G_motion 

    # feedrate 
    MOM_force once F 

    # spindle and coolant
    MOM_force once S M_spindle M_coolant

    set save_event $mom_motion_event
    set mom_motion_event "first_move"
    MOM_rapid_move
    set mom_motion_event $save_event

    for {set i 0} {$i < 3} {incr i} {
        set mom_pos($i) [expr $mom_prev_pos($i) + $mom_sys_automatic_reengage_distance*$mom_prev_tool_axis($i)]
    }
    MOM_rapid_move

    for {set i 0} {$i < 3} {incr i} {
        set mom_pos($i) $mom_prev_pos($i)
    }

    set save_feed $feed
    set feed $mom_sys_automatic_reengage_feedrate
    MOM_linear_move

    set feed $save_feed

    for {set i 0} {$i < 3} {incr i} {
        set mom_pos($i) $sav_pos($i)
    }
}

#=============================================================
proc InitAutoRetract { } {
#=============================================================
#
#  This command initializes the parameters for an automatic
#  tape break sequence.
#
#
#  Imported this command to the post as needed. It will
#  be executed automatically at the start of program and anytime
#  when the post is loaded as a slave post of a linked post.
#
#
   global mom_sys_automatic_retract_distance
   global mom_sys_automatic_reengage_distance
   global mom_sys_automatic_reengage_feedrate
   global mom_sys_max_cut_time_per_tool
   global mom_sys_min_cut_time_per_tool
   global mom_sys_cut_motion_types
   global mom_sys_tool_number 
   global mom_sys_tool_change_motion_types

  #
  # These variables are used to control the cutting time per tool.  A tool 
  # change will occur after the minimum and before the maximum cutting time.  
  # If a suitable move type occurs in the tool path after 
  # the minimum but before the maximum time a retract and tool change 
  # will take place before that motion.  If no suitable move type is 
  # encountered after the minimum and before the maximum, a retract and 
  # tool change will occur immediately regardless of the motion type.
  #
   set mom_sys_max_cut_time_per_tool [Auto_retract_parameter_object Auto_retract_max_cut_time_per_tool ]
   set mom_sys_min_cut_time_per_tool [Auto_retract_parameter_object Auto_retract_min_cut_time_per_tool ]

  #
  # This variable is used to control the delta move along the tool axis when 
  # breaking the tape.
  #
   set mom_sys_automatic_retract_distance [Auto_retract_parameter_object Auto_retract_retract_distance ]

  #
  # This variable is used to define how close the reengage distance gets to 
  # the previous point.
  #
   set mom_sys_automatic_reengage_distance [Auto_retract_parameter_object Auto_retract_reengage_distance ]

  #
  # This variable defines the feedrate used to reengage to the previous point.
  # It is assumed to be in IPM or MMPM.
  #
   set mom_sys_automatic_reengage_feedrate [Auto_retract_parameter_object Auto_retract_reengage_feedrate ]

  #
  # This list controls the tool numbers that will be used for the replacement 
  # tools.  This list may be as short or long as you need it.  If you only want
  # to load tool 1 every time then you could use {1}.
  #
   set mom_sys_tool_number [Auto_retract_parameter_object Auto_retract_tool_number ]

  #
  # This list contains the cut types that will be used to increment the cutting 
  # time.
  #
   set mom_sys_cut_motion_types [Auto_retract_parameter_object Auto_retract_cut_motion_types]
  #
  # This list contains the cut types that will NOT be used for automatic retract
  # and tool change.  If you know that your stepovers will be off the part, you
  # may want to remove STEPOVER from this list.
  #
   set mom_sys_tool_change_motion_types [Auto_retract_parameter_object Auto_retract_tool_change_motion_types]
}

#____________________________________________________________________________________________
# <Documentation>
# 5.
# Additional UI groups definition for auto retract
#
# <Example>
#
#___________________________________________________________________________________________
LIB_GE_CREATE_obj Auto_retract {UI_TREE} {
    LIB_GE_property_ui_name        "UIName"
    LIB_GE_property_ui_tooltip     "UITooltip"

set id "Auto_retract_root"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Automatic Retract}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "root"
    set ui_sequence($id)    -1

set id "Auto_retract_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Automatic Retract Parameters Init}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "Auto_retract_root"
    set ui_sequence($id)    -1

set id "Auto_retract_param_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Retract Parameters}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "Auto_retract_node"
    set ui_sequence($id)    -1
}
#____________________________________________________________________________________________
# <Documentation>
# 6.
# Additional UI properties definition for auto retract
#
# <Example>
#
#____________________________________________________________________________________________
LIB_GE_CREATE_obj Auto_retract_parameter_object {} {
    LIB_GE_property_ui_name        "Name"
    LIB_GE_property_ui_tooltip     "Tooltip"

set id "Auto_retract_retract_distance"
    set $id 10.0
    set options($id)        {*VALUE*}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "DOUBLE"
    set access($id)         222
    set dialog($id)         {{Retract Distance}}
    set descr($id)          {{Defined distance for retraction.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1

set id "Auto_retract_reengage_distance"
    set $id 0.1
    set options($id)        {*VALUE*}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "DOUBLE"
    set access($id)         222
    set dialog($id)         {{Reengage Distance}}
    set descr($id)          {{Defined distance for reengagement.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1

set id "Auto_retract_reengage_feedrate"
    set $id 10.0
    set options($id)        {*VALUE*}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "DOUBLE"
    set access($id)         222
    set dialog($id)         {{Reengage Feedrate}}
    set descr($id)          {{Defined feedrate for reengagement }}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1

set id "Auto_retract_max_cut_time_per_tool"
    set $id 60.0
    set options($id)        {*VALUE*}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "DOUBLE"
    set access($id)         222
    set dialog($id)         {{Max Cut Time Per Tool}}
    set descr($id)          {{Defined maximum duration time for a tool in cutting.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1

set id "Auto_retract_min_cut_time_per_tool"
    set $id 30.0
    set options($id)        {*VALUE*}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "DOUBLE"
    set access($id)         222
    set dialog($id)         {{Min Cut Time Per Tool}}
    set descr($id)          {{Defined minimum duration time for a tool in cutting.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1
    
set id "Auto_retract_tool_number"
    set $id "1 2 3 4 5 6"
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Tool Number}}
    set descr($id)          {{Defined available tool numbers for tool change during automatic retract.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1
    
set id "Auto_retract_cut_motion_types"
    set $id "CUT FIRSTCUT STEPOVER CYCLE"
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Cut Motion Types}}
    set descr($id)          {{Defined cut types that will be used to increment the cutting time.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1
    
set id "Auto_retract_tool_change_motion_types"
    set $id "CUT FIRSTCUT STEPOVER CYCLE"
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Undesired Tool Change Motion Types}}
    set descr($id)          {{Defined cut types that will NOT be used for automatic retract and tool change. If you know that your stepovers will be off the part, you may want to remove STEPOVER from this list.}}
    set ui_parent($id)      "Auto_retract_param_group"
    set ui_sequence($id)    -1

}
