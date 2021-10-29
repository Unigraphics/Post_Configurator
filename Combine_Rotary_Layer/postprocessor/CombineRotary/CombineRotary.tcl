#############################################################################################
#
#	Combine Rotary Layer
#
#############################################################################################
#
#	Copyright 2020 Siemens Digital Industries Software
#				All Rights Reserved.
#
#############################################################################################
# Description
# This combine rotary layer enable the users to combine consecutive
# rotary moves (rapid move motion type) into a single move when
# there is no change in X, Y and Z.
#
# ==> This functionality will only work in NX10 or newer.
#
# The combining of blocks will be terminated when the rotary axis
# being combined reverses its direction or the total angle of
# the combined rotary move would have exceeded 180 degrees.
#
# The current rapid move will be suppressed and combined with next motion, when
# both moves are of RAPID motion type.
# Import the layer in an existing post processor by the Layer Import option from Post Configurator.
# This layer only works in NX1899 or newer.
#############################################################################################
# History
# 16 July 2020   XY   Initial version
##############################################################################################
#
#
#____________________________________________________________________________________________
# Content
#
# 1.  Modified Buffers/ Buffer extensions
# 2.  Global variable definitions
# 3.  Event handler procedures
# 4.  Additional UI groups definition for auto retract
# 5.  Additional UI properties definition for auto retract
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
LIB_GE_command_buffer_edit_append MOM_machine_mode MOM_machine_mode_LIB_ENTRY_end InitCombineRotary _InitCombineRotary
LIB_GE_command_buffer_edit_prepend MOM_before_motion MOM_before_motion_ENTRY_start CombineRotaryCheck _CombineRotaryCheck
LIB_GE_command_buffer_edit_append MOM_rapid_move_LIB MOM_rapid_move_LIB_ENTRY_start CombineRotaryOutput _CombineRotaryOutput

#____________________________________________________________________________________________
# <Documentation>
# 2.
# Global variable definitions
#
# <Example>
#
#____________________________________________________________________________________________

#____________________________________________________________________________________________
# <Documentation>
# 3.
# Event handler procedure
#
# <Example>
#
#___________________________________________________________________________________________

