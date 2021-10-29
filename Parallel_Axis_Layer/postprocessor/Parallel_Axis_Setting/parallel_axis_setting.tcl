#############################################################################################
#
#	Parallel Axis Setting Layer
#
#############################################################################################
#
#	Copyright 2020 Siemens Digital Industries Software
#				All Rights Reserved.
#
#############################################################################################
# Description
# Parallel axis output in operation for reuse controller independent. To reuse import the layer in
# an existing post processor by the Layer Import option from Post Configurator.
#############################################################################################
# DATE         NAME                  DESCRIPTION OF CHANGE
# ----         ----                  ---------------------
# 15-Jun-2020  HZ                    Initial version
# $HISTORY$ 
#############################################################################################


LIB_GE_command_buffer_edit_append MOM_start_of_path_LIB MOM_start_of_path_LIB_ENTRY_start {parallel_axis_turbo_set} _ParallelAxisTurbo

LIB_GE_command_buffer_edit_prepend MOM_before_motion MOM_before_motion_ENTRY_end {parallel_axis_before_motion} _ParallelAxisBeforeMotion

LIB_GE_command_buffer_edit_prepend MOM_initial_move_LIB MOM_initial_move_LIB_ENTRY_start {parallel_axis_initial_motion} _ParallelAxisInitialMotion

LIB_GE_command_buffer_edit_prepend MOM_first_move_LIB MOM_first_move_LIB_ENTRY_start {parallel_axis_initial_motion} _ParallelAxisFirstMotion


#------------------------------------------------------------
proc MOM_set_parallel_axis { } {
#------------------------------------------------------------

	global mom_parallel_axis_mode mom_sys_leader drive_axis
	
	set parallel_axis_names [split $mom_parallel_axis_mode "-"]
	
	# Quill axis
	set mom_sys_leader(QUILL) [lindex $parallel_axis_names 0]
	# Drive axis
	set drive_axis_leader [lindex $parallel_axis_names 1]
	
	MOM_do_template quill_axis_move
	
	switch -- $mom_parallel_axis_mode {
		"W-Z" - 
		"Z-W" {
			set mom_sys_leader(Z) $drive_axis_leader
			set drive_axis 2
		}
		"V-Y" -
		"Y-V" {
			set mom_sys_leader(Y) $drive_axis_leader
			set drive_axis 1
		}
		"U-X" - 
		"X-U" {
			set mom_sys_leader(X) $drive_axis_leader
			set drive_axis 0
		}
	}
}

#------------------------------------------------------------
proc parallel_axis_turbo_set { } {
#------------------------------------------------------------

	global mom_kin_is_turbo_output mom_motion_event 
	
	# Parallel axis could only work in turbo off or advanced turbo mode
	if {[LIB_SPF_get_pretreatment mom_kin_is_turbo_output] == "TRUE"} {
		if {[CONF_CTRL_setting turbo_mode] == 1 || [CONF_CTRL_setting turbo_mode] == 2} {
			LIB_SPF_turbo_status "enable" "advanced"
		}

		MOM_set_adv_turbo_callback {$mom_motion_event == "rapid_move"   } parallel_axis_before_motion
		MOM_set_adv_turbo_callback {$mom_motion_event == "linear_move"  } parallel_axis_before_motion
		MOM_set_adv_turbo_callback {$mom_motion_event == "circular_move"} parallel_axis_before_motion
	}
}