#=============================================================
proc CombineRotaryCheck { } {
#=============================================================
# This command is used to check the condition if
# consecutive rotary moves of a single rotary axis
# can be combined when there is no change in X, Y and Z.
#
# Motion types that can be combined are:
#     FIRSTCUT, CUT, STEPOVER & RAPID
#
# When current and next motions are of the same type (FIRSTCUT, CUT,
# STEPOVER or RAPID), the current linear or rapid move will be suppressed & combined
#
# Combining of blocks will be terminated when the rotary axis reverses
# its direction or the total combined angle has exceeded 180 degrees.
#
# * Rotary angles at the equator will be output.
#
# When a rotary axis has limited travel, "Retract / Re-Engage" method
# should be used to handle axis limit violation.
# "::mom_kin_4th_axis_limit_action" or "::mom_kin_5th_axis_limit_action"
# should be set properly.
#
#-------------------------------------------------------------
# 16-Jul-2020 XY - Adapted from PB to PC. Only combine rapid moves.
#

   # Skip execution, if function of combining rotary moves is not activated.
   #
    if { ![info exists ::mom_sys_combine_rotary_mode] } {
        return
    }

    if {[Combine_rotary_setting_object Output_equator_angles] == "on"} {
        set ::mom_sys_combine_rotary_output_equator_angles 1
    } else {
        set ::mom_sys_combine_rotary_output_equator_angles 0
    }

    set ::mom_sys_skip_move "NO"

   # Read-ahead must be enabled
    if { [info exists ::mom_kin_read_ahead_next_motion] && [string match $::mom_kin_read_ahead_next_motion "TRUE"] &&\
         [info exists ::mom_nxt_pos] && [info exists ::mom_nxt_motion_type] } {

       # Patch up possible missing KIN variables
        if { ![info exists ::mom_kin_machine_type] || ![string match $::mom_kin_machine_type "5_axis_*"] } {

           set vars_list { axis_min_incr\
                           axis_direction\
                           axis_leader\
                           axis_min_limit\
                           axis_max_limit\
                         }

           foreach kin_var $vars_list {
              if { [info exists ::mom_kin_4th_${kin_var}] && ![info exists ::mom_kin_5th_${kin_var}] } {
                 set ::mom_kin_5th_${kin_var} [set ::mom_kin_4th_${kin_var}]
              }
           }

           if { [info exists ::mom_sys_leader(fourth_axis)] && ![info exists ::mom_sys_leader(fifth_axis)] } {
              set ::mom_sys_leader(fifth_axis) [set ::mom_sys_leader(fourth_axis)]
           }
        }


        set tolm $::mom_kin_machine_resolution
        set tol4 $::mom_kin_4th_axis_min_incr
        set tol5 $::mom_kin_5th_axis_min_incr

       # Initialize previous position
        if { ![info exists ::prev_4th_output] } { set ::prev_4th_output [ROUND $::mom_out_angle_pos(0) $tol4] }
        if { ![info exists ::prev_5th_output] } { set ::prev_5th_output [ROUND $::mom_out_angle_pos(1) $tol5] }

       # Check if rotary axis has been repositioned (set in reposition_move)
        if { [info exists ::mom_sys_rotary_axis_retract_repositioned] } {
          # OPERATOR_MSG "Rotary axis retract & repositioned."
           unset ::mom_sys_rotary_axis_retract_repositioned
        }

       # Retain previous position
        set P4 $::prev_4th_output
        set P5 $::prev_5th_output

        set ::prev_4th_output [ROUND $::mom_out_angle_pos(0) $tol4]
        set ::prev_5th_output [ROUND $::mom_out_angle_pos(1) $tol5]

       # Initialize last position
        if { ![info exists ::last_4th_output] } { set ::last_4th_output $P4 }
        if { ![info exists ::last_5th_output] } { set ::last_5th_output $P5 }

       # Initialize last direction indicator
        if { ![info exists ::last_4th_dir] } { set ::last_4th_dir 0 }
        if { ![info exists ::last_5th_dir] } { set ::last_5th_dir 0 }


       # Lock next pos when needed.
       if { [info exists ::mom_sys_rotary_axis_index] && [llength [info commands LOCK_AXIS]] } {
          LOCK_AXIS ::mom_nxt_pos ::mom_nxt_pos ::mom_nxt_out_angle_pos
       }

       set ::mom_nxt_pos(3) [LIB_SPF_rotset $::mom_nxt_pos(3) $::mom_out_angle_pos(0) $::mom_kin_4th_axis_direction\
                                    $::mom_kin_4th_axis_leader ::mom_sys_leader(fourth_axis)\
                                    $::mom_kin_4th_axis_min_limit $::mom_kin_4th_axis_max_limit]

       set ::mom_nxt_pos(4) [LIB_SPF_rotset $::mom_nxt_pos(4) $::mom_out_angle_pos(1) $::mom_kin_5th_axis_direction\
                                    $::mom_kin_5th_axis_leader ::mom_sys_leader(fifth_axis)\
                                    $::mom_kin_5th_axis_min_limit $::mom_kin_5th_axis_max_limit]


        set PX [ROUND $::mom_prev_pos(0) $tolm]
        set PY [ROUND $::mom_prev_pos(1) $tolm]
        set PZ [ROUND $::mom_prev_pos(2) $tolm]

        set NX [ROUND $::mom_nxt_pos(0) $tolm]
        set NY [ROUND $::mom_nxt_pos(1) $tolm]
        set NZ [ROUND $::mom_nxt_pos(2) $tolm]

        set N4 [ROUND $::mom_nxt_pos(3) $tol4]
        set N5 [ROUND $::mom_nxt_pos(4) $tol5]

        set CX [ROUND $::mom_pos(0) $tolm]
        set CY [ROUND $::mom_pos(1) $tolm]
        set CZ [ROUND $::mom_pos(2) $tolm]

        set C4 [ROUND $::mom_out_angle_pos(0) $tol4]
        set C5 [ROUND $::mom_out_angle_pos(1) $tol5]

        set D4 [expr $C4 - $P4]

        if [EQ_is_equal $D4 0] {
            set cur_4th_dir 0
        } elseif { ([EQ_is_gt $D4 -180] && [EQ_is_lt $D4 0]) || [EQ_is_gt $D4 180] } {
            set cur_4th_dir -1
        } else {
            set cur_4th_dir 1
        }

        set T4 [expr $N4 - $::last_4th_output]

        if [EQ_is_equal $T4 0] {
            set tot_4th_dir 0
        } elseif { ([EQ_is_gt $T4 -180] && [EQ_is_lt $T4 0]) || [EQ_is_gt $T4 180] } {
            set tot_4th_dir -1
        } else {
            set tot_4th_dir 1
        }

        if { [EQ_is_lt [expr $cur_4th_dir * $::last_4th_dir] 0] ||\
             [EQ_is_lt [expr $cur_4th_dir * $tot_4th_dir] 0] } {
            set switch_dir_4th "YES"
        } else {
            set switch_dir_4th "NO"
        }

        set D5 [expr $C5 - $P5]

        if [EQ_is_equal $D5 0] {
            set cur_5th_dir 0
        } elseif { ([EQ_is_gt $D5 -180] && [EQ_is_lt $D5 0]) || [EQ_is_gt $D5 180] } {
            set cur_5th_dir -1
        } else {
            set cur_5th_dir 1
        }

        set T5 [expr $N5 - $::last_5th_output]

        if [EQ_is_equal $T5 0] {
            set tot_5th_dir 0
        } elseif { ([EQ_is_ge $T5 -180] && [EQ_is_lt $T5 0]) || [EQ_is_ge $T5 180] } {
            set tot_5th_dir -1
        } else {
            set tot_5th_dir 1
        }

        if { [EQ_is_lt [expr $cur_5th_dir * $::last_5th_dir] 0] ||\
             [EQ_is_lt [expr $cur_5th_dir * $tot_5th_dir] 0] } {
            set switch_dir_5th "YES"
        } else {
            set switch_dir_5th "NO"
        }

        if { [info exists ::mom_motion_type] && [string match $::mom_motion_type "RAPID"] } {

            if { [EQ_is_equal $NX $CX] && [EQ_is_equal $NY $CY] && [EQ_is_equal $NZ $CZ] } {
                if {![EQ_is_equal $P4 $C4] && [EQ_is_equal $P5 $C5] &&\
                    ![EQ_is_equal $N4 $C4] && [EQ_is_equal $N5 $C5] &&\
                     $::mom_sys_combine_rotary_mode != 5 && [info exists switch_dir_4th] && [string match $switch_dir_4th "NO"] } {

                    set ::mom_sys_skip_move "YES"
                    MOM_force once fourth_axis
                    set ::mom_sys_combine_rotary_mode "4"

                } elseif\
                   { [EQ_is_equal $P4 $C4] && ![EQ_is_equal $P5 $C5] &&\
                     [EQ_is_equal $N4 $C4] && ![EQ_is_equal $N5 $C5] &&\
                     $::mom_sys_combine_rotary_mode != 4 && [info exists switch_dir_5th] && [string match $switch_dir_5th "NO"] } {

                    set ::mom_sys_skip_move "YES"
                    MOM_force once fifth_axis
                    set ::mom_sys_combine_rotary_mode "5"

                }
            }
        }

       # Update direction under all conditions
        set ::last_4th_dir $cur_4th_dir
        set ::last_5th_dir $cur_5th_dir

       # Output angles at equator
       if { [info exists ::mom_sys_combine_rotary_output_equator_angles] && [string match $::mom_sys_combine_rotary_output_equator_angles 1 ] } {
           if { [info exists ::mom_sys_skip_move] && [string match $::mom_sys_skip_move "YES"] } {
              switch $::mom_sys_combine_rotary_mode {
                 "4" {
                    set C4a [expr abs($C4)]
                    if { [EQ_is_equal $C4a 0.0] || [EQ_is_equal $C4a 180.0] || [EQ_is_equal $C4a 360.0] } {
                      #OPERATOR_MSG "Forced output of C4 = $C4a"
                       set ::mom_sys_skip_move "NO"
                    }
                 }
                 "5" {
                    set C5a [expr abs($C5)]
                    if { [EQ_is_equal $C5a 0.0] || [EQ_is_equal $C5a 180.0] || [EQ_is_equal $C5a 360.0] } {
                      #OPERATOR_MSG "Forced output of C5 = $C5a"
                       set ::mom_sys_skip_move "NO"
                    }
                 }
              }
           }

           if { [info exists ::mom_sys_skip_move] && [string match $::mom_sys_skip_move "YES"] } {
              switch $::mom_sys_combine_rotary_mode {
                 "4" {
                    foreach eqt { 0.0 180.0 -180.0 360.0 -360.0 } {
                       if { ([EQ_is_lt $P4 $eqt] && [EQ_is_gt $C4 $eqt]) ||\
                            ([EQ_is_gt $P4 $eqt] && [EQ_is_lt $C4 $eqt]) } {

                         #OPERATOR_MSG "Forced output of $eqt before C4($C4) for ${::mom_motion_event}"
                          set ::mom_out_angle_pos(0) $eqt

                          set ::mom_sys_skip_move "NO"
                          MOM_${::mom_motion_event}
                          set ::mom_sys_skip_move "YES"

                          break
                       }
                    }
                 }
                 "5" {
                    foreach eqt { 0.0 180.0 -180.0 360.0 -360.0 } {
                       if { ([EQ_is_lt $P5 $eqt] && [EQ_is_gt $C5 $eqt]) ||\
                            ([EQ_is_gt $P5 $eqt] && [EQ_is_lt $C5 $eqt]) } {

                         #OPERATOR_MSG "Forced output of $eqt before C5($C5) for ${::mom_motion_event}"
                          set ::mom_out_angle_pos(1) $eqt

                          set ::mom_sys_skip_move "NO"
                          MOM_${::mom_motion_event}
                          set ::mom_sys_skip_move "YES"

                          break
                       }
                    }
                 }
              }
           }
        }


       # Skip output of next motion -
       # Preserve current feedrate
        if { [info exists ::mom_sys_skip_move] && [string match $::mom_sys_skip_move "YES"] } {
          # set ::mom_sys_abort_next_event 1
          # Recompute feedrate, if it's FRN
           if { [info exists ::mom_sys_contour_feed_mode(ROTARY)] && [string match $::mom_sys_contour_feed_mode(ROTARY) "FRN"] } {

              if { ![info exists ::mom_user_combined_rotary_feed] } {
                 set ::mom_user_combined_rotary_feed 0.0
                 set current_feed_num 1.0
              } else {
                 set current_feed_num $::mom_user_combined_rotary_feed
              }

             # Combined FRN = (frn1 * frn2)/(frn1 + frn2)
              set ::mom_user_combined_rotary_feed \
                  [expr ($current_feed_num * $::mom_feed_rate_number) / ($::mom_user_combined_rotary_feed + $::mom_feed_rate_number)]

           } else {

              if { ![info exists ::mom_user_combined_rotary_feed] } {
                 set ::mom_user_combined_rotary_feed $::feed
              }
           }

          # Signal combine_rotary_output to skip output of current move.
            return
        }

        if { [info exists ::mom_user_combined_rotary_feed] } {
           set ::feed $::mom_user_combined_rotary_feed
           unset ::mom_user_combined_rotary_feed
        }

        set ::mom_sys_combine_rotary_mode "1"

        set ::last_4th_output $C4
        set ::last_5th_output $C5

    }
}