#------------------------------------------------------------
proc parallel_axis_before_motion { } {
#------------------------------------------------------------

	global mom_parallel_axis_mode drive_axis
	global mom_motion_type mom_motion_event	lib_flag 
	global mom_namespace_name mom_output_pos_type mom_pos
	global mom_mcs_goto mom_quill_axis_position mom_cycle_spindle_axis
	global mom_cycle_feed_to_pos mom_cycle_rapid_to_pos mom_cycle_retract_to_pos 
	global mom_cycle_feed_to mom_cycle_rapid_to mom_cycle_retract_to    

	# No set modes UDE
	if {![info exists mom_parallel_axis_mode]} {
		return
	}

	if {![string compare "CYCLE" $mom_motion_type]} {
		# Drill/Tap/Bore cycles need to update feed_to_pos/rapid_to_pos/retract_to_pos
		if {[string match "drill*_move" $mom_motion_event] ||
			[string match "tap*_move" $mom_motion_event]   ||
			[string match "bore*_move" $mom_motion_event]} {
			
			if {$lib_flag(local_namespace_output) == 1} {
				if {[info exists mom_namespace_name] && $mom_namespace_name == "::LOCAL_CSYS"} {
					if {[info exists mom_output_pos_type] && $mom_output_pos_type == "mom_mcs_goto"} {			
						set ${mom_namespace_name}::mom_mcs_goto($mom_cycle_spindle_axis) [expr $${mom_namespace_name}::mom_mcs_goto($mom_cycle_spindle_axis) - $mom_quill_axis_position]
						
						set ${mom_namespace_name}::mom_cycle_feed_to_pos($mom_cycle_spindle_axis)    [expr $${mom_namespace_name}::mom_mcs_goto($mom_cycle_spindle_axis) + $mom_cycle_feed_to   ]
						set ${mom_namespace_name}::mom_cycle_rapid_to_pos($mom_cycle_spindle_axis)   [expr $${mom_namespace_name}::mom_mcs_goto($mom_cycle_spindle_axis) + $mom_cycle_rapid_to  ]
						set ${mom_namespace_name}::mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [expr $${mom_namespace_name}::mom_mcs_goto($mom_cycle_spindle_axis) + $mom_cycle_retract_to]
					} else {					
						set ${mom_namespace_name}::mom_pos($mom_cycle_spindle_axis) [expr $${mom_namespace_name}::mom_pos($mom_cycle_spindle_axis) - $mom_quill_axis_position]
					
						set ${mom_namespace_name}::mom_cycle_feed_to_pos($mom_cycle_spindle_axis)    [expr $${mom_namespace_name}::mom_pos($mom_cycle_spindle_axis) + $mom_cycle_feed_to   ]
						set ${mom_namespace_name}::mom_cycle_rapid_to_pos($mom_cycle_spindle_axis)   [expr $${mom_namespace_name}::mom_pos($mom_cycle_spindle_axis) + $mom_cycle_rapid_to  ]
						set ${mom_namespace_name}::mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [expr $${mom_namespace_name}::mom_pos($mom_cycle_spindle_axis) + $mom_cycle_retract_to]
					}
				} else {
					if {[info exists mom_output_pos_type] && $mom_output_pos_type == "mom_mcs_goto"} {					
						set mom_mcs_goto($mom_cycle_spindle_axis) [expr $mom_mcs_goto($mom_cycle_spindle_axis) - $mom_quill_axis_position]
					
						set mom_cycle_feed_to_pos($mom_cycle_spindle_axis)    [expr $mom_mcs_goto($mom_cycle_spindle_axis) + $mom_cycle_feed_to   ]
						set mom_cycle_rapid_to_pos($mom_cycle_spindle_axis)   [expr $mom_mcs_goto($mom_cycle_spindle_axis) + $mom_cycle_rapid_to  ]
						set mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [expr $mom_mcs_goto($mom_cycle_spindle_axis) + $mom_cycle_retract_to]
					} else {					
						set mom_pos($mom_cycle_spindle_axis) [expr $mom_pos($mom_cycle_spindle_axis) - $mom_quill_axis_position]
					
						set mom_cycle_feed_to_pos($mom_cycle_spindle_axis)    [expr $mom_pos($mom_cycle_spindle_axis) + $mom_cycle_feed_to   ]
						set mom_cycle_rapid_to_pos($mom_cycle_spindle_axis)   [expr $mom_pos($mom_cycle_spindle_axis) + $mom_cycle_rapid_to  ]
						set mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [expr $mom_pos($mom_cycle_spindle_axis) + $mom_cycle_retract_to]
					}
				}
			} else {			
				set mom_pos($mom_cycle_spindle_axis) [expr $mom_pos($mom_cycle_spindle_axis) - $mom_quill_axis_position]
			
				set mom_cycle_feed_to_pos($mom_cycle_spindle_axis)    [expr $mom_pos($mom_cycle_spindle_axis) + $mom_cycle_feed_to   ]
				set mom_cycle_rapid_to_pos($mom_cycle_spindle_axis)   [expr $mom_pos($mom_cycle_spindle_axis) + $mom_cycle_rapid_to  ]
				set mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [expr $mom_pos($mom_cycle_spindle_axis) + $mom_cycle_retract_to]					
			}
		}
	} else {
		if {$lib_flag(local_namespace_output) == 1} {
			if {[info exists mom_namespace_name] && $mom_namespace_name == "::LOCAL_CSYS"} {
				if {[info exists mom_output_pos_type] && $mom_output_pos_type == "mom_mcs_goto"} {				
					set ${mom_namespace_name}::mom_mcs_goto($drive_axis) [expr $${mom_namespace_name}::mom_mcs_goto($drive_axis) - $mom_quill_axis_position]
				} else {				
					set ${mom_namespace_name}::mom_pos($drive_axis) [expr $${mom_namespace_name}::mom_pos($drive_axis) - $mom_quill_axis_position]
				}
			} else {
				if {[info exists mom_output_pos_type] && $mom_output_pos_type == "mom_mcs_goto"} {				
					set mom_mcs_goto($drive_axis) [expr $mom_mcs_goto($drive_axis) - $mom_quill_axis_position]
				} else {				
					set mom_pos($drive_axis) [expr $mom_pos($drive_axis) - $mom_quill_axis_position]
				}
			}
		} else {		
			set mom_pos($drive_axis) [expr $mom_pos($drive_axis) - $mom_quill_axis_position]
		}
	}
}

#------------------------------------------------------------
proc parallel_axis_initial_motion { } {
#------------------------------------------------------------

	global mom_parallel_axis_mode lib_flag mom_namespace_name
	global mom_output_pos_type mom_pos mom_mcs_goto
	global drive_axis mom_quill_axis_position

	# No set modes UDE
	if {![info exists mom_parallel_axis_mode]} {
		return
	}

	# For positioning with local namespace on, mom variables in local namspace for initial motion are calculated in mom_initial_move, not in mom_before_motion
	if {$lib_flag(local_namespace_output) == 1} {
		if {[info exists mom_namespace_name] && $mom_namespace_name == "::LOCAL_CSYS"} {
			if {[info exists mom_output_pos_type] && $mom_output_pos_type == "mom_mcs_goto"} {	
				set ${mom_namespace_name}::mom_mcs_goto($drive_axis) [expr $${mom_namespace_name}::mom_mcs_goto($drive_axis) - $mom_quill_axis_position]
			} else {			
				set ${mom_namespace_name}::mom_pos($drive_axis) [expr $${mom_namespace_name}::mom_pos($drive_axis) - $mom_quill_axis_position]
			}
		}			
	}
}