#=============================================================
proc InitCombineRotary { } {
#=============================================================
# This command is used to initialize the functionality of combining consecutive
# rotary moves into a single move when there is no change in
# X, Y and Z.
#
#-------------------------------------------------------------
# 16-Jul-2020 XY - Adapted from PB to PC
#

# ==> Uncomment next statement to disable the combine-rotary functionality
# return

   #<04-30-2013 gsl> This version only works when ROUND command is available.
   #
    if { ![llength [info commands ROUND]] } {

    uplevel #0 {
       #===============================================================================
       proc ROUND { value {resol 1} } {
       #===============================================================================
       # This command rounds off a number by the given output resolution.
       # When the resolution is not specified, it rounds the number to an integer.
       #
       #<04-24-2013 gsl> Initial implementation
       #
          set ret_val $value

          # Perform regular rounding when output resolution is "1".
          if { [EQ_is_equal $resol 1] } \
          {
             return [expr round( $value )]
          }

          # When the output resolution is near "0", the original value is returned.
          if { ![EQ_is_zero $resol] } \
          {
              if [EQ_is_zero $value] \
              {
                 set ret_val 0.0

              } else \
              {
                 set sign 1

                 set x [expr $value / $resol]

                 # Either value or resol can be negative; and that will cause x to be negative.
                 if [expr $x < 0.0] \
                 {
                    set sign -1
                 }

                 # To compensate for the loss of floating point accuracy
                 set x [expr floor( abs($x) + 0.501 )]

                 set ret_val [expr $sign * $x * $resol]
              }
           }

           return $ret_val
       }

    } ;# uplevel
    }



   # Clear possible residual
    if { [info exists ::mom_sys_skip_move] } {
        unset ::mom_sys_skip_move
    }


   # Enable combining rotary moves with read-ahead function
   #
    if {[Combine_rotary_setting_object Enable_combine_rotary] == "on"} {
        set ::mom_sys_combine_rotary_mode     "1"
        set ::mom_kin_read_ahead_next_motion  "TRUE"
    }

    MOM_reload_kinematics_variable mom_kin_read_ahead_next_motion
}


#=============================================================
proc CombineRotaryOutput { } {
#=============================================================
# This command is used to skip the output when consecutive rotary moves can be combined.
#
   # Skip execution, if function of combining rotary moves is not activated.
   # - This flag should be set in CombineRotaryInit
   #
   
    if { ![info exists ::mom_sys_combine_rotary_mode] } {
        return
    }


   # This command should be called by MOM_rapid_move
   #
    if { [lindex [info level -1] 0] != "MOM_rapid_move_LIB" } {
        return
    }


   # Flag set in combine_rotary_check to tell if next block should be combined.
   # - Need to skip output, exchange the end points' info then abort
   #
    if { [info exists ::mom_sys_skip_move] && [string match $::mom_sys_skip_move "YES"] } {
    
        VMOV 5 ::mom_prev_pos      ::mom_pos
        VMOV 3 ::mom_prev_mcs_goto ::mom_mcs_goto

        MOM_reload_variable -a mom_pos
        MOM_reload_variable -a mom_mcs_goto

        MOM_abort_event
     }
}

#____________________________________________________________________________________________
# <Documentation>
# 4.
# Additional UI groups definition for auto retract
#
# <Example>
#
#___________________________________________________________________________________________
LIB_GE_CREATE_obj Combine_rotary {UI_TREE} {
    LIB_GE_property_ui_name        "UIName"
    LIB_GE_property_ui_tooltip     "UITooltip"

set id "Combine_rotary_root"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Combine Rotary}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "root"
    set ui_sequence($id)    -1

set id "Combine_rotary_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Combine Rotary Setting}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "Combine_rotary_root"
    set ui_sequence($id)    -1

set id "Combine_rotary_setting_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Combine Rotary Options}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "Combine_rotary_node"
    set ui_sequence($id)    -1
}
#____________________________________________________________________________________________
# <Documentation>
# 5.
# Additional UI properties definition for auto retract
#
# <Example>
#
#____________________________________________________________________________________________
LIB_GE_CREATE_obj Combine_rotary_setting_object {} {
    LIB_GE_property_ui_name        "Name"
    LIB_GE_property_ui_tooltip     "Tooltip"

set id "Enable_combine_rotary"
	set $id		"off"
		set options($id)	{Off|On}
		set options_ids($id) 	{off|on}
		set datatype($id) 	"OPTION"
		set access($id) 	222
		set dialog($id) 	{{Enable combine rotary}}
		set descr($id) 		{{Defined whether to combine rotary is enabled.}}
		set ui_parent($id) "Combine_rotary_setting_group"
		set ui_sequence($id) -1

set id "Output_equator_angles"
	set $id		"off"
		set options($id)	{Off|On}
		set options_ids($id) 	{off|on}
		set datatype($id) 	"OPTION"
		set access($id) 	222
		set dialog($id) 	{{Output rotary angles at equator}}
		set descr($id) 		{{Defined whether to output rotary angles at equator (0, +/-180, +/-360).}}
		set ui_parent($id) "Combine_rotary_setting_group"
		set ui_sequence($id) -1

}
