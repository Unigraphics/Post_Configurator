########################## TCL Event Handlers ##########################
#
#  sim08_mill_5ax_sinumerik_mm.tcl - 5_axis_dual_table
#
#    This is a 5-Axis Milling Machine With
#     Dual Rotary Tables.
#
#  Created by ndcep8 @ Tuesday, February 07, 2017 10:36:50 AM China Standard Time
#  with Post Builder version 11.0.1.
#
########################################################################



#=============================================================
proc PB_CMD___log_revisions { } {
#=============================================================
# Dummy command to log changes in this post --
#
# 02-26-09 gsl - Initial version
# 05-05-2011 lili Remove PB_CMD_define_feed_varialble_value from initial move and first move
#                 Add it into PB_CMD_MOM_sinumerik_840D
#                 Move feedrate define in variable from PB_CMD_before_motion to PB_CMD_FEEDRATE_SET
# 10-15-13 Allen - PR6944859 fixed:Modify PB_CMD_choose_output_mode.
#                - PR6927279 fixed:Delete PB_CMD_reset_all_motion_variables_to_zero in end of path to support ROTATE UDE.
#                - Behavior change: no home return in the end of path if there is no tool change in next operation.
#                  Home return if it is the last operation. Add new command PB_CMD__check_block_return_to_reference_point.
#                - Behavior change: table axis will not return to zero if the tool vector turn to be along Z axis in
#                  cycle plane change or in rapid move. modified in PB_CMD_detect_operation_type, PB_CMD_rotate_rapid_coordinate,
#                  PB_CMD_rotate_cycle_coordinate,PB_CMD__check_reset_trans and PB_CMD__check_reset_cycle800.
#                - Bug fix in general proc: 4th and 5th axis and related mom motion variable should be switched for head head machine
#                  when changing the kinematics. Fixed in DPP_GE_COOR_ROT_AUTO3D and  DPP_GE_RESTORE_KINEMATICS.
# 05-20-14 Lili  - Remove mom_kin_arc_output_mode and mom_kin_helical_arc_output_mode from DPP_GE_RESTORE_KINEMATICS.
#                  They affect compressor mode. PB_CMD__check_block_reset_cycle832 is updated to restore them.
# 06-04-14 Allen - PR7143300 fix: check if variable mom_next_oper_has_tool_change and mom_current_oper_is_last_oper_in_program exists
#                  for PB_CMD__check_block_return_to_reference_point
# 07-08-14 Allen - Enhance new tap cycle: Add PB_CMD__check_block_tap_type_powerline, PB_CMD__check_block_tap_type_solutionline,
#                  PB_CMD__check_block_tap_float_solutionline, PB_CMD__check_block_tap_float_powerline and
#                  PB_CMD_cycle_tap_parameter_setting.
# 07-14-14 Lili  - Fix clearance plane position issue in PB_CMD_rotate_cycle_coordinate.
# 04-30-15 ljt   - add PB_CMD_spindle_orient, and add PB__CMD_check_block_cycle_retract to fix PR7162261. PR7281995
# 07-31-15 szl   - PR6988503 remove mom_kin_helical_arc_output_mode from DPP_GE_RESTORE_KINEMATICS.
# 19-Aug-2015 gsl - Refiled in PB v10.03 with updated PB_CMD_fix_RAPID_SET
# 08-21-2015 szl - Fix PR7471332:Parse error during machine code simulation if the UDE Operator Message is added.
# 08-21-2015 szl - Enhance the warning message when users set wrong pitch and wrong spindle speed,fix PR7463004.
# 09-16-2015 szl - DPP_GE_RESTORE_KINEMATICS is fixed with save_kin_machine_type exist checking, fix PR7383025
# 09-17-2015 szl - Updated PB_CMD_abort_event. Output a warning message in NC output while postprocessor cannot calculate the valid rotary position, fix PR7465721.
# 18-Sep-2015 ljt - Fix lock axis issues: replace obsolete variables with new iks variables in UNLOCK_AXIS and LOCK_AXIS,
#                 - fix PR6961328 in PB_CMD_MOM_lock_axis, comment out reload mom_pos in LOCK_AXIS_MOTION and lock mom_prev_pos in LINEARIZE_LOCK_MOTION
# 12-22-2015 szl - Add PB_CMD_spindle_off and PB_CMD_coolant_on to enhance back counter sinking and deep hole drilling.
# 12-22-2015 ljt - Updated PB_CMD_spindle_orient. Remove global declaration and account the rotation of feature reference vector for 3axis machine.
# 03-29-2016 szl - Updated PB_CMD_coolant_on. Update mom_coolant_mode if operation doesn't attach UDE, otherwise it won't work in turbo mode.
#                  Updated MOM_coolant_on. Output M_coolant code when coolant_on UDE is activated for operations.
# 07-26-2016 Shuai - Updated PB_CMD_detect_operation_type: set coordinate system offset to value 0 in 5-axis operation. Fix PR7700495.
# 08-09-2016 lili - Fix ZYX rotation angle calculation issue in DPP_GE_CALCULATE_COOR_ROT_ANGLE. zero resolution was too high.
# 08-15-2016 szl - Update PB_CMD_MOM_rotate: remove original contents and call proc PB_CMD_kin__MOM_rotate.
# 01-06-2017 szl - Resaved with PB v11.0.1.
#                  Replace MOM_abort with new MOM extension MOM_abort_program.
# 22-Jan-2017 shuai - CYCLE832 enhancement.
#                     1. Add the new macro "CYCLE832_v47".
#                     2. Add the new options "Top Surface Smooth" and "Rotary Tolerance" into UDE "Sinumerik 840D".
#                     3. Add the new command PB_CMD_check_settings_for_cycle832, PB_CMD_reset_arc_compressor_mode, PB_CMD_detect_5axis_tool_path and PB_CMD_detect_hole_cutting_operation.
#                     4. Update the commands.
#                        PB_CMD_MOM_sinumerik_840D, PB_CMD__check_block_CYCLE832, PB_CMD__check_block_reset_cycle832, PB_CMD_init_high_speed_setting,
#                        PB_CMD_reset_Sinumerik_setting, PB_CMD_reset_sinumerik_setting_in_group, PB_CMD_set_Sinumerik_default_setting and PB_CMD_set_Sinumerik_version.
#                     5. Adjust some codes format in this TCL file to make the logic and description more clear.
#
}



  set cam_post_dir [MOM_ask_env_var UGII_CAM_POST_DIR]
  set this_post_dir "[file dirname [info script]]"


  if { ![info exists mom_sys_post_initialized] } {

     if { ![info exists mom_sys_ugpost_base_initialized] } {
        source ${cam_post_dir}ugpost_base.tcl
        set mom_sys_ugpost_base_initialized 1
     }
 
 
     set mom_sys_debug_mode OFF
 
 
     if { ![info exists env(PB_SUPPRESS_UGPOST_DEBUG)] } {
        set env(PB_SUPPRESS_UGPOST_DEBUG) 0
     }
 
     if { $env(PB_SUPPRESS_UGPOST_DEBUG) } {
        set mom_sys_debug_mode OFF
     }
 
     if { ![string compare $mom_sys_debug_mode "OFF"] } {
 
        proc MOM_before_each_add_var {} {}
        proc MOM_before_each_event   {} {}
        proc MOM_before_load_address {} {}
        proc MOM_end_debug {} {}
 
     } else {
 
        set cam_debug_dir [MOM_ask_env_var UGII_CAM_DEBUG_DIR]
        source ${cam_debug_dir}mom_review.tcl
     }


   ####  Listing File variables 
     set mom_sys_list_output                       "OFF"
     set mom_sys_header_output                     "OFF"
     set mom_sys_list_file_rows                    "40"
     set mom_sys_list_file_columns                 "132"
     set mom_sys_warning_output                    "OFF"
     set mom_sys_warning_output_option             "FILE"
     set mom_sys_group_output                      "OFF"
     set mom_sys_list_file_suffix                  "lpt"
     set mom_sys_output_file_suffix                "mpf"
     set mom_sys_commentary_output                 "ON"
     set mom_sys_commentary_list                   "x y z 4axis 5axis feed speed"
     set mom_sys_pb_link_var_mode                  "OFF"


     if { [string match "OFF" $mom_sys_warning_output] } {
        catch { rename MOM__util_print ugpost_MOM__util_print }
        proc MOM__util_print { args } {}
     }


     MOM_set_debug_mode $mom_sys_debug_mode


     if { [string match "OFF" $mom_sys_warning_output] } {
        catch { rename MOM__util_print "" }
        catch { rename ugpost_MOM__util_print MOM__util_print }
     }


   #=============================================================
   proc MOM_before_output { } {
   #=============================================================
   # This command is executed just before every NC block is
   # to be output to a file.
   #
   # - Never overload this command!
   # - Any customization should be done in PB_CMD_before_output!
   #

      if { [llength [info commands PB_CMD_kin_before_output]] &&\
           [llength [info commands PB_CMD_before_output]] } {

         PB_CMD_kin_before_output
      }

   ######### The following procedure invokes the listing file with warnings.

      global mom_sys_list_output
      if { [string match "ON" $mom_sys_list_output] } {
         LIST_FILE
      } else {
         global tape_bytes mom_o_buffer
         if { ![info exists tape_bytes] } {
            set tape_bytes [string length $mom_o_buffer]
         } else {
            incr tape_bytes [string length $mom_o_buffer]
         }
      }
   }


     if { [string match "OFF" [MOM_ask_env_var UGII_CAM_POST_LINK_VAR_MODE]] } {
        set mom_sys_link_var_mode                     "OFF"
     } else {
        set mom_sys_link_var_mode                     "$mom_sys_pb_link_var_mode"
     }


     set mom_sys_control_out                       ";"
     set mom_sys_control_in                        ""


    # Retain UDE handlers of ugpost_base
     foreach ude_handler { MOM_insert \
                           MOM_operator_message \
                           MOM_opskip_off \
                           MOM_opskip_on \
                           MOM_pprint \
                           MOM_text \
                         } \
     {
        if { [llength [info commands $ude_handler]] &&\
            ![llength [info commands ugpost_${ude_handler}]] } {
           rename $ude_handler ugpost_${ude_handler}
        }
     }


     set mom_sys_post_initialized 1
  }


  set mom_sys_use_default_unit_fragment         "ON"
  set mom_sys_alt_unit_post_name                "sim08_mill_5ax_sinumerik_mm__IN.pui"


########## SYSTEM VARIABLE DECLARATIONS ##############
  set mom_sys_rapid_code                        "1099"
  set mom_sys_linear_code                       "1"
  set mom_sys_circle_code(CLW)                  "2"
  set mom_sys_circle_code(CCLW)                 "3"
  set mom_sys_delay_code(SECONDS)               "4"
  set mom_sys_delay_code(REVOLUTIONS)           "4"
  set mom_sys_cutcom_plane_code(XY)             "17"
  set mom_sys_cutcom_plane_code(ZX)             "18"
  set mom_sys_cutcom_plane_code(XZ)             "18"
  set mom_sys_cutcom_plane_code(YZ)             "19"
  set mom_sys_cutcom_plane_code(ZY)             "19"
  set mom_sys_cutcom_code(OFF)                  "40"
  set mom_sys_cutcom_code(LEFT)                 "41"
  set mom_sys_cutcom_code(RIGHT)                "42"
  set mom_sys_unit_code(IN)                     "700"
  set mom_sys_unit_code(MM)                     "710"
  set mom_sys_output_code(ABSOLUTE)             "90"
  set mom_sys_output_code(INCREMENTAL)          "91"
  set mom_sys_feed_rate_mode_code(FRN)          "93"
  set mom_sys_spindle_mode_code(SFM)            "96"
  set mom_sys_spindle_mode_code(RPM)            "97"
  set mom_sys_feed_rate_mode_code(MMPM)         "94"
  set mom_sys_feed_rate_mode_code(MMPR)         "95"
  
  set mom_sys_program_stop_code                 "0"
  set mom_sys_optional_stop_code                "1"
  set mom_sys_end_of_program_code               "2"
  set mom_sys_spindle_direction_code(CLW)       "3"
  set mom_sys_spindle_direction_code(CCLW)      "4"
  set mom_sys_spindle_direction_code(OFF)       "5"
  set mom_sys_tool_change_code                  "6"
  set mom_sys_coolant_code(ON)                  "8"
  set mom_sys_coolant_code(FLOOD)               "8"
  set mom_sys_coolant_code(MIST)                "7"
  set mom_sys_coolant_code(THRU)                "26"
  set mom_sys_coolant_code(TAP)                 "8"
  set mom_sys_coolant_code(OFF)                 "9"
  set mom_sys_rewind_code                       "30"
  
  set mom_sys_4th_axis_has_limits               "1"
  set mom_sys_5th_axis_has_limits               "1"
  set mom_sys_sim_cycle_drill                   "0"
  set mom_sys_sim_cycle_drill_dwell             "0"
  set mom_sys_sim_cycle_drill_deep              "0"
  set mom_sys_sim_cycle_drill_break_chip        "0"
  set mom_sys_sim_cycle_tap                     "0"
  set mom_sys_sim_cycle_bore                    "0"
  set mom_sys_sim_cycle_bore_drag               "0"
  set mom_sys_sim_cycle_bore_nodrag             "0"
  set mom_sys_sim_cycle_bore_manual             "0"
  set mom_sys_sim_cycle_bore_dwell              "0"
  set mom_sys_sim_cycle_bore_manual_dwell       "0"
  set mom_sys_sim_cycle_bore_back               "0"
  set mom_sys_cir_vector                        "Vector - Arc Start to Center"
  set mom_sys_spindle_ranges                    "0"
  set mom_sys_rewind_stop_code                  "\#"
  set mom_sys_home_pos(0)                       "0"
  set mom_sys_home_pos(1)                       "0"
  set mom_sys_home_pos(2)                       "0"
  set mom_sys_zero                              "0"
  set mom_sys_opskip_block_leader               "/"
  set mom_sys_seqnum_start                      "10"
  set mom_sys_seqnum_incr                       "10"
  set mom_sys_seqnum_freq                       "1"
  set mom_sys_seqnum_max                        "99999999"
  set mom_sys_lathe_x_double                    "1"
  set mom_sys_lathe_i_double                    "1"
  set mom_sys_lathe_y_double                    "1"
  set mom_sys_lathe_j_double                    "1"
  set mom_sys_lathe_x_factor                    "1"
  set mom_sys_lathe_y_factor                    "1"
  set mom_sys_lathe_z_factor                    "1"
  set mom_sys_lathe_i_factor                    "1"
  set mom_sys_lathe_j_factor                    "1"
  set mom_sys_lathe_k_factor                    "1"
  set mom_sys_leader(N)                         "N"
  set mom_sys_leader(X)                         "X"
  set mom_sys_leader(Y)                         "Y"
  set mom_sys_leader(Z)                         "Z"
  set mom_sys_leader(fourth_axis)               "A"
  set mom_sys_leader(fifth_axis)                "C"
  set mom_sys_contour_feed_mode(LINEAR)         "MMPM"
  set mom_sys_rapid_feed_mode(LINEAR)           "MMPM"
  set mom_sys_cycle_feed_mode                   "MMPM"
  set mom_sys_feed_param(IPM,format)            "Feed_IPM"
  set mom_sys_feed_param(IPR,format)            "Feed_IPR"
  set mom_sys_feed_param(FRN,format)            "Feed_INV"
  set mom_sys_vnc_rapid_dogleg                  "1"
  set mom_sys_prev_mach_head                    ""
  set mom_sys_curr_mach_head                    ""
  set mom_sys_contour_feed_mode(ROTARY)         "MMPM"
  set mom_sys_contour_feed_mode(LINEAR_ROTARY)  "MMPM"
  set mom_sys_feed_param(DPM,format)            "Feed_DPM"
  set mom_sys_rapid_feed_mode(ROTARY)           "MMPM"
  set mom_sys_rapid_feed_mode(LINEAR_ROTARY)    "MMPM"
  set mom_sys_feed_param(MMPM,format)           "Feed_MMPM"
  set mom_sys_feed_param(MMPR,format)           "Feed_MMPR"
  set mom_sys_retract_distance                  "10"
  set mom_sys_advanced_turbo_output             "0"
  set mom_sys_linearization_method              "angle"
  set mom_sys_tool_number_max                   "32"
  set mom_sys_tool_number_min                   "1"
  set mom_sys_post_description                  "This is a 5-Axis Milling Machine With\n\
                                                  Dual Rotary Tables."
  set mom_sys_ugpadvkins_used                   "0"
  set mom_sys_post_builder_version              "11.0.1"

####### KINEMATIC VARIABLE DECLARATIONS ##############
  set mom_kin_4th_axis_ang_offset               "0.0"
  set mom_kin_4th_axis_center_offset(0)         "0.0"
  set mom_kin_4th_axis_center_offset(1)         "0.0"
  set mom_kin_4th_axis_center_offset(2)         "0.0"
  set mom_kin_4th_axis_direction                "MAGNITUDE_DETERMINES_DIRECTION"
  set mom_kin_4th_axis_incr_switch              "OFF"
  set mom_kin_4th_axis_leader                   "A"
  set mom_kin_4th_axis_limit_action             "Warning"
  set mom_kin_4th_axis_max_limit                "115"
  set mom_kin_4th_axis_min_incr                 "0.001"
  set mom_kin_4th_axis_min_limit                "-115"
  set mom_kin_4th_axis_plane                    "YZ"
  set mom_kin_4th_axis_point(0)                 "0.0"
  set mom_kin_4th_axis_point(1)                 "0.0"
  set mom_kin_4th_axis_point(2)                 "0.0"
  set mom_kin_4th_axis_rotation                 "standard"
  set mom_kin_4th_axis_type                     "Table"
  set mom_kin_4th_axis_vector(0)                "1"
  set mom_kin_4th_axis_vector(1)                "0"
  set mom_kin_4th_axis_vector(2)                "0"
  set mom_kin_4th_axis_zero                     "0.0"
  set mom_kin_5th_axis_ang_offset               "0.0"
  set mom_kin_5th_axis_center_offset(0)         "0.0"
  set mom_kin_5th_axis_center_offset(1)         "0.0"
  set mom_kin_5th_axis_center_offset(2)         "0.0"
  set mom_kin_5th_axis_direction                "MAGNITUDE_DETERMINES_DIRECTION"
  set mom_kin_5th_axis_incr_switch              "OFF"
  set mom_kin_5th_axis_leader                   "C"
  set mom_kin_5th_axis_limit_action             "Warning"
  set mom_kin_5th_axis_max_limit                "360000"
  set mom_kin_5th_axis_min_incr                 "0.001"
  set mom_kin_5th_axis_min_limit                "-360000"
  set mom_kin_5th_axis_plane                    "XY"
  set mom_kin_5th_axis_point(0)                 "0.0"
  set mom_kin_5th_axis_point(1)                 "0.0"
  set mom_kin_5th_axis_point(2)                 "0.0"
  set mom_kin_5th_axis_rotation                 "standard"
  set mom_kin_5th_axis_type                     "Table"
  set mom_kin_5th_axis_vector(0)                "0"
  set mom_kin_5th_axis_vector(1)                "0"
  set mom_kin_5th_axis_vector(2)                "1"
  set mom_kin_5th_axis_zero                     "0.0"
  set mom_kin_arc_output_mode                   "FULL_CIRCLE"
  set mom_kin_arc_valid_plane                   "XY"
  set mom_kin_clamp_time                        "2.0"
  set mom_kin_cycle_plane_change_per_axis       "1"
  set mom_kin_cycle_plane_change_to_lower       "1"
  set mom_kin_flush_time                        "2.0"
  set mom_kin_linearization_flag                "1"
  set mom_kin_linearization_tol                 "0.01"
  set mom_kin_machine_resolution                "0.001"
  set mom_kin_machine_type                      "5_axis_dual_table"
  set mom_kin_machine_zero_offset(0)            "0.0"
  set mom_kin_machine_zero_offset(1)            "0.0"
  set mom_kin_machine_zero_offset(2)            "0.0"
  set mom_kin_max_arc_radius                    "99999.999"
  set mom_kin_max_dpm                           "10000"
  set mom_kin_max_fpm                           "15000"
  set mom_kin_max_fpr                           "1000"
  set mom_kin_max_frn                           "1000"
  set mom_kin_min_arc_length                    "0.20"
  set mom_kin_min_arc_radius                    "0.001"
  set mom_kin_min_dpm                           "0.0"
  set mom_kin_min_fpm                           "0.1"
  set mom_kin_min_fpr                           "0.1"
  set mom_kin_min_frn                           "0.01"
  set mom_kin_output_unit                       "MM"
  set mom_kin_pivot_gauge_offset                "0"
  set mom_kin_pivot_guage_offset                ""
  set mom_kin_post_data_unit                    "MM"
  set mom_kin_rapid_feed_rate                   "10000"
  set mom_kin_retract_distance                  "500"
  set mom_kin_rotary_axis_method                "PREVIOUS"
  set mom_kin_spindle_axis(0)                   "0.0"
  set mom_kin_spindle_axis(1)                   "0.0"
  set mom_kin_spindle_axis(2)                   "1.0"
  set mom_kin_tool_change_time                  "0.0"
  set mom_kin_x_axis_limit                      "1000"
  set mom_kin_y_axis_limit                      "1000"
  set mom_kin_z_axis_limit                      "1000"




if [llength [info commands MOM_SYS_do_template] ] {
   if [llength [info commands MOM_do_template] ] {
      rename MOM_do_template ""
   }
   rename MOM_SYS_do_template MOM_do_template
}




#=============================================================
proc MOM_start_of_program { } {
#=============================================================
  global mom_logname mom_date is_from
  global mom_coolant_status mom_cutcom_status
  global mom_clamp_status mom_cycle_status
  global mom_spindle_status mom_cutcom_plane pb_start_of_program_flag
  global mom_cutcom_adjust_register mom_tool_adjust_register
  global mom_tool_length_adjust_register mom_length_comp_register
  global mom_flush_register mom_wire_cutcom_adjust_register
  global mom_wire_cutcom_status

    set pb_start_of_program_flag 0
    set mom_coolant_status UNDEFINED
    set mom_cutcom_status  UNDEFINED
    set mom_clamp_status   UNDEFINED
    set mom_cycle_status   UNDEFINED
    set mom_spindle_status UNDEFINED
    set mom_cutcom_plane   UNDEFINED
    set mom_wire_cutcom_status  UNDEFINED

    catch {unset mom_cutcom_adjust_register}
    catch {unset mom_tool_adjust_register}
    catch {unset mom_tool_length_adjust_register}
    catch {unset mom_length_comp_register}
    catch {unset mom_flush_register}
    catch {unset mom_wire_cutcom_adjust_register}

    set is_from ""

    catch { OPEN_files } ;# Open warning and listing files
    LIST_FILE_HEADER     ;# List header in commentary listing



  global mom_sys_post_initialized
  if { $mom_sys_post_initialized > 1 } { return }


   # Load parameters for alternate output units
    PB_load_alternate_unit_settings
    rename PB_load_alternate_unit_settings ""


#************
uplevel #0 {


#=============================================================
proc MOM_sync { } {
#=============================================================
  if [llength [info commands PB_CMD_kin_handle_sync_event] ] {
    PB_CMD_kin_handle_sync_event
  }
}


#=============================================================
proc MOM_set_csys { } {
#=============================================================
  if [llength [info commands PB_CMD_kin_set_csys] ] {
    PB_CMD_kin_set_csys
  }
}


#=============================================================
proc MOM_msys { } {
#=============================================================
}


#=============================================================
proc MOM_end_of_program { } {
#=============================================================
   PB_CMD_end_of_extcall_program
   MOM_output_literal ";End of Program"
   MOM_force Once T
   MOM_do_template end_of_program_1
   MOM_force Once M
   MOM_do_template end_of_program_2
   MOM_do_template end_of_program
   PB_CMD_end_of_program
   MOM_set_seq_off

#**** The following procedure lists the tool list with time in commentary data
   LIST_FILE_TRAILER

#**** The following procedure closes the warning and listing files
   CLOSE_files

   if [CMD_EXIST PB_CMD_kin_end_of_program] {
      PB_CMD_kin_end_of_program
   }
}


  incr mom_sys_post_initialized


} ;# uplevel
#***********


}


#=============================================================
proc PB_init_new_iks { } {
#=============================================================
  global mom_kin_iks_usage mom_kin_spindle_axis
  global mom_kin_4th_axis_vector mom_kin_5th_axis_vector


   set mom_kin_iks_usage 1

  # Override spindle axis vector defined in PB_CMD_init_rotary
   set mom_kin_spindle_axis(0)  0.0
   set mom_kin_spindle_axis(1)  0.0
   set mom_kin_spindle_axis(2)  1.0

  # Unitize vectors
   foreach i { 0 1 2 } {
      set vec($i) $mom_kin_spindle_axis($i)
   }
   VEC3_unitize vec mom_kin_spindle_axis

   foreach i { 0 1 2 } {
      set vec($i) $mom_kin_4th_axis_vector($i)
   }
   VEC3_unitize vec mom_kin_4th_axis_vector

   foreach i { 0 1 2 } {
      set vec($i) $mom_kin_5th_axis_vector($i)
   }
   VEC3_unitize vec mom_kin_5th_axis_vector

  # Reload kinematics
   MOM_reload_kinematics
}


#=============================================================
proc PB_DELAY_TIME_SET { } {
#=============================================================
  global mom_sys_delay_param mom_delay_value
  global mom_delay_revs mom_delay_mode delay_time

  # Post Builder provided format for the current mode:
   if { [info exists mom_sys_delay_param(${mom_delay_mode},format)] != 0 } {
      MOM_set_address_format dwell $mom_sys_delay_param(${mom_delay_mode},format)
   }

   switch $mom_delay_mode {
      SECONDS { set delay_time $mom_delay_value }
      default { set delay_time $mom_delay_revs  }
   }
}


#=============================================================
proc MOM_before_motion { } {
#=============================================================
  global mom_motion_event mom_motion_type

   FEEDRATE_SET

   switch $mom_motion_type {
      ENGAGE   { PB_engage_move }
      APPROACH { PB_approach_move }
      FIRSTCUT { catch {PB_first_cut} }
      RETRACT  { PB_retract_move }
      RETURN   { catch {PB_return_move} }
      default  {}
   }

   if { [llength [info commands PB_CMD_kin_before_motion] ] } { PB_CMD_kin_before_motion }
   if { [llength [info commands PB_CMD_before_motion] ] }     { PB_CMD_before_motion }
}


#=============================================================
proc MOM_start_of_group { } {
#=============================================================
  global mom_sys_group_output mom_group_name group_level ptp_file_name
  global mom_sequence_number mom_sequence_increment mom_sequence_frequency
  global mom_sys_ptp_output pb_start_of_program_flag

   if { ![hiset group_level] } {
      set group_level 0
      return
   }

   if { [hiset mom_sys_group_output] } {
      if { ![string compare $mom_sys_group_output "OFF"] } {
         set group_level 0
         return
      }
   }

   if { [hiset group_level] } {
      incr group_level
   } else {
      set group_level 1
   }

   if { $group_level > 1 } {
      return
   }

   SEQNO_RESET ; #<4133654>
   MOM_reset_sequence $mom_sequence_number $mom_sequence_increment $mom_sequence_frequency

   if { [info exists ptp_file_name] } {
      MOM_close_output_file $ptp_file_name
      MOM_start_of_program
      if { ![string compare $mom_sys_ptp_output "ON"] } {
         MOM_open_output_file $ptp_file_name
      }
   } else {
      MOM_start_of_program
   }

   PB_start_of_program
   set pb_start_of_program_flag 1
}


#=============================================================
proc MOM_machine_mode { } {
#=============================================================
  global pb_start_of_program_flag
  global mom_operation_name mom_sys_change_mach_operation_name

   set mom_sys_change_mach_operation_name $mom_operation_name

   if { $pb_start_of_program_flag == 0 } {
      PB_start_of_program
      set pb_start_of_program_flag 1
   }

  # For simple mill-turn
   if { [llength [info commands PB_machine_mode] ] } {
      if { [catch {PB_machine_mode} res] } {
         CATCH_WARNING "$res"
      }
   }
}


#=============================================================
proc PB_FORCE { option args } {
#=============================================================
   set adds [join $args]
   if { [info exists option] && [llength $adds] } {
      lappend cmd MOM_force
      lappend cmd $option
      lappend cmd [join $adds]
      eval [join $cmd]
   }
}


#=============================================================
proc PB_SET_RAPID_MOD { mod_list blk_list ADDR NEW_MOD_LIST } {
#=============================================================
  upvar $ADDR addr
  upvar $NEW_MOD_LIST new_mod_list
  global mom_cycle_spindle_axis traverse_axis1 traverse_axis2


   set new_mod_list [list]

   foreach mod $mod_list {
      switch $mod {
         "rapid1" {
            set elem $addr($traverse_axis1)
            if { [lsearch $blk_list $elem] >= 0 } {
               lappend new_mod_list $elem
            }
         }
         "rapid2" {
            set elem $addr($traverse_axis2)
            if { [lsearch $blk_list $elem] >= 0 } {
               lappend new_mod_list $elem
            }
         }
         "rapid3" {
            set elem $addr($mom_cycle_spindle_axis)
            if { [lsearch $blk_list $elem] >= 0 } {
               lappend new_mod_list $elem
            }
         }
         default {
            set elem $mod
            if { [lsearch $blk_list $elem] >= 0 } {
               lappend new_mod_list $elem
            }
         }
      }
   }
}


########################
# Redefine FEEDRATE_SET
########################
if { [llength [info commands ugpost_FEEDRATE_SET] ] } {
   rename ugpost_FEEDRATE_SET ""
}

if { [llength [info commands FEEDRATE_SET] ] } {
   rename FEEDRATE_SET ugpost_FEEDRATE_SET
} else {
   proc ugpost_FEEDRATE_SET {} {}
}


#=============================================================
proc FEEDRATE_SET { } {
#=============================================================
   if { [llength [info commands PB_CMD_kin_feedrate_set] ] } {
      PB_CMD_kin_feedrate_set
   } else {
      ugpost_FEEDRATE_SET
   }
}


############## EVENT HANDLING SECTION ################


#=============================================================
proc MOM_auxfun { } {
#=============================================================
   MOM_do_template auxfun
}


#=============================================================
proc MOM_bore { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE
   CYCLE_SET
}


#=============================================================
proc MOM_bore_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_cycle_group
  global mom_siemens_cycle_rff
  global mom_ude_siemens_cycle_group_end
  global mom_legend_group
  global mom_siemens_bore_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE85_Bore MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE85_Bore_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_bore_back { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE_BACK
   CYCLE_SET
}


#=============================================================
proc MOM_bore_back_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_cycle_group
  global mom_siemens_cycle_liftoff
  global mom_siemens_cycle_rpa
  global mom_siemens_cycle_rpo
  global mom_siemens_cycle_rpap
  global mom_ude_siemens_cycle_group_end
  global mom_legend_group
  global mom_siemens_bore_back_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE86 MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE86_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_bore_drag { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE_DRAG
   CYCLE_SET
}


#=============================================================
proc MOM_bore_drag_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_legend_group
  global mom_siemens_bore_drag_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      PB_call_macro CYCLE89 MCALL
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_bore_dwell { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE_DWELL
   CYCLE_SET
}


#=============================================================
proc MOM_bore_dwell_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE85_Bore_Dwell MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE85_Bore_Dwell_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_bore_manual { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE_MANUAL
   CYCLE_SET
}


#=============================================================
proc MOM_bore_manual_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_legend_group
  global mom_siemens_bore_manual
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      PB_call_macro CYCLE87 MCALL
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_bore_manual_dwell { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE_MANUAL_DWELL
   CYCLE_SET
}


#=============================================================
proc MOM_bore_manual_dwell_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      PB_call_macro CYCLE88 MCALL
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_bore_no_drag { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name BORE_NO_DRAG
   CYCLE_SET
}


#=============================================================
proc MOM_bore_no_drag_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_cycle_group
  global mom_siemens_cycle_rpa
  global mom_siemens_cycle_rpo
  global mom_siemens_cycle_rpap
  global mom_ude_siemens_cycle_group_end
  global mom_legend_group
  global mom_siemens_bore_nodrag_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE86 MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE86_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_circular_move { } {
#=============================================================

   ABORT_EVENT_CHECK

   CIRCLE_SET
   if { [PB_CMD__check_block_trafoof_mode] } {
      MOM_force Once X Y I J
      MOM_do_template circular_move
   }
   if { [PB_CMD__check_block_traori_mode] } {
      MOM_force Once X Y I J
      MOM_do_template circular_move_1
   }
}


#=============================================================
proc MOM_clamp { } {
#=============================================================
   global mom_clamp_axis
   global mom_clamp_status
   global mom_clamp_text
   PB_CMD_MOM_clamp
}


#=============================================================
proc MOM_coolant_off { } {
#=============================================================
   COOLANT_SET
   MOM_do_template coolant_off
}


#=============================================================
proc MOM_coolant_on { } {
#=============================================================
   COOLANT_SET
   MOM_do_template coolant_on
}


#=============================================================
proc MOM_cutcom_on { } {
#=============================================================
   CUTCOM_SET

   global mom_cutcom_adjust_register
   set cutcom_register_min 1
   set cutcom_register_max 99
   if { [info exists mom_cutcom_adjust_register] } {
      if { $mom_cutcom_adjust_register < $cutcom_register_min ||\
           $mom_cutcom_adjust_register > $cutcom_register_max } {
         CATCH_WARNING "CUTCOM register $mom_cutcom_adjust_register must be within the range between 1 and 99"
      }
   }
}


#=============================================================
proc MOM_cutcom_off { } {
#=============================================================
   CUTCOM_SET
   MOM_do_template cutcom_off
}


#=============================================================
proc MOM_cycle_off { } {
#=============================================================
   PB_call_macro MCALL
   PB_CMD_cancel_cycle
}


#=============================================================
proc MOM_cycle_plane_change { } {
#=============================================================
  global cycle_init_flag
  global mom_cycle_tool_axis_change
  global mom_cycle_clearance_plane_change

   set cycle_init_flag TRUE
   if { [PB_CMD__check_block_cycle_plane_change] } {
      PB_call_macro MCALL
   }
   PB_CMD_rotate_cycle_coordinate
   PB_CMD_set_cycle_plane_change
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_delay { } {
#=============================================================
   PB_DELAY_TIME_SET
   if { [PB_CMD__check_block_delay_seconds] } {
      MOM_force Once G dwell
      MOM_do_template delay
   }
   if { [PB_CMD__check_block_delay_revolutions] } {
      MOM_force Once G delay_revolution
      MOM_do_template delay_1
   }
}


#=============================================================
proc MOM_dnc_header { } {
#=============================================================
   global mom_dnc_machine_name
   global mom_dnc_program_name
   global mom_dnc_data_type
   global mom_dnc_version_number
   global mom_dnc_release_number
   global mom_dnc_user_name
   PB_CMD_MOM_dnc_header
}


#=============================================================
proc MOM_drill { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name DRILL
   CYCLE_SET
}


#=============================================================
proc MOM_drill_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_legend_group
  global mom_siemens_drill_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE81 MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE81_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_drill_break_chip { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name DRILL_BREAK_CHIP
   CYCLE_SET
}


#=============================================================
proc MOM_drill_break_chip_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_cycle_group
  global mom_siemens_cycle_o_dtd_mode
  global mom_siemens_cycle_o_dtd
  global mom_siemens_cycle_frf
  global mom_siemens_cycle_o_vrt
  global mom_ude_siemens_cycle_group_end
  global mom_legend_group
  global mom_siemens_drill_breakchip_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE83_Break_Chip MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE83_Break_Chip_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_drill_deep { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name DRILL_DEEP
   CYCLE_SET
}


#=============================================================
proc MOM_drill_deep_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_cycle_group
  global mom_siemens_cycle_dts_mode
  global mom_siemens_cycle_dts
  global mom_siemens_cycle_o_dtd_mode
  global mom_siemens_cycle_o_dtd
  global mom_siemens_cycle_frf
  global mom_siemens_cycle_o_dis1
  global mom_ude_siemens_cycle_group_end
  global mom_legend_group
  global mom_siemens_drill_deep_map
  global mom_legend_group_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE83_Deep MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE83_Deep_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_drill_dwell { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name DRILL_DWELL
   CYCLE_SET
}


#=============================================================
proc MOM_drill_dwell_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_CYCLE_powerline] } {
         PB_call_macro CYCLE82 MCALL
      }
      if { [PB_CMD__check_block_CYCLE_solutionline] } {
         PB_call_macro CYCLE82_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_drill_text { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name DRILL_TEXT
   CYCLE_SET
}


#=============================================================
proc MOM_drill_text_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

   PB_CMD_drill_text_move
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_end_of_path { } {
#=============================================================
  global mom_sys_add_cutting_time mom_sys_add_non_cutting_time
  global mom_cutting_time mom_machine_time

  # Accumulated time should be in minutes.
   set mom_cutting_time [expr $mom_cutting_time + $mom_sys_add_cutting_time]
   set mom_machine_time [expr $mom_machine_time + $mom_sys_add_cutting_time + $mom_sys_add_non_cutting_time]
   MOM_reload_variable mom_cutting_time
   MOM_reload_variable mom_machine_time

   if [CMD_EXIST PB_CMD_kin_end_of_path] {
      PB_CMD_kin_end_of_path
   }

   MOM_output_literal ";End of Path"
   if { [PB_CMD__check_block_reset_trans] } {
      MOM_do_template reset_trans
   }
   if { [PB_CMD__check_block_reset_cycle800] } {
      MOM_do_template reset_cycle800
   }
   if { [PB_CMD__check_block_reset_traori] } {
      MOM_do_template trafoof
   }
   if { [PB_CMD__check_block_return_to_reference_point] } {
      MOM_force Once Text G_motion Text D
      MOM_do_template tool_change_return_home_Z
   }
   if { [PB_CMD__check_block_return_to_reference_point] } {
      MOM_force Once Text G_motion Text D
      MOM_do_template tool_change_return_home
   }
   if { [PB_CMD__check_block_reset_cycle832] } {
      MOM_do_template reset_cycle832
   }
   MOM_do_template spindle_off
   PB_CMD_reset_control_mode
   PB_CMD_end_of_extcall_operation
   PB_CMD_reset_Sinumerik_setting
   global mom_sys_in_operation
   set mom_sys_in_operation 0
}


#=============================================================
proc MOM_end_of_subop_path { } {
#=============================================================
}


#=============================================================
proc MOM_first_move { } {
#=============================================================
  global mom_feed_rate mom_feed_rate_per_rev mom_motion_type
  global mom_kin_max_fpm mom_motion_event
   COOLANT_SET ; CUTCOM_SET ; SPINDLE_SET ; RAPID_SET


  # Configure turbo output settings
   if { [CMD_EXIST CONFIG_TURBO_OUTPUT] } {
      CONFIG_TURBO_OUTPUT
   }

   PB_CMD_detect_operation_type
   PB_CMD_define_feed_variable_value
   MOM_do_template msg_method
   MOM_do_template g17
   MOM_output_literal ";First Move"
   if { [PB_CMD__check_block_CYCLE832] } {
      PB_call_macro CYCLE832_v7
   }
   if { [PB_CMD__check_block_rotation_axes] } {
      MOM_force Once G_motion fourth_axis fifth_axis
      MOM_do_template rotation_axes
   }
   if { [PB_CMD__check_block_ORIRESET] } {
      PB_call_macro ORIRESET
   }
   MOM_do_template traori_trafoof
   MOM_force Once G_offset
   MOM_do_template fixture_offset
   PB_CMD_output_trans_arot
   if { [PB_CMD__check_block_CYCLE800] } {
      PB_call_macro CYCLE800_sl
   }
   PB_CMD_move_force_addresses
   PB_CMD_coolant_on
   catch { MOM_$mom_motion_event }
}


#=============================================================
proc MOM_first_tool { } {
#=============================================================
  global mom_sys_first_tool_handled

  # First tool only gets handled once
   if { [info exists mom_sys_first_tool_handled] } {
      MOM_tool_change
      return
   }

   set mom_sys_first_tool_handled 1

   MOM_do_template trafoof
   MOM_force Once Text G_motion Text D
   MOM_do_template tool_change_return_home_Z
   MOM_force Once Text G_motion Text D
   MOM_do_template tool_change_return_home
   MOM_output_literal ";First Tool"
   MOM_force Once T
   MOM_do_template tool_change
   MOM_force Once M
   MOM_do_template tool_change_1
   MOM_do_template msg_method
   MOM_do_template trafoof
   MOM_force Once Text G_motion Text D
   MOM_do_template tool_change_return_home_Z
   MOM_force Once Text G_motion Text D
   MOM_do_template tool_change_return_home
}


#=============================================================
proc MOM_from_move { } {
#=============================================================
  global mom_feed_rate mom_feed_rate_per_rev  mom_motion_type mom_kin_max_fpm
   COOLANT_SET ; CUTCOM_SET ; SPINDLE_SET ; RAPID_SET

}


#=============================================================
proc MOM_gohome_move { } {
#=============================================================
   MOM_rapid_move
}


#=============================================================
proc MOM_head { } {
#=============================================================
   global mom_head_name
}


#=============================================================
proc MOM_Head { } {
#=============================================================
   MOM_head
}


#=============================================================
proc MOM_HEAD { } {
#=============================================================
   MOM_head
}


#=============================================================
proc MOM_helix_move { } {
#=============================================================
   PB_CMD_set_helix_move
   if { [PB_CMD__check_block_trafoof_mode] } {
      MOM_force Once helix_turn
      MOM_do_template helix_move
   }
   if { [PB_CMD__check_block_traori_mode] } {
      MOM_force Once helix_turn
      MOM_do_template helix_move_1
   }
}


#=============================================================
proc MOM_high_speed_setting { } {
#=============================================================
   global mom_ude_siemens_tolerance_group
   global mom_siemens_tol
   global mom_siemens_rotary_tol
   global mom_ude_siemens_tolerance_group_end
   global mom_ude_siemens_csf_group
   global mom_siemens_compressor
   global mom_siemens_smoothing
   global mom_siemens_feedforward
   global mom_siemens_top_surface_smooth
   global mom_ude_siemens_csf_group_end
   global mom_ude_siemens_hsm
   global mom_siemens_5axis_mode
   global mom_ude_siemens_hsm_end
   global mom_ude_siemens_5axis_group
   global mom_siemens_ori_def
   global mom_ude_siemens_5axis_group_end
   global mom_ude_siemens_feedrate_group
   global mom_siemens_feed_definition
   global mom_ude_siemens_feedrate_group_end
   PB_CMD_MOM_sinumerik_840D
}


#=============================================================
proc MOM_initial_move { } {
#=============================================================
  global mom_feed_rate mom_feed_rate_per_rev mom_motion_type
  global mom_kin_max_fpm mom_motion_event
   COOLANT_SET ; CUTCOM_SET ; SPINDLE_SET ; RAPID_SET


  # Configure turbo output settings
   if { [CMD_EXIST CONFIG_TURBO_OUTPUT] } {
      CONFIG_TURBO_OUTPUT
   }

   PB_CMD_define_feed_variable_value
   PB_CMD_detect_operation_type
   MOM_do_template g17
   MOM_output_literal ";Initial Move"
   if { [PB_CMD__check_block_rotation_axes] } {
      MOM_force Once G_motion fourth_axis fifth_axis
      MOM_do_template rotation_axes
   }
   if { [PB_CMD__check_block_ORIRESET] } {
      PB_call_macro ORIRESET
   }
   if { [PB_CMD__check_block_CYCLE832] } {
      PB_call_macro CYCLE832_v7
   }
   MOM_force Once transf
   MOM_do_template traori_trafoof
   MOM_force Once G_offset
   MOM_do_template fixture_offset
   PB_CMD_output_trans_arot
   if { [PB_CMD__check_block_CYCLE800] } {
      PB_call_macro CYCLE800_sl
   }
   PB_CMD_move_force_addresses
   PB_CMD_coolant_on

  global mom_programmed_feed_rate
   if { [EQ_is_equal $mom_programmed_feed_rate 0] } {
      MOM_rapid_move
   } else {
      MOM_linear_move
   }
}


#=============================================================
proc MOM_insert { } {
#=============================================================
   global mom_Instruction
   PB_CMD_MOM_insert
}


#=============================================================
proc MOM_instance_operation_handler { } {
#=============================================================
   global mom_handle_instanced_operations
}


#=============================================================
proc MOM_length_compensation { } {
#=============================================================
   TOOL_SET MOM_length_compensation
}


#=============================================================
proc MOM_linear_move { } {
#=============================================================
   ABORT_EVENT_CHECK

   HANDLE_FIRST_LINEAR_MOVE

   if { [PB_CMD__check_block_rotary] } {
      MOM_do_template linear_move
   }
   if { [PB_CMD__check_block_traori_rotary] } {
      MOM_do_template linear_move_2
   }
   if { [PB_CMD__check_block_traori_vector] } {
      MOM_do_template linear_move_1
   }
}


#=============================================================
proc MOM_load_tool { } {
#=============================================================
   global mom_tool_change_type mom_manual_tool_change
   global mom_tool_number mom_next_tool_number
   global mom_sys_tool_number_max mom_sys_tool_number_min

   if { $mom_tool_number < $mom_sys_tool_number_min || \
        $mom_tool_number > $mom_sys_tool_number_max } {

      global mom_warning_info
      set mom_warning_info "Tool number to be output ($mom_tool_number) exceeds limits of\
                            ($mom_sys_tool_number_min/$mom_sys_tool_number_max)"
      MOM_catch_warning
   }

}


#=============================================================
proc MOM_lock_axis { } {
#=============================================================
   global mom_lock_axis
   global mom_lock_axis_plane
   global mom_lock_axis_value
   PB_CMD_MOM_lock_axis
}


#=============================================================
proc MOM_nurbs_move { } {
#=============================================================
   PB_CMD_nurbs_spline
}


#=============================================================
proc MOM_operator_message { } {
#=============================================================
   global mom_operator_message
   PB_CMD_MOM_operator_message
}


#=============================================================
proc MOM_opskip_off { } {
#=============================================================
   global mom_opskip_text
   PB_CMD_MOM_opskip_off
}


#=============================================================
proc MOM_opskip_on { } {
#=============================================================
   global mom_opskip_text
   PB_CMD_MOM_opskip_on
}


#=============================================================
proc MOM_opstop { } {
#=============================================================
   MOM_do_template opstop
}


#=============================================================
proc MOM_origin { } {
#=============================================================
   global mom_X
   global mom_Y
   global mom_Z
   global mom_origin_text
}


#=============================================================
proc MOM_pprint { } {
#=============================================================
   global mom_pprint
   PB_CMD_MOM_pprint
}


#=============================================================
proc MOM_prefun { } {
#=============================================================
   MOM_do_template prefun
}


#=============================================================
proc MOM_program_control { } {
#=============================================================
   global mom_siemens_program_control
   PB_CMD_MOM_program_control
}


#=============================================================
proc MOM_rapid_move { } {
#=============================================================
  global rapid_spindle_inhibit rapid_traverse_inhibit
  global spindle_first is_from
  global mom_cycle_spindle_axis traverse_axis1 traverse_axis2
  global mom_motion_event

   ABORT_EVENT_CHECK

   set spindle_first NONE

   set aa(0) X ; set aa(1) Y ; set aa(2) Z
   RAPID_SET
   PB_CMD_rotate_rapid_coordinate
   if { [PB_CMD__check_block_rotary] } {
      MOM_do_template rapid_traverse
   }
   if { [PB_CMD__check_block_traori_rotary] } {
      MOM_do_template rapid_move
   }
   if { [PB_CMD__check_block_traori_vector] } {
      MOM_do_template rapid_move_1
   }
}


#=============================================================
proc MOM_rotate { } {
#=============================================================
   global mom_rotate_axis_type
   global mom_rotation_mode
   global mom_rotation_direction
   global mom_rotation_angle
   global mom_rotation_reference_mode
   global mom_rotation_text
   PB_CMD_MOM_rotate
}


#=============================================================
proc MOM_select_head { } {
#=============================================================
   global mom_head_type
   global mom_head_text
}


#=============================================================
proc MOM_sequence_number { } {
#=============================================================
   global mom_sequence_mode
   global mom_sequence_number
   global mom_sequence_increment
   global mom_sequence_frequency
   global mom_sequence_text
   SEQNO_SET
}


#=============================================================
proc MOM_set_axis { } {
#=============================================================
   global mom_axis_position
   global mom_axis_position_value
}


#=============================================================
proc MOM_set_modes { } {
#=============================================================
   MODES_SET
}


#=============================================================
proc MOM_set_polar { } {
#=============================================================
   global mom_coordinate_output_mode
}


#=============================================================
proc MOM_spindle_rpm { } {
#=============================================================
   SPINDLE_SET
   MOM_force Once S M_spindle
   MOM_do_template spindle_rpm
}


#=============================================================
proc MOM_spindle_off { } {
#=============================================================
   PB_CMD_spindle_off
   MOM_do_template spindle_off
}


#=============================================================
proc MOM_start_of_path { } {
#=============================================================
  global mom_sys_in_operation
   set mom_sys_in_operation 1

  global first_linear_move ; set first_linear_move 0
   TOOL_SET MOM_start_of_path

  global mom_sys_add_cutting_time mom_sys_add_non_cutting_time
  global mom_sys_machine_time mom_machine_time
   set mom_sys_add_cutting_time 0.0
   set mom_sys_add_non_cutting_time 0.0
   set mom_sys_machine_time $mom_machine_time

   if [CMD_EXIST PB_CMD_kin_start_of_path] {
      PB_CMD_kin_start_of_path
   }

   PB_CMD_start_of_extcall_operation
   PB_CMD_output_start_program
   PB_CMD_reset_sinumerik_setting_in_group
   PB_CMD_set_fixture_offset
   MOM_output_literal ";Start of Path"
   MOM_do_template start_of_path_2
   MOM_do_template home_position
   MOM_do_template home_position_rotary
   MOM_output_literal "; "
   global mom_operation_name
   MOM_output_literal ";Operation : $mom_operation_name"
   MOM_output_literal "; "
   PB_CMD_start_of_operation_force_addresses
}


#=============================================================
proc MOM_start_of_subop_path { } {
#=============================================================
}


#=============================================================
proc MOM_stop { } {
#=============================================================
   MOM_do_template stop
}


#=============================================================
proc MOM_tap { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name TAP
   CYCLE_SET
}


#=============================================================
proc MOM_tap_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_thread_group
  global mom_siemens_cycle_mpit
  global mom_siemens_cycle_o_ptab
  global mom_ude_siemens_thread_group_end
  global mom_legend_rigid_group
  global mom_siemens_rigid_tap_map
  global mom_legend_rigid_group_end
  global mom_ude_siemens_other_group
  global mom_siemens_cycle_sdac
  global mom_siemens_cycle_o_techno
  global mom_ude_siemens_other_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_tap_type_powerline] } {
         PB_call_macro CYCLE84 MCALL
      }
      if { [PB_CMD__check_block_tap_type_solutionline] } {
         PB_call_macro CYCLE84_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_tap_break_chip { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name TAP_BREAK_CHIP
   CYCLE_SET
}


#=============================================================
proc MOM_tap_break_chip_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_thread_group
  global mom_siemens_cycle_mpit
  global mom_siemens_cycle_o_ptab
  global mom_ude_siemens_thread_group_end
  global mom_ude_siemens_rigid_group
  global mom_cycle_step_clearance
  global mom_ude_siemens_rigid_group_end
  global mom_legend_rigid_group
  global mom_siemens_rigid_tap_map
  global mom_legend_rigid_group_end
  global mom_ude_siemens_other_group
  global mom_siemens_cycle_sdac
  global mom_siemens_cycle_o_techno
  global mom_ude_siemens_other_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_tap_type_powerline] } {
         PB_call_macro CYCLE84 MCALL
      }
      if { [PB_CMD__check_block_tap_type_solutionline] } {
         PB_call_macro CYCLE84_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_tap_deep { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name TAP_DEEP
   CYCLE_SET
}


#=============================================================
proc MOM_tap_deep_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_thread_group
  global mom_siemens_cycle_mpit
  global mom_siemens_cycle_o_ptab
  global mom_ude_siemens_thread_group_end
  global mom_legend_rigid_group
  global mom_siemens_rigid_tap_map
  global mom_legend_rigid_group_end
  global mom_ude_siemens_other_group
  global mom_siemens_cycle_sdac
  global mom_siemens_cycle_o_techno
  global mom_ude_siemens_other_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_tap_type_powerline] } {
         PB_call_macro CYCLE84 MCALL
      }
      if { [PB_CMD__check_block_tap_type_solutionline] } {
         PB_call_macro CYCLE84_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_tap_float { } {
#=============================================================
  global cycle_name
  global cycle_init_flag

   set cycle_init_flag TRUE
   set cycle_name TAP_FLOAT
   CYCLE_SET
}


#=============================================================
proc MOM_tap_float_move { } {
#=============================================================
   global cycle_init_flag


   ABORT_EVENT_CHECK

  global mom_ude_siemens_thread_group
  global mom_siemens_cycle_mpit
  global mom_siemens_cycle_o_ptab
  global mom_ude_siemens_thread_group_end
  global mom_ude_siemens_float_group
  global mom_siemens_cycle_sdr
  global mom_siemens_cycle_enc
  global mom_ude_siemens_float_group_end
  global mom_legend_float_group
  global mom_siemens_float_tap_map
  global mom_legend_float_group_end
  global mom_ude_siemens_other_group
  global mom_siemens_cycle_sdac
  global mom_siemens_cycle_o_techno
  global mom_ude_siemens_other_end

   if { ![string compare $cycle_init_flag "TRUE"] } {
      PB_CMD_rotate_cycle_coordinate
      PB_CMD_init_cycle_parameters
      if { [PB_CMD__check_block_tap_float_powerline] } {
         PB_call_macro CYCLE840 MCALL
      }
      if { [PB_CMD__check_block_tap_float_solutionline] } {
         PB_call_macro CYCLE840_sl MCALL
      }
   }

   if { [llength [info commands PB_CMD_config_cycle_start]] } {
      PB_CMD_config_cycle_start
   }
   MOM_do_template cycle_parameters_1
   set cycle_init_flag FALSE
}


#=============================================================
proc MOM_text { } {
#=============================================================
   global mom_user_defined_text
   PB_CMD_MOM_text
}


#=============================================================
proc MOM_tool_change { } {
#=============================================================
   global mom_tool_change_type mom_manual_tool_change
   global mom_tool_number mom_next_tool_number
   global mom_sys_tool_number_max mom_sys_tool_number_min

   if { $mom_tool_number < $mom_sys_tool_number_min || \
        $mom_tool_number > $mom_sys_tool_number_max } {

      global mom_warning_info
      set mom_warning_info "Tool number to be output ($mom_tool_number) exceeds limits of\
                            ($mom_sys_tool_number_min/$mom_sys_tool_number_max)"
      MOM_catch_warning
   }

   if { [info exists mom_tool_change_type] } {
      switch $mom_tool_change_type {
         MANUAL { PB_manual_tool_change }
         AUTO   { PB_auto_tool_change }
      }
   } elseif { [info exists mom_manual_tool_change] } {
      if { ![string compare $mom_manual_tool_change "TRUE"] } {
         PB_manual_tool_change
      }
   }
}


#=============================================================
proc MOM_tool_path_type { } {
#=============================================================
   global mom_ude_5axis_tool_path
}


#=============================================================
proc MOM_tool_preselect { } {
#=============================================================
   global mom_tool_preselect_number mom_tool_number mom_next_tool_number
   global mom_sys_tool_number_max mom_sys_tool_number_min

   if { [info exists mom_tool_preselect_number] } {
      if { $mom_tool_preselect_number < $mom_sys_tool_number_min || \
           $mom_tool_preselect_number > $mom_sys_tool_number_max } {

         global mom_warning_info
         set mom_warning_info "Preselected Tool number ($mom_tool_preselect_number) exceeds limits of\
                               ($mom_sys_tool_number_min/$mom_sys_tool_number_max)"
         MOM_catch_warning
      }

      set mom_next_tool_number $mom_tool_preselect_number
   }

   MOM_do_template tool_preselect
}


#=============================================================
proc MOM_zero { } {
#=============================================================
   global mom_work_coordinate_number
}


#=============================================================
proc PB_approach_move { } {
#=============================================================
   PB_CMD_output_motion_message
}


#=============================================================
proc PB_auto_tool_change { } {
#=============================================================
   global mom_tool_number mom_next_tool_number
   if { ![info exists mom_next_tool_number] } {
      set mom_next_tool_number $mom_tool_number
   }

   MOM_output_literal ";Tool Change"
   MOM_force Once T
   MOM_do_template tool_change
   MOM_force Once M
   MOM_do_template tool_change_1
   MOM_do_template msg_method
   MOM_do_template trafoof
   MOM_force Once Text G_motion Text D
   MOM_do_template tool_change_return_home_Z
   MOM_force Once Text G_motion Text D
   MOM_do_template tool_change_return_home
}


#=============================================================
proc PB_engage_move { } {
#=============================================================
   PB_CMD_output_motion_message
}


#=============================================================
proc PB_feedrates { } {
#=============================================================
}


#=============================================================
proc PB_first_cut { } {
#=============================================================
}


#=============================================================
proc PB_first_linear_move { } {
#=============================================================
  global mom_sys_first_linear_move

  # Set this variable to signal 1st linear move has been handled.
   set mom_sys_first_linear_move 1

}


#=============================================================
proc PB_manual_tool_change { } {
#=============================================================
   PB_CMD_move_force_addresses
   MOM_do_template stop
}


#=============================================================
proc PB_retract_move { } {
#=============================================================
   PB_CMD_output_motion_message
}


#=============================================================
proc PB_return_move { } {
#=============================================================
   PB_CMD_output_motion_message
}


#=============================================================
proc PB_start_of_program { } {
#=============================================================

   if [CMD_EXIST PB_CMD_kin_start_of_program] {
      PB_CMD_kin_start_of_program
   }

   PB_CMD_set_Sinumerik_version
   PB_CMD_set_Sinumerik_default_setting
   MOM_set_seq_off
   PB_CMD_init_ini_files
   PB_CMD_init_variables
   PB_CMD_init_helix
   PB_CMD_init_nurbs
   PB_CMD_init_high_speed_setting
   PB_CMD_init_extcall
   PB_CMD_fix_RAPID_SET
   PB_CMD_spindle_orient
   PB_CMD_uplevel_ROTARY_AXIS_RETRACT
   MOM_set_seq_on

   if [CMD_EXIST PB_CMD_kin_start_of_program_2] {
      PB_CMD_kin_start_of_program_2
   }
}


#=============================================================
proc PB_user_def_axis_limit_action { args } {
#=============================================================
}


#=============================================================
proc PB_CMD_FEEDRATE_NUMBER { } {
#=============================================================
#
#  This custom command is called by FEEDRATE_SET;
#  it allows you to modify the feed rate number after being
#  calculated by the system.
#
#<03-13-08 gsl> - Added use of frn factor (defined in ugpost_base.tcl) & max frn here
#                 Use global frn factor (defined as 1.0 in ugpost_base.tcl) or
#                 define a custom one here

  global mom_feed_rate_number
  global mom_sys_frn_factor
  global mom_kin_max_frn

 # set mom_sys_frn_factor 1.0

  set f 0.0

  if { [info exists mom_feed_rate_number] } {
    set f [expr $mom_feed_rate_number * $mom_sys_frn_factor]
    if { [EQ_is_gt $f $mom_kin_max_frn] } {
      set f $mom_kin_max_frn
    }
  }

return $f
}


#=============================================================
proc PB_CMD_FEEDRATE_SET { } {
#=============================================================
# This custom command will be executed automatically in
# MOM_before_motion event handler.
# Important! Don't change following sentence unless you know what are you doing.
  global mom_sinumerik_feed
  global feed
  set mom_sinumerik_feed $feed

# Define feedrate in variables
  global mom_siemens_feed_definition
  global mom_motion_type
  if { [info exists mom_siemens_feed_definition] && $mom_siemens_feed_definition == "ON" } {
     if { $mom_motion_type != "CYCLE" } {
        PB_CMD_define_feedrate_format
     }
  }
}


#=============================================================
proc PB_CMD_MOM_clamp { } {
#=============================================================
# Default handler for UDE MOM_clamp
# - Do not attach it to any event!
#

  global mom_clamp_axis mom_clamp_status mom_sys_auto_clamp

  if { ![string compare "AUTO" $mom_clamp_axis] } {

    if { ![string compare "ON" $mom_clamp_status] } {
      set mom_sys_auto_clamp "ON"
    } elseif { ![string compare "OFF" $mom_clamp_status] } {
      set mom_sys_auto_clamp "OFF"
    }

  } else {

    CATCH_WARNING "$mom_clamp_axis not handled in current implementation!"
  }
}


#=============================================================
proc PB_CMD_MOM_dnc_header { } {
#=============================================================

  global mom_dnc_machine_name
  global mom_dnc_program_name
  global mom_dnc_data_type
  global mom_dnc_version_number
  global mom_dnc_release_number
  global mom_dnc_user_name
  global mom_logname
  global mom_oper_program
  global env
  global mom_command_status
  global mom_sys_in_operation
  global mom_operation_name
  global mom_group_name

  if { [info exists mom_sys_in_operation] && $mom_sys_in_operation == 1 } {
    CATCH_WARNING "DNC Header event should not be assigned to an operation ($mom_operation_name)."
return
  }

  if { ![info exists mom_group_name] } {
return
  }

  if { [info exists env(COMPUTERNAME)] } {
    set computer $env(COMPUTERNAME)
  } else {
    set computer ""
  }

  if { ![info exists mom_dnc_machine_name] || [string trim $mom_dnc_machine_name] == "" } {
    set mom_dnc_machine_name $computer
  }

  if { ![info exists mom_dnc_user_name] || [string trim $mom_dnc_user_name] == "" } {
    set mom_dnc_user_name $mom_logname
  }

  if { ![info exists mom_dnc_program_name] || [string trim $mom_dnc_program_name] == "" } {
    set mom_dnc_program_name $mom_oper_program
  }

  if { ![info exists mom_dnc_data_type] || [string trim $mom_dnc_data_type] == "" } {
    set mom_dnc_data_type "MPF"
  }

  if { ![info exists mom_dnc_version_number] || [string trim $mom_dnc_version_number] == "" } {
    set mom_dnc_version_number 1
  }

  if { ![info exists mom_dnc_release_number] || [string trim $mom_dnc_release_number] == "" } {
    set mom_dnc_release_number 1
  }

  MOM_set_seq_off
  MOM_output_literal ";HEADER-START"
  MOM_output_literal ";NODENAME=$mom_dnc_machine_name"
  MOM_output_literal ";NCDATANAME=$mom_dnc_program_name"
  MOM_output_literal ";NCDATATYPE=$mom_dnc_data_type"
  MOM_output_literal ";VERSION=$mom_dnc_version_number"
  MOM_output_literal ";RELEASEID=$mom_dnc_release_number"
  MOM_output_literal ";DEVELNAME=$mom_dnc_user_name"
  MOM_output_literal ";HEADER-END"
  MOM_output_literal ";NC-START"
  MOM_output_literal "%"
  MOM_set_seq_on
}


#=============================================================
proc PB_CMD_MOM_insert { } {
#=============================================================
# Default handler for UDE MOM_insert
# - Do not attach it to any event!
#
# This procedure is executed when the Insert command is activated.
#
   global mom_Instruction
   MOM_output_literal "$mom_Instruction"
}


#=============================================================
proc PB_CMD_MOM_lock_axis { } {
#=============================================================
# Default handler for UDE MOM_lock_axis
# - Do not attach it to any event!
#
# 18-Sep-2015 ljt - reset positive_radius, fix PR6961328

  global mom_sys_lock_value mom_sys_lock_plane
  global mom_sys_lock_axis mom_sys_lock_status

   set status [SET_LOCK axis plane value]
   if { ![string compare "error" $status] } {
      MOM_catch_warning
      set mom_sys_lock_status OFF
   } else {
      set mom_sys_lock_status $status
      if { [string compare "OFF" $status] } {
         set mom_sys_lock_axis $axis
         set mom_sys_lock_plane $plane
         set mom_sys_lock_value $value

         LOCK_AXIS_INITIALIZE
      } else {
         global positive_radius

         set positive_radius "0"
      }
   }
}


#=============================================================
proc PB_CMD_MOM_operator_message { } {
#=============================================================
# Default handler for UDE MOM_operator_message
# - Do not attach it to any event!
#
# This procedure is executed when the Operator Message command is activated.
# 08-21-2015 szl - Fix PR7471332:Parse error during machine code simulation if the UDE Operator Message is added.
#
   global mom_operator_message mom_operator_message_defined
   global mom_operator_message_status
   global ptp_file_name group_output_file mom_group_name
   global mom_sys_commentary_output
   global mom_sys_control_in
   global mom_sys_control_out
   global mom_sys_ptp_output
   global mom_post_in_simulation

   if { [info exists mom_operator_message_defined] } {
      if { $mom_operator_message_defined == 0 } {
return
      }
   }

   if { [string compare "ON" $mom_operator_message] && [string compare "OFF" $mom_operator_message] } {

      set brac_start [string first \( $mom_operator_message]
      set brac_end   [string last \) $mom_operator_message]

      if { $brac_start != 0 } {
         set text_string "("
      } else {
         set text_string ""
      }

      append text_string $mom_operator_message

      if { $brac_end != [expr [string length $mom_operator_message] - 1] } {
         append text_string ")"
      }

      MOM_close_output_file   $ptp_file_name

      if { [info exists mom_group_name] } {
         if { [info exists group_output_file($mom_group_name)] } {
            MOM_close_output_file $group_output_file($mom_group_name)
         }
      }

      MOM_suppress once N

      if { ![info exists mom_post_in_simulation] || $mom_post_in_simulation == 0 } {
                MOM_output_literal $text_string
      }

      if { ![string compare "ON" $mom_sys_ptp_output] } {
         MOM_open_output_file    $ptp_file_name
      }

      if { [info exists mom_group_name] } {
         if { [info exists group_output_file($mom_group_name)] } {
            MOM_open_output_file $group_output_file($mom_group_name)
         }
      }

      set need_commentary $mom_sys_commentary_output
      set mom_sys_commentary_output OFF
      regsub -all {[)]} $text_string $mom_sys_control_in text_string
      regsub -all {[(]} $text_string $mom_sys_control_out text_string

      MOM_output_literal $text_string

      set mom_sys_commentary_output $need_commentary

   } else {
      set mom_operator_message_status $mom_operator_message
   }
}


#=============================================================
proc PB_CMD_MOM_opskip_off { } {
#=============================================================
# Default handler for UDE MOM_opskip_off
# - Do not attach it to any event!
#
# This procedure is executed when the Optional skip command is activated.
#
   global mom_sys_opskip_block_leader
   MOM_set_line_leader off  $mom_sys_opskip_block_leader
}


#=============================================================
proc PB_CMD_MOM_opskip_on { } {
#=============================================================
# Default handler for UDE MOM_opskip_on
# - Do not attach it to any event!
#
# This procedure is executed when the Optional skip command is activated.
#
   global mom_sys_opskip_block_leader
   MOM_set_line_leader always  $mom_sys_opskip_block_leader
}


#=============================================================
proc PB_CMD_MOM_pprint { } {
#=============================================================
# Default handler for UDE MOM_pprint
# - Do not attach it to any event!
#
# This procedure is executed when the PPrint command is activated.
#
   global mom_pprint_defined

   if { [info exists mom_pprint_defined] } {
      if { $mom_pprint_defined == 0 } {
return
      }
   }

   PPRINT_OUTPUT
}


#=============================================================
proc PB_CMD_MOM_program_control { } {
#=============================================================
  global mom_group_name mom_siemens_program_control
  global mom_sys_in_operation
  global mom_sys_ptp_output ptp_file_name

  if { [info exists mom_sys_in_operation] && $mom_sys_in_operation == 1 } {
    if { [string match "TRUE" $mom_siemens_program_control] } {
      set mom_siemens_program_control "FALSE"
    }

    global mom_operation_name
    CATCH_WARNING "Sinumerik Program Control event should not be assigned to an operatrion ($mom_operation_name)."

return
  }

  if { ![string match "ON" $mom_sys_ptp_output] || ![info exists ptp_file_name] } {
return
  }

  if { [string match "TRUE" $mom_siemens_program_control] } {
    if { ![info exists mom_group_name] } {
       set mom_siemens_program_control "FALSE"
return
    }
    MOM_set_seq_off
    MOM_output_literal ";Main program"
    MOM_set_seq_on
    MOM_close_output_file $ptp_file_name
  }
}


#=============================================================
proc PB_CMD_MOM_rotate { } {
#=============================================================
# Default handler for UDE MOM_rotate
# - Do not attach it to any event!
#
# This command handles a Rotate UDE.
#
# Key parameters set in UDE -
#   mom_rotate_axis_type        :  [ AAXIS | BAXIS   | CAXIS    | HEAD | TABLE | FOURTH_AXIS | FIFTH_AXIS ]
#   mom_rotation_mode           :  [ NONE  | ATANGLE | ABSOLUTE | INCREMENTAL ]
#   mom_rotation_direction      :  [ NONE  | CLW     | CCLW ]
#   mom_rotation_angle          :  Specified angle
#   mom_rotation_reference_mode :  [ ON    | OFF ]
#
   PB_CMD_kin__MOM_rotate
}


#=============================================================
proc PB_CMD_MOM_sinumerik_840D { } {
#=============================================================
# This command is the Sinumerik 840D UDE handler.
#
# The user can use Sinumerik 840 UDE to set Sinumerik 840D advanced features.
#
# 23-Dec-2016 shuai - CYCLE832 enhancement.
#

  global mom_output_unit
  global mom_part_unit
  global mom_siemens_tol
  global mom_siemens_tol_status
  global mom_siemens_tol_defined

  # Set the tolerance.
  if {[info exists mom_siemens_tol_defined] && $mom_siemens_tol_defined == 1} {

     if {![string match $mom_part_unit $mom_output_unit] } {

        switch $mom_output_unit {

           IN {set mom_siemens_tol [expr $mom_siemens_tol/25.4]}
           MM {set mom_siemens_tol [expr $mom_siemens_tol*25.4]}
        }
     }

     set mom_siemens_tol [format "%.6f" $mom_siemens_tol]
     set mom_siemens_tol_status "User"

  } else {

     # <lili 2013-06-20> Add following line to reset tolerance status
     set mom_siemens_tol_status "System"
  }

  # Optimal codes by Sinumerik version.
  global sinumerik_version

  if {![info exists sinumerik_version] } {
    set sinumerik_version "V7"
  }

  # The options (compressor, smoothing and feed foward.) only have effects on V6 and V7.
  global mom_siemens_compressor
  global mom_siemens_smoothing
  global mom_siemens_feedforward

  if {![string compare "V6" $sinumerik_version] || ![string compare "V7" $sinumerik_version] } {

     # Set the compressor.
     if {[string match "ON" $mom_siemens_compressor]} {

        switch $sinumerik_version {

           "V6"   {set mom_siemens_compressor "COMPCURV"}
           "V7"   {set mom_siemens_compressor "COMPCAD"}
        }

     } elseif {[string match "OFF" $mom_siemens_compressor]} {

        set mom_siemens_compressor "COMPOF"
     }

     # Set the smoothing.
     if {[string match "ON" $mom_siemens_smoothing]} {

        switch $sinumerik_version {

           "V6"   {set mom_siemens_smoothing "G642"}
           "V7"   {set mom_siemens_smoothing "G645"}
        }

     } elseif {[string match "OFF" $mom_siemens_smoothing]} {

        switch $sinumerik_version {

           "V6" {set mom_siemens_smoothing "G64"}
           "V7" {set mom_siemens_smoothing "G60"}
        }
     }

     # Set the feed forward.
     if {[string match "ON" $mom_siemens_feedforward]} {
        set mom_siemens_feedforward "FFWON"
     }  elseif {[string match "OFF" $mom_siemens_feedforward]} {
        set mom_siemens_feedforward "FFWOF"
     }
  }

  # Set the top surface smooth.
  global mom_siemens_top_surface_smooth

  if {[string match "TOP*ON" $mom_siemens_top_surface_smooth]} {
     set mom_siemens_top_surface_smooth "_TOP_SURFACE_SMOOTH_ON"
  } elseif {[string match "TOP*OFF" $mom_siemens_top_surface_smooth]} {
     set mom_siemens_top_surface_smooth "_TOP_SURFACE_SMOOTH_OFF"
  } else {
     set mom_siemens_top_surface_smooth ""
  }

  # Set the transformation.
  global mom_siemens_5axis_mode
  global mom_siemens_5axis_output_mode

  if {[info exists mom_siemens_5axis_mode]} {

     switch $mom_siemens_5axis_mode {

        TRAORI -
        TRAORI2 {set mom_siemens_5axis_output_mode 1}
        default {set mom_siemens_5axis_output_mode 0}
     }
  }

  # Set the rotary tolerance.
  global mom_siemens_rotary_tol
  global mom_siemens_rotary_tol_status
  global mom_siemens_rotary_tol_defined

  if {[info exists mom_siemens_rotary_tol_defined] && $mom_siemens_rotary_tol_defined == 1} {

     set mom_siemens_rotary_tol [format "%.6f" $mom_siemens_rotary_tol]
     set mom_siemens_rotary_tol_status "User"

  } else {

     set mom_siemens_rotary_tol_status "System"
  }

  # Set the group settings.
  global mom_siemens_ori_def
  global mom_siemens_feed_definition
  global mom_group_name
  global mom_siemens_tol_group
  global mom_siemens_tol_status_group
  global mom_siemens_rotary_tol_group
  global mom_siemens_rotary_tol_status_group
  global mom_sys_in_operation
  global mom_siemens_milling_setting

  if {[info exists mom_sys_in_operation ] && $mom_sys_in_operation == 1} {

     if {[string match "Group*" $mom_siemens_milling_setting]} {
        set mom_siemens_milling_setting "Group_UDE_operation"
     } else {
        set mom_siemens_milling_setting "UDE_operation"
     }

  } else {

     if {[info exists mom_group_name]} {
        set mom_siemens_milling_setting "Group$mom_group_name"
     } else {
        set mom_siemens_milling_setting "Group"
     }

     if {[info exists mom_siemens_tol_status]} {
        set mom_siemens_tol_status_group $mom_siemens_tol_status
     }
     if {[info exists mom_siemens_tol]} {
        set mom_siemens_tol_group $mom_siemens_tol
     }

     global mom_siemens_compressor_group
     global mom_siemens_smoothing_group
     global mom_siemens_feedforward_group
     global mom_siemens_top_surface_smooth_group
     global mom_siemens_5axis_mode_group
     global mom_siemens_ori_def_group
     global mom_siemens_feed_definition_group

     set mom_siemens_compressor_group $mom_siemens_compressor
     set mom_siemens_smoothing_group $mom_siemens_smoothing
     set mom_siemens_feedforward_group $mom_siemens_feedforward
     set mom_siemens_top_surface_smooth_group $mom_siemens_top_surface_smooth
     set mom_siemens_5axis_mode_group $mom_siemens_5axis_mode
     set mom_siemens_ori_def_group $mom_siemens_ori_def
     set mom_siemens_feed_definition_group $mom_siemens_feed_definition

     if {[info exists mom_siemens_rotary_tol_status]} {
        set mom_siemens_rotary_tol_status_group $mom_siemens_rotary_tol_status
     }
     if {[info exists mom_siemens_rotary_tol]} {
        set mom_siemens_rotary_tol_group $mom_siemens_rotary_tol
     }
  }

}


#=============================================================
proc PB_CMD_MOM_text { } {
#=============================================================
# Default handler for UDE MOM_text
# - Do not attach it to any event!
#
# This procedure is executed when the Text command is activated.
#
   global mom_user_defined_text mom_record_fields
   global mom_sys_control_out mom_sys_control_in
   global mom_record_text mom_pprint set mom_Instruction mom_operator_message
   global mom_pprint_defined mom_operator_message_defined

   switch $mom_record_fields(0) {
   "PPRINT"
         {
           set mom_pprint_defined 1
           set mom_pprint $mom_record_text
           MOM_pprint
         }
   "INSERT"
         {
           set mom_Instruction $mom_record_text
           MOM_insert
         }
   "DISPLY"
         {
           set mom_operator_message_defined 1
           set mom_operator_message $mom_record_text
           MOM_operator_message
         }
   default
         {
           if {[info exists mom_user_defined_text]} {
             MOM_output_literal "${mom_sys_control_out}${mom_user_defined_text}${mom_sys_control_in}"
           }
         }
   }
}


#=============================================================
proc PB_CMD__check_block_CYCLE800 { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_rotary_direction_4th
   global coord_angle coord_offset
   global cycle800_inc_retract
   global cycle800_tc cycle800_dir
   global cycle800_st cycle800_mode
   global mom_siemens_coord_rotation
   global mom_siemens_5axis_mode
   global mom_siemens_cycle_dmode

#-----------------------------------------------------------
#Please set your swivel data record
#-----------------------------------------------------------
   set cycle800_tc "\"R_DATA\"" ;# For example,please put your data here

#-----------------------------------------------------------
#Please set your incremental retraction
#-----------------------------------------------------------
   set cycle800_inc_retract "1"

#-----------------------------------------------------------
   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      set mom_siemens_cycle_dmode 0

   } else {
      if {[info exists mom_siemens_cycle_dmode]} {unset mom_siemens_cycle_dmode}
   }

      if { ![info exists mom_siemens_coord_rotation] } {
         set mom_siemens_coord_rotation 0
      }
      if {$mom_siemens_coord_rotation !=0 && [info exists mom_siemens_5axis_mode] && [string match "SWIVELING" $mom_siemens_5axis_mode] } {
        set cycle800_dir $mom_rotary_direction_4th
        set cycle800_st 0
        set cycle800_mode 57

        MOM_do_template rotation_axes CREATE
 return 1
      }
 return 0






}


#=============================================================
proc PB_CMD__check_block_CYCLE832 { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output
#
# 22-Dec-2016 shuai - CYCLE832 enhancement.
#

   global mom_logname
   global mom_operation_type
   global mom_operation_name
   global mom_cutmthd_libref
   global mom_siemens_method
   global mom_siemens_smoothing
   global mom_siemens_compressor
   global mom_siemens_feedforward
   global mom_siemens_5axis_output
   global mom_siemens_tol_status
   global mom_siemens_tol
   global mom_siemens_rotary_tol
   global mom_siemens_top_surface_smooth
   global mom_siemens_5axis_output_mode
   global sinumerik_version
   global cycle832_tolm
   global cycle832_v832
   global cycle832_tol
   global cycle832_otol

   if {![info exists sinumerik_version] } {

      return 0
   }

   if {[string compare $sinumerik_version "V6"] && \
       [string compare $sinumerik_version "V7"] && \
       [string compare $sinumerik_version "from V26 to V44"] && \
       [string compare $sinumerik_version "V45"] && \
       [string compare $sinumerik_version "V47"]} {

      return 0
   }


   # If tolerance is redefined in UDE, output again as User Defined.
   if {![info exists mom_siemens_tol_status] } {
      set mom_siemens_tol_status "System"
   }

   if {[string compare "System" $mom_siemens_tol_status] && [info exists mom_siemens_tol]} {

      set tol [format "%.6f" $mom_siemens_tol]
      MOM_output_literal "_camtolerance=$tol  ;  User Defined"
   }

   if {[info exists mom_cutmthd_libref]} {

      switch $mom_cutmthd_libref {

         OPD0_00021 {set mom_siemens_method "ROUGHING"}
         OPD0_00022 {set mom_siemens_method "ROUGH-FINISHING"}
         OPD0_00023 {set mom_siemens_method "FINISHING"}
         default    {set mom_siemens_method "DESELECTION"}
      }

   } else {

      set mom_siemens_method "DESELECTION"
   }

   # <lili 2013-06-20> Enhancement for new drilling cycle operation type.
   # Output cycle832 for milling operation.
   if {[string compare "Point to Point" $mom_operation_type] && \
       [string compare "Hole Making" $mom_operation_type] && \
       [string compare "Drilling" $mom_operation_type]} {

      # If compressor is on, set circular and helical motion to linear.
      PB_CMD_arc_compressor_mode

      # <22-Dec-2016 shuai> - Add the output conditions when NCK version is 4.5 and 4.7.
      #                       Adjust the TCL codes format to make the logic more clear.
      switch $sinumerik_version {

         "V6" {

            if {[info exists cycle832_v832]} {unset cycle832_v832}

            set list5 {COMPOF COMPCAD COMPCURV BSPLINE}
            set list4 {FFWOF FFWON BRISK}
            set list3 {G64 G641 G642}
            set list2 {TRAFOOF TRAORI TRAORI2}
            set list0 {DESELECTION FINISHING ROUGH-FINISHING ROUGHING}
            set tolm 0
            set i 0

            foreach b5 $list5 b4 $list4 b3 $list3 b2 $list2 b0 $list0 {

               if {[string match $b5 $mom_siemens_compressor]} {
                  set tolm [expr $tolm+$i*100000]
               }

               if {[string match $b4 $mom_siemens_feedforward]} {
                  set tolm [expr $tolm+$i*10000]
               }

               if {[string match $b3 $mom_siemens_smoothing]} {
                  set tolm [expr $tolm+$i*1000]
               }

               if {[string match $b2 $mom_siemens_5axis_output]} {
                  set tolm [expr $tolm+$i*100]
               }

               if {[string match $b0 $mom_siemens_method]} {
                  set tolm [expr $tolm+$i]
               }

               incr i
            }

            set cycle832_tolm $tolm

            PB_call_macro CYCLE832

            return 0
         }

         "V7" -

         "from V26 to V44" {

            set cycle832_v832 "1"

            switch -- $mom_siemens_method {

               "ROUGHING"        {set cycle832_tolm 3}
               "ROUGH-FINISHING" {set cycle832_tolm 2}
               "FINISHING"       {set cycle832_tolm 1}
               default           {set cycle832_tolm 0}
            }

            if {![string compare "V7" $sinumerik_version] } {
               PB_CMD_check_settings_for_cycle832
            }

            return 1
         }

         "V45" -

         "V47" {

            set rot ""
            set top ""

            set cycle832_tol "_camtolerance"
            set cycle832_otol 1

            if {[PB_CMD_detect_5axis_tool_path]} {

               set rot "_ORI"
               set cycle832_otol $mom_siemens_rotary_tol
            }

            if {![string compare "V47" $sinumerik_version] } {

               if {[info exists mom_siemens_top_surface_smooth] && [string compare "" $mom_siemens_top_surface_smooth]} {
                  set top "${mom_siemens_top_surface_smooth}+"
               }
            }

            switch -- $mom_siemens_method {

               "ROUGHING"        {set cycle832_tolm "_ROUGH"}
               "ROUGH-FINISHING" {set cycle832_tolm "_SEMIFIN"}
               "FINISHING"       {set cycle832_tolm "_FINISH"}

               default           {

                  set cycle832_tolm "_OFF"
                  set top ""
                  set rot ""
                  set cycle832_otol 1
               }
            }

            set cycle832_tolm $top$rot$cycle832_tolm

            PB_call_macro CYCLE832_v47

            return 0
         }
      }
   }

   return 0

}


#=============================================================
proc PB_CMD__check_block_CYCLE840_powerline { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_cycle_option


   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Powerline"]} {
      if { [info exists mom_cycle_option] && [string match "OPTION" $mom_cycle_option] } {
        PB_CMD_cycle_tap
 return 1
      } else {
 return 0
      }
   } else {
 return 0
   }

}


#=============================================================
proc PB_CMD__check_block_CYCLE840_solutionline { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_siemens_cycle_o_ptab
   global mom_siemens_cycle_dmode
   global mom_siemens_cycle_amode
   global mom_machine_mode
   global mom_cycle_option
   global mom_cycle_spindle_axis

   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      if { [info exists mom_cycle_option] && [string match "OPTION" $mom_cycle_option] } {
         PB_CMD_cycle_tap
         if {[info exists mom_siemens_cycle_o_ptab] && [string match "Module(*" $mom_siemens_cycle_o_ptab]} {
            set mom_siemens_cycle_o_ptab 4
         }
         if {[string match $mom_machine_mode "MILL"]} {
            set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
         } elseif {[string match $mom_machine_mode "TURN"]} {
            set mom_siemens_cycle_dmode 100
         }
         set mom_siemens_cycle_amode 0
 return 1
      } else {
 return 0
      }
   } else {
 return 0
   }
}


#=============================================================
proc PB_CMD__check_block_CYCLE84_powerline { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_cycle_option


   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Powerline"]} {
      if { [info exists mom_cycle_option] && [string match "OPTION" $mom_cycle_option] } {
 return 0
      } else {
         PB_CMD_cycle_tap
 return 1
      }
   } else {
 return 0
   }
}


#=============================================================
proc PB_CMD__check_block_CYCLE84_solutionline { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_siemens_cycle_o_ptab
   global mom_siemens_cycle_dmode
   global mom_siemens_cycle_amode
   global mom_cycle_spindle_axis
   global mom_cycle_option
   global mom_cycle_spindle_axis

   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      if { [info exists mom_cycle_option] && [string match "OPTION" $mom_cycle_option] } {
 return 0
      } else {
         PB_CMD_cycle_tap
         if {[info exists mom_siemens_cycle_o_ptab] && [string match "Module(*" $mom_siemens_cycle_o_ptab]} {
            set mom_siemens_cycle_o_ptab 4
         }
         set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
         set mom_siemens_cycle_amode 0
 return 1
      }
   } else {
 return 0
   }
}


#=============================================================
proc PB_CMD__check_block_CYCLE_powerline { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version


   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Powerline"]} {
 return 1
   } else {
 return 0
   }



}


#=============================================================
proc PB_CMD__check_block_CYCLE_solutionline { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global mom_logname
   global mom_cycle_feed_to_pos
   global mom_cycle_spindle_axis
   global mom_cycle_hole_dia
   global mom_siemens_cycle_gmode
   global mom_siemens_cycle_dmode
   global mom_siemens_cycle_amode
   global mom_siemens_cycle_liftoff
   global sinumerik_control_version
   global mom_motion_event



   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      if {![info exists mom_motion_event]} {
  return 0
      }
      switch $mom_motion_event {
         drill_move {
            if {![info exists mom_siemens_cycle_gmode]} {set mom_siemens_cycle_gmode 0}
            if {[string match $mom_siemens_cycle_gmode "Depth"]} {set mom_siemens_cycle_gmode 0}
            if {[string match $mom_siemens_cycle_gmode "Diameter"]} {set mom_siemens_cycle_gmode 1}
            if {$mom_siemens_cycle_gmode ==1 && [info exists mom_cycle_hole_dia] } {
               set mom_cycle_feed_to_pos($mom_cycle_spindle_axis) $mom_cycle_hole_dia
            }
            set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
            set mom_siemens_cycle_amode 0
         }
         drill_dwell_move {
            set mom_siemens_cycle_gmode 0
            set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
            set mom_siemens_cycle_amode 0

         }
         drill_deep_move -
         drill_break_chip_move {
            set mom_siemens_cycle_gmode 0
            set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
            set mom_siemens_cycle_amode 0
         }
         bore_move -
         bore_dwell_move {
            set mom_siemens_cycle_plane [expr 3-$mom_cycle_spindle_axis]
            set mom_siemens_cycle_amode 0
         }
         bore_no_drag_move {
            set mom_siemens_cycle_gmode 0
            set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
            set mom_siemens_cycle_amode 0
         }
         bore_back_move {
            set mom_siemens_cycle_gmode 0
            if {[info exists mom_siemens_cycle_liftoff] && [string match $mom_siemens_cycle_liftoff "No"]} {
                set mom_siemens_cycle_gmode 1
            }
            set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
            set mom_siemens_cycle_amode 0
         }
         default {}
      };#switch
 return 1
   } else {
 return 0
   }

}


#=============================================================
proc PB_CMD__check_block_FGREF { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global mom_logname
   global sinumerik_version
   global mom_kin_machine_type

  # Output reference radius of rotary axis for sinumerik SW version 5.
  if {[info exists sinumerik_version] && ([string match "V5" $sinumerik_version] || [string match "V6" $sinumerik_version])} {
 return 1
  }
 return 0
}


#=============================================================
proc PB_CMD__check_block_ORIRESET { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output
#

  global mom_init_pos
  global mom_out_angle_pos
  global mom_kin_machine_type
  global sinumerik_version
  global mom_siemens_ori_def
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode

  if {[string match "3_axis_mill" $mom_kin_machine_type]} {

     return 0
  }

  if {![info exists mom_siemens_coord_rotation] } {
     set mom_siemens_coord_rotation 0
  }

  if {![info exists mom_siemens_5axis_mode] } {
     set mom_siemens_5axis_mode TRAFOOF
  }

  if {$mom_siemens_coord_rotation != 0 && [string match "SWIVELING" $mom_siemens_5axis_mode]} {

     return 0
  }

  if {[info exists sinumerik_version] && ([string match "V7" $sinumerik_version] || [string match "from V26 to V44" $sinumerik_version] || [string match "V45" $sinumerik_version] || [string match "V47" $sinumerik_version]) && \
      [info exists mom_siemens_ori_def] && ![string match "*ROTARY*" $mom_siemens_ori_def]} {

     if {$mom_siemens_coord_rotation == 1} {

        if {[info exists mom_init_pos(3)]} {
           set mom_out_angle_pos(0) $mom_init_pos(3)
        }

        if {[info exists mom_init_pos(4)]} {
           set mom_out_angle_pos(1) $mom_init_pos(4)
        }
     }

     return 1
  }

  return 0

}


#=============================================================
proc PB_CMD__check_block_cycle_plane_change { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global mom_logname
   global mom_siemens_cycle_count

   if {$mom_siemens_cycle_count==0} {
 return 0
   } else {
 return 1
   }
}


#=============================================================
proc PB_CMD__check_block_cycle_retract { } {
#=============================================================
# This custom command should return
#   1 : Output block
#   0 : No output
# 07-May-15 Jintao - fix PR7162261 and PTP/Hole making issues

  global mom_prev_pos
  global mom_tool_axis
  global mom_operation_type
  global mom_cycle_retract_to
  global mom_cycle_clearance_pos
  global mom_cycle_retract_mode

# PB_CMD_init_cycle_parameters deals with auto mode, cycle_init_flag = TRUE
  if { [info exists mom_cycle_retract_mode] && [string match "AUTO" $mom_cycle_retract_mode] } {
     return 0
  }

  if { [string match "Point to Point" $mom_operation_type] ||\
       [string match "Hole Making" $mom_operation_type] } {
     VEC3_scale mom_cycle_retract_to mom_tool_axis retract_to_pos
     VEC3_add mom_prev_pos retract_to_pos retract_to_pos
     VEC3_sub mom_cycle_clearance_pos retract_to_pos delta_vec
     set dist [VEC3_dot delta_vec mom_tool_axis]
     if { [EQ_is_gt $dist 0.0] } {
       return 1
     } else {
       return 0
     }
  } else {
     return 0
  }

}


#=============================================================
proc PB_CMD__check_block_delay_revolutions { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global mom_logname
   global mom_delay_mode

  if {[string match $mom_delay_mode "REVOLUTIONS"]} {
 return 1
  }
 return 0
}


#=============================================================
proc PB_CMD__check_block_delay_seconds { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global mom_logname
   global mom_delay_mode

  if {[string match $mom_delay_mode "SECONDS"]} {
 return 1
  }
 return 0


}


#=============================================================
proc PB_CMD__check_block_ori_coordinate { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

# Output 5 axis orientation coordinate
  global mom_kin_machine_type
  global mom_siemens_ori_coord
  global mom_siemens_ori_inter
  global mom_siemens_5axis_mode
  if { ![string match "3_axis_mill*" $mom_kin_machine_type] && ![string match "SWIVELING" $mom_siemens_5axis_mode] } {
     if { [info exists mom_siemens_ori_coord] } {
 return 1
     }
  }
 return 0

}


#=============================================================
proc PB_CMD__check_block_ori_interpolation { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   # Output 5 axis orientation interpolation
  global mom_kin_machine_type
  global mom_siemens_ori_coord
  global mom_siemens_ori_inter
  global mom_siemens_5axis_mode
  if { ![string match "3_axis_mill*" $mom_kin_machine_type] && ![string match "SWIVELING" $mom_siemens_5axis_mode] } {
     if { [info exists mom_siemens_ori_inter] } {
 return 1
     }
  }
 return 0
}


#=============================================================
proc PB_CMD__check_block_reset_cycle800 { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

# 10-15-13 Allen- restore kinematics in 3+2 axis SWIVELING mode.

  global mom_siemens_coord_rotation
  global mom_kin_machine_type
  global mom_siemens_5axis_mode
  global mom_siemens_5axis_output_mode
  global coord_ang_A coord_ang_B coord_ang_C

  if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation != 0 } {
     if { ![string compare "SWIVELING" $mom_siemens_5axis_mode] } {
        DPP_GE_RESTORE_KINEMATICS
        if { $mom_siemens_coord_rotation == 2 } {
        # Reset rotation mode to NONE if it is auto 3D rotation
           set mom_siemens_coord_rotation 0
           set coord_ang_A 0; set coord_ang_B 0; set coord_ang_C 0
        }
  return 1
     }
   }

  return 0

}


#=============================================================
proc PB_CMD__check_block_reset_cycle832 { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output
#
# 22-Dec-2016 shuai - CYCLE832 enhancement.
#

  global sinumerik_version
  global mom_operation_type
  global cycle832_tol
  global cycle832_otol
  global cycle832_tolm

  if {![info exists sinumerik_version] } {

     return 0
  }

  if {[string compare $sinumerik_version "V6"] && \
      [string compare $sinumerik_version "V7"] && \
      [string compare $sinumerik_version "from V26 to V44"] && \
      [string compare $sinumerik_version "V45"] && \
      [string compare $sinumerik_version "V47"]} {

     return 0
  }


  # <lili 2013-06-20> Enhancement for new drilling cycle operation type.
  if {[string compare "Point to Point" $mom_operation_type] && \
      [string compare "Hole Making" $mom_operation_type] && \
      [string compare "Drilling" $mom_operation_type]} {

     PB_CMD_reset_arc_compressor_mode

     return 1

  } else {

     return 0
  }

}


#=============================================================
proc PB_CMD__check_block_reset_trans { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

# 10-15-13 Allen - restore kinematics in 3+2 axis TRAORI mode.

  global mom_siemens_coord_rotation
  global mom_kin_machine_type
  global mom_siemens_5axis_mode
  global coord_offset_flag
  global coord_ang_A coord_ang_B coord_ang_C

  if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation != 0 } {
     if { [string compare "SWIVELING" $mom_siemens_5axis_mode] } {
        DPP_GE_RESTORE_KINEMATICS
        if { $mom_siemens_coord_rotation == 2 } {
        # Reset rotation mode to NONE if it is auto 3D rotation
           set mom_siemens_coord_rotation 0
           set coord_ang_A 0; set coord_ang_B 0; set coord_ang_C 0
        }
 return 1
     }
  }

  if { [info exists coord_offset_flag] && $coord_offset_flag == 1 } {
 return 1
  }

 return 0

}


#=============================================================
proc PB_CMD__check_block_reset_traori { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

   global mom_logname
   global mom_siemens_5axis_output_mode

   if { $mom_siemens_5axis_output_mode == 1 } {
     set mom_siemens_5axis_output_mode 0
 return 1
  } else {
 return 0
  }




}


#=============================================================
proc PB_CMD__check_block_return_to_reference_point { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output
#
# If next operation has tool change or it's the last operation, go to reference point, turn off
# spindle and coolant. Otherwise, don't do these.
#
# 06-07-2013 levi - Initial version.
# 10-16-2013 levi - Set the rotary angles to 0 and reload the variables.
# 06-04-14 Allen - Fix PR7143300 to check if variable mom_next_oper_has_tool_change and mom_current_oper_is_last_oper_in_program exist.

  global mom_next_oper_has_tool_change
  global mom_current_oper_is_last_oper_in_program
  global mom_out_angle_pos
  global mom_prev_out_angle_pos
  global mom_pos
  global mom_prev_pos

  if {([info exists mom_next_oper_has_tool_change] && $mom_next_oper_has_tool_change == "YES") || ([info exists mom_current_oper_is_last_oper_in_program] && $mom_current_oper_is_last_oper_in_program == "YES")} {
     set mom_out_angle_pos(0) 0
     set mom_out_angle_pos(1) 0
     set mom_prev_out_angle_pos(0) 0.0
     set mom_prev_out_angle_pos(1) 0.0
     set mom_pos(3) 0.0
     set mom_pos(4) 0.0
     set mom_prev_pos(3) 0.0
     set mom_prev_pos(4) 0.0
     MOM_reload_variable -a mom_out_angle_pos
     MOM_reload_variable -a mom_prev_out_angle_pos
     MOM_reload_variable -a mom_out_angle_pos
     MOM_reload_variable -a mom_pos
     MOM_reload_variable -a mom_prev_pos
     return 1
  } else {
     return 0
  }

}


#=============================================================
proc PB_CMD__check_block_rotary { } {
#=============================================================
# This custom command should return
#   1 : Output Non-TRAORI mode with rotary axes value motion BLOCK
#   0 : No output

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis
  global mom_siemens_5axis_output_mode
  global mom_operation_name
  global mom_current_motion

  # 5 axis orient definition
  if { ![info exists mom_siemens_ori_def] } {
     set mom_siemens_ori_def "ROTARY AXES"
  }

  if {![info exists mom_siemens_5axis_output_mode]} {
     set mom_siemens_5axis_output_mode 0
  }

  if {$mom_siemens_5axis_output_mode == 0} {
     if { ![string match "*ROTARY*" $mom_siemens_ori_def] && ([string match "first_move" $mom_current_motion] ||\
           [string match "initial_move" $mom_current_motion])} {
        CATCH_WARNING "$mom_operation_name:A3B3C3 should work with TRAORI mode, change to rotary output"
     }

 return 1
  } else {
     if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
        if { [info exists mom_tool_axis] && [info exists mom_prev_tool_axis] } {
           if { [VEC3_is_equal mom_tool_axis mom_prev_tool_axis] } {
              MOM_suppress Once fourth_axis fifth_axis
           }
        }
        if { $mom_siemens_coord_rotation != 0 && [string match "SWIVELING" $mom_siemens_5axis_mode] } {
           MOM_suppress Once fourth_axis fifth_axis
        }

 return 1
     }
  }


 return 0
}


#=============================================================
proc PB_CMD__check_block_rotation_axes { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output
#

  global mom_kin_machine_type
  global sinumerik_version
  global mom_siemens_ori_def
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_init_pos
  global mom_out_angle_pos

  if {[string match "3_axis_mill" $mom_kin_machine_type]} {

     return 0
  }

  if {![info exists mom_siemens_coord_rotation] } {
     set mom_siemens_coord_rotation 0
  }

  if {![info exists mom_siemens_5axis_mode] } {
     set mom_siemens_5axis_mode TRAFOOF
  }

  if {$mom_siemens_coord_rotation != 0 && [string match "SWIVELING" $mom_siemens_5axis_mode]} {

     return 0
  }

  if {[info exists sinumerik_version] && ([string match "V7" $sinumerik_version] || [string match "from V26 to V44" $sinumerik_version] || [string match "V45" $sinumerik_version] || [string match "V47" $sinumerik_version]) && \
      [info exists mom_siemens_ori_def] && ![string match "*ROTARY*" $mom_siemens_ori_def]} {

     return 0

  } else {

     # For simulation, in case rotary axis limits are reloaded from machine.
     global mom_prev_out_angle_pos mom_sys_leader
     global mom_kin_4th_axis_max_limit mom_kin_4th_axis_direction mom_kin_4th_axis_min_limit mom_kin_4th_axis_leader
     global mom_kin_5th_axis_max_limit mom_kin_5th_axis_direction mom_kin_5th_axis_min_limit mom_kin_5th_axis_leader

     MOM_force once fourth_axis fifth_axis

     if {![info exists mom_prev_out_angle_pos(0)] } {set mom_prev_out_angle_pos(0) 0}
     if {![info exists mom_prev_out_angle_pos(1)] } {set mom_prev_out_angle_pos(1) 0}

     if {$mom_siemens_coord_rotation == 1} {

        if {[info exists mom_init_pos(3)]} {
           set mom_out_angle_pos(0) [ROTSET $mom_init_pos(3) $mom_prev_out_angle_pos(0)  $mom_kin_4th_axis_direction  $mom_kin_4th_axis_leader  mom_sys_leader(fourth_axis)  $mom_kin_4th_axis_min_limit  $mom_kin_4th_axis_max_limit]
        }

        if {[info exists mom_init_pos(4)]} {
          set mom_out_angle_pos(1) [ROTSET $mom_init_pos(4) $mom_prev_out_angle_pos(1)  $mom_kin_5th_axis_direction   $mom_kin_5th_axis_leader   mom_sys_leader(fifth_axis)  $mom_kin_5th_axis_min_limit  $mom_kin_5th_axis_max_limit]
        }
     }

     return 1
  }

}


#=============================================================
proc PB_CMD__check_block_tap_float_powerline { } {
#=============================================================
# 07-08-14 Allen - This custom command is used to decide if it should output tap float block.
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Powerline"]} {
      PB_CMD_cycle_tap_parameter_setting
 return 1
   } else {
 return 0
   }


}


#=============================================================
proc PB_CMD__check_block_tap_float_solutionline { } {
#=============================================================
# 07-08-14 Allen - This custom command is used to decide if it should output tap float block.
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_siemens_cycle_o_ptab
   global mom_siemens_cycle_dmode
   global mom_siemens_cycle_amode
   global mom_machine_mode
   global mom_cycle_spindle_axis

   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      PB_CMD_cycle_tap_parameter_setting
      if {[info exists mom_siemens_cycle_o_ptab] && [string match "Module(*" $mom_siemens_cycle_o_ptab]} {
         set mom_siemens_cycle_o_ptab 4
      }
      if {[string match $mom_machine_mode "MILL"]} {
         set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
      } elseif {[string match $mom_machine_mode "TURN"]} {
         set mom_siemens_cycle_dmode 100
      }
      set mom_siemens_cycle_amode 0
 return 1
   } else {
 return 0
   }

}


#=============================================================
proc PB_CMD__check_block_tap_type_powerline { } {
#=============================================================
# 07-08-14 Allen - This custom command is used to decide if it should output tap* block.
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_motion_event
   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Powerline"]} {
      PB_CMD_cycle_tap_parameter_setting
 return 1
   } else {
 return 0
   }

}


#=============================================================
proc PB_CMD__check_block_tap_type_solutionline { } {
#=============================================================
# 07-08-14 Allen - This custom command is used to decide if it should output tap* block.
#   1 : Output BLOCK
#   0 : No output

   global sinumerik_control_version
   global mom_siemens_cycle_o_ptab
   global mom_siemens_cycle_dmode
   global mom_siemens_cycle_amode
   global mom_cycle_spindle_axis
   global mom_motion_event

   if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      PB_CMD_cycle_tap_parameter_setting
      if {[info exists mom_siemens_cycle_o_ptab] && [string match "Module(*" $mom_siemens_cycle_o_ptab]} {
         set mom_siemens_cycle_o_ptab 4
      }
      set mom_siemens_cycle_dmode [expr 3-$mom_cycle_spindle_axis]
      set mom_siemens_cycle_amode 0
 return 1
   } else {
 return 0
   }

}


#=============================================================
proc PB_CMD__check_block_trafoof_mode { } {
#=============================================================
# This custom command should return
#   1 : Output Non-TRAORI mode motion BLOCK
#   0 : No output

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_3Dcutcom_mode
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis
  global mom_siemens_5axis_output_mode


  if {![info exists mom_siemens_5axis_output_mode]} {
     set mom_siemens_5axis_output_mode 0
  }

  if {$mom_siemens_5axis_output_mode == 0} {
 return 1
  } else {
     if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
 return 1
     }
 return 0
  }

}


#=============================================================
proc PB_CMD__check_block_traori_mode { } {
#=============================================================
# This custom command should return
#   1 : Output TRAORI mode motion BLOCK
#   0 : No output

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_3Dcutcom_mode
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis
  global mom_siemens_5axis_output_mode
  global mom_contact_status
  global mcs_contact_normal mcs_contact_point
  global mom_contact_normal mom_contact_point
  global mom_mcs_goto

  if {![info exists mom_siemens_5axis_output_mode]} {
     set mom_siemens_5axis_output_mode 0
  }

  if {$mom_siemens_5axis_output_mode == 1} {
      if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
 return 0
      }
      if { [info exists mom_contact_status] && $mom_contact_status == "ON" } {
         if { [info exists mcs_contact_normal] && [info exists mom_contact_normal] } {
            VMOV 3 mcs_contact_normal mom_contact_normal
         }
         if { [info exists mom_contact_point] } {
            MCS_VECTOR mom_contact_point mcs_contact_point
            VMOV 3 mcs_contact_point mom_mcs_goto
         }
      }

 return 1
  } else {
 return 0
  }

}


#=============================================================
proc PB_CMD__check_block_traori_rotary { } {
#=============================================================
# This custom command should return
#   1 : Output TRAORI mode with rotary axes value motion BLOCK
#   0 : No output

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_3Dcutcom_mode
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis
  global mom_siemens_5axis_output_mode
  global mom_contact_status
  global mcs_contact_normal mcs_contact_point
  global mom_contact_normal mom_contact_point
  global mom_mcs_goto

  # 5 axis orient definition
  if { ![info exists mom_siemens_ori_def] } {
     set mom_siemens_ori_def "ROTARY AXES"
  }

  if {![info exists mom_siemens_5axis_output_mode]} {
     set mom_siemens_5axis_output_mode 0
  }

  if {$mom_siemens_5axis_output_mode == 1} {

     if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
 return 0
     }

     if { [string match "*ROTARY*" $mom_siemens_ori_def] } {

        if { [info exists mom_contact_status] && $mom_contact_status == "ON" } {
            if { [info exists mcs_contact_normal] && [info exists mom_contact_normal] } {
               VMOV 3 mcs_contact_normal mom_contact_normal
            }
            if { [info exists mom_contact_point] } {
               MCS_VECTOR mom_contact_point mcs_contact_point
               VMOV 3 mcs_contact_point mom_mcs_goto
            }
        }

        if { [info exists mom_tool_axis] && [info exists mom_prev_tool_axis] } {
           if { [VEC3_is_equal mom_tool_axis mom_prev_tool_axis] } {
              MOM_suppress Once fourth_axis fifth_axis
           }
        }

        #Drilling Cycle
       global cycle_init_flag mom_cycle_rapid_to mom_tool_axis
       global mom_current_motion
       if { [info exists cycle_init_flag] && $cycle_init_flag == "TRUE" } {
         if { [string match "initial_move" $mom_current_motion] || [string match "first_move" $mom_current_motion]} {
            set mom_mcs_goto(0) [expr $mom_mcs_goto(0) + $mom_cycle_rapid_to*$mom_tool_axis(0)]
            set mom_mcs_goto(1) [expr $mom_mcs_goto(1) + $mom_cycle_rapid_to*$mom_tool_axis(1)]
            set mom_mcs_goto(2) [expr $mom_mcs_goto(2) + $mom_cycle_rapid_to*$mom_tool_axis(2)]
         }
      }
 return 1
     }
  }

 return 0

}


#=============================================================
proc PB_CMD__check_block_traori_vector { } {
#=============================================================
# This custom command should return
#   1 : Output TRAORI mode with rotary vector motion BLOCK
#   0 : No output

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_3Dcutcom_mode
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis
  global mom_siemens_5axis_output_mode
  global mom_contact_status
  global mcs_contact_normal mcs_contact_point
  global mom_contact_normal mom_contact_point
  global mom_mcs_goto

  # 5 axis orient definition
  if { ![info exists mom_siemens_ori_def] } {
     set mom_siemens_ori_def "ROTARY AXES"
  }

  if {![info exists mom_siemens_5axis_output_mode]} {
     set mom_siemens_5axis_output_mode 0
  }

  if {$mom_siemens_5axis_output_mode == 1} {

     if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
 return 0
     }

     if { [string match "*VECTOR*" $mom_siemens_ori_def]} {
        if { [info exists mom_contact_status] && $mom_contact_status == "ON" } {
            if { [info exists mcs_contact_normal] && [info exists mom_contact_normal] } {
               VMOV 3 mcs_contact_normal mom_contact_normal
            }
            if { [info exists mom_contact_point] } {
               MCS_VECTOR mom_contact_point mcs_contact_point
               VMOV 3 mcs_contact_point mom_mcs_goto
            }
        }

        #Drilling Cycle
       global cycle_init_flag mom_cycle_rapid_to mom_tool_axis
       global mom_current_motion
       if { [info exists cycle_init_flag] && $cycle_init_flag == "TRUE" } {
         if { [string match "initial_move" $mom_current_motion] || [string match "first_move" $mom_current_motion]} {
            set mom_mcs_goto(0) [expr $mom_mcs_goto(0) + $mom_cycle_rapid_to*$mom_tool_axis(0)]
            set mom_mcs_goto(1) [expr $mom_mcs_goto(1) + $mom_cycle_rapid_to*$mom_tool_axis(1)]
            set mom_mcs_goto(2) [expr $mom_mcs_goto(2) + $mom_cycle_rapid_to*$mom_tool_axis(2)]
         }
      }

 return 1
     }
  }

 return 0

}


#=============================================================
proc PB_CMD__check_block_vector { } {
#=============================================================
# This custom command should return
#   1 : Output BLOCK
#   0 : No output

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_3Dcutcom_mode
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis

  # 5 axis orient definition
  if { ![info exists mom_siemens_ori_def] } {
     set mom_siemens_ori_def "ROTARY AXES"
  }


  if { [string match "*VECTOR*" $mom_siemens_ori_def] && [string compare "3_axis_mill" $mom_kin_machine_type]  } {

     if { [string match "ORIMKS" $mom_siemens_ori_coord] && $mom_siemens_coord_rotation == 1 } {
        global mom_tool_axis mom_csys_matrix csys_matrix tool_axis

        MTX3_transpose mom_csys_matrix csys_matrix
        MTX3_vec_multiply mom_tool_axis csys_matrix tool_axis
        VMOV 3 tool_axis mom_tool_axis
     }
     if { $mom_siemens_coord_rotation != 0 && [string match "SWIVELING" $mom_siemens_5axis_mode] } {
        MOM_suppress Once A3 B3 C3
     }

     #Cutcom type
     if { [info exists mom_siemens_3Dcutcom_mode] } {
        if { [string match "3DF" $mom_siemens_3Dcutcom_mode] || [string match "3DFF" $mom_siemens_3Dcutcom_mode] } {
           global mom_contact_status
           if { [info exists mom_contact_status] && [string match "ON" $mom_contact_status] } {
              MOM_force Once A5 B5 C5
           } else {
              MOM_suppress Once A5 B5 C5
           }
        } else {
           MOM_suppress Once A5 B5 C5
        }
     }
return 1
  }

return 0


}


#=============================================================
proc PB_CMD__choose_preferred_solution { } {
#=============================================================
# ==> Do not rename this command!
#
#  This command will recompute rotary angles using the alternate solution
#  of a 5-axis motion based on the setting of "mom_preferred_zone_flag"
#  as the preferred delimiter.  The choices are:
#
#    [XPLUS | XMINUS | YPLUS | YMINUS | FOURTH | FIFTH]
#
#
#  => This command may be attached to Rapid Move or Cycle Plane Change
#     to influence the solution of the rotary axes.
#  => Initial rotary angle can be influenced by using a "Rotate" UDE.
#  => May need to recompute FRN, since length of travel may change.
#
#-------------------------------------------------------------
#<04-24-2014 gsl> Attempt to resolve PR#6738915
#<07-13-2015 gsl> Reworked logic for FOURTH & FIFTH cases
#
#return


  #----------------------------------------------------------
  # Preferred zone flag can be set via an UDE or other means.
  #
   #   EVENT preferred_solution
   #   {
   #     UI_LABEL "Preferred Solution"
   #     PARAM choose_preferred_zone
   #     {
   #        TYPE b
   #        DEFVAL "TRUE"
   #        UI_LABEL "Choose Preferred Zone"
   #     }
   #     PARAM preferred_zone_flag
   #     {
   #        TYPE o
   #        DEFVAL "YPLUS"
   #        OPTIONS "XPLUS","XMINUS","YPLUS","YMINUS","FOURTH","FIFTH"
   #        UI_LABEL "Preferred Zone"
   #     }
   #   }


   if { [info exists ::mom_preferred_zone_flag] } {

     # Only handle Rapid & Cycles for the time being,
     # user may add other cases as desired.
      if { [string compare "RAPID" $::mom_motion_type] &&\
           [string compare "CYCLE" $::mom_motion_type] } {
return
      }


      if { ![info exists ::mom_prev_out_angle_pos] } {
         array set ::mom_prev_out_angle_pos [array get ::mom_out_angle_pos]
         MOM_reload_variable -a mom_prev_out_angle_pos
return
      }


      set co "$::mom_sys_control_out"
      set ci "$::mom_sys_control_in"

      set __use_alternate 0

      switch $::mom_preferred_zone_flag {
         XPLUS  {
            if { !([EQ_is_gt $::mom_pos(0) 0.0] || [EQ_is_zero $::mom_pos(0)]) } {
               set __use_alternate 1
            }
         }
         XMINUS {
            if { !([EQ_is_le $::mom_pos(0) 0.0]) } {
               set __use_alternate 1
            }
         }
         YPLUS  {
            if { !([EQ_is_gt $::mom_pos(1) 0.0] || [EQ_is_zero $::mom_pos(1)]) } {
               set __use_alternate 1
            }
         }
         YMINUS {
            if { !([EQ_is_le $::mom_pos(1) 0.0]) } {
               set __use_alternate 1
            }
         }
         FOURTH {
            set del4 [expr abs( $::mom_out_angle_pos(0) - $::mom_prev_out_angle_pos(0) )]

            VMOV 5 ::mom_alt_pos ::mom_pos
            set out_angle_4th [ROTSET $::mom_pos(3) $::mom_prev_out_angle_pos(0) $::mom_kin_4th_axis_direction\
                                      $::mom_kin_4th_axis_leader ::mom_sys_leader(fourth_axis)\
                                      $::mom_kin_4th_axis_min_limit $::mom_kin_4th_axis_max_limit]

            set del4a [expr abs( $out_angle_4th - $::mom_prev_out_angle_pos(0) )]

            if [expr $del4 > $del4a] {
               set __use_alternate 1
            }
         }
         FIFTH  {
            set del5 [expr abs( $::mom_out_angle_pos(1) - $::mom_prev_out_angle_pos(1) )]

            VMOV 5 ::mom_alt_pos ::mom_pos
            set out_angle_5th [ROTSET $::mom_pos(4) $::mom_prev_out_angle_pos(1) $::mom_kin_5th_axis_direction\
                                      $::mom_kin_5th_axis_leader ::mom_sys_leader(fifth_axis)\
                                      $::mom_kin_5th_axis_min_limit $::mom_kin_5th_axis_max_limit]

            set del5a [expr abs( $out_angle_5th - $::mom_prev_out_angle_pos(1) )]

            if [expr $del5 > $del5a] {
               set __use_alternate 1
            }
         }
         default {
            CATCH_WARNING "$co Preferred delimiter \"$::mom_preferred_zone_flag\" is not available! $ci"
         }
      }


     # Recompute output when needed
      if { $__use_alternate } {

         set a4 $::mom_out_angle_pos(0)
         set a5 $::mom_out_angle_pos(1)

         VMOV 5 ::mom_alt_pos ::mom_pos
         set ::mom_out_angle_pos(0) [ROTSET $::mom_pos(3) $::mom_prev_out_angle_pos(0) $::mom_kin_4th_axis_direction\
                                            $::mom_kin_4th_axis_leader ::mom_sys_leader(fourth_axis)\
                                            $::mom_kin_4th_axis_min_limit $::mom_kin_4th_axis_max_limit]
         set ::mom_out_angle_pos(1) [ROTSET $::mom_pos(4) $::mom_prev_out_angle_pos(1) $::mom_kin_5th_axis_direction\
                                            $::mom_kin_5th_axis_leader ::mom_sys_leader(fifth_axis)\
                                            $::mom_kin_5th_axis_min_limit $::mom_kin_5th_axis_max_limit]

         MOM_reload_variable -a mom_out_angle_pos
         MOM_reload_variable -a mom_pos

         set msg "$co Use alternate solution : $::mom_preferred_zone_flag \
                      ($a4 / $a5) -> ($::mom_out_angle_pos(0) / $::mom_out_angle_pos(1)) $ci"

         CATCH_WARNING $msg
      }


     # Recompute output coords for cycles
      if { ![info exists ::mom_sys_cycle_after_initial] } {
         set ::mom_sys_cycle_after_initial "FALSE"
      }

      if { [string match "CYCLE" $::mom_motion_type] } {

         if { [string match "initial_move" $::mom_motion_event] } {
            set ::mom_sys_cycle_after_initial "TRUE"
return
         }

         if { [string match "TRUE" $::mom_sys_cycle_after_initial] } {
            set ::mom_pos(0) [expr $::mom_pos(0) - $::mom_cycle_rapid_to * $::mom_tool_axis(0)]
            set ::mom_pos(1) [expr $::mom_pos(1) - $::mom_cycle_rapid_to * $::mom_tool_axis(1)]
            set ::mom_pos(2) [expr $::mom_pos(2) - $::mom_cycle_rapid_to * $::mom_tool_axis(2)]
         }

         set ::mom_sys_cycle_after_initial "FALSE"

         if { [string match "Table" $::mom_kin_4th_axis_type] } {

           #<04-16-2014 gsl> "mom_spindle_axis" would have incorporated the direction of head attachment already.
            if [info exists ::mom_spindle_axis] {
               VMOV 3 ::mom_spindle_axis ::mom_sys_spindle_axis
            } else {
               VMOV 3 ::mom_kin_spindle_axis ::mom_sys_spindle_axis
            }

         } elseif { [string match "Table" $::mom_kin_5th_axis_type] } {

            VMOV 3 ::mom_tool_axis vec

            switch $::mom_kin_4th_axis_plane {
               XY {
                  set vec(2) 0.0
               }
               ZX {
                  set vec(1) 0.0
               }
               YZ {
                  set vec(0) 0.0
               }
            }

           #<04-16-2014 gsl> Reworked logic to prevent potential error
            set len [VEC3_mag vec]
            if { [EQ_is_gt $len 0.0] } {
               VEC3_unitize vec ::mom_sys_spindle_axis
            } else {
               set ::mom_sys_spindle_axis(0) 0.0
               set ::mom_sys_spindle_axis(1) 0.0
               set ::mom_sys_spindle_axis(2) 1.0
            }

         } else {

            VMOV 3 ::mom_tool_axis ::mom_sys_spindle_axis
         }

         set ::mom_cycle_feed_to_pos(0)    [expr $::mom_pos(0) + $::mom_cycle_feed_to    * $::mom_sys_spindle_axis(0)]
         set ::mom_cycle_feed_to_pos(1)    [expr $::mom_pos(1) + $::mom_cycle_feed_to    * $::mom_sys_spindle_axis(1)]
         set ::mom_cycle_feed_to_pos(2)    [expr $::mom_pos(2) + $::mom_cycle_feed_to    * $::mom_sys_spindle_axis(2)]

         set ::mom_cycle_rapid_to_pos(0)   [expr $::mom_pos(0) + $::mom_cycle_rapid_to   * $::mom_sys_spindle_axis(0)]
         set ::mom_cycle_rapid_to_pos(1)   [expr $::mom_pos(1) + $::mom_cycle_rapid_to   * $::mom_sys_spindle_axis(1)]
         set ::mom_cycle_rapid_to_pos(2)   [expr $::mom_pos(2) + $::mom_cycle_rapid_to   * $::mom_sys_spindle_axis(2)]

         set ::mom_cycle_retract_to_pos(0) [expr $::mom_pos(0) + $::mom_cycle_retract_to * $::mom_sys_spindle_axis(0)]
         set ::mom_cycle_retract_to_pos(1) [expr $::mom_pos(1) + $::mom_cycle_retract_to * $::mom_sys_spindle_axis(1)]
         set ::mom_cycle_retract_to_pos(2) [expr $::mom_pos(2) + $::mom_cycle_retract_to * $::mom_sys_spindle_axis(2)]
      }
   }
}


#=============================================================
proc PB_CMD__config_post_options { } {
#=============================================================
# <PB v10.03>
# This command should be called by Start-of-Program event;
# it enables users to set options (not via UI) that would
# affect the behavior and output of this post.
#
# Comment out next line to activate this command
return

  # <PB v10.03>
  # - Feed mode for RETRACT motion has been handled as RAPID,
  #   next option enables users to treat RETRACT as CONTOURing.
  #
   if { ![info exists ::mom_sys_retract_feed_mode] } {
      set ::mom_sys_retract_feed_mode  "CONTOUR"
   }
}


#=============================================================
proc PB_CMD__define_debug_msg { } {
#=============================================================
# This special command can be executed at Start of Program to facilitate
# the debugging capability of posts created by Post Builder.
# ==> DO NOT add or call it in any event or command!
# ==> DO NOT change its name!
#
# => Variable "PB_POST__debug" can be set true (1) to activate debug.
#
# => Signature of PB_POST__debug_msg { args } command should not be changed.
#    Calls to this command are embedded in all handlers generated by Post Builder.
#    *** Do Not call it in any before-output commands!!!
#    *** Do Not use it in utility commands e.g. CALLED_BY
#    This command can be called in other custom commands for debugging purpose.
#
# => Contents of debug messages (below) can be configured as desired by the users.
#
#-------------------------------------------------------------
# 01-17-2014 gsl - Initial version (v902)
#
#  ||||||||||||||||||||
#  VVVVVVVVVVVVVVVVVVVV
   set PB_POST__debug 0

   if $PB_POST__debug {
     uplevel #0 {
      proc PB_POST__debug_msg { args } {

         MOM_output_literal ">>> in [info level -1] - [join $args]"

        #+++++++++++++++++++++++++++++++++++++++++++++++++++
        # Configure the details of variables to be observed
        #
         if [info exists ::mom_out_angle_pos(1)] {
            MOM_output_literal ">>>>> mom_out_angle_pos(1): $::mom_out_angle_pos(1)"
         }
        #+++++++++++++++++++++++++++++++++++++++++++++++++++
      }
     }
   } else {
     uplevel #0 {
      proc PB_POST__debug_msg { args } {}
     }
   }
}


#=============================================================
proc PB_CMD__log_revisions { } {
#=============================================================
# Dummy command to log changes in this post --
#
# 02-26-09 gsl - Initial version
#
}


#=============================================================
proc PB_CMD__manage_part_attributes { } {
#=============================================================
# This command allows the user to manage the MOM variables
# generated for the part attributes, in case of conflicts.
#
# ==> This command is executed automatically when present in
#     the post. DO NOT add or call it in any event or command.
#

  # This command should only be called by MOM__part_attributes!
   if { ![CALLED_BY "MOM__part_attributes"] } {
return
   }

}


#=============================================================
proc PB_CMD__validate_4_axis_motion { } {
#=============================================================
# Validate legitimate motion for 4-axis post -
#
# => "mom_spindle_axis" accounts for the direction change resulted from the angled-head attachment added to the spindle.
#
# For a 4-axis Table - The spindle axis (Vs) and tool axis (Vt) should be either co-linear '||'
#                      BOTH on the plane of rotation (Vp).
# For a 4-axis Head  - The spindle axis (Vs) MUST lie ON the plane of rotation (Vp) '&&'
#                      identical to the tool axis (Vt).
#
# - The max/min of the rotary axis will further constraint the reachability.
# - Vectors' DOT product will be 0 or +/-1. (Vt.Vp => 0 || +/-1)
#
#-------------------------------------------------------------
# 04-29-2015 gsl - Carved out of LOCK_AXIS_MOTION to be called in MOM_before_motion
#

   if { [string match "4_axis_table" $::mom_kin_machine_type] } {

      if { !( [EQ_is_equal [expr abs( [VEC3_dot ::mom_sys_spindle_axis ::mom_tool_axis] )] 1.0] || \
              ( [EQ_is_equal [VEC3_dot ::mom_sys_spindle_axis ::mom_kin_4th_axis_vector] 0.0] && \
                [EQ_is_equal [VEC3_dot ::mom_tool_axis        ::mom_kin_4th_axis_vector] 0.0] ) ) } {

         CATCH_WARNING "Illegal motion for 4-axis table machine"
         MOM_abort_event

         return 0
      }
   }

   if { [string match "4_axis_head" $::mom_kin_machine_type] } {

      if { !( [EQ_is_equal [VEC3_dot ::mom_sys_spindle_axis ::mom_kin_4th_axis_vector] 0.0] && \
              [EQ_is_equal [VEC3_dot ::mom_sys_spindle_axis ::mom_tool_axis] 1.0] ) } {

         CATCH_WARNING "Illegal motion for 4-axis head machine"
         MOM_abort_event

         return 0
      }
   }

   return 1
}


#=============================================================
proc PB_CMD__validate_motion { } {
#=============================================================
# Validate legitimate motion outputs of different post configurations -
# ==> Do not rename this command!
#
# For a 4-axis Table - The spindle axis (Vs) and tool axis (Vt) should be either co-linear or (||)
#                      BOTH on the plane of rotation (Vp).
# For a 4-axis Head  - The spindle axis (Vs) should be identical to the tool axis (Vt) and (&&)
#                      must lie ON the plane of rotation (Vp).
#
# - "mom_spindle_axis" has accounted for the direction change resulted from
#   the angled-head attachment added to the spindle.
# - The max/min of the rotary axis will further constraint the reachability.
# - Vectors' DOT product will be 0 or +/-1. (Vt.Vp => 0 || +/-1)
#
# ==> This command can be enhanced to validate outputs of other post configurations.
#
#   Return: 1 = Motion OK
#           0 = Motion Bad
#-------------------------------------------------------------
# 04-29-2015 gsl - New
#

# return 1


  # "mom_spindle_axis" would include transformation of head attachment.
   if [info exists ::mom_spindle_axis] {
      VMOV 3 ::mom_spindle_axis ::mom_sys_spindle_axis
   } else {
      VMOV 3 ::mom_kin_spindle_axis ::mom_sys_spindle_axis
   }

   if { [string match "4_axis_table" $::mom_kin_machine_type] } {

      if { !( [EQ_is_equal [expr abs([VEC3_dot ::mom_sys_spindle_axis ::mom_tool_axis])] 1.0] || \
              ( [EQ_is_equal [VEC3_dot ::mom_sys_spindle_axis ::mom_kin_4th_axis_vector] 0.0] && \
                [EQ_is_equal [VEC3_dot ::mom_tool_axis        ::mom_kin_4th_axis_vector] 0.0] ) ) } {

         CATCH_WARNING "Illegal motion for 4-axis table machine"
         return 0
      }
   }

   if { [string match "4_axis_head" $::mom_kin_machine_type] } {

      if { !( [EQ_is_equal [VEC3_dot ::mom_sys_spindle_axis ::mom_tool_axis] 1.0] && \
              [EQ_is_equal [VEC3_dot ::mom_sys_spindle_axis ::mom_kin_4th_axis_vector] 0.0] ) } {

         CATCH_WARNING "Illegal motion for 4-axis head machine"
         return 0
      }
   }

   return 1
}


#=============================================================
proc PB_CMD_abort_event { } {
#=============================================================
# This command can be called to abort an event based on the
# flag being set by other handler under certain conditions,
# such as an invalid tool axis vector.
#
# Users can set the global variable mom_sys_abort_next_event to
# different severity levels throughout the post and designate
# how to handle different conditions in this command.
#
# - Rapid, linear, circular and cycle move events have this trigger
#   built in by default in PB6.0.
#
# 09-17-2015 szl - Output a warning message in NC output while postprocessor
#                  cannot calculate the valid rotary position.

   global mom_sys_abort_next_event
   global mom_warning_info
   global mom_sys_warning_output
   global mom_sys_warning_output_option

   if { [info exists mom_sys_abort_next_event] } {

      switch $mom_sys_abort_next_event {
        1 {
            unset mom_sys_abort_next_event
            if { ![string compare "WARNING: unable to determine valid rotary positions" $mom_warning_info] } {

               set save_mom_sys_warning_putput $mom_sys_warning_output
               set save_mom_sys_warning_output_option $mom_sys_warning_output_option


               set mom_sys_warning_output "ON"
               set mom_sys_warning_output_option "LIST"

               MOM_catch_warning

               set mom_sys_warning_output $save_mom_sys_warning_putput
               set mom_sys_warning_output_option $save_mom_sys_warning_output_option
            }
        }
         2 {
            unset mom_sys_abort_next_event
            CATCH_WARNING "Event aborted!"

            MOM_abort_event
         }
         default {
           unset mom_sys_abort_next_event
            CATCH_WARNING "Event warned!"
         }
      }
   }
}


#=============================================================
proc PB_CMD_arc_compressor_mode { } {
#=============================================================
# This procedure is used to set arc mode by Sinumerik compressor mode
  global mom_kin_arc_output_mode save_mom_kin_arc_output_mode
  global mom_kin_helical_arc_output_mode save_mom_kin_helical_arc_output_mode
  global mom_siemens_compressor

  if { [info exists mom_siemens_compressor] && $mom_siemens_compressor != "COMPOF" } {
     if { ![info exists save_mom_kin_arc_output_mode] } {
        set save_mom_kin_arc_output_mode $mom_kin_arc_output_mode
        set save_mom_kin_helical_arc_output_mode $mom_kin_helical_arc_output_mode
     }
     set mom_kin_arc_output_mode "LINEAR"
     set mom_kin_helical_arc_output_mode "LINEAR"
     MOM_reload_kinematics
  }

}


#=============================================================
proc PB_CMD_ask_machine_type { } {
#=============================================================
# Utility to return machine type per mom_kin_machine_type
#
# Revisions:
#-----------
# 02-26-09 gsl - Initial version
#
   global mom_kin_machine_type

   if { [string match "*wedm*" $mom_kin_machine_type] } {
return WEDM
   } elseif { [string match "*axis*" $mom_kin_machine_type] } {
return MILL
   } elseif { [string match "*lathe*" $mom_kin_machine_type] } {
return TURN
   } else {
return $mom_kin_machine_type
   }
}


#=============================================================
proc PB_CMD_before_motion { } {
#=============================================================
# Output motion type for following motions
  global mom_motion_type
  switch $mom_motion_type {
      "FIRSTCUT" -
      "DEPARTURE" -
      "STEPOVER" -
      "CUT" { PB_CMD_output_motion_message}
  }

}


#=============================================================
proc PB_CMD_before_output { } {
#=============================================================
# This command allows users to massage the NC data (mom_o_buffer) before
# it finally gets output.  If present in the post, this command gets executed
# by MOM_before_output automatically.
#
# - DO NOT overload MOM_before_output! All customization should be done here!
# - DO NOT call any MOM output commands in this command, it will become cyclicle!
# - No need to attach this command to any event marker.
#

   global mom_o_buffer
   global mom_sys_leader
   global mom_sys_control_out mom_sys_control_in
}


#=============================================================
proc PB_CMD_cancel_cycle { } {
#=============================================================
 # Unset parameters used in current cycle.
  global mom_cycle_delay_sec

  set cycle_param_list {RTP RFP SDIS DP DFR DTB FDEP FDPR DAM DTS FRF VARI O_AXN O_MDEP O_VRT O_DTD O_DIS1 \
                        SDR SDAC MPIT ENC PIT POSS SST SST1 O_PTAB O_TECHNO O_VAR1 O_DAM  FFR RFF SDIR RPA RPO RPAP \
                        AMODE DMODE GMODE LIFTOFF}


  foreach param $cycle_param_list {
    set param [string tolower $param]
    set param mom_siemens_cycle_$param
    global $param
    if {[info exists $param]} {
       unset $param
    }
  }
  catch { unset mom_cycle_delay_sec }


 # Reset count of cycle move
  global mom_siemens_cycle_count
  set mom_siemens_cycle_count 0

  MOM_force Once X Y Z
}


#=============================================================
proc PB_CMD_check_settings_for_cycle832 { } {
#=============================================================
# This command is used to check the settings for cycle832.
#
# 04-Jan-2017 shuai - CYCLE832 enhancement.
#

  global mom_siemens_compressor
  global mom_siemens_smoothing
  global mom_siemens_feedforward
  global mom_operation_name

  if {[info exists mom_siemens_compressor] && ![string compare "COMPOF" $mom_siemens_compressor]} {

     # MOM_output_to_listing_device "Warning in $mom_operation_name: User defined compressor off is conflict with controller default setting in CYCLE832."
     # MOM_output_to_listing_device "$mom_siemens_compressor will be output with CYCLE832."
     MOM_output_literal "$mom_siemens_compressor"
  }

  if {[info exists mom_siemens_smoothing] && ![string compare "G60" $mom_siemens_smoothing]} {

     MOM_output_to_listing_device "Warning in $mom_operation_name: User defined smoothing off is conflict with controller default setting in CYCLE832."
     MOM_output_to_listing_device "$mom_siemens_smoothing will be output with CYCLE832."
     MOM_output_literal "$mom_siemens_smoothing"
  }

  if {[info exists mom_siemens_feedforward] && ![string compare "FFWOF" $mom_siemens_feedforward]} {

     MOM_output_to_listing_device "Warning in $mom_operation_name: User defined feed forward off is conflict with controller default setting in CYCLE832."
     MOM_output_to_listing_device "$mom_siemens_feedforward will be output with CYCLE832."
     MOM_output_literal "$mom_siemens_feedforward"
  }

}


#=============================================================
proc PB_CMD_choose_output_mode { } {
#=============================================================
# This proc is used to output proper address for current mode.
#
# 10-15-13 Allen - Modify it to output fourth_axis fifth_axis for using LOCK_AXIS.

  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_3Dcutcom_mode
  global mom_siemens_coord_rotation
  global mom_siemens_5axis_mode
  global mom_siemens_ori_coord
  global mom_prev_tool_axis
  global mom_tool_axis

  # 5 axis orient definition
  if { ![info exists mom_siemens_ori_def] } {
     set mom_siemens_ori_def "ROTARY AXES"
  }

  if { [string match "3_axis_mill" $mom_kin_machine_type] } {
     MOM_suppress Once A3 B3 C3
  } else {
     if { [string match "*ROTARY*" $mom_siemens_ori_def] } {
        MOM_suppress Once A3 B3 C3
     } else {
        if { [string match "ORIMKS" $mom_siemens_ori_coord] && $mom_siemens_coord_rotation == 1 } {
           global mom_tool_axis mom_csys_matrix csys_matrix tool_axis

           MTX3_transpose mom_csys_matrix csys_matrix
           MTX3_vec_multiply mom_tool_axis csys_matrix tool_axis
           VMOV 3 tool_axis mom_tool_axis
        }

      #  MOM_force Once A3 B3 C3
        MOM_suppress Once fourth_axis fifth_axis
     }
  }

  if { $mom_siemens_coord_rotation != 0 && [string match "SWIVELING" $mom_siemens_5axis_mode] } {
     MOM_suppress Once fourth_axis fifth_axis
     MOM_suppress Once A3 B3 C3
  }

  #Cutcom type
  if { [info exists mom_siemens_3Dcutcom_mode] } {
     if { [string match "3DF" $mom_siemens_3Dcutcom_mode] || [string match "3DFF" $mom_siemens_3Dcutcom_mode] } {
        global mom_contact_status
        if { [info exists mom_contact_status] && [string match "ON" $mom_contact_status] } {
           MOM_force Once A5 B5 C5
        } else {
       MOM_suppress Once A5 B5 C5
        }
     } else {
        MOM_suppress Once A5 B5 C5
     }
  }
}


#=============================================================
proc PB_CMD_clamp_fifth_axis { } {
#=============================================================
#  This command is used by auto clamping to output the code
#  needed to clamp the fifth axis.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#
  MOM_output_literal "M12"
}


#=============================================================
proc PB_CMD_clamp_fourth_axis { } {
#=============================================================
#  This command is used by auto clamping to output the code
#  needed to clamp the fourth axis.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#
  MOM_output_literal "M10"
}


#=============================================================
proc PB_CMD_config_cycle_start { } {
#=============================================================
# When a post (PUI) is configured to use this command as the
# "post_startblk" parameter, this command will be inserted and
# output as the anchor element for the cycles using "cycle start"
# to execute the cycles.
#
# You can add codes here for the needs of individual cycles or
# any other purposes.
#
# ==> This command may not be deleted or added to other event markers.
#
   PB_CMD_choose_output_mode

   global mom_siemens_cycle_count mom_cycle_spindle_axis
   global mom_siemens_coord_rotation

   if {![info exists mom_siemens_cycle_count]} {
      set mom_siemens_cycle_count 0
   }

   if {$mom_siemens_cycle_count == 0} {
      MOM_force Once X Y
   }

   incr mom_siemens_cycle_count

   if { $mom_siemens_coord_rotation == 1 } {
     MOM_suppress Once fourth_axis fifth_axis A3 B3 C3
   }

#<lili 2014-11-28> Fix drilling cycle motion output with TRAORI mode issue.
   global mom_siemens_5axis_output_mode
   global mom_pos mom_mcs_goto

  if {$mom_siemens_5axis_output_mode == 1 && $mom_siemens_coord_rotation !=2} {
     set mom_pos(0) $mom_mcs_goto(0)
     set mom_pos(1) $mom_mcs_goto(1)
  }
}


#=============================================================
proc PB_CMD_coolant_on { } {
#=============================================================
# This command is used to set coolant on as default for OOTB kits unless
# the operation type is Deep Hole Drilling.
#
# 2015-12-22 szl - Initial implementation
# 2016-03-29 szl - Update mom_coolant_mode if operation doesn't attach UDE, otherwise it won't work in turbo mode.

   global mom_operation_type mom_coolant_status mom_coolant_mode

   if {![string match "Deep Hole Drilling" $mom_operation_type]} {

      if { [info exists mom_coolant_mode] && $mom_coolant_mode == "" } {
         set mom_coolant_status "ON"
         set mom_coolant_mode "ON"
      }
   }
}


#=============================================================
proc PB_CMD_creat_tool_list { } {
#=============================================================
#  Place this custom command in either the start of program
#  or the end of program event marker to generate a tool list
#  in your NC file.
#
#  The Shop Doc template file "pb_post_tool_list.tpl" distributed with
#  Post Builder in "POSTBUILD/pblib/misc" directory can be copied
#  to the "mach/resource/postprocessor" or "mach/resource/shop_docs" directory,
#  in case that your UG runtime environment does not have access to the
#  Post Builder installation.
#
#  Accessing "pb_post_tool_list.tpl" in other location can also be accomplished
#  by changing the code below titled "Generate tool list data" in this proc.
#
#  The variable "mom_sys_tool_list_output_type" set in this proc allows you
#  to select the type of tool list to be generated.
#  The options are:
#
#   "ORDER_IN_USE"     - List tools used in the program in the order of operations.
#   "ALL_UNIQUE"       - List all unique tools once for each in the order of use.
#   "GROUP_BY_TYPE"    - List tools in groups of different tool types.
#
# The desired tool list type can be set by changing the code below.
# The default is set to "GROUP_BY_TYPE".
#

   set wfl_global [info globals "mom_*"]
   foreach gv $wfl_global {
      global Twfl_$gv $gv
      if {[info exists $gv]} {
        if {![array exists $gv]} {
           set wfl Twfl_$gv
           set $wfl [set $gv]
        }
     }
   }

   global mom_sys_tool_list_initialized
   global mom_sys_tool_list_output_type


   if { ![info exists mom_sys_tool_list_initialized] || !$mom_sys_tool_list_initialized } {
      MOM_output_to_listing_device "proc PB_CMD_init_tool_list must be executed in the Start of Program before PB_CMD_create_tool_list is called."
return
   }


  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Set mom_sys_tool_list_output_type to the desired output fashion.
  #
  #   "ORDER_IN_USE"     - List tools used in the program in the order of operations.
  #   "ALL_UNIQUE"       - List all unique tools once for each in the order of use.
  #   "GROUP_BY_TYPE"    - List tools in groups of different tool types.
  #
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # set mom_sys_tool_list_output_type "ORDER_IN_USE"
  # set mom_sys_tool_list_output_type "ALL_UNIQUE"
   set mom_sys_tool_list_output_type "GROUP_BY_TYPE"


   global mom_sys_control_out mom_sys_control_in
   global current_program_name
   global mom_tool_number mom_tool_length_adjust_register mom_tool_name


  #----------------------------------------------------------------------------
  # Save info for the currently active tool in the program being post-prcessed
  # before starting Shop Doc mechanism for tool list generation.
  #----------------------------------------------------------------------------
   if [llength [info commands PB_CMD_save_active_oper_tool_data] ] {
      PB_CMD_save_active_oper_tool_data
   }


  #-----------------------------------------------------------
  # Create tool list per selected top-level group.
  # Group name is set to blank if no group has been selected.
  #-----------------------------------------------------------
   global mom_parent_group_name

   if [info exists mom_parent_group_name] {
      set current_program_name $mom_parent_group_name
   } else {
      set current_program_name ""
   }


   set ci " "
   set co " "

   if [info exists mom_sys_control_in] { set ci $mom_sys_control_in }
   if [info exists mom_sys_control_out] { set co $mom_sys_control_out }


  #*************************
  # Generate tool list data
  #*************************
   set template_file pb_post_tool_list.tpl

   global tcl_platform
   if [string match "windows" $tcl_platform(platform)] {
      set pb_lib_misc_dir [MOM_ask_env_var UGII_BASE_DIR]\\postbuild\\pblib\\misc\\
   } else {
      set pb_lib_misc_dir [MOM_ask_env_var UGII_BASE_DIR]/postbuild/pblib/misc/
   }

   set cam_post_dir     [MOM_ask_env_var UGII_CAM_POST_DIR]
   set cam_shop_doc_dir [MOM_ask_env_var UGII_CAM_SHOP_DOC_DIR]

   if { [file exists ${pb_lib_misc_dir}${template_file}] } {

      MOM_do_template_file ${pb_lib_misc_dir}${template_file}

   } elseif { [file exists ${cam_post_dir}${template_file}] } {

      MOM_do_template_file ${cam_post_dir}${template_file}

   } elseif { [file exists ${cam_shop_doc_dir}${template_file}] } {

      MOM_do_template_file ${cam_shop_doc_dir}${template_file}

   } else {

      MOM_output_to_listing_device  "ERROR : Template file pb_post_tool_list.tpl is not found in the following directories: \n \n          $pb_lib_misc_dir \n          $cam_post_dir \n          $cam_shop_doc_dir \n \n        Tool list cannot be generated.\n"
return
   }



  #------------------
  # Tool list header
  #------------------
#   shop_doc_output_literal "$co===============================================================================================$ci"
#   shop_doc_output_literal "$co                                   T O O L   L I S T                                           $ci"
#   shop_doc_output_literal "$co===============================================================================================$ci"


  #------------------
  # Output tool list
  #------------------
   global tool_data_buffer
   global mom_sys_tool_stack

   switch $mom_sys_tool_list_output_type {

      "ORDER_IN_USE" {
         set tool_list $mom_sys_tool_stack(IN_USE)
      }

      "GROUP_BY_TYPE" {
         set tool_list [concat $mom_sys_tool_stack(LATHE)  $mom_sys_tool_stack(DRILL)  $mom_sys_tool_stack(MILL)]
      }

      default {
         set tool_list $mom_sys_tool_stack(ALL)
      }
   }


   set prev_tool_type ""

   foreach tool $tool_list {

      set tool_type $tool_data_buffer($tool,type)

     # Output tool type header if it changes.
      if { ![string match "$tool_type" $prev_tool_type] } {
         if { [info exists tool_data_buffer($tool_type,header)] &&  $tool_data_buffer($tool_type,header) != "" } {
            shop_doc_output_literal ";$tool_data_buffer($tool_type,header)"
         }
      }

      if [info exists tool_data_buffer($tool,output)] {
         shop_doc_output_literal ";$tool_data_buffer($tool,output)"
      }
      set prev_tool_type $tool_type
   }



  #------------------
  # Tool list footer
  #------------------
   shop_doc_output_literal ";$co                                                                                               $ci"


  #-------------------------------------------------------------------------------
  # Restore info for the currently active tool in the program being post-prcessed.
  #-------------------------------------------------------------------------------
   if [llength [info commands PB_CMD_restore_active_oper_tool_data] ] {
      PB_CMD_restore_active_oper_tool_data
   }

  set wfl_global [info globals "Twfl_*"]
  foreach gv $wfl_global {
     set mv [string trimleft $gv "Twfl_"]
     global $gv $mv
     if {[info exists $gv]} {
       set $mv [set $gv]
       unset $gv
    }
  }
}


#=============================================================
proc PB_CMD_cycle_tap { } {
#=============================================================
# This procedure is used to set tap cycle parameters for sinumerik 840D
#

  #-------------------------------------------------------
  # Inputs for tapping
  #-------------------------------------------------------
   global mom_spindle_speed
   global mom_spindle_direction
   global mom_motion_event
   global feed

   global mom_siemens_cycle_sdr
   global mom_siemens_cycle_enc
   global mom_siemens_cycle_sdac
   global mom_siemens_cycle_mpit
   global mom_siemens_cycle_pit
   global mom_siemens_cycle_poss
   global mom_siemens_cycle_sst
   global mom_siemens_cycle_sst1
   global mom_siemens_cycle_sdac
   global mom_siemens_cycle_sdr
   global mom_siemens_cycle_enc
   global mom_siemens_cycle_o_ptab
   global mom_siemens_cycle_o_var1
   global mom_cycle_option


   if { ![string match "tap*_move" $mom_motion_event] } {
return
   }

   if { ![info exists mom_siemens_cycle_sdac] } {
      set mom_siemens_cycle_sdac 3
   } else {
      switch $mom_siemens_cycle_sdac {
         CLW     { set mom_siemens_cycle_sdac 3 }
         CCLW    { set mom_siemens_cycle_sdac 4 }
         Off     { set mom_siemens_cycle_sdac 5 }
         default {}
      }
   }

   global mom_siemens_cycle_mpit_defined

   if { [info exists mom_siemens_cycle_mpit] } {
      if { $mom_spindle_direction == "CCLW" } {
         set mom_siemens_cycle_mpit [expr -1*$mom_siemens_cycle_mpit]
      }

     # If users set mpit, pit will be ignored
      UNSET_VARS mom_siemens_cycle_pit
      UNSET_VARS mom_siemens_cycle_o_ptab

   } else {
      if { [info exists mom_siemens_cycle_o_ptab] } {
         switch $mom_siemens_cycle_o_ptab {
            "Post Defined"        { set mom_siemens_cycle_o_ptab 0 }
            "Millimeter"          { set mom_siemens_cycle_o_ptab 1 }
            "Groove per Inch"     { set mom_siemens_cycle_o_ptab 2 }
            "Inch per Revolution" { set mom_siemens_cycle_o_ptab 3 }
            default               {}
         }
      } else {
         set mom_siemens_cycle_o_ptab 0
      }

      if {[info exists mom_siemens_cycle_pit]} {
         if {$mom_siemens_cycle_pit == 0 || $mom_siemens_cycle_o_ptab == 0} {
            global mom_cycle_feed_rate_per_rev mom_cycle_feed_rate
            if {[info exist mom_cycle_feed_rate_per_rev] && ![EQ_is_zero $mom_cycle_feed_rate_per_rev]} {
                set mom_siemens_cycle_pit $mom_cycle_feed_rate_per_rev
            } elseif { [info exists mom_spindle_speed] && $mom_spindle_speed != 0 } {
                set mom_siemens_cycle_pit [expr $mom_cycle_feed_rate/$mom_spindle_speed]
            }
         }
         if {$mom_spindle_direction == "CCLW"} {
            set mom_siemens_cycle_pit [expr -1*$mom_siemens_cycle_pit]
         }
      } else {
         global mom_cycle_feed_rate_per_rev mom_cycle_feed_rate
         if {[info exist mom_cycle_feed_rate_per_rev] && ![EQ_is_zero $mom_cycle_feed_rate_per_rev]} {
            set mom_siemens_cycle_pit $mom_cycle_feed_rate_per_rev
            if {$mom_spindle_direction == "CCLW"} {
               set mom_siemens_cycle_pit [expr -1*$mom_siemens_cycle_pit]
            }
         } elseif { [info exists mom_spindle_speed] && $mom_spindle_speed != 0 } {
            set mom_siemens_cycle_pit [expr $mom_cycle_feed_rate/$mom_spindle_speed]
            if {$mom_spindle_direction == "CCLW"} {
               set mom_siemens_cycle_pit [expr -1*$mom_siemens_cycle_pit]
            }
         }
      }
   }

   if { [info exists mom_spindle_speed] } {
      set mom_siemens_cycle_sst $mom_spindle_speed
   }
   if {![info exists mom_siemens_cycle_sst1] } {
      set mom_siemens_cycle_sst1 0
   }

   if { [info exists mom_siemens_cycle_o_var1] } {
      switch $mom_siemens_cycle_o_var1 {
         "Single Pass" { set mom_siemens_cycle_o_var1 0 }
         "Break Chip"  { set mom_siemens_cycle_o_var1 1 }
         "Remove Chip" { set mom_siemens_cycle_o_var1 2 }
         default       {}
      }
   }

   if { [info exists mom_siemens_cycle_enc] } {
      switch $mom_siemens_cycle_enc {
         "Use Encoder-Dwell Off"             { set mom_siemens_cycle_enc 0  }
         "Use Encoder-Dwell On"              { set mom_siemens_cycle_enc 20 }
         "No Encoder-Feed Rate before Cycle" { set mom_siemens_cycle_enc 1  }
         "No Encoder-Feed Rate in Cycle"     { set mom_siemens_cycle_enc 11 }
         default  {}
      }
   }

   if { [info exists mom_siemens_cycle_sdr] } {
      switch $mom_siemens_cycle_sdr {
         "Reversal" { set mom_siemens_cycle_sdr 0 }
         "CLW"      { set mom_siemens_cycle_sdr 3 }
         "CCLW"     { set mom_siemens_cycle_sdr 4 }
         default    {}
      }
   }

}


#=============================================================
proc PB_CMD_cycle_tap_parameter_setting { } {
#=============================================================
# 07-08-14 Allen - This procedure is used to set tap cycle parameters for sinumerik 840D
# 08-21-2015 szl  - Enhance the warning message when users set wrong pitch and wrong spindle speed,fix PR7463004.

  #-------------------------------------------------------
  # Inputs for tapping
  #-------------------------------------------------------
   global mom_spindle_speed
   global mom_spindle_direction
   global mom_motion_event
   global mom_siemens_cycle_mpit
   global mom_cycle_thread_pitch
   global mom_siemens_cycle_poss
   global mom_siemens_cycle_sst
   global mom_siemens_cycle_sst1
   global mom_siemens_cycle_sdac
   global mom_siemens_cycle_sdr
   global mom_siemens_cycle_enc
   global mom_siemens_cycle_o_ptab
   global mom_siemens_cycle_o_var1
   global mom_output_unit
   global mom_operation_name
   global mom_cycle_thread_right_handed
   global mom_siemens_cycle_pit
   global mom_tool_pitch
   global mom_retract_spindle
   global mom_cycle_step1
   global mom_siemens_cycle_o_dam
   global mom_cycle_orient
   global mom_siemens_cycle_o_vrt
   global mom_cycle_step_clearance
   global mom_cycle_feed_rate_mode
   global mom_cycle_feed_rate
   global mom_tool_name
   global mom_feed_cut_unit
   global mom_spindle_rpm

   if { ![string match "tap*_move" $mom_motion_event] } {
return
   }

   if { ![info exists mom_siemens_cycle_sdac] } {
      set mom_siemens_cycle_sdac 3
   } else {
      switch $mom_siemens_cycle_sdac {
         CLW     { set mom_siemens_cycle_sdac 3 }
         CCLW    { set mom_siemens_cycle_sdac 4 }
         Off     { set mom_siemens_cycle_sdac 5 }
         default {}
      }
   }


   if { [info exists mom_siemens_cycle_mpit] } {
      if { ![info exists mom_cycle_thread_right_handed] } {
         if {$mom_spindle_direction == "CCLW"} {
            set mom_siemens_cycle_mpit [expr -1*$mom_siemens_cycle_mpit]
         }
      } elseif { $mom_cycle_thread_right_handed == "FALSE" } {
         set mom_siemens_cycle_mpit [expr -1*$mom_siemens_cycle_mpit]
      }
     # If users set mpit, pit will be ignored
      UNSET_VARS mom_siemens_cycle_o_ptab
      UNSET_VARS mom_siemens_cycle_pit

   } else {
      if { [info exists mom_siemens_cycle_o_ptab] } {
         switch $mom_siemens_cycle_o_ptab {
            "Post Defined"        { set mom_siemens_cycle_o_ptab 0 }
            "Millimeter"          { set mom_siemens_cycle_o_ptab 1 }
            "Groove per Inch"     { set mom_siemens_cycle_o_ptab 2 }
            "Inch per Revolution" { set mom_siemens_cycle_o_ptab 3 }
            default               {}
         }
      } else {
         set mom_siemens_cycle_o_ptab 0
      }

      if { [info exists mom_tool_pitch] } {
      if {[info exists mom_cycle_thread_pitch]} {
         set mom_siemens_cycle_pit $mom_cycle_thread_pitch
      } else {
            set mom_siemens_cycle_pit $mom_tool_pitch
         }
         } else {
         MOM_display_message "$mom_operation_name: No pitch defined on the tool. Please use Tap tool. \n Post Processing will be aborted." "Postprocessor error message" "E"
         MOM_abort_program
      }

      if {$mom_siemens_cycle_o_ptab == 1} {
         if {[string match "IN" $mom_output_unit]} {
            set mom_siemens_cycle_pit [expr $mom_siemens_cycle_pit*25.4]
         }
      } elseif { $mom_siemens_cycle_o_ptab == 2} {
         if {![string match "IN" $mom_output_unit]} {
            set mom_siemens_cycle_pit [expr 25.4/$mom_siemens_cycle_pit]
         } else {
            set mom_siemens_cycle_pit [expr 1/$mom_siemens_cycle_pit]
         }
      } elseif { $mom_siemens_cycle_o_ptab == 3 } {
         if {![string match "IN" $mom_output_unit]} {
            set mom_siemens_cycle_pit [expr $mom_siemens_cycle_pit/25.4]
         }
      }
      if { ![info exists mom_cycle_thread_right_handed] } {
         if {$mom_spindle_direction == "CCLW"} {
            set mom_siemens_cycle_pit [expr -1*$mom_siemens_cycle_pit]
         }
      } elseif { $mom_cycle_thread_right_handed == "FALSE" } {
         set mom_siemens_cycle_pit [expr -1*$mom_siemens_cycle_pit]
      }
   }

   if {[info exists mom_spindle_speed] && ![EQ_is_zero $mom_spindle_speed] } {
      set mom_siemens_cycle_sst $mom_spindle_rpm
   } else {
      MOM_display_message "$mom_operation_name : spindle speed is 0. Post Processing will be aborted." "Postprocessor error message" "E"
      MOM_abort_program
   }

   if { ![info exists mom_retract_spindle] || $mom_retract_spindle == 0} {
      set mom_siemens_cycle_sst1 $mom_spindle_rpm
   } else {
      set mom_siemens_cycle_sst1 [expr 0.01*$mom_retract_spindle*$mom_spindle_speed]
   }

     #mom_siemens_cycle_o_var1 is set for cycle84
   switch $mom_motion_event {
      "tap_move"             { set mom_siemens_cycle_o_var1 0 }
      "tap_break_chip_move"  { set mom_siemens_cycle_o_var1 1
                               set mom_siemens_cycle_o_dam $mom_cycle_step1
                               catch {set mom_siemens_cycle_poss $mom_cycle_orient}
                               if {![info exists mom_cycle_step_clearance]} { set  mom_cycle_step_clearance 0}
                               set mom_siemens_cycle_o_vrt $mom_cycle_step_clearance
      }
      "tap_deep_move"        { set mom_siemens_cycle_o_var1 2
                               set mom_siemens_cycle_o_dam $mom_cycle_step1
                               catch {set mom_siemens_cycle_poss $mom_cycle_orient}
      }
      "tap_float_move"       {}
      default                {}
   }

   #mom_siemens_cycle_enc is set for cycle840
   if { [info exists mom_siemens_cycle_enc] } {
      switch $mom_siemens_cycle_enc {
         "Use Encoder-Dwell Off"             { set mom_siemens_cycle_enc 0  }
         "Use Encoder-Dwell On"              { set mom_siemens_cycle_enc 20 }
         "No Encoder-Feed Rate before Cycle" { set mom_siemens_cycle_enc 1  }
         "No Encoder-Feed Rate in Cycle"     { set mom_siemens_cycle_enc 11 }
         default  {}
      }
   }
   #mom_siemens_cycle_sdr is set for cycle840
   if { [info exists mom_siemens_cycle_sdr] } {
      switch $mom_siemens_cycle_sdr {
         "Reversal" { set mom_siemens_cycle_sdr 0 }
         "CLW"      { set mom_siemens_cycle_sdr 3 }
         "CCLW"     { set mom_siemens_cycle_sdr 4 }
         default    {}
      }
   }

}


#=============================================================
proc PB_CMD_define_feed_variable_value { } {
#=============================================================
#This command is used to get feed value and define feed rate in variables.
#and PB_CMD_define_feedrate_format which is called from PB_CMD_before_motion.
  global mom_siemens_feed_value
  global mom_siemens_feed_definition
  global mom_seqnum
  global mom_siemens_feed_block
  global mom_siemens_feed_output_block
  global mom_siemens_feed_output_seqnum
  global feed_definition

  if { [info exists mom_siemens_feed_definition] && $mom_siemens_feed_definition == "ON" } {
     PB_CMD_get_feed_value
     MOM_output_literal ";"
     MOM_output_literal "_F_CUTTING=$mom_siemens_feed_value(cut) _F_ENGAGE=$mom_siemens_feed_value(engage) _F_RETRACT=$mom_siemens_feed_value(retract)"
     MOM_output_literal ";"
  }
}


#=============================================================
proc PB_CMD_define_feedrate_format { } {
#=============================================================
# This command is used to redefine feedrate output format as string and record feedrate
# value.
# Using mom_sinumerik_feed instead of feed for output in NX7.0. feed cannot be set to a
# string value.
  global mom_siemens_feed_definition
  global mom_siemens_feed_var_num
  global mom_siemens_feed_value
  global feed
  global mom_motion_type
  global feed_definition
  global mom_sinumerik_feed

  # Feedrate definition in variable
  if {[info exists mom_siemens_feed_definition] && $mom_siemens_feed_definition == "ON"} {
     MOM_set_address_format F String
     set motion_type [string tolower $mom_motion_type]
     switch $motion_type {
        "cut" -
        "firstcut" -
        "stepover" { set mom_sinumerik_feed "=_F_CUTTING"}
        "engage" { set mom_sinumerik_feed "=_F_ENGAGE"}
        "retract" { set mom_sinumerik_feed "=_F_RETRACT"}
        default {
           # set mom_sinumerik_feed 0
           MOM_set_address_format F Feed
        }
     }
  }
}


#=============================================================
proc PB_CMD_detect_5axis_tool_path { } {
#=============================================================
# This proc is used to detect if the operation is 5 axis simultaneous milling operation.
#
# This command is referenced by DPP_GE_DETECT_5AXIS_TOOL_PATH.
#
# In this command, tool path type is detected by mom_operation_type, mom_tool_path_type and mom_tool_axis_type.
#
# The result may not always match 5-axis simultaneous milling.
# It is more tolerance.
#
# Return:
#   1 - tool path is 5 axis simultaneous
#   0 - tool path is not 5 axis simultaneous
#
# 16-Jan-2017 shuai - Initial version.
#

  global mom_tool_axis_type
  global mom_tool_path_type
  global mom_operation_type

  if {![info exists mom_tool_axis_type] } {
     set mom_tool_axis_type 0
  }

  if {![info exists mom_tool_path_type] } {
     set mom_tool_path_type "undefined"
  }

  if {[PB_CMD_detect_hole_cutting_operation]} {

     return 0

  } elseif {($mom_tool_axis_type >= 2 && [string match "Variable-axis *" $mom_operation_type]) || \
            ![string compare "Sequential Mill Main Operation" $mom_operation_type] || \
            (![string compare "variable_axis" $mom_tool_path_type] && ![string match "Variable-axis *" $mom_operation_type] && [string compare "Generic Motion" $mom_operation_type])} {

     return 1

  } else {

     return 0
  }

}


#=============================================================
proc PB_CMD_detect_hole_cutting_operation { } {
#=============================================================
# This proc is used to detect if the operation is a hole cutting operation.
#
# This command is referenced by DPP_GE_DETECT_HOLE_CUTTING_OPERATION.
#
# Hole cutting operation includs:
#   Point to Point,
#   Hole Making,
#   Drilling
#   Cylinder Milling,
#   Thread Milling,
#   Chamfer Milling,
#   Radial Groove Milling.
#
# Return:
#   1 - operation is hole cutting operation
#   0 - operation is not hole cutting operation
#
# 16-Jan-2017 shuai - Initial version.
#

  global mom_operation_type

  if {![string compare "Point to Point" $mom_operation_type] || \
      ![string compare "Hole Making" $mom_operation_type] || \
      ![string compare "Drilling" $mom_operation_type] || \
      ![string compare "Cylinder Milling" $mom_operation_type] || \
      ![string compare "Thread Milling" $mom_operation_type] || \
      ![string compare "Chamfer Milling" $mom_operation_type] || \
      ![string compare "Radial Groove Milling" $mom_operation_type] } {

     return 1

  } else {

     return 0
  }

}


#=============================================================
proc PB_CMD_detect_operation_type { } {
#=============================================================
# This command is used to set operation's output type based on tool path type and UDE.
# Following variables will be set in this command
# mom_siemens_5axis_mode "TRAORI"/"TRAORI2"/"TRAFOOF"/"SWIVELING"
# mom_siemens_5axis_output "TRAORI"/"TRAORI(2)""TRAFOOF"
# mom_siemens_5axis_output_mode "1"/"0" ;#TCP mode
# mom_siemens_coord_rotation "0"/"1"/"2"

  global mom_ude_5axis_tool_path
  global dpp_ge
  global mom_siemens_5axis_output_mode
  global mom_siemens_5axis_mode
  global mom_siemens_5axis_output
  global mom_siemens_coord_rotation
  global dpp_coord_rotation_output_type
  global coord_angle coord_offset
  global coord_ang_A coord_ang_B coord_ang_C
  global mom_siemens_milling_setting
  global mom_operation_name
  global cycle_init_flag mom_current_motion
  global mom_cycle_rapid_to
  global mom_pos
  global mom_kin_coordinate_system_type

  #10-15-2013 Allen- Save kinematics
  DPP_GE_SAVE_KINEMATICS
  # Detect tool path type
  if {[info exists mom_ude_5axis_tool_path] } {
    # tool path type set by UDE
    if {$mom_ude_5axis_tool_path == "YES"} {
       set dpp_ge(toolpath_axis_num) 5
    } else {
       set dpp_ge(toolpath_axis_num) 3
    }
  } else {
    # tool path type set by post
    if {[DPP_GE_DETECT_5AXIS_TOOL_PATH]} {
       set dpp_ge(toolpath_axis_num) 5
    } else {
       set dpp_ge(toolpath_axis_num) 3
    }
  }


  # Set output mode by post default rule if no UDE
  if { $mom_siemens_milling_setting == "Default"} {
     if {$dpp_ge(toolpath_axis_num)==5} {
       # set 5-axis simultaneous operation type
        set mom_siemens_5axis_mode "TRAORI"
     } else {
        set mom_siemens_5axis_mode $dpp_coord_rotation_output_type
     }
  }

  set mom_siemens_5axis_output_mode 0

  if {$mom_siemens_5axis_mode == "TRAORI" || $mom_siemens_5axis_mode == "TRAORI2" } {
     set mom_siemens_5axis_output_mode 1
     set mom_siemens_5axis_output "TRAORI"
     if {$mom_siemens_5axis_mode == "TRAORI2"} {
        set mom_siemens_5axis_output "TRAORI(2)"
     }
  } elseif {$mom_siemens_5axis_mode == "TRAFOOF"} {
     set mom_siemens_5axis_output_mode 0
     set mom_siemens_5axis_output "TRAFOOF"
  } elseif {$mom_siemens_5axis_mode == "SWIVELING"} {
     set mom_siemens_5axis_output_mode 0
     set mom_siemens_5axis_output "TRAFOOF"
     if {$dpp_ge(toolpath_axis_num) == 5} {
        MOM_output_to_listing_device " $mom_operation_name is 5 axis simultaneous operation, \
                                      should not work with SWIVELING mode please check UDE "
        set dpp_ge(toolpath_axis_num) 3
     }
  }

  # Get coordinate rotation mode
  # mom_siemens_coord_rotation is 0 - no coordinate rotation
  # mom_siemens_coord_rotation is 1 - coordinate rotation from Local CSYS rotation MCS
  # mom_siemens_coord_rotation is 2 - coordinate rotation from tilt tool axis
  set mom_siemens_coord_rotation 0
  if {$dpp_ge(toolpath_axis_num)==5} {
    # set 5-axis simultaneous operation type
     set mom_siemens_coord_rotation 0

     # <26-Jul-2016 Shuai Set coordinate system offset to value 0 in 5-axis operation.>
     # <Fix PR7700495>
     set coord_offset(0) 0; set coord_offset(1) 0; set coord_offset(2) 0

     set coord_angle(1) 0; set coord_angle(2) 0; set coord_angle(3) 0
     if {[info exists mom_kin_coordinate_system_type] && ![string compare "CSYS" $mom_kin_coordinate_system_type]} {
         MOM_output_to_listing_device "$mom_operation_name : LOCAL CSYS Rotated MCS should not work with 5-axis simultaneous operation!"
     }
     global mom_kin_arc_output_mode save_mom_kin_arc_output_mode
     global mom_kin_helical_arc_output_mode save_mom_kin_helical_arc_output_mode
     if { ![info exists save_mom_kin_arc_output_mode] } {
        set save_mom_kin_arc_output_mode $mom_kin_arc_output_mode
        set save_mom_kin_helical_arc_output_mode $mom_kin_helical_arc_output_mode
     }
     set mom_kin_arc_output_mode "LINEAR"
     set mom_kin_helical_arc_output_mode "LINEAR"
     MOM_reload_kinematics
  } else {
    # check if operation is 3-axis or 3+2 axis operation
    # if operation is 3+2 operation and not under local CSYS rotation MCS
    # machine kinmeatics is reloaded to dual-table machine.
     set dpp_ge(coord_rot) [DPP_GE_COOR_ROT "XYZ" rot_angle offset pos]
     # set cooridnate linear offset value
     VMOV 3 offset coord_offset
     # set coordinate rotation agnle
     VMOV 3 rot_angle coord_angle
     set coord_ang_A $coord_angle(0);set coord_ang_B $coord_angle(1);set coord_ang_C $coord_angle(2)
     if {$dpp_ge(coord_rot) != "NONE"} {
         if {$dpp_ge(coord_rot) == "AUTO_3D"}  {
            set mom_siemens_coord_rotation 2
            VMOV 3 pos mom_pos
            if {[info exists cycle_init_flag] && $cycle_init_flag == "TRUE"} {
               if { [string match "initial_move" $mom_current_motion]} {
                  set mom_pos(2) [expr $mom_pos(2) + $mom_cycle_rapid_to]
               }
            }
            MOM_reload_variable -a mom_pos
         } else {
            set mom_siemens_coord_rotation 1
         }
     } else {

        if { $mom_siemens_milling_setting == "Default"} {
           set mom_siemens_5axis_mode "TRAFOOF"
           set mom_siemens_5axis_output "TRAFOOF"
           set mom_siemens_5axis_output_mode 0
        }
        set mom_siemens_coord_rotation 0
     }
  }

 #MOM_output_to_listing_device "$mom_operation_name rot $mom_siemens_coord_rotation 5axis $mom_siemens_5axis_mode"
}


#=============================================================
proc PB_CMD_drill_text_move { } {
#=============================================================
  global mom_cycle_delay
  global mom_cycle_delay_revs

  if { [info exists mom_cycle_delay] || [info exists mom_cycle_delay_revs] } {
     MOM_drill_dwell_move
  } else {
     MOM_drill_move
  }
}


#=============================================================
proc PB_CMD_end_of_alignment_character { } {
#=============================================================
 #  Return sequnece number back to orignal
 #  This command may be used with the command "PM_CMD_start_of_alignment_character"

  global mom_sys_leader saved_seq_num
  if { [info exists saved_seq_num] } {
    set mom_sys_leader(N) $saved_seq_num
  }
}


#=============================================================
proc PB_CMD_end_of_extcall_operation { } {
#=============================================================
# This command is used to close sub program for each operation and output EXTCALL into main program.
# This command must be put in end of path
  global mom_siemens_program_control
  global ptp_file_name
  global mom_sys_ptp_output
  global mom_output_file_directory
  global mom_operation_name

  if { ![string match "ON" $mom_sys_ptp_output] || ![info exists ptp_file_name] } {
return
  }

  if { [info exists mom_siemens_program_control] && [string match "TRUE" $mom_siemens_program_control] } {
     set output_extn ".spf"
     set subroutine_name "${mom_output_file_directory}${mom_operation_name}${output_extn}"
     #<2011-09-20 lili> output extcall at here to work with simulation.
     #Redirectory to csefiles/subprog if it works with simulation.
     global mom_post_in_simulation
     if {[info exists mom_post_in_simulation] && [string match "CSE" $mom_post_in_simulation]} {
        global mom_part_name
        set part_dir "[file dirname $mom_part_name]/"
        if {[catch {file mkdir ${part_dir}cse_files/subprog/}]} {
           MOM_output_to_listing_device "${part_dir}cse_files: No write access! Subprogram file is in $mom_output_file_directory"
        } else {
           set subprog_dir ${part_dir}cse_files/subprog/
           if {[file isdirectory $subprog_dir]} {
              set subroutine_name [file nativename "${subprog_dir}${mom_operation_name}${output_extn}"]
           }
        }
     }
     if { [file exists $subroutine_name] } {
        MOM_output_literal "M17"
        global feedrate_file_name
        set feedrate_file_name $subroutine_name
        if {[llength [info commands PB_CMD_output_feedrate_variables]]} {
        PB_CMD_output_feedrate_variables
        }
        MOM_close_output_file $subroutine_name
        #<2011-09-20 lili> MOM_end_subroutine only works for simulation, no effect to post.
        MOM_end_subroutine
     }
      MOM_open_output_file $ptp_file_name
      MOM_set_seq_off
      MOM_output_literal "EXTCALL (\"$mom_operation_name\")"
      MOM_close_output_file $ptp_file_name
  }
}


#=============================================================
proc PB_CMD_end_of_extcall_program { } {
#=============================================================
#This command must be put in end of program before all output templates you need
#for the main program like M30.
  global mom_siemens_program_control
  global ptp_file_name
  global mom_sys_ptp_output
  global mom_sequence_number mom_sequence_increment mom_sequence_frequency
  global mom_sys_in_operation

  if { [info exists mom_sys_in_operation] && $mom_sys_in_operation == 1 } {
return
  }

  if { ![string match "ON" $mom_sys_ptp_output] || ![info exists ptp_file_name] } {
return
  }

  if { [info exists mom_siemens_program_control] && [string match "TRUE" $mom_siemens_program_control] } {
     MOM_open_output_file $ptp_file_name
     #<2011-09-20> remove the M30 output from this command to work better with simulation
     #MOM_output_text "M30"
     unset mom_siemens_program_control
  }
}


#=============================================================
proc PB_CMD_end_of_program { } {
#=============================================================
# Reset start_output_flag, it is set in PB_CMD_output_start_program
  global start_output_flag
  set start_output_flag 0
}


#=============================================================
proc PB_CMD_fifth_axis_rotate_move { } {
#=============================================================
#  This command is used by the ROTATE ude command to output a
#  fifth axis rotary move.  You can use the NC Data Definitions
#  section of postbuilder to modify the fifth_axis_rotary_move
#  block template.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#

  MOM_force once fifth_axis
  MOM_do_template fifth_axis_rotate_move
}


#=============================================================
proc PB_CMD_fix_RAPID_SET { } {
#=============================================================
# This command is provided to overwrite the system RAPID_SET
# (defined in ugpost_base.tcl) in order to correct the problem
# with workplane change that doesn't account for +/- directions
# along X or Y principal axis.  It also fixes the problem that
# the First Move was never identified correctly to force
# the output of the 1st point.
#
# The original command has been renamed as ugpost_RAPID_SET.
#
# - This command may be attached to the "Start of Program" event marker.
#
#
# Revisions:
#-----------
# 02-18-08 gsl - Initial version
# 02-26-09 gsl - Used mom_kin_machine_type to derive machine mode when it's UNDEFINED.
# 08-18-15 sws - PR7294525 : Use mom_current_motion to detect first move & initial move
#

  # Only redefine RAPID_SET once, since ugpost_base is only loaded once.
  #
   if { ![CMD_EXIST ugpost_RAPID_SET] } {
      if { [CMD_EXIST RAPID_SET] } {
         rename RAPID_SET ugpost_RAPID_SET
      }
   } else {
return
   }


#***********
uplevel #0 {

#====================
proc RAPID_SET { } {
#====================

   if { [CMD_EXIST PB_CMD_set_principal_axis] } {
      PB_CMD_set_principal_axis
   }


   global mom_cycle_spindle_axis mom_sys_work_plane_change
   global traverse_axis1 traverse_axis2 mom_motion_event mom_machine_mode
   global mom_pos mom_prev_pos mom_from_pos mom_last_pos mom_sys_home_pos
   global mom_sys_tool_change_pos
   global spindle_first rapid_spindle_inhibit rapid_traverse_inhibit
   global mom_current_motion


   if { ![info exists mom_from_pos($mom_cycle_spindle_axis)] && \
         [info exists mom_sys_home_pos($mom_cycle_spindle_axis)] } {

      set mom_from_pos(0) $mom_sys_home_pos(0)
      set mom_from_pos(1) $mom_sys_home_pos(1)
      set mom_from_pos(2) $mom_sys_home_pos(2)

   } elseif { ![info exists mom_sys_home_pos($mom_cycle_spindle_axis)] && \
              [info exists mom_from_pos($mom_cycle_spindle_axis)] } {

      set mom_sys_home_pos(0) $mom_from_pos(0)
      set mom_sys_home_pos(1) $mom_from_pos(1)
      set mom_sys_home_pos(2) $mom_from_pos(2)

   } elseif { ![info exists mom_sys_home_pos($mom_cycle_spindle_axis)] && \
             ![info exists mom_from_pos($mom_cycle_spindle_axis)] } {

      set mom_from_pos(0) 0.0 ; set mom_sys_home_pos(0) 0.0
      set mom_from_pos(1) 0.0 ; set mom_sys_home_pos(1) 0.0
      set mom_from_pos(2) 0.0 ; set mom_sys_home_pos(2) 0.0
   }

   if { ![info exists mom_sys_tool_change_pos($mom_cycle_spindle_axis)] } {
      set mom_sys_tool_change_pos($mom_cycle_spindle_axis) 100000.0
   }


   set is_initial_move [string match "initial_move" $mom_current_motion]
   set is_first_move   [string match "first_move"   $mom_current_motion]

   if { $is_initial_move || $is_first_move } {
      set mom_last_pos($mom_cycle_spindle_axis) $mom_sys_tool_change_pos($mom_cycle_spindle_axis)
   } else {
      if { [info exists mom_last_pos($mom_cycle_spindle_axis)] == 0 } {
         set mom_last_pos($mom_cycle_spindle_axis) $mom_sys_home_pos($mom_cycle_spindle_axis)
      }
   }


   if { $mom_machine_mode != "MILL" && $mom_machine_mode != "DRILL" } {
     # When machine mode is UNDEFINED, ask machine type
      if { ![string match "MILL" [PB_CMD_ask_machine_type]] } {
return
      }
   }


   WORKPLANE_SET

   set rapid_spindle_inhibit  FALSE
   set rapid_traverse_inhibit FALSE


   if { [EQ_is_lt $mom_pos($mom_cycle_spindle_axis) $mom_last_pos($mom_cycle_spindle_axis)] } {
      set going_lower 1
   } else {
      set going_lower 0
   }


   if { ![info exists mom_sys_work_plane_change] } {
      set mom_sys_work_plane_change 1
   }


  # Reverse workplane change direction per spindle axis
   global mom_spindle_axis

   if { [info exists mom_spindle_axis] } {

    #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # User can temporarily disable the work plane change for rapid moves along non-principal
    # spindle axis even when work plane change has been set in the Rapid Move event.
    #
    # Work plane change, if set, will still be in effect for moves along principal axes.
    #
    # - This flag has no effect if the work plane change is not set.
    #

      set disable_non_principal_spindle 0


      switch $mom_cycle_spindle_axis {
         0 {
            if [EQ_is_lt $mom_spindle_axis(0) 0.0] {
               set going_lower [expr abs($going_lower - 1)]
            }
         }
         1 {
            if [EQ_is_lt $mom_spindle_axis(1) 0.0] {
               set going_lower [expr abs($going_lower - 1)]
            }
         }
         2 {
         # Multi-spindle machine
            if [EQ_is_lt $mom_spindle_axis(2) 0.0] {
               set going_lower [expr abs($going_lower - 1)]
            }
         }
      }


     # Per user's choice above, disable work plane change for non-principal spindle axis
     #
      if { $disable_non_principal_spindle } {

         if { ![EQ_is_equal $mom_spindle_axis(0) 1] && \
              ![EQ_is_equal $mom_spindle_axis(1) 1] && \
              ![EQ_is_equal $mom_spindle_axis(0) 1] } {

            global mom_user_work_plane_change
            global mom_user_spindle_first

            set mom_user_work_plane_change $mom_sys_work_plane_change
            set mom_sys_work_plane_change 0

            if [info exists spindle_first] {
               set mom_user_spindle_first $spindle_first
            } else {
               set mom_user_spindle_first NONE
            }
         }
      }
   }


   if { $mom_sys_work_plane_change } {

      if { $going_lower } {
         set spindle_first FALSE
      } else {
         set spindle_first TRUE
      }

     # Force output in Initial Move and First Move.
      if { !$is_initial_move && !$is_first_move } {

         if { [EQ_is_equal $mom_pos($mom_cycle_spindle_axis) $mom_last_pos($mom_cycle_spindle_axis)] } {
            set rapid_spindle_inhibit TRUE
         } else {
            set rapid_spindle_inhibit FALSE
         }

         if { [EQ_is_equal $mom_pos($traverse_axis1) $mom_prev_pos($traverse_axis1)] && \
              [EQ_is_equal $mom_pos($traverse_axis2) $mom_prev_pos($traverse_axis2)] && \
              [EQ_is_equal $mom_pos(3) $mom_prev_pos(3)] && [EQ_is_equal $mom_pos(4) $mom_prev_pos(4)] } {

            set rapid_traverse_inhibit TRUE
         } else {
            set rapid_traverse_inhibit FALSE
         }
      }

   } else {
      set spindle_first NONE
   }

} ;# RAPID_SET

} ;# uplevel
#***********
}


#=============================================================
proc PB_CMD_fourth_axis_rotate_move { } {
#=============================================================
#  This command is used by the ROTATE ude command to output a
#  fourth axis rotary move.  You can use the NC Data Definitions
#  section of postbuilder to modify the fourth_axis_rotary_move
#  block template.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#

  MOM_force once fourth_axis
  MOM_do_template fourth_axis_rotate_move
}


#=============================================================
proc PB_CMD_get_feed_value { } {
#=============================================================
# This command is used to get defined feedrate values in NX.
#
  global mom_feed_cut_value mom_feed_cut_unit
  global mom_feed_rapid_value
  global mom_feed_approach_value
  global mom_feed_engage_value mom_feed_engage_unit
  global mom_feed_first_cut_value
  global mom_feed_departure_value
  global mom_feed_retract_value mom_feed_retract_unit
  global mom_feed_return_value
  global mom_feed_stepover_value
  global mom_feed_traversal_value
  global mom_siemens_feed_var_num
  global mom_siemens_feed_value
  global mom_siemens_feed_definition
  global mom_output_unit mom_part_unit

  if {![string compare $mom_part_unit $mom_output_unit]} {
     set unit_conversion 1
  } elseif { ![string compare "IN" $mom_output_unit] } {
     set unit_conversion [expr 1.0/25.4]
  } else {
     set unit_conversion 25.4
  }

  if {[EQ_is_zero $mom_feed_engage_value]} {set mom_feed_engage_value $mom_feed_cut_value}
  if {[EQ_is_zero $mom_feed_retract_value]} {set mom_feed_retract_value $mom_feed_cut_value}

  set mom_siemens_feed_value(cut)    [expr $unit_conversion*$mom_feed_cut_value]
  set mom_siemens_feed_value(engage) [expr $unit_conversion*$mom_feed_engage_value]
  set mom_siemens_feed_value(retract) [expr $unit_conversion*$mom_feed_retract_value]


  set mom_siemens_feed_value(cut) [format "%.2f" $mom_siemens_feed_value(cut)]
  set mom_siemens_feed_value(engage) [format "%.2f" $mom_siemens_feed_value(engage)]
  set mom_siemens_feed_value(retract) [format "%.2f" $mom_siemens_feed_value(retract)]
}


#=============================================================
proc PB_CMD_handle_sync_event { } {
#=============================================================
  global mom_sync_code
  global mom_sync_index
  global mom_sync_start
  global mom_sync_incr
  global mom_sync_max
  global mom_sync_number


  set mom_sync_start     0
  set mom_sync_incr       1
  set mom_sync_max    100


  if {![info exists mom_sync_code] } {
    set mom_sync_code $mom_sync_start
  }

  set mom_sync_code [expr $mom_sync_code + $mom_sync_incr]

  MOM_output_literal "WAITM($mom_sync_number,1,2)"
}


#=============================================================
proc PB_CMD_init_cycle_parameters { } {
#=============================================================
#this procedure is used to set cycle parameters for sinumerik 840D
# ouput cycle feed mode
   global mom_motion_event
   switch $mom_motion_event {
      bore_move -
      bore_dwell_move { }
      default { MOM_do_template cycle_feed_mode }
   }

   global mom_cycle_spindle_axis
   if {![info exists mom_cycle_spindle_axis]} {
      set mom_cycle_spindle_axis 2
   }

   global mom_cycle_retract_mode mom_cycle_retract_to_pos
   if {[info exists mom_cycle_retract_mode] && [string match "AUTO" $mom_cycle_retract_mode] } {
      set retract_spindle Z
      set mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [MOM_ask_address_value $retract_spindle]
   }

   #-------------------------------------------------------
   #optinal data
   #-------------------------------------------------------
   global mom_cycle_delay_mode
   global mom_cycle_delay
   global mom_cycle_delay_revs
   global mom_siemens_cycle_dtb
   global mom_siemens_cycle_dts_mode
   global mom_siemens_cycle_dts
   global mom_siemens_cycle_o_dtd_mode
   global mom_siemens_cycle_o_dtd

  if {[info exists mom_cycle_delay_mode]} {
      set mom_cycle_delay_mode [string toupper $mom_cycle_delay_mode]
      if {[info exists mom_cycle_delay] && [string match "SECONDS" $mom_cycle_delay_mode]} {
          set mom_siemens_cycle_dtb [expr abs($mom_cycle_delay)]
      } elseif {[info exists mom_cycle_delay_revs] && [string match "REVOLUTIONS" $mom_cycle_delay_mode]} {
          set mom_siemens_cycle_dtb [expr -1*abs($mom_cycle_delay_revs)]
          set mom_cycle_delay_revs [expr -1*$mom_cycle_delay_revs]
      } elseif { [string match "OFF" $mom_cycle_delay_mode]} {
      } else {
          set mom_cycle_delay 1
          set mom_siemens_cycle_dtb 1
      }
   }

   if {[info exists mom_siemens_cycle_dts_mode]} {
      set mom_siemens_cycle_dts_mode [string toupper $mom_siemens_cycle_dts_mode]
      if {[info exists mom_siemens_cycle_dts] && [string match "SECONDS" $mom_siemens_cycle_dts_mode]} {
          set mom_siemens_cycle_dts [expr abs($mom_siemens_cycle_dts)]
      } elseif {[info exists mom_siemens_cycle_dts] && [string match "REVOLUTIONS" $mom_siemens_cycle_dts_mode]} {
          set mom_siemens_cycle_dts [expr -1*abs($mom_siemens_cycle_dts)]
      } elseif {[string match "OFF" $mom_siemens_cycle_dts_mode]} {
          catch {unset mom_siemens_cycle_dts}
      }
   }

   if {[info exists mom_siemens_cycle_o_dtd_mode]} {
      set mom_siemens_cycle_o_dtd_mode [string toupper $mom_siemens_cycle_o_dtd_mode]
      if {[info exists mom_siemens_cycle_o_dtd] && [string match "SECONDS" $mom_siemens_cycle_o_dtd_mode]} {
          set mom_siemens_cycle_o_dtd [expr abs($mom_siemens_cycle_o_dtd)]
      } elseif {[info exists mom_siemens_cycle_o_dtd] && [string match "REVOLUTIONS" $mom_siemens_cycle_o_dtd_mode]} {
          set mom_siemens_cycle_o_dtd [expr -1*abs($mom_siemens_cycle_o_dtd)]
      } elseif {[string match "ON" $mom_siemens_cycle_o_dtd_mode]} {
          set mom_siemens_cycle_o_dtd 0
      } elseif {[string match "OFF" $mom_siemens_cycle_o_dtd_mode]} {
          catch {unset mom_siemens_cycle_o_dtd}
      }
   }

   global mom_cycle_step1
   global mom_cycle_step2
   global mom_cycle_step3
   global feed
   global mom_sys_spindle_direction_code
   global mom_spindle_direction
   global mom_feed_retract_value

   global mom_siemens_cycle_fdpr
   global mom_siemens_cycle_dam
   global mom_siemens_cycle_frf
   global mom_siemens_cycle_ffr
   global mom_siemens_cycle_rff
   global mom_siemens_cycle_sdir
   global mom_siemens_cycle_o_mdep

   if [info exists mom_cycle_step1] {
       set mom_siemens_cycle_fdpr $mom_cycle_step1
   }
   if {[info exists mom_cycle_step2]} {
       set mom_siemens_cycle_dam $mom_cycle_step2
   }
   if {[info exists mom_cycle_step3]} {
       set mom_siemens_cycle_o_mdep $mom_cycle_step3
   }
   set mom_siemens_cycle_ffr $feed

   if {![info exists mom_siemens_cycle_rff] || [EQ_is_zero $mom_siemens_cycle_rff]} {
      if {[info exists mom_feed_retract_value] && ![EQ_is_zero $mom_feed_retract_value]} {
         set mom_siemens_cycle_rff $mom_feed_retract_value
      } else {
         set mom_siemens_cycle_rff $feed
      }
   }

   if {![info exists mom_siemens_cycle_frf]} {
      set mom_siemens_cycle_frf 1
   }

   set mom_siemens_cycle_sdir 3
   if {[info exists mom_spindle_direction]} {
       switch $mom_spindle_direction {
          "CLW"  { set mom_siemens_cycle_sdir 3}
          "CCLW" { set mom_siemens_cycle_sdir 4}
       }
   }
}


#=============================================================
proc PB_CMD_init_dnc_header { } {
#=============================================================
#
#  This custom will produce a DNC header at the start of your NC output.
#
#  To enable the DNC Header you must attach a DNC Header UDE to your
#  program group.
#
#      Note:  The system will automatically use the machine name,
#      program name and user name if you leave those fields blank.
#
  set level [info level]
  set upper_proc [info level [expr $level-1]]
  if {![string match $upper_proc "PB_start_of_program"]} {
     global mom_warning_info
     set mom_warning_info "PB_CMD_init_dnc_header should not be called by $upper_proc . It should be only attached to Start of Program event marker."
     catch { MOM_catch_warning }
return
  }

  if {![llength [info commands MOM_dnc_header ]]} {
    uplevel #0 {
    #=============================================================
    proc MOM_dnc_header {} {
    #=============================================================
      global mom_dnc_machine_name
      global mom_dnc_program_name
      global mom_dnc_data_type
      global mom_dnc_version_number
      global mom_dnc_release_number
      global mom_dnc_user_name
      global mom_command_status
      PB_CMD_MOM_dnc_header
    }
    };#uplevel
  }
}


#=============================================================
proc PB_CMD_init_extcall { } {
#=============================================================
# This command will generate separated sub program file for each operation and
# main program file using EXTCALL to call sub programs.
#
# This command is used with PB_CMD_start_of_extcall_operation,
# PB_CMD_end_of_extcall_operation and PB_CMD_end_of_extcall_program
#
# You must attach a Sinumerik Program Control UDE to your program group.
#
  set level [info level]
  set upper_proc [info level [expr $level-1]]
  if { ![string match $upper_proc "PB_start_of_program"] } {
     global mom_warning_info
     set mom_warning_info "PB_CMD_init_extcall should not be called by $upper_proc . It should be only attached to Start of Program event marker."
     catch { MOM_catch_warning }
return
  }

  if { ![llength [info commands MOM_program_control ]] } {
     uplevel #0 {
     #=============================================================
     proc MOM_program_control { } {
     #=============================================================
        global mom_siemens_program_control
        PB_CMD_MOM_program_control
     }
     };#uplevel
  }
}


#=============================================================
proc PB_CMD_init_helix { } {
#=============================================================
uplevel #0 {
#
# This ommand will be executed automatically at the start of program and
# anytime it is loaded as a slave post of a linked post.
#
# This procedure can be used to enable your post to output helix.
# You can choose from the following options to format the circle
# block template to output the helix parameters.
#

set mom_sys_helix_pitch_type    "none"

#
# The default setting for mom_sys_helix_pitch_type is "rise_radian".
# This is the most common.  Other choices are:
#
#    "rise_radian"              Measures the rise over one radian.
#    "rise_revolution"          Measures the rise over 360 degrees.
#    "none"                     Will suppress the output of pitch.
#    "other"                    Allows you to calculate the pitch
#                               using your own formula.
#
# This custom command uses the block template circular_move to output
# the helix block.  If your post uses a block template with a different
# name, you must edit the line that outputs the helix block.

#
#  The following variable deines the output mode for helical records.
#
#  FULL_CIRCLE  -- This mode will output a helix record for each 360
#                  degrees of the helix.
#  QUADRANT  --    This mode will output a helix record for each 90
#                  degrees of the helix.
#  LINEAR  --      This mode will output the entire helix as linear gotos.
#  END_POINT --    This mode will assume the control can define an entire
#                  helix in a single block.

   set mom_kin_helical_arc_output_mode END_POINT

   MOM_reload_kinematics

} ;# uplevel
}


#=============================================================
proc PB_CMD_init_high_speed_setting { } {
#=============================================================
# This command is used to uplevel the MOM_high_speed_setting.
#
# It is applied for the UDE "Sinumerik 840D".
#
# Please don't remove this command.
#
# 23-Dec-2016 shuai - CYCLE832 enhancement.
#

  if {![CALLED_BY "PB_start_of_program" 1] } {

     return
  }


  if { ![llength [info commands MOM_high_speed_setting ]] } {

     uplevel #0 {

     #=============================================================
     proc MOM_high_speed_setting { } {
     #=============================================================

       PB_CMD_MOM_sinumerik_840D

     } ; # proc MOM_high_speed_setting

     } ; # uplevel

  }

}


#=============================================================
proc PB_CMD_init_ini_files { } {
#=============================================================
# This procedure is used with simulation_ini.tcl file which should be sourced
# in postprocessor as a user tcl file for generating ini files.
# This procedure will be excuted when simulation_ini.tcl is sourcing.
# Once you source the simulation_ini.tcl file in a postprocessor, remove this
# procedure from Start of Program will NOT affect the result.
#
# Following mom variables are used to set the options for ini files.
# mom_sinumerik_ini_create
#    "Yes"          ini files will be created
#    "No "          ini files will not be created
#
# mom_sinumerik_ini_location
#    "Part"         ini files will be output to a subfolder \cse_files\subprog
#                   of cam part file location. If \cse_files\subprog is not exists
#                   post will create this folder.
#    "CSE"          ini files will be output to sub folder \subprog of \cse_driver
#                   folder which located in same directory of \postprocessor as installed
#                   machine examples.
#    "ENV"          ini files will be output to a sub folder \subprog of enviornment
#                   variable defined directory.
#                   If it is not exists, ini files will be output to "Part".
#
# mom_sinumerik_ini_existing
#    "Rename"       Rename existing ini files to .bck in place where the one is created.
#    "Keep"         Keep ini files in place where the one is created.
#    "Delete"       Delete ini files in place where the one is created.
#
# mom_sinumerik_ini_end_status
#    "Rename"       Rename created ini file to .bck file after post run.
#    "Keep"         Keep created ini files after post run.
#    "Delete"       Delete created ini files after post run.


  global mom_sinumerik_ini_create
  global mom_sinumerik_ini_location
  global mom_sinumerik_ini_keep_existing
  global mom_sinumerik_ini_end_status

  set mom_sinumerik_ini_create     "Yes"
  set mom_sinumerik_ini_location   "Part"
  set mom_sinumerik_ini_existing   "Rename"
  set mom_sinumerik_ini_end_status "Keep"
}


#=============================================================
proc PB_CMD_init_nurbs { } {
#=============================================================
#
#  You will need to activate nurbs motion in NX CAM under machine control
#  to generate nurbs events.
#
#  This procedure is used to initialize nurbs output type.  It must be
#  placed in the Start of Program marker.
#
#  If set mom_kin_nurbs_output_type as "BSPLINE", please call PB_CMD_nurbs_spline
#  at NURBS Motion event. If set mom_kin_nurbs_output_type as "SIEMENS_POLY",
#  please call PB_CMD_nurbs_poly at NURBS Motion event.

  global mom_kin_nurbs_output_type
  global mom_kin_read_ahead_next_motion

  set mom_kin_nurbs_output_type              "BSPLINE"

  # For nurbs(Bspline) event to get next motion's type
  set mom_kin_read_ahead_next_motion 1
  MOM_reload_kinematics
}


#=============================================================
proc PB_CMD_init_rotary { } {
#=============================================================
#
# Retract and Re-Engage Parameters
#
# This option is activated by setting the Axis Limit Violation
# Handling option on the Machine Tool dialog to Retract/Re-Engage.
#
# The sequence of actions that take place when a rotary limit violation
# occurs is a retract to the clearance geometry at the rapid feedrate,
# reposition the rotary axes so they do not violate, move back to
# the engage point at the retract feedrate and engage into the part again.
#
# You can set additional parameters that will control the retract
# and re-engage motion.
#
#
#  mom_kin_retract_type ------- specifies the method used to
#                               calculate the retract point.
#                               The method can be of
#
#    DISTANCE : The retract will be to a point at a fixed distance
#               along the spindle axis.
#
#    SURFACE  : For a 4-axis rotary head machine, the retract will
#               be to a cylinder.  For a 5-axis dual heads machine,
#               the retract will be to a sphere.  For machine with
#               only rotary table(s), the retract will be to a plane
#               normal & along the spindle axis.
#
#  mom_kin_retract_distance --- specifies the distance or radius for
#                               defining the geometry of retraction.
#
#  mom_kin_reengage_distance -- specifies the re-engage point above
#                               the part.
#
#=============================================================
# Revisions:
# 03-13-09 gsl - Use global declaration in place of "uplevel"
#=============================================================
#
   global mom_kin_retract_type
   global mom_kin_retract_distance
   global mom_kin_reengage_distance
   global mom_kin_spindle_axis
   global mom_sys_spindle_axis
   global mom_sys_lock_status


set mom_kin_retract_type                "DISTANCE"
set mom_kin_retract_distance            10.0
set mom_kin_reengage_distance           .20

#
# The following parameters are used by UG Post.
# --> Do NOT change them unless you know what you are doing!
#
if { ![info exists mom_kin_spindle_axis] } {
  set mom_kin_spindle_axis(0)                    0.0
  set mom_kin_spindle_axis(1)                    0.0
  set mom_kin_spindle_axis(2)                    1.0
}

set spindle_axis_defined 1
if { ![info exists mom_sys_spindle_axis] } {
  set spindle_axis_defined 0
} else {
  if { ![array exists mom_sys_spindle_axis] } {
    unset mom_sys_spindle_axis
    set spindle_axis_defined 0
  }
}
if !$spindle_axis_defined {
  set mom_sys_spindle_axis(0)                    0.0
  set mom_sys_spindle_axis(1)                    0.0
  set mom_sys_spindle_axis(2)                    1.0
}

set mom_sys_lock_status                        "OFF"
}


#=============================================================
proc PB_CMD_init_tool_list { } {
#=============================================================
#  This command will be executed automatically at the "Start of Program" to
#  prepare for the tool list generation.
#
#  This command will add the shop doc event handlers to the post.
#  You may edit the proc MOM_TOOL_BODY to customize your tool list output.
#
#  Only the tools used in the program being post-processed will be listed.
#
#  In order to create the tool list, you MUST add the command
#  PB_CMD_create_tool_list to either the "Start of Program"
#  or the "End of Program" event marker depending on where
#  the tool list is to be output in your NC code.
#
#  The Shop Doc template file "pb_post_tool_list.tpl" residing in the
#  "postbuild/pblib/misc" directory is required for this service to work.
#  You may need to copy it to the "mach/resource/postprocessor"
#  or "mach/resource/shop_docs" directory, in case your UG runtime
#  environment does not have access to the Post Builder installation.
#

   global mom_sys_tool_list_initialized


uplevel #0 {

proc MOM_TOOL_BODY { } {
   global mom_tool_name
   global mom_tool_number
   global mom_tool_diameter
   global mom_tool_length
   global mom_tool_type
   global mom_template_subtype
   global mom_tool_point_angle
   global mom_tool_flute_length
   global mom_tool_length_adjust_register
   global mom_tool_nose_radius
   global mom_tool_corner1_radius
   global mom_tool_flute_length
   global mom_tool_orientation
   global mom_sys_control_out mom_sys_control_in
   global cycle_program_name current_program_name
   global mom_sys_tool_stack

   global tool_data_buffer


  # Handle single operation case.
  # current_program_name will be blank when no group has been selected.

   if { $current_program_name != "" } {
      set n1 [string toupper $cycle_program_name]
      set n2 [string toupper $current_program_name]
      if { $n1 != $n2 && $n1 != "" } {
return
      }
   } else {

     # mom_sys_change_mach_operation_name is set in MOM_machine_mode
     # Use this variable to generate tool info for a single operation.

      global mom_sys_change_mach_operation_name mom_operation_name

      if [info exists mom_sys_change_mach_operation_name] {
         if { ![string match "$mom_operation_name" $mom_sys_change_mach_operation_name] } {
return
         }
      } else {
return
      }
   }


  #****************************
  # Collect various tool lists
  #****************************
   lappend mom_sys_tool_stack(IN_USE) $mom_tool_name

   set tool_type [MAP_TOOL_TYPE]

   if { [lsearch $mom_sys_tool_stack(ALL) $mom_tool_name] < 0 } {

      lappend mom_sys_tool_stack(ALL)         $mom_tool_name
      lappend mom_sys_tool_stack($tool_type)  $mom_tool_name
   }


  #*************************************************
  # Define data to be output for each tool per type
  #*************************************************
   set output ""

   set ci $mom_sys_control_in
   set co $mom_sys_control_out

   if { $mom_template_subtype == "" } { set mom_template_subtype $mom_tool_type }

   set tool_name [string range $mom_tool_name 0 19]
   set template_subtype [string range $mom_template_subtype 0 19]

   switch $tool_type {

      "MILL" {


         set output [format "%-20s %-20s %-10.4f %-10.4f %-10.4f %-10d"  $tool_name $template_subtype  $mom_tool_diameter $mom_tool_corner1_radius  $mom_tool_flute_length $mom_tool_length_adjust_register]
      }

      "DRILL" {

         set mom_tool_point_angle [expr (180.0 / 3.14159) * $mom_tool_point_angle]
         set output [format "%-20s %-20s %-10.4f %-10.4f %-10.4f %-10d"  $tool_name $template_subtype  $mom_tool_diameter $mom_tool_point_angle  $mom_tool_flute_length $mom_tool_length_adjust_register]
      }

      "LATHE" {

         set pi [expr 2 * asin(1.0)]
         set tool_orient [expr (180. / 3.14159) * $mom_tool_orientation]
         set output [format "%-20s %-20s %-10.4f %-15.4f %-10d"  $tool_name $template_subtype  $mom_tool_nose_radius $tool_orient  $mom_tool_length_adjust_register]
      }
   }


  #*******************************************************************************
  # Fetch tool time data from the post.
  # This info is only available when tool list is created at the end of a program.
  #*******************************************************************************
   global mom_sys_tool_list_output_type
   global mom_sys_tool_time
   global mom_operation_name

   set tool_time ""

   if [info exists mom_sys_tool_time] {

      switch $mom_sys_tool_list_output_type {
         "ORDER_IN_USE" {
           # Tool time per operations.
            set tool_time $mom_sys_tool_time($mom_tool_name,$mom_operation_name)
         }

         default {
           # Accumulate tool time from all operations using this tool.
            set tool_time 0
            if [info exists mom_sys_tool_time($mom_tool_name,oper_list)] {
               foreach oper $mom_sys_tool_time($mom_tool_name,oper_list) {
                  set tool_time [expr $tool_time + $mom_sys_tool_time($mom_tool_name,$oper)]
               }
            }
         }
      }
   }

   if { $tool_time != ""  &&  $tool_time != "0" } {
      set tool_time [format "%-10.2f" $tool_time]
   }


  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # Store data to be output or used in PB_CMD_create_tool_list.
  #
  # <Ex.>
  #  global mom_tool_number
  #   set tool_data_buffer($mom_tool_name,tool_number) $mom_tool_number
  #
  # If a BLOCK_TEMPLATE is used to output the data, the global varaibles
  # used in the expression of an Address need to be set accordingly
  # before "MOM_do_template" is called.
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   set tool_data_buffer($mom_tool_name,output) "$co$output$tool_time$ci"
   set tool_data_buffer($mom_tool_name,type)   "$tool_type"
}


proc MOM_SETUP_HDR {} {
   global mom_sys_control_out mom_sys_control_in


  # Initialize various tool lists
   global mom_sys_tool_stack

   set mom_sys_tool_stack(IN_USE) [list]
   set mom_sys_tool_stack(ALL)    [list]
   set mom_sys_tool_stack(MILL)   [list]
   set mom_sys_tool_stack(DRILL)  [list]
   set mom_sys_tool_stack(LATHE)  [list]


   set ci $mom_sys_control_in
   set co $mom_sys_control_out


  #++++++++++++++++++++++++++++++++++++++++++
  # Define header to be output per tool type
  #++++++++++++++++++++++++++++++++++++++++++
   global tool_data_buffer

   set tool_desc   "DESCRIPTION"
   set tool_dia    "DIAMETER"
   set corner_rad  "COR RAD"
   set tip_ang     "TIP ANG"
   set flute_len   "FLUTE LEN"
   set adjust      "ADJ REG"
   set nose_dia    "NOSE RAD"
   set tool_orient "TOOL ORIENT"

  # Label title for tool time only when it exists.
   global mom_sys_tool_time
   if [info exists mom_sys_tool_time] {
      set mach_time   "MACH TIME"
   } else {
      set mach_time   ""
   }

     set tool_name   "DRILL"
     set output [format "%-20s %-20s %-10s %-10s %-10s %-9s %-10s"  $tool_name $tool_desc  $tool_dia $tip_ang $flute_len $adjust $mach_time]

     set header [list]
     lappend header "$co                                                                                               $ci"
     lappend header ";$co-----------------------------------------------------------------------------------------------$ci"
     lappend header ";$co$output$ci"
     lappend header ";$co-----------------------------------------------------------------------------------------------$ci"

   set tool_data_buffer(DRILL,header) [join $header \n]


     set tool_name   "MILL"
     set output [format "%-20s %-20s %-10s %-10s %-10s %-9s %-10s"  $tool_name $tool_desc  $tool_dia $corner_rad $flute_len $adjust $mach_time]

     set header [list]
     lappend header "$co                                                                                               $ci"
     lappend header ";$co-----------------------------------------------------------------------------------------------$ci"
     lappend header ";$co$output$ci"
     lappend header ";$co-----------------------------------------------------------------------------------------------$ci"

   set tool_data_buffer(MILL,header) [join $header \n]


     set tool_name   "LATHE"
     set output [format "%-20s %-20s %-10s %-15s %-9s %-10s"  $tool_name $tool_desc $nose_dia $tool_orient $adjust $mach_time]

     set header [list]
     lappend header "$co                                                                                               $ci"
     lappend header ";$co-----------------------------------------------------------------------------------------------$ci"
     lappend header ";$co$output$ci"
     lappend header ";$co-----------------------------------------------------------------------------------------------$ci"

   set tool_data_buffer(LATHE,header) [join $header \n]
}


proc MOM_PROGRAMVIEW_HDR {} {}
proc MOM_SETUP_FTR {} {}


proc MOM_MEMBERS_HDR {} {
   global mom_sys_program_stack cycle_program_name
   global current_program_name

   lappend mom_sys_program_stack $cycle_program_name

   if { [lsearch $mom_sys_program_stack "$current_program_name"] >= 0 } {
      set cycle_program_name $current_program_name
   }
}


proc MOM_MEMBERS_FTR {} {
   global mom_sys_program_stack cycle_program_name
   global current_program_name

   set mom_sys_program_stack [lreplace $mom_sys_program_stack end end]
   set cycle_program_name [lindex $mom_sys_program_stack end]

   if { [lsearch $mom_sys_program_stack "$current_program_name"] >= 0 } {
      set cycle_program_name $current_program_name
   }
}


proc MOM_PROGRAM_BODY {} {
   global mom_object_name cycle_program_name

   set cycle_program_name $mom_object_name
}


proc MOM_SETUP_BODY {} {}
proc MOM_OPER_BODY  {} {}
proc MOM_TOOL_HDR   {} {}
proc MOM_TOOL_FTR   {} {}
proc MOM_PROGRAMVIEW_FTR {} {}


proc MAP_TOOL_TYPE { } {
   global mom_tool_type

   if {[string match "Milling*" $mom_tool_type]} {
      return "MILL"
   } elseif { [string match "Turning*" $mom_tool_type]} {
      return "LATHE"
   } elseif { [string match "Grooving*" $mom_tool_type]} {
      return "LATHE"
   } elseif { [string match "Threading*" $mom_tool_type]} {
      return "LATHE"
   } elseif { [string match "Drilling*" $mom_tool_type]} {
      return "DRILL"
   } else {
      return ""
   }
}


proc shop_doc_output_literal { line } {
   global tool_list_commentary list_file

   set line_list [split $line \n]

   foreach line $line_list {

      if [info exists tool_list_commentary] {
         puts $list_file $line
      } else {
         MOM_output_literal $line
      }

   }
}


} ;# uplevel


   set mom_sys_tool_list_initialized 1
}


#=============================================================
proc PB_CMD_init_variables { } {
#=============================================================
#This command is used to initialize the variables used in
#Sinumerik 840D postprocessors.

#Initial 5axis mode.
  global mom_siemens_5axis_output_mode
  set mom_siemens_5axis_output_mode 0

#Coordinate rotation
  global mom_siemens_coord_rotation
  set mom_siemens_coord_rotation 0

#Motion message
  global mom_siemens_pre_motion
  set mom_siemens_pre_motion "start"

#Drilling cycle count
  global mom_siemens_cycle_count
  set mom_siemens_cycle_count 0

  if {[llength [info commands MOM_ask_mcs_info ]]} {
     MOM_ask_mcs_info
  }
}


#=============================================================
proc PB_CMD_kin__MOM_lintol { } {
#=============================================================
   global mom_kin_linearization_flag
   global mom_kin_linearization_tol
   global mom_lintol_status
   global mom_lintol

   if { ![string compare "ON" $mom_lintol_status] } {
      set mom_kin_linearization_flag "TRUE"
      if { [info exists mom_lintol] } {
         set mom_kin_linearization_tol $mom_lintol
      }
   } elseif { ![string compare "OFF" $mom_lintol_status] } {
      set mom_kin_linearization_flag "FALSE"
   }
}


#=============================================================
proc PB_CMD_kin__MOM_rotate { } {
#=============================================================
# This command handles a Rotate UDE.
#
# Key parameters set in UDE -
#   mom_rotate_axis_type        :  [ AAXIS | BAXIS   | CAXIS    | HEAD | TABLE | FOURTH_AXIS | FIFTH_AXIS ]
#   mom_rotation_mode           :  [ NONE  | ATANGLE | ABSOLUTE | INCREMENTAL ]
#   mom_rotation_direction      :  [ NONE  | CLW     | CCLW ]
#   mom_rotation_angle          :  Specified angle
#   mom_rotation_reference_mode :  [ ON    | OFF ]
#
#
## <rws 04-11-2008>
## If in TURN mode and user invokes "Flip tool around Holder" a MOM_rotate event is generated
## When this happens ABORT this event via return
##
## 09-12-2013 gsl - Made code & functionality of MOM_rotate sharable among all multi-axis posts.
##

   global mom_machine_mode


   if { [info exists mom_machine_mode] && [string match "TURN" $mom_machine_mode] } {
      if [CMD_EXIST PB_CMD_handle_lathe_flash_tool] {
         PB_CMD_handle_lathe_flash_tool
      }
return
   }


   global mom_rotate_axis_type mom_rotation_mode mom_rotation_direction
   global mom_rotation_angle mom_rotation_reference_mode
   global mom_kin_machine_type mom_kin_4th_axis_direction mom_kin_5th_axis_direction
   global mom_kin_4th_axis_leader mom_kin_5th_axis_leader
   global mom_kin_4th_axis_leader mom_kin_5th_axis_leader mom_pos
   global mom_out_angle_pos
   global unlocked_prev_pos mom_sys_leader
   global mom_kin_4th_axis_min_limit mom_kin_4th_axis_max_limit
   global mom_kin_5th_axis_min_limit mom_kin_5th_axis_max_limit
   global mom_prev_pos
   global mom_prev_rot_ang_4th mom_prev_rot_ang_5th


   if { ![info exists mom_rotation_angle] } {
     # Should the event be aborted here???
return
   }


   if { ![info exists mom_kin_5th_axis_direction] } {
      set mom_kin_5th_axis_direction "0"
   }


  #
  #  Determine which rotary axis the UDE has specifid - fourth(3), fifth(4) or invalid(0)
  #
  #
   if { [string match "*3_axis_mill_turn*" $mom_kin_machine_type] } {

      switch $mom_rotate_axis_type {
         CAXIS -
         FOURTH_AXIS -
         TABLE {
            set axis 3
         }
         default {
            set axis 0
         }
      }

   } else {

      switch $mom_rotate_axis_type {
         AAXIS -
         BAXIS -
         CAXIS {
            set axis [AXIS_SET $mom_rotate_axis_type]
         }
         HEAD {
            if { ![string compare "5_axis_head_table" $mom_kin_machine_type] ||\
                 ![string compare "5_AXIS_HEAD_TABLE" $mom_kin_machine_type] } {
               set axis 4
            } else {
               set axis 3
            }
         }
         FIFTH_AXIS {
            set axis 4
         }
         FOURTH_AXIS -
         TABLE -
         default {
            set axis 3
         }
      }
   }

   if { $axis == 0 } {
      CATCH_WARNING "Invalid rotary axis ($mom_rotate_axis_type) has been specified."
      MOM_abort_event
   }

   switch $mom_rotation_mode {
      NONE -
      ATANGLE {
         set angle $mom_rotation_angle
         set mode 0
      }
      ABSOLUTE {
         set angle $mom_rotation_angle
         set mode 1
      }
      INCREMENTAL {
         set angle [expr $mom_pos($axis) + $mom_rotation_angle]
         set mode 0
      }
   }

   switch $mom_rotation_direction {
      NONE {
         set dir 0
      }
      CLW {
         set dir 1
      }
      CCLW {
         set dir -1
      }
   }

   set ang [LIMIT_ANGLE $angle]
   set mom_pos($axis) $ang

   if { $axis == "3" } { ;# Rotate 4th axis

      if { ![info exists mom_prev_rot_ang_4th] } {
         set mom_prev_rot_ang_4th [MOM_ask_address_value fourth_axis]
      }
      if { [string length [string trim $mom_prev_rot_ang_4th]] == 0 } {
         set mom_prev_rot_ang_4th 0.0
      }

      set prev_angles(0) $mom_prev_rot_ang_4th

   } elseif { $axis == "4" } { ;# Rotate 5th axis

      if { ![info exists mom_prev_rot_ang_5th] } {
         set mom_prev_rot_ang_5th [MOM_ask_address_value fifth_axis]
      }
      if { [string length [string trim $mom_prev_rot_ang_5th]] == 0 } {
         set mom_prev_rot_ang_5th 0.0
      }

      set prev_angles(1) $mom_prev_rot_ang_5th
   }

   set p [expr $axis + 1]
   set a [expr $axis - 3]

   if { $axis == 3  &&  [string match "MAGNITUDE_DETERMINES_DIRECTION" $mom_kin_4th_axis_direction] } {

      set dirtype "MAGNITUDE_DETERMINES_DIRECTION"

      global mom_sys_4th_axis_dir_mode

      if { [info exists mom_sys_4th_axis_dir_mode] && ![string compare "ON" $mom_sys_4th_axis_dir_mode] } {

         set del $dir
         if { $del == 0 } {
            set del [expr $ang - $mom_prev_pos(3)]
            if { $del >  180.0 } { set del [expr $del - 360.0] }
            if { $del < -180.0 } { set del [expr $del + 360.0] }
         }

         global mom_sys_4th_axis_cur_dir
         global mom_sys_4th_axis_clw_code mom_sys_4th_axis_cclw_code

         if { $del > 0.0 } {
            set mom_sys_4th_axis_cur_dir $mom_sys_4th_axis_clw_code
         } elseif { $del < 0.0 } {
            set mom_sys_4th_axis_cur_dir $mom_sys_4th_axis_cclw_code
         }
      }

   } elseif { $axis == 4  &&  [string match "MAGNITUDE_DETERMINES_DIRECTION" $mom_kin_5th_axis_direction] } {

      set dirtype "MAGNITUDE_DETERMINES_DIRECTION"

      global mom_sys_5th_axis_dir_mode

      if { [info exists mom_sys_5th_axis_dir_mode] && ![string compare "ON" $mom_sys_5th_axis_dir_mode] } {

         set del $dir
         if { $del == 0 } {
            set del [expr $ang - $mom_prev_pos(4)]
            if { $del >  180.0 } { set del [expr $del - 360.0] }
            if { $del < -180.0 } { set del [expr $del + 360.0] }
         }

         global mom_sys_5th_axis_cur_dir
         global mom_sys_5th_axis_clw_code mom_sys_5th_axis_cclw_code

         if { $del > 0.0 } {
            set mom_sys_5th_axis_cur_dir $mom_sys_5th_axis_clw_code
         } elseif { $del < 0.0 } {
            set mom_sys_5th_axis_cur_dir $mom_sys_5th_axis_cclw_code
         }
      }

   } else {

      set dirtype "SIGN_DETERMINES_DIRECTION"
   }

   if { $mode == 1 } {

      set mom_out_angle_pos($a) $angle

   } elseif { [string match "MAGNITUDE_DETERMINES_DIRECTION" $dirtype] } {

      if { $axis == 3 } {
         set mom_out_angle_pos($a) [ROTSET $ang $prev_angles(0) $mom_kin_4th_axis_direction\
                                                $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                                $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]
      } else {
         set mom_out_angle_pos($a) [ROTSET $ang $prev_angles(1) $mom_kin_5th_axis_direction\
                                                $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                                $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]
      }

   } elseif { [string match "SIGN_DETERMINES_DIRECTION" $dirtype] } {

      if { $dir == -1 } {
         if { $axis == 3 } {
            set mom_sys_leader(fourth_axis) $mom_kin_4th_axis_leader-
         } else {
            set mom_sys_leader(fifth_axis) $mom_kin_5th_axis_leader-
         }
      } elseif { $dir == 0 } {
         if { $axis == 3 } {
            set mom_out_angle_pos($a) [ROTSET $ang $prev_angles(0) $mom_kin_4th_axis_direction\
                                                   $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                                   $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]
         } else {
            set mom_out_angle_pos($a) [ROTSET $ang $prev_angles(1) $mom_kin_5th_axis_direction\
                                                   $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                                   $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]
         }
      } elseif { $dir == 1 } {
         set mom_out_angle_pos($a) $ang
      }
   }


  #<04-25-2013 gsl> No clamp code output when rotation is ref only.
   if { ![string compare "OFF" $mom_rotation_reference_mode] } {
      global mom_sys_auto_clamp

      if { [info exists mom_sys_auto_clamp] && [string match "ON" $mom_sys_auto_clamp] } {

         set out1 "1"
         set out2 "0"

         if { $axis == 3 } { ;# Rotate 4th axis
            AUTO_CLAMP_2 $out1
            AUTO_CLAMP_1 $out2
         } else {
            AUTO_CLAMP_1 $out1
            AUTO_CLAMP_2 $out2
         }
      }
   }


   if { $axis == 3 } {

      ####  <rws>
      ####  Use ROTREF switch ON to not output the actual 4th axis move

      if { ![string compare "OFF" $mom_rotation_reference_mode] } {
         PB_CMD_fourth_axis_rotate_move
      }

      if { ![string compare "SIGN_DETERMINES_DIRECTION" $mom_kin_4th_axis_direction] } {
         set mom_prev_rot_ang_4th [expr abs($mom_out_angle_pos(0))]
      } else {
         set mom_prev_rot_ang_4th $mom_out_angle_pos(0)
      }

      MOM_reload_variable mom_prev_rot_ang_4th

   } else {

      if { [info exists mom_kin_5th_axis_direction] } {

         ####  <rws>
         ####  Use ROTREF switch ON to not output the actual 5th axis move

         if { ![string compare "OFF" $mom_rotation_reference_mode] } {
            PB_CMD_fifth_axis_rotate_move
         }

         if { ![string compare "SIGN_DETERMINES_DIRECTION" $mom_kin_5th_axis_direction] } {
            set mom_prev_rot_ang_5th [expr abs($mom_out_angle_pos(1))]
         } else {
            set mom_prev_rot_ang_5th $mom_out_angle_pos(1)
         }

         MOM_reload_variable mom_prev_rot_ang_5th
      }
   }

  #<05-10-06 sws> pb351 - Uncommented next 3 lines
  #<01-07-10 wbh> Reset mom_prev_pos using the variable mom_out_angle_pos
  # set mom_prev_pos($axis) $ang
   set mom_prev_pos($axis) $mom_out_angle_pos([expr $axis-3])
   MOM_reload_variable -a mom_prev_pos
   MOM_reload_variable -a mom_out_angle_pos
}


#=============================================================
proc PB_CMD_kin_abort_event { } {
#=============================================================
   if { [llength [info commands PB_CMD_abort_event]] } {
      PB_CMD_abort_event
   }
}


#=============================================================
proc PB_CMD_kin_before_motion { } {
#=============================================================
#  This custom command is used by UG Post to support Set/Lock,
#  rotary axis limit violation retracts and auto clamping.
#
#  --> Do not change this command!  If you want to improve
#      performance, you may comment out any of these commands.
#
   global mom_kin_machine_type

   if { [info exists mom_kin_machine_type] } {
      if { [string match "*3_axis_mill*" $mom_kin_machine_type] ||\
           [string match "*lathe*" $mom_kin_machine_type] } {
return
      }
   }


  # Validate legitimate motion
   if { ![VALIDATE_MOTION] } {

     # PB_CMD_abort_event should be revised to handle the new abort level.
     # To abort the motion completely, it should not unset mom_sys_abort_next_event immediately.

      set ::mom_sys_abort_next_event 3
      return
   }


  # Lock on and not circular move
   global mom_sys_lock_status  ;# Set in MOM_lock_axis
   global mom_current_motion
   if { [info exists mom_sys_lock_status] && ![string compare "ON" $mom_sys_lock_status] } {
      if { [info exists mom_current_motion] && [string compare "circular_move" $mom_current_motion] } {

         LOCK_AXIS_MOTION
      }
   }


  # Handle rotary over travel for linear moves (mom_sys_rotary_error set in PB_catch_warning)
   global mom_sys_rotary_error mom_motion_event
   if { [info exists mom_sys_rotary_error] } {
      if { $mom_sys_rotary_error != 0 && \
           [info exists mom_motion_event] && ![string compare "linear_move" $mom_motion_event] } {

         ROTARY_AXIS_RETRACT
      }

     # Error state s/b reset every time to avoid residual effect!
      UNSET_VARS mom_sys_rotary_error
   }


  # Auto clamp on
   global mom_sys_auto_clamp
   if { [info exists mom_sys_auto_clamp] && ![string compare "ON" $mom_sys_auto_clamp] } {

      AUTO_CLAMP
   }
}


#=============================================================
proc PB_CMD_kin_before_output { } {
#=============================================================
# Broker command ensuring PB_CMD_before_output,if present, gets executed
# by MOM_before_output.
#
   if [llength [info commands PB_CMD_before_output] ] {
      PB_CMD_before_output
   }
}


#=============================================================
proc PB_CMD_kin_catch_warning { } {
#=============================================================
# Called by PB_catch_warning
#
# - String with "mom_warning_info" (come from event generator or handlers)
#   may be output by MOM_catch_warning to the message file.
#
# - "mom_warning_info" will be transfered to "mom_sys_rotary_error" for
#   PB_CMD_kin_before_motion to handle the error condition.
#

  global mom_sys_rotary_error mom_warning_info

   if { [string match "ROTARY CROSSING LIMIT." $mom_warning_info] } {
      set mom_sys_rotary_error $mom_warning_info
   }

   if { [string match "secondary rotary position being used" $mom_warning_info] } {
      set mom_sys_rotary_error $mom_warning_info
   }

   if { [string match "WARNING: unable to determine valid rotary positions" $mom_warning_info] } {

     # To abort the current event
     # - Whoever handles this condition MUST unset it to avoid any lingering effect!
     #
      global mom_sys_abort_next_event
      set mom_sys_abort_next_event 1
   }
}


#=============================================================
proc PB_CMD_kin_end_of_path { } {
#=============================================================
  # Record tool time for this operation.
   if { [llength [info commands PB_CMD_set_oper_tool_time] ] } {
      PB_CMD_set_oper_tool_time
   }

  # Clear tool holder angle used in operation
   global mom_use_b_axis
   UNSET_VARS mom_use_b_axis
}


#=============================================================
proc PB_CMD_kin_feedrate_set { } {
#=============================================================
# This command supercedes the functionalites provided by the
# FEEDRATE_SET in ugpost_base.tcl.  Post Builder automatically
# generates proper call sequences to this command in the
# Event handlers.
#
# This command must be used in conjunction with ugpost_base.tcl.
#
   global   feed com_feed_rate
   global   mom_feed_rate_output_mode super_feed_mode feed_mode
   global   mom_cycle_feed_rate_mode mom_cycle_feed_rate
   global   mom_cycle_feed_rate_per_rev
   global   mom_motion_type
   global   Feed_IPM Feed_IPR Feed_MMPM Feed_MMPR Feed_INV
   global   mom_sys_feed_param
   global   mom_sys_cycle_feed_mode


   set super_feed_mode $mom_feed_rate_output_mode

   set f_pm [ASK_FEEDRATE_FPM]
   set f_pr [ASK_FEEDRATE_FPR]

   switch $mom_motion_type {

      CYCLE {
         if { [info exists mom_sys_cycle_feed_mode] } {
            if { [string compare "Auto" $mom_sys_cycle_feed_mode] } {
               set mom_cycle_feed_rate_mode $mom_sys_cycle_feed_mode
            }
         }
         if { [info exists mom_cycle_feed_rate_mode] }    { set super_feed_mode $mom_cycle_feed_rate_mode }
         if { [info exists mom_cycle_feed_rate] }         { set f_pm $mom_cycle_feed_rate }
         if { [info exists mom_cycle_feed_rate_per_rev] } { set f_pr $mom_cycle_feed_rate_per_rev }
      }

      FROM -
      RETRACT -
      RETURN -
      LIFT -
      TRAVERSAL -
      GOHOME -
      GOHOME_DEFAULT -
      RAPID {
         SUPER_FEED_MODE_SET RAPID
      }

      default {
         if { [EQ_is_zero $f_pm] && [EQ_is_zero $f_pr] } {
            SUPER_FEED_MODE_SET RAPID
         } else {
            SUPER_FEED_MODE_SET CONTOUR
         }
      }
   }


   set feed_mode $super_feed_mode


  # Adjust feedrate format per Post output unit again.
   global mom_kin_output_unit
   if { ![string compare "IN" $mom_kin_output_unit] } {
      switch $feed_mode {
         MMPM {
            set feed_mode "IPM"
            CATCH_WARNING "Feedrate mode MMPM changed to IPM"
         }
         MMPR {
            set feed_mode "IPR"
            CATCH_WARNING "Feedrate mode MMPR changed to IPR"
         }
      }
   } else {
      switch $feed_mode {
         IPM {
            set feed_mode "MMPM"
            CATCH_WARNING "Feedrate mode IPM changed to MMPM"
         }
         IPR {
            set feed_mode "MMPR"
            CATCH_WARNING "Feedrate mode IPR changed to MMPR"
         }
      }
   }


   switch $feed_mode {
      IPM     -
      MMPM    { set feed $f_pm }
      IPR     -
      MMPR    { set feed $f_pr }
      DPM     { set feed [PB_CMD_FEEDRATE_DPM] }
      FRN     -
      INVERSE { set feed [PB_CMD_FEEDRATE_NUMBER] }
      default {
         CATCH_WARNING "INVALID FEED RATE MODE"
         return
      }
   }


  # Post Builder provided format for the current mode:
   if { [info exists mom_sys_feed_param(${feed_mode},format)] } {
      MOM_set_address_format F $mom_sys_feed_param(${feed_mode},format)
   } else {
      switch $feed_mode {
         IPM     -
         MMPM    -
         IPR     -
         MMPR    -
         DPM     -
         FRN     { MOM_set_address_format F Feed_${feed_mode} }
         INVERSE { MOM_set_address_format F Feed_INV }
      }
   }

  # Commentary output
   set com_feed_rate $f_pm


  # Execute user's command, if any.
   if { [llength [info commands "PB_CMD_FEEDRATE_SET"]] } {
      PB_CMD_FEEDRATE_SET
   }
}


#=============================================================
proc PB_CMD_kin_handle_sync_event { } {
#=============================================================
   PB_CMD_handle_sync_event
}


#=============================================================
proc PB_CMD_kin_init_new_iks { } {
#=============================================================
   global mom_new_iks_exists

  # Revert legacy dual-head kinematic parameters when new IKS is absent.
   if { ![info exists mom_new_iks_exists] } {
      set ugii_version [string trim [MOM_ask_env_var UGII_VERSION]]
      if { ![string match "v3" $ugii_version] } {

         if { [llength [info commands PB_CMD_revert_dual_head_kin_vars] ] } {
            PB_CMD_revert_dual_head_kin_vars
         }
return
      }
   }

  # Initialize new IKS parameters.
   if { [llength [info commands PB_init_new_iks] ] } {
      PB_init_new_iks
   }

  # Users can provide next command to modify or disable new IKS options.
   if { [llength [info commands PB_CMD_revise_new_iks] ] } {
      PB_CMD_revise_new_iks
   }

  # Revert legacy dual-head kinematic parameters when new IKS is disabled.
   global mom_kin_iks_usage
   if { $mom_kin_iks_usage == 0 } {
      if { [llength [info commands PB_CMD_revert_dual_head_kin_vars] ] } {
         PB_CMD_revert_dual_head_kin_vars
      }
   }
}


#=============================================================
proc PB_CMD_kin_init_probing_cycles { } {
#=============================================================
   set cmd PB_CMD_init_probing_cycles
   if { [llength [info commands "$cmd"]] } {
      eval $cmd
   }
}


#=============================================================
proc PB_CMD_kin_init_rotary { } {
#=============================================================
# Following commands are defined (via uplevel) here:
#
#    MOM_clamp
#    MOM_rotate
#    MOM_lock_axis
#    PB_catch_warning
#    MOM_lintol
#

   global mom_kin_machine_type

   if { [info exists mom_kin_machine_type] } {
      if { [string match "*3_axis_mill*" $mom_kin_machine_type] ||\
           [string match "*lathe*" $mom_kin_machine_type] } {
return
      }
   }


   if { [llength [info commands PB_CMD_init_rotary] ] } {
      PB_CMD_init_rotary
   }


#***********
uplevel #0 {


#=============================================================
### This is the backup of original MOM_clamp handler.
###
### - New command PB_CMD_MOM_clamp is created with the
###   same content of the original command and executed
###   by the new MOM_clamp handler.
###
proc DUMMY_MOM_clamp { } {
#=============================================================
  global mom_clamp_axis mom_clamp_status mom_sys_auto_clamp

   if { ![string compare "AUTO" $mom_clamp_axis] } {

      if { ![string compare "ON" $mom_clamp_status] } {
         set mom_sys_auto_clamp "ON"
      } elseif { ![string compare "OFF" $mom_clamp_status] } {
         set mom_sys_auto_clamp "OFF"
      }
   } else {
      CATCH_WARNING "$mom_clamp_axis not handled in current implementation!"
   }
}


#=============================================================
### This is the backup of original MOM_rotate handler.
###
### - New command PB_CMD_MOM_rotate is created with the
###   same content of the original command and executed
###   by the new MOM_rotate handler.
###
proc DUMMY_MOM_rotate { } {
#=============================================================
# This command handles a Rotate UDE.
#
# Key parameters set in UDE -
#   mom_rotate_axis_type        :  [ AAXIS | BAXIS   | CAXIS    | HEAD | TABLE | FOURTH_AXIS | FIFTH_AXIS ]
#   mom_rotation_mode           :  [ NONE  | ATANGLE | ABSOLUTE | INCREMENTAL ]
#   mom_rotation_direction      :  [ NONE  | CLW     | CCLW ]
#   mom_rotation_angle          :  Specified angle
#   mom_rotation_reference_mode :  [ ON    | OFF ]
#
   PB_CMD_kin__MOM_rotate
}


#=============================================================
### This is the backup of original MOM_lock_axis handler.
###
### - New command PB_CMD_MOM_lock_axis is created with the
###   same content of the original command and executed
###   by the new MOM_lock_axis handler.
###
proc DUMMY_MOM_lock_axis { } {
#=============================================================
# This command handles a Lock Axis UDE.
#
# Key parameters set in UDE -
#   mom_lock_axis               :  [ XAXIS | YAXIS | ZAXIS | AAXIS | BAXIS | CAXIS | FOURTH | FIFTH | OFF ]
#   mom_lock_axis_plane         :  [ XYPLANE | YZPLANE | ZXPLANE | NONE ]
#   mom_lock_axis_value         :  Angle or coordinate value in Absolute Coordinates System
#   mom_lock_axis_value_defined :  [ 0 | 1 ]
#
# 18-Sep-2015 ljt - Reset positive_radius when lock-axis is OFF

  global mom_sys_lock_value mom_sys_lock_plane
  global mom_sys_lock_axis mom_sys_lock_status

 # Check if the rotary axis is the locked axis, it must be the 4th axis for a 4-axis machine,
 # or the 5th axis for a 5-axis machine. Otherwise, an error will be returned, or lock-axis will be turned off.
 #
 # It determines the locked axis  (axis: 0=X, 1=Y, 2=Z, 3=4th, 4=5th),
 #                   locked plane (plane: 0=YZ, 1=ZX, 2=XY), and
 #                   locked value (value: angle or coordinate that can be carried out)
 #
   set status [SET_LOCK axis plane value] ;# ON/OFF/error

   # Handle "error" condition returned from SET_LOCK
   # - Message in mom_warning_info
   if { ![string compare "error" $status] } {
      global mom_warning_info
      CATCH_WARNING $mom_warning_info

      set mom_sys_lock_status OFF
   } else {
      set mom_sys_lock_status $status
      if { ![string compare "ON" $status] } {
         set mom_sys_lock_axis $axis
         set mom_sys_lock_plane $plane
         set mom_sys_lock_value $value

         LOCK_AXIS_INITIALIZE
      } else {
         global positive_radius
         set positive_radius "0"
      }
   }
}


#=============================================================
proc PB_catch_warning { } {
#=============================================================
# Called by MOM_catch_warning (ugpost_base.tcl)
#
# - String with "mom_warning_info" (come from event generator or handlers)
#   may be output by MOM_catch_warning to the message file.
#
# - "mom_warning_info" will be transfered to "mom_sys_rotary_error" for
#   PB_CMD_kin_before_motion to handle the error condition.
#
   PB_CMD_kin_catch_warning
}


#=============================================================
proc MOM_lintol { } {
#=============================================================
   PB_CMD_kin__MOM_lintol
}


} ;# uplevel
#***********

}


#=============================================================
proc PB_CMD_kin_set_csys { } {
#=============================================================
   if [llength [info commands PB_CMD_set_csys] ] {
      PB_CMD_set_csys
   }

   # Overload IKS params from machine model.
   PB_CMD_reload_iks_parameters

   # In case Axis Rotation has been set to "reverse"
   if { [llength [info commands PB_CMD_reverse_rotation_vector] ] } {
      PB_CMD_reverse_rotation_vector
   }
}


#=============================================================
proc PB_CMD_kin_start_of_path { } {
#=============================================================
# - For mill post -
#
#  This command is executed at the start of every operation.
#  It will verify if a new head (post) was loaded and will
#  then initialize any functionality specific to that post.
#
#  It will also restore the master Start of Program &
#  End of Program event handlers.
#
#  --> DO NOT CHANGE THIS COMMAND UNLESS YOU KNOW WHAT YOU ARE DOING.
#  --> DO NOT CALL THIS COMMAND FROM ANY OTHER CUSTOM COMMAND.
#
  global mom_sys_head_change_init_program

   if { [info exists mom_sys_head_change_init_program] } {

      PB_CMD_kin_start_of_program
      unset mom_sys_head_change_init_program


     # Load alternate units' parameters
      if [CMD_EXIST PB_load_alternate_unit_settings] {
         PB_load_alternate_unit_settings
         rename PB_load_alternate_unit_settings ""
      }


     # Execute start of head callback in new post's context.
      global CURRENT_HEAD
      if { [info exists CURRENT_HEAD] && [CMD_EXIST PB_start_of_HEAD__$CURRENT_HEAD] } {
         PB_start_of_HEAD__$CURRENT_HEAD
      }

     # Restore master start & end of program handlers
      if { [CMD_EXIST "MOM_start_of_program_save"] } {
         if { [CMD_EXIST "MOM_start_of_program"] } {
            rename MOM_start_of_program ""
         }
         rename MOM_start_of_program_save MOM_start_of_program
      }
      if { [CMD_EXIST "MOM_end_of_program_save"] } {
         if { [CMD_EXIST "MOM_end_of_program"] } {
            rename MOM_end_of_program ""
         }
         rename MOM_end_of_program_save MOM_end_of_program
      }

     # Restore master head change event handler
      if { [CMD_EXIST "MOM_head_save"] } {
         if { [CMD_EXIST "MOM_head"] } {
            rename MOM_head ""
         }
         rename MOM_head_save MOM_head
      }
   }

  # Overload IKS params from machine model.
   PB_CMD_reload_iks_parameters

  # Incase Axis Rotation has been set to "reverse"
   if { [CMD_EXIST PB_CMD_reverse_rotation_vector] } {
      PB_CMD_reverse_rotation_vector
   }

  # Initialize tool time accumulator for this operation.
   if { [CMD_EXIST PB_CMD_init_oper_tool_time] } {
      PB_CMD_init_oper_tool_time
   }

  # Force out motion G code at the start of path.
   MOM_force once G_motion
}


#=============================================================
proc PB_CMD_kin_start_of_program { } {
#=============================================================
#  This command will execute the following custom commands for
#  initialization.  They will be executed once at the start of
#  program and again each time they are loaded as a linked post.
#  After execution they will be deleted so that they are not
#  present when a different post is loaded.  You may add a call
#  to any command that you want executed when a linked post is
#  loaded.
#
#  Note when a linked post is called in, the Start of Program
#  event marker is not executed again.
#
#  --> DO NOT REMOVE ANY LINES FROM THIS PROCEDURE UNLESS YOU KNOW
#      WHAT YOU ARE DOING.
#  --> DO NOT CALL THIS PROCEDURE FROM ANY
#      OTHER CUSTOM COMMAND.
#
   global mom_kin_machine_type


   set command_list [list]

   if { [info exists mom_kin_machine_type] } {
      if { ![string match "*3_axis_mill*" $mom_kin_machine_type] && ![string match "*lathe*" $mom_kin_machine_type] } {

         lappend command_list  PB_CMD_kin_init_rotary
      }
   }

   lappend command_list  PB_CMD_kin_init_new_iks

   lappend command_list  PB_CMD_init_pivot_offsets
   lappend command_list  PB_CMD_init_auto_retract
   lappend command_list  PB_CMD_initialize_parallel_zw_mode
   lappend command_list  PB_CMD_init_parallel_zw_mode
   lappend command_list  PB_CMD_initialize_tool_list
   lappend command_list  PB_CMD_init_tool_list
   lappend command_list  PB_CMD_init_tape_break
   lappend command_list  PB_CMD_initialize_spindle_axis
   lappend command_list  PB_CMD_init_spindle_axis
   lappend command_list  PB_CMD_initialize_helix
   lappend command_list  PB_CMD_init_helix
   lappend command_list  PB_CMD_pq_cutcom_initialize
   lappend command_list  PB_CMD_init_pq_cutcom

   lappend command_list  PB_CMD_kin_init_probing_cycles

   lappend command_list  PB_DEFINE_MACROS

   if { [info exists mom_kin_machine_type] } {
      if { [string match "*3_axis_mill_turn*" $mom_kin_machine_type] } {

         lappend command_list  PB_CMD_kin_init_mill_xzc
         lappend command_list  PB_CMD_kin_mill_xzc_init
         lappend command_list  PB_CMD_kin_init_mill_turn
         lappend command_list  PB_CMD_kin_mill_turn_initialize
      }
   }


   foreach cmd $command_list {

      if { [llength [info commands "$cmd"]] } {

        # <PB v2.0.2>
        # Old init commands for XZC/MILL_TURN posts are not executed.
        # Parameters set by these commands in the v2.0 legacy posts
        # will need to be transfered to PB_CMD_init_mill_xzc &
        # PB_CMD_init_mill_turn commands respectively.

         switch $cmd {
            "PB_CMD_kin_mill_xzc_init" -
            "PB_CMD_kin_mill_turn_initialize" {}
            default { eval $cmd }
         }
         rename $cmd ""
         proc $cmd { args } {}
      }
   }
}


#=============================================================
proc PB_CMD_linear_move { } {
#=============================================================
#  This command is executed automatically by other functions
#  to output a linear move.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#
#
#  This command, when present in the post, will be used for
#     simulated cycles feed moves
#     mill/turn mill linearization
#     four and five axis retract and re-engage
#

# Add condition for Sinumerik 840D template post
   if { [PB_CMD__check_block_rotary] } {
      MOM_do_template linear_move
   }
   if { [PB_CMD__check_block_traori_rotary] } {
      MOM_do_template linear_move
   }
   if {[PB_CMD__check_block_traori_vector] } {
      MOM_do_template linear_move_1
   }
}


#=============================================================
proc PB_CMD_log_revisions { } {
#=============================================================
# Dummy command to log changes in this post --
#
# 02-26-09 gsl - Initial version
#
# 05-05-2011 lili Remove PB_CMD_define_feed_varialble_value from initial move and first move
#                 Add it into PB_CMD_MOM_sinumerik_840D
#                 Move feedrate define in variable from PB_CMD_before_motion to PB_CMD_FEEDRATE_SET
# resolution
# coordinate rotation
# nurbs
# cutcom
# test FGREF for 3 and 4 axis machine
}


#=============================================================
proc PB_CMD_move_force_addresses { } {
#=============================================================
  MOM_force once G_motion X Y Z D
}


#=============================================================
proc PB_CMD_nurbs_poly { } {
#=============================================================
  global mom_kin_nurbs_output_type
  if { ![string match "SIEMENS_POLY" $mom_kin_nurbs_output_type] } { return }

  global mom_nurbs_point_count
  global mom_nurbs_points
  global mom_nurbs_coefficients
  global mom_nurbs_point_x
  global mom_nurbs_co_efficient_0
  global mom_nurbs_co_efficient_1
  global mom_nurbs_point_y
  global mom_nurbs_co_efficient_3
  global mom_nurbs_co_efficient_4
  global mom_nurbs_point_z
  global mom_nurbs_co_efficient_6
  global mom_nurbs_co_efficient_7

  for { set ii 0 } { $ii < $mom_nurbs_point_count } { incr ii } {
    set poly_output_mode ""
    set xe [expr ($mom_nurbs_points($ii,0) + $mom_nurbs_coefficients($ii,0) + $mom_nurbs_coefficients($ii,1) + $mom_nurbs_coefficients($ii,2))]
    set ye [expr ($mom_nurbs_points($ii,1) + $mom_nurbs_coefficients($ii,3) + $mom_nurbs_coefficients($ii,4) + $mom_nurbs_coefficients($ii,5))]
    set ze [expr ($mom_nurbs_points($ii,2) + $mom_nurbs_coefficients($ii,6) + $mom_nurbs_coefficients($ii,7) + $mom_nurbs_coefficients($ii,8))]
    set mom_nurbs_point_x        $xe
    set mom_nurbs_co_efficient_0 $mom_nurbs_coefficients($ii,1)
    set mom_nurbs_co_efficient_1 $mom_nurbs_coefficients($ii,0)
    set mom_nurbs_point_y        $ye
    set mom_nurbs_co_efficient_3 $mom_nurbs_coefficients($ii,4)
    set mom_nurbs_co_efficient_4 $mom_nurbs_coefficients($ii,3)
    set mom_nurbs_point_z        $ze
    set mom_nurbs_co_efficient_6 $mom_nurbs_coefficients($ii,7)
    set mom_nurbs_co_efficient_7 $mom_nurbs_coefficients($ii,6)
    MOM_do_template nurbs_poly
  }
}


#=============================================================
proc PB_CMD_nurbs_spline { } {
#=============================================================
  global mom_kin_nurbs_output_type
  global mom_nurbs_knot_count
  global mom_nurbs_point_count
  global mom_nurbs_order

  global nurbs_knot_count
  global nurbs_cntrl_count
  global nurbs_precision
  global nurbs_move_flag
  global prev_nurbs_move_flag
  global saved_nurbs_order

  global mom_nurbs_points
  global mom_nurbs_knots
  global point_length
  global last_motion_type

  global mom_prev_pos
  global mom_pos
  global mom_nxt_motion_event mom_current_motion

  global mom_kin_nurbs_output_type
  if { ![string match "BSPLINE" $mom_kin_nurbs_output_type] } { return }

  if {![string match "first_move" $mom_current_motion] && ![string match "MOM_first_move" [MOM_ask_event_type]] } {
     set nurbs_move_flag 1
     if {[info exists prev_nurbs_move_flag] && $prev_nurbs_move_flag == 1} {
        if {[info exists saved_nurbs_order] && $saved_nurbs_order == $mom_nurbs_order} {
           set nurbs_move_flag 2
        }
     }
  } else {
     set nurbs_move_flag 0
     set saved_nurbs_order 0
  }

  if {[info exists mom_nxt_motion_event] && [string match "*nurbs*" $mom_nxt_motion_event]} {
     set prev_nurbs_move_flag 1
  } else {
     set prev_nurbs_move_flag 0
  }

if {1} {
# change nurbs move with degree 1 to linear move
 if {$mom_nurbs_order == 2} {
     if {$nurbs_move_flag == 0} {
         set start_count 0
     } else {
         set start_count 1
     }
     for {set i $start_count} {$i< $mom_nurbs_point_count} {incr i} {
         set mom_pos(0) $mom_nurbs_points($i,0)
         set mom_pos(1) $mom_nurbs_points($i,1)
         set mom_pos(2) $mom_nurbs_points($i,2)
         MOM_linear_move
     }
     set prev_nurbs_move_flag 0
     set saved_nurbs_order 2
     MOM_abort_event
 }
}
  set nurbs_knot_count 2
  MOM_force ALWAYS PL
  MOM_force once G_motion

  for { set nurbs_cntrl_count 0 } { $nurbs_cntrl_count < $mom_nurbs_point_count } { incr nurbs_cntrl_count } {
    # caculate knots vector difference
    set nurbs_knot_count_saved [expr $nurbs_knot_count - 1 ]
    set point_length [expr $mom_nurbs_knots($nurbs_knot_count)-$mom_nurbs_knots($nurbs_knot_count_saved)]

        if { $nurbs_move_flag == 0 && $nurbs_cntrl_count == 0 } {
             MOM_do_template nurbs_bspline_start
             #MOM_add_to_block_buffer nurbs_bspline start [MOM_do_template nurbs_start CREATE]
             MOM_suppress Once SD
        } elseif { $nurbs_move_flag != 0 && $nurbs_cntrl_count == 0 } {
         # suppress first contrl point
           MOM_suppress once X Y Z PL SD
           MOM_do_template nurbs_bspline
    } else {
        # output BSPLINE and SD keywords with second control point
           if { $nurbs_move_flag != 2 && $nurbs_cntrl_count == 1} {
               MOM_force once SD
           }
    #   MOM_force once X Y Z
           MOM_do_template nurbs_bspline
    }

        set nurbs_knot_count [expr $nurbs_knot_count + 1]
  }

  set saved_nurbs_order $mom_nurbs_order

  set nurbs_count [expr $mom_nurbs_point_count -1]
  for { set i 0 } { $i < 3 } { incr i } {
      set mom_prev_pos($i) $mom_nurbs_points($nurbs_count,$i)
      set mom_pos($i) $mom_nurbs_points($nurbs_count,$i)
  }
  MOM_reload_variable -a mom_prev_pos
  MOM_reload_variable -a mom_pos
}


#=============================================================
proc PB_CMD_output_5axis { } {
#=============================================================
#This command is used to output tool tip position independent with machinme kinematics(TRAORI)
#This command must be placed in PB_CMD_before_motion.
   global mom_siemens_coord_rotation mom_siemens_5axis_output_mode
   global mom_mcs_goto mom_pos mom_tool_axis
   global mom_prev_mcs_goto mom_prev_pos
   global mom_arc_center mom_pos_arc_center
   global mcs_contact_point mcs_contact_normal
   global mom_kin_machine_type
   global mom_cutcom_mode mom_cutcom_status
   global mom_contact_point mom_contact_center mom_contact_normal
   global mom_contact_status
   global cycle_init_flag
   global mom_current_motion mom_motion_type
   global mom_cycle_rapid_to mom_cycle_retract_to mom_cycle_feed_to
   global mom_siemens_ori_coord mom_init_pos mom_out_angle_pos
   global mom_cycle_rapid_to_pos mom_cycle_retract_to_pos mom_cycle_feed_to_pos
   global mom_cycle_spindle_axis
   global mom_cutcom_plane

   if { ![info exists mom_siemens_coord_rotation] } {
      set mom_siemens_coord_rotation 0
   }

   if { ![info exists mom_siemens_5axis_output_mode] } {
      set mom_siemens_5axis_output_mode 0
   }

   if { $mom_siemens_coord_rotation == 2 } {
return
   }

   if { $mom_siemens_5axis_output_mode != 0 } {
      VMOV 3 mom_mcs_goto mom_pos
      VMOV 3 mom_prev_mcs_goto mom_prev_pos
      VMOV 3 mom_arc_center mom_pos_arc_center

      if { [info exists cycle_init_flag] && $cycle_init_flag == "TRUE" } {
         if { [string match "initial_move" $mom_current_motion] } {
            set mom_pos(0) [expr $mom_pos(0) + $mom_cycle_rapid_to*$mom_tool_axis(0)]
            set mom_pos(1) [expr $mom_pos(1) + $mom_cycle_rapid_to*$mom_tool_axis(1)]
            set mom_pos(2) [expr $mom_pos(2) + $mom_cycle_rapid_to*$mom_tool_axis(2)]
         }
      }

      if { [string match "CYCLE" $mom_motion_type] && [string compare "cycle_plane_change" $mom_current_motion] } {
         if { $mom_siemens_coord_rotation == 1 } {
            set mom_cycle_spindle_axis 2
         }

         if { ![string match "first_move" $mom_current_motion] &&\
              ![string match "initial_move" $mom_current_motion] } {
            set mom_cycle_rapid_to_pos($mom_cycle_spindle_axis)   [expr $mom_pos($mom_cycle_spindle_axis)+$mom_cycle_rapid_to]
            set mom_cycle_retract_to_pos($mom_cycle_spindle_axis) [expr $mom_pos($mom_cycle_spindle_axis)+$mom_cycle_retract_to]
            set mom_cycle_feed_to_pos($mom_cycle_spindle_axis)    [expr $mom_pos($mom_cycle_spindle_axis)+$mom_cycle_feed_to]
         }
      }

      if { [info exists mom_contact_status] && $mom_contact_status == "ON" } {
         if { [info exists mcs_contact_normal] && [info exists mom_contact_normal] } {
            VMOV 3 mcs_contact_normal mom_contact_normal
         }
         if { [info exists mom_contact_point] } {
            MCS_VECTOR mom_contact_point mcs_contact_point
            VMOV 3 mcs_contact_point mom_mcs_goto
            VMOV 3 mcs_contact_point mom_pos
         }
      }
   }
}


#=============================================================
proc PB_CMD_output_feed_define { } {
#=============================================================
# This is used to output feedrate variable's value
# Please DO NOT remove this command unless you know what you are doing.
     global mom_siemens_feed_output_block
     global mom_seqnum
     set mom_siemens_feed_output_block [expr int($mom_seqnum)]
     MOM_output_literal ";"
}


#=============================================================
proc PB_CMD_output_feedrate_def { } {
#=============================================================
#This command is used to generate feedrate variables in NC code.
#This command must be placed in the End of Program.
  global ptp_file_name
  global group_output_file
  global mom_group_name
  global mom_sys_ptp_output
  global mom_output_file_directory
  global mom_output_file_basename
  global output_extn
  global mom_sequence_number
  global mom_sequence_increment
  global mom_sequence_frequency
  global mom_siemens_feed_var_num
  global mom_siemens_feed_value
  global mom_siemens_feed_definition
  global feed_definition
  global mom_siemens_program_control
  global mom_sys_in_operation
  global feedrate_file_name

  #In case group output is generated
  if { [info exists mom_group_name] } {
     if { [info exists group_output_file($mom_group_name)] } {
        set feedrate_file_name $group_output_file($mom_group_name)
        PB_CMD_output_feedrate_variables
return
     }
  }

  #Output feedrate variable definitions to NC code file
  if { [info exists ptp_file_name] } {
     set feedrate_file_name $ptp_file_name
     PB_CMD_output_feedrate_variables
  }

  set mom_siemens_feed_definition "OFF"
}


#=============================================================
proc PB_CMD_output_feedrate_variables { } {
#=============================================================
# This command is used to define feedrate variables in NC files.
# This command is called by PB_CMD_feedrate_def and PB_CMD_end_of_extcall_operation.
  global feedrate_file_name
  global mom_sys_ptp_output
  global mom_sequence_number
  global mom_sequence_increment
  global mom_sequence_frequency
  global mom_siemens_feed_var_num
  global mom_siemens_feed_value
  global mom_siemens_feed_definition
  global feed_definition
  global mom_siemens_program_control
  global mom_sys_in_operation
  global mom_sys_leader
  global mom_sys_control_out
  global mom_siemens_feed_block_num
  global mom_siemens_feed_block
  global mom_siemens_feed_output_seqnum

  #feed_definition is set in PB_CMD_define_feedrate_format.
  if {![info exists feed_definition]} {
return
  } else {
     unset feed_definition
  }

  if {$mom_sys_ptp_output != "ON" && ![file exists $feedrate_file_name]} {
return
  }

  MOM_close_output_file $feedrate_file_name
  set ncfile [open $feedrate_file_name r]
  set i 0
  foreach line [split [read $ncfile] \n] {
     set fileline($i) $line
     incr i
  }
  set line_num $i
  close $ncfile
  MOM_remove_file $feedrate_file_name
  MOM_open_output_file  $feedrate_file_name

  set j 1
  for {set i 0} {$i<$line_num} {incr i} {
     if {[string match "$mom_sys_leader(N)$mom_siemens_feed_output_seqnum($j) ;" $fileline($i)]} {
        MOM_output_text "$mom_sys_leader(N)$mom_siemens_feed_output_seqnum($j) $mom_siemens_feed_block($j)"
     } elseif {[string match "*$mom_siemens_feed_block($j)" $fileline($i)]} {
        regsub $mom_siemens_feed_block($j) $fileline($i) ";" outline
        MOM_output_text "$outline"
        if {$j < $mom_siemens_feed_block_num} {
           incr j
        }
     } else {
        MOM_output_text $fileline($i)
     }
  }
}


#=============================================================
proc PB_CMD_output_motion_message { } {
#=============================================================
# This command is used to output motion type before movements.
 global mom_motion_type
 global mom_siemens_pre_motion

 if { ![info exists mom_siemens_pre_motion] || ![info exists mom_motion_type] } {
return
 }
 if { ![string match $mom_motion_type $mom_siemens_pre_motion] } {
    switch $mom_motion_type {
      "FIRSTCUT" -
      "STEPOVER" -
      "CUT" {
         if { ![string match "FIRSTCUT" $mom_siemens_pre_motion] && ![string match "CUT" $mom_siemens_pre_motion] && ![string match "STEPOVER" $mom_siemens_pre_motion] } {
            MOM_output_literal ";Cutting"
         }
         set mom_siemens_pre_motion $mom_motion_type
      }
      default {
         set motion_type_first [string toupper [string index $mom_motion_type 0]]
         set motion_type_end [string tolower [string range $mom_motion_type 1 end]]
         set motion_type $motion_type_first$motion_type_end
         MOM_output_literal ";$motion_type Move"
         set mom_siemens_pre_motion $mom_motion_type
      }
    }
 }
}


#=============================================================
proc PB_CMD_output_start_path { } {
#=============================================================
# Output tool, method, tolerance and stock info from CAM operations.
  global mom_oper_method
  global mom_stock_part
  global mom_tool_name
  global mom_tool_type
  global mom_tool_diameter
  global mom_tool_length
  global mom_tool_corner1_radius
  global mom_inside_outside_tolerances
  global mom_operation_name
  global sinumerik_version
  global mom_kin_machine_type
  global mom_kin_4th_axis_leader
  global mom_kin_5th_axis_leader


  MOM_output_literal ";"
  if {[info exists mom_oper_method]} {
     MOM_output_literal ";TECHNOLOGY: $mom_oper_method"
  }
  if {[info exists mom_tool_name]} {
     MOM_output_literal ";TOOL NAME : $mom_tool_name"
  }
  if {[info exists mom_tool_type]} {
     MOM_output_literal ";TOOL TYPE : $mom_tool_type"
  }
  if {[info exists mom_tool_diameter]} {
     MOM_output_literal ";TOOL DIAMETER     : [format "%.6f" $mom_tool_diameter]"

  }
  if {[info exists mom_tool_length]} {
     MOM_output_literal ";TOOL LENGTH       : [format "%.6f" $mom_tool_length]"
  }
  if {[info exists mom_tool_corner1_radius]} {
     MOM_output_literal ";TOOL CORNER RADIUS: [format "%.6f" $mom_tool_corner1_radius]"
  }

  if {[info exists mom_inside_outside_tolerances] && [info exists mom_stock_part]} {
     set intol [format "%.6f" $mom_inside_outside_tolerances(0)]
     set outtol [format "%.6f" $mom_inside_outside_tolerances(1)]
     set stock [format "%.6f" $mom_stock_part]

     MOM_output_literal ";"
     MOM_output_literal ";Intol     : $intol"
     MOM_output_literal ";Outtol    : $outtol"
     MOM_output_literal ";Stock     : $stock"
  }
}


#=============================================================
proc PB_CMD_output_start_program { } {
#=============================================================
# This command is used to output start of program NC codes for sinumerik 840D!
#
  global mom_date
  global mom_part_name
  global mom_definition_file_name
  global start_output_flag
  global mom_sys_leader
  global mom_kin_machine_type

  if { ![info exists start_output_flag] || $start_output_flag == 0 } {
     set start_output_flag 1
     MOM_output_literal ";Start of Program"
    # MOM_output_literal ";"
    # MOM_output_literal ";PART NAME   :$mom_part_name"
    # MOM_output_literal ";DATE TIME   :$mom_date"
     MOM_output_literal ";"
     MOM_output_literal "DEF REAL _camtolerance"
     set fourth_home ""
     set fifth_home ""
     if {[string compare "3_axis_mill" $mom_kin_machine_type]} {
        set mom_sys_leader(fourth_axis_home) "_[set mom_sys_leader(fourth_axis)]_HOME"
        set fourth_home ", $mom_sys_leader(fourth_axis_home)"
        if {[string match "5_axis*" $mom_kin_machine_type]} {
           set mom_sys_leader(fifth_axis_home) "_[set mom_sys_leader(fifth_axis)]_HOME"
           set fifth_home ", $mom_sys_leader(fifth_axis_home)"
        }
     }
     MOM_output_literal "DEF REAL _X_HOME, _Y_HOME, _Z_HOME$fourth_home$fifth_home"
     MOM_output_literal "DEF REAL _F_CUTTING, _F_ENGAGE, _F_RETRACT"
     MOM_output_literal ";"
     MOM_force Once G_cutcom G_plane G F_control G_stopping G_feed G_unit G_mode
     MOM_do_template start_of_program
  }
}


#=============================================================
proc PB_CMD_output_trans_arot { } {
#=============================================================
# This custom command is used to output coordinate rotation codes.
# It will output TRANS and AROT.

  global sinumerik_version
  global mom_operation_type
  global mom_kin_coordinate_system_type
  global mom_out_angle_pos
  global mom_siemens_coord_rotation mom_siemens_5axis_output_mode
  global coord_ref_x coord_ref_y coord_ref_z
  global coord_ang_A coord_ang_B coord_ang_C
  global coord_angle
  global coord_offset
  global cycle800_inc_retract
  global cycle800_tc cycle800_dir
  global cycle800_st cycle800_mode
  global mom_siemens_5axis_mode
  global mom_kin_machine_type
  global mom_siemens_ori_def
  global mom_siemens_ori_inter
  global rot_angle_pos mom_init_pos
  global mom_rotary_direction_4th mom_rotary_direction_5th
  global mom_pos mom_alt_pos mom_out_angle_pos
  global mom_siemens_ori_coord
  global mom_kin_machine_type
  global mom_kin_4th_axis_type
  global mom_kin_5th_axis_type
  global mom_tool_axis_type
  global mom_operation_name
  global mom_tool_axis
  global sinumerik_control_version
  global mom_siemens_cycle_plane
  global mom_tool_path_type

  if {[info exists sinumerik_control_version] && [string match $sinumerik_control_version "Solutionline"]} {
      set mom_siemens_cycle_plane 1
  }

  if { [string match "3_axis_mill" $mom_kin_machine_type] } {
return
  }



  if { ![info exists mom_siemens_coord_rotation] } {
     set mom_siemens_coord_rotation 0
  }

  if { $mom_siemens_coord_rotation == 0 } {
     if { [array exists coord_offset] } {
        if { ![EQ_is_zero $coord_offset(0)] || ![EQ_is_zero $coord_offset(1)] || ![EQ_is_zero $coord_offset(2)] } {
           MOM_force once X Y Z
           MOM_do_template frame_trans
           global coord_offset_flag
           set coord_offset_flag 1
        }
     }
  } else {
  # Local csys rotation is setting
     if { $mom_siemens_coord_rotation == 1 } {
        if { ![EQ_is_equal $mom_tool_axis(2) 1.0] } {
            MOM_output_to_listing_device \
              "Warning in $mom_operation_name: Wrong Local MCS, Z axis is not parallel to tool axis vector."
        }
     }

    # Output TRANS and AROT
     if { ![string match "SWIVELING" $mom_siemens_5axis_mode] } {
        if { [array exists coord_offset] } {
           if { ![EQ_is_zero $coord_offset(0)] || ![EQ_is_zero $coord_offset(1)] || ![EQ_is_zero $coord_offset(2)] } {
              MOM_force once X Y Z
              MOM_do_template frame_trans
           }
        }
        if { ![EQ_is_zero $coord_ang_A] } {
           MOM_do_template frame_arot_x
        }
        if { ![EQ_is_zero $coord_ang_B] } {
           MOM_do_template frame_arot_y
        }
        if { ![EQ_is_zero $coord_ang_C] } {
           MOM_do_template frame_arot_z
        }
     }
  }

}


#=============================================================
proc PB_CMD_pause { } {
#=============================================================
# This command enables you to pause the UG/Post processing.
#
  PAUSE
}


#=============================================================
proc PB_CMD_reload_iks_parameters { } {
#=============================================================
# This command overloads new IKS params from a machine model.(NX4)
# It will be executed automatically at the start of each path
# or when CSYS has changed.
#
   global mom_csys_matrix
   global mom_kin_iks_usage

  #----------------------------------------------------------
  # Set a classification to fetch kinematic parameters from
  # a particular set of K-components of a machine.
  # - Default is NONE.
  #----------------------------------------------------------
   set custom_classification NONE

   if { [info exists mom_kin_iks_usage] && $mom_kin_iks_usage == 1 } {
      if { [info exists mom_csys_matrix] } {
         if { [llength [info commands MOM_validate_machine_model] ] } {
            if { [MOM_validate_machine_model] == "TRUE" } {
               MOM_reload_iks_parameters "$custom_classification"
               MOM_reload_kinematics
            }
         }
      }
   }
}


#=============================================================
proc PB_CMD_reposition_move { } {
#=============================================================
#
#  This command is used by rotary axis retract to reposition the
#  rotary axes after the tool has been fully retracted.
#
#  You can modify the this command to customize the reposition move.
#  If you need a custom command to be output with this block,
#  you must execute a call a the custom command either before or after
#  the MOM_do_template command.
#
   MOM_suppress once X Y Z
   MOM_do_template rapid_traverse
}


#=============================================================
proc PB_CMD_reset_Sinumerik_setting { } {
#=============================================================
# This command is used to reset the setting for Sinumerik.
#
# It is called in MOM_end_of_path.
#
# 23-Dec-2016 shuai - CYCLE832 enhancement.
#

  global mom_group_name
  global mom_prev_group_name

  if {[info exists mom_group_name] && $mom_group_name != ""} {
     set mom_prev_group_name $mom_group_name
  }

  global mom_current_oper_is_last_oper_in_program
  global mom_siemens_tol_group
  global mom_siemens_tol_status_group
  global mom_siemens_rotary_tol_group
  global mom_siemens_rotary_tol_status_group
  global mom_siemens_feed_definition
  global mom_siemens_milling_setting

  if {[info exists mom_current_oper_is_last_oper_in_program] && [string match "YES" $mom_current_oper_is_last_oper_in_program]} {

     if {[info exists mom_siemens_tol_group]} {
        unset mom_siemens_tol_group
     }
     if {[info exists mom_siemens_tol_status_group]} {
        unset mom_siemens_tol_status_group
     }

     if {[info exists mom_siemens_rotary_tol_group]} {
        unset mom_siemens_rotary_tol_group
     }
     if {[info exists mom_siemens_rotary_tol_status_group]} {
        unset mom_siemens_rotary_tol_status_group
     }

     set mom_siemens_feed_definition "OFF"
     set mom_siemens_milling_setting "Default"

     if {[llength [info commands PB_CMD_set_Sinumerik_default_setting]]} {
        PB_CMD_set_Sinumerik_default_setting
     }

     return
  }

  global mom_siemens_tol
  global mom_siemens_tol_status
  global mom_siemens_rotary_tol
  global mom_siemens_rotary_tol_status
  global mom_siemens_compressor mom_siemens_compressor_group
  global mom_siemens_smoothing mom_siemens_smoothing_group
  global mom_siemens_feedforward mom_siemens_feedforward_group
  global mom_siemens_top_surface_smooth mom_siemens_top_surface_smooth_group
  global mom_siemens_5axis_mode mom_siemens_5axis_mode_group
  global mom_siemens_ori_def mom_siemens_ori_def_group
  global mom_siemens_feed_definition_group

  if {[string match "Group*" $mom_siemens_milling_setting]} {

     if {[info exists mom_siemens_tol_group]} {
        set mom_siemens_tol $mom_siemens_tol_group
     }
     if {[info exists mom_siemens_tol_status_group]} {
        set mom_siemens_tol_status $mom_siemens_tol_status_group
     }

     set mom_siemens_compressor $mom_siemens_compressor_group
     set mom_siemens_smoothing $mom_siemens_smoothing_group
     set mom_siemens_feedforward $mom_siemens_feedforward_group
     set mom_siemens_top_surface_smooth $mom_siemens_top_surface_smooth_group
     set mom_siemens_5axis_mode $mom_siemens_5axis_mode_group
     set mom_siemens_ori_def $mom_siemens_ori_def_group
     set mom_siemens_feed_definition $mom_siemens_feed_definition_group

     if {[info exists mom_siemens_rotary_tol_status_group]} {
        set mom_siemens_rotary_tol_status $mom_siemens_rotary_tol_status_group
     }
     if {[info exists mom_siemens_rotary_tol_group]} {
        set mom_siemens_rotary_tol $mom_siemens_rotary_tol_group
     }

     # <lili 2013-06-20> Enhancement for group UDE switch.
     if {[info exists mom_group_name]} {
        set mom_siemens_milling_setting "Group$mom_group_name"
     } else {
        set mom_siemens_milling_setting "Group"
     }

  } else {

     set mom_siemens_feed_definition "OFF"
     set mom_siemens_milling_setting "Default"

     if {[llength [info commands PB_CMD_set_Sinumerik_default_setting]]} {
        PB_CMD_set_Sinumerik_default_setting
     }
  }

}


#=============================================================
proc PB_CMD_reset_all_motion_variables_to_zero { } {
#=============================================================
   global mom_prev_pos
   global mom_pos
   global mom_prev_out_angle_pos
   global mom_out_angle_pos
   global mom_prev_rot_ang_4th
   global mom_prev_rot_ang_5th
   global mom_rotation_angle

   set mom_prev_pos(0) 0.0
   set mom_prev_pos(1) 0.0
   set mom_prev_pos(2) 0.0
   set mom_prev_pos(3) 0.0
   set mom_prev_pos(4) 0.0

   set mom_pos(0) 0.0
   set mom_pos(1) 0.0
   set mom_pos(2) 0.0
   set mom_pos(3) 0.0
   set mom_pos(4) 0.0

    set mom_prev_out_angle_pos(0) 0.0
    set mom_prev_out_angle_pos(1) 0.0

    set mom_out_angle_pos(0) 0.0
    set mom_out_angle_pos(1) 0.0

    set mom_prev_rot_ang_4th 0.0
    set mom_prev_rot_ang_5th 0.0

    set mom_rotation_angle 0.0

    MOM_reload_variable -a mom_prev_pos
    MOM_reload_variable -a mom_pos
    MOM_reload_variable -a mom_prev_out_angle_pos
    MOM_reload_variable -a mom_out_angle_pos
    MOM_reload_variable mom_prev_rot_ang_4th
    MOM_reload_variable mom_prev_rot_ang_5th
    MOM_reload_variable mom_rotation_angle

    MOM_reload_kinematics

    DPP_GE_RESTORE_KINEMATICS
}


#=============================================================
proc PB_CMD_reset_arc_compressor_mode { } {
#=============================================================
# This command is used to reset circular and helical mode when compressor is off.

  global mom_kin_arc_output_mode  save_mom_kin_arc_output_mode
  global mom_kin_helical_arc_output_mode  save_mom_kin_helical_arc_output_mode

  if {[info exists save_mom_kin_arc_output_mode] && [info exists save_mom_kin_helical_arc_output_mode]} {

     set mom_kin_arc_output_mode $save_mom_kin_arc_output_mode
     set mom_kin_helical_arc_output_mode $save_mom_kin_helical_arc_output_mode

     MOM_reload_kinematics
  }

}


#=============================================================
proc PB_CMD_reset_control_mode { } {
#=============================================================
  # Motion message flag
  global mom_siemens_pre_motion
  set mom_siemens_pre_motion "end"

  global mom_ude_5axis_tool_path
  catch {unset mom_ude_5axis_tool_path}

  global mom_cycle_option
  catch {unset mom_cycle_option}
}


#=============================================================
proc PB_CMD_reset_fourth_axis { } {
#=============================================================
global mom_angle_out_pos mom_prev_out_angle_pos mom_pos

set mom_prev_out_angle_pos(0) 0.0
set mom_prev_pos(3) 0.0


MOM_reload_variable -a mom_prev_out_angle_pos
MOM_reload_variable -a mom_prev_pos
}


#=============================================================
proc PB_CMD_reset_output_digits { } {
#=============================================================
 # Reset address format according to difference setting.
 # Before use this command,please make sure following formats have been created.
 # AbsCoord_mm AbsCoord_less_mm AbsCoord_nurbs_mm
 # AbsCoord_in AbsCoord_less_in AbsCoord_nurbs_in
 # Rotary Rotary_less

  global mom_motion_output_type
  global mom_siemens_5axis_output_mode
  global mom_output_unit
  global mom_kin_machine_resolution
  global mom_kin_4th_axis_min_incr
  global mom_kin_5th_axis_min_incr

  set address_list [list X Y Z I J K]
  if {[string match $mom_output_unit "MM"]} {
     if {![info exists mom_motion_output_type] || $mom_motion_output_type < 2} {
        global mom_operation_type
        if {![string match "Point to Point" $mom_operation_type] && ![string match "Hole Making" $mom_operation_type] \
            && $mom_siemens_5axis_output_mode == 1} {
           foreach address $address_list {
              catch {MOM_set_address_format $address AbsCoord_mm}
           }
           catch {MOM_set_address_format fourth_axis Rotary}
           catch {MOM_set_address_format fifth_axis Rotary}
        } else {
           foreach address $address_list {
              catch {MOM_set_address_format $address AbsCoord_less_mm}
           }
           catch {MOM_set_address_format fourth_axis Rotary_less}
           catch {MOM_set_address_format fifth_axis Rotary_less}
        }
     } else {
        #For nurbs output
            foreach address $address_list {
              catch {MOM_set_address_format $address AbsCoord_nurbs_mm}
           }
           catch {MOM_set_address_format fourth_axis Rotary}
           catch {MOM_set_address_format fifth_axis Rotary}
     }
  } else {
     if {![info exists mom_motion_output_type] || $mom_motion_output_type < 2} {
        global mom_operation_type
        if {![string match "Point to Point" $mom_operation_type] && ![string match "Hole Making" $mom_operation_type] \
            && $mom_siemens_5axis_output_mode == 1} {
           foreach address $address_list {
              catch {MOM_set_address_format $address AbsCoord_in}
           }
           catch {MOM_set_address_format fourth_axis Rotary}
           catch {MOM_set_address_format fifth_axis Rotary}
        } else {
           foreach address $address_list {
              catch {MOM_set_address_format $address AbsCoord_less_in}
           }
           catch {MOM_set_address_format fourth_axis Rotary_less}
           catch {MOM_set_address_format fifth_axis Rotary_less}
        }
     } else {
        #For nurbs output
         foreach address $address_list {
           catch {MOM_set_address_format $address AbsCoord_nurbs_in}
        }
        catch {MOM_set_address_format fourth_axis Rotary}
        catch {MOM_set_address_format fifth_axis Rotary}
     }
  }
}


#=============================================================
proc PB_CMD_reset_sinumerik_setting_in_group { } {
#=============================================================
# Please DO NOT remove this command from Start of Path, unless you know what you
# are doing.
# This command is used to reset sinumerik settings for different program group.
  global mom_siemens_milling_setting
  global mom_siemens_feed_definition
  global mom_prev_group_name mom_group_name
  global sinumerik_version
  global mom_kin_machine_type
  global mom_kin_4th_axis_leader
  global mom_kin_5th_axis_leader

  if {![info exists mom_siemens_milling_setting]} {
     set mom_siemens_milling_setting "Default"
  }
  if { [info exists mom_prev_group_name] && [string match "Group$mom_prev_group_name" $mom_siemens_milling_setting] } {
     if { [info exists mom_group_name] && ![string match $mom_group_name $mom_prev_group_name] } {
        set mom_siemens_feed_definition "OFF"
        set mom_siemens_milling_setting "Default"
        if {[llength [info commands PB_CMD_set_Sinumerik_default_setting]]} {
           PB_CMD_set_Sinumerik_default_setting
        }
     }
  }
}


#=============================================================
proc PB_CMD_restore_active_oper_tool_data { } {
#=============================================================
#  This command restores the attributes of the tool used in the current operation
#  to be post-processed before the generation of the tool list.
#  The attributes have been saved in proc PB_CMD_save_active_oper_tool_data.
#  This command wil be executed automatically in PB_CMD_create_tool_list.
   global mom_sys_oper_tool_attr_list
   global mom_sys_oper_tool_attr_saved_arr
   foreach mom_var $mom_sys_oper_tool_attr_list {
      global $mom_var
      if [info exists mom_sys_oper_tool_attr_saved_arr($mom_var)] {
         set $mom_var $mom_sys_oper_tool_attr_saved_arr($mom_var)
      }
    }
}


#=============================================================
proc PB_CMD_restore_work_plane_change { } {
#=============================================================
#<02-18-08 gsl> Restore work plane change flag, if being disabled due to a simulated cycle.

  global mom_user_work_plane_change mom_sys_work_plane_change
  global mom_user_spindle_first spindle_first

  if { [info exists mom_user_work_plane_change] } {
    set mom_sys_work_plane_change $mom_user_work_plane_change
    set spindle_first $mom_user_spindle_first
    unset mom_user_work_plane_change
    unset mom_user_spindle_first
  }
}


#=============================================================
proc PB_CMD_retract_move { } {
#=============================================================
#  This command is used by rotary axis retract to move away from
#  the part.  This move is a three axis move along the tool axis at
#  a retract feedrate.
#
#  You can modify the this command to customize the retract move.
#  If you need a custom command to be output with this block,
#  you must execute a call to the custom command either before or after
#  the MOM_do_template command.
#
#  If you need to modify the x,y or z locations you will need to do the
#  following.  (without the #)
#
#  global mom_pos
#  set mom_pos(0) 1.0
#  set mom_pos(1) 2.0
#  set mom_pos(2) 3.0

   MOM_do_template linear_move
}


#=============================================================
proc PB_CMD_reverse_rotation_vector { } {
#=============================================================
# This command fixes the vectors of rotary axes.
# It will be executed automatically when present in the post.
#
# --> Do not attach this command to any event marker!
#

  global mom_kin_iks_usage
  global mom_csys_matrix

   set reverse_vector 0

   if { [info exists mom_kin_iks_usage] && $mom_kin_iks_usage == 1 } {
      if { [info exists mom_csys_matrix] } {
         if { [llength [info commands MOM_validate_machine_model] ] } {
            if { ![string compare "TRUE" [MOM_validate_machine_model]] } {
               set reverse_vector 1
            }
         }
      }
   }

   if $reverse_vector {

     global mom_kin_4th_axis_vector mom_kin_5th_axis_vector
     global mom_kin_4th_axis_rotation mom_kin_5th_axis_rotation

      foreach axis { 4th_axis 5th_axis } {

         if { [info exists mom_kin_${axis}_rotation] && [string match "reverse" [set mom_kin_${axis}_rotation]] } {

            if { [info exists mom_kin_${axis}_vector] } {
               foreach i { 0 1 2 } {
                  set mom_kin_${axis}_vector($i) [expr -1 * [set mom_kin_${axis}_vector($i)]]
               }
            }
         }
      }

      MOM_reload_kinematics
   }
}


#=============================================================
proc PB_CMD_revert_dual_head_kin_vars { } {
#=============================================================
# Only dual-head 5-axis mill posts will be affected by this
# command.
#
# This command reverts kinematic parameters for dual-head 5-axis
# mill posts to maintain compatibility and to allow the posts
# to run in UG/Post prior to NX3.
#
# Attributes of the 4th & 5th Addresses, their locations in
# the Master Word Sequence and all the Blocks that use these
# Addresses will be reconditioned with call to
#
#     PB_swap_dual_head_elements
#
#-------------------------------------------------------------
# 04-15-05 gsl - Added for PB v3.4
#-------------------------------------------------------------

  global mom_kin_machine_type


  if { ![string match  "5_axis_dual_head"  $mom_kin_machine_type] } {
return
  }


  set var_list { ang_offset center_offset(0) center_offset(1) center_offset(2) direction incr_switch leader limit_action max_limit min_incr min_limit plane rotation zero }

  set center_offset_set 0

  foreach var $var_list {
    # Global declaration
    if { [string match "center_offset*" $var] } {
      if { !$center_offset_set } {
         global mom_kin_4th_axis_center_offset mom_kin_5th_axis_center_offset
         set center_offset_set 1
      }
    } else {
      global mom_kin_4th_axis_[set var] mom_kin_5th_axis_[set var]
    }

    # Swap values
    set val [set mom_kin_4th_axis_[set var]]
    set mom_kin_4th_axis_[set var] [set mom_kin_5th_axis_[set var]]
    set mom_kin_5th_axis_[set var] $val
  }

  # Update kinematic parameters
  MOM_reload_kinematics


  # Swap address leaders
  global mom_sys_leader

  set val $mom_sys_leader(fourth_axis)
  set mom_sys_leader(fourth_axis) $mom_sys_leader(fifth_axis)
  set mom_sys_leader(fifth_axis)  $val

  # Swap elements in definition file
  if { [llength [info commands PB_swap_dual_head_elements] ] } {
     PB_swap_dual_head_elements
  }
}


#=============================================================
proc PB_CMD_revise_new_iks { } {
#=============================================================
# This command is executed automatically, which allows you
# to change the default IKS parameters or disable the IKS
# service completely.
#
# *** Do not attach this command to any event marker! ***
#
   global mom_kin_iks_usage
   global mom_kin_rotary_axis_method
   global mom_kin_spindle_axis
   global mom_kin_4th_axis_vector
   global mom_kin_5th_axis_vector


  # Uncomment next statement to disable new IKS service
  # set mom_kin_iks_usage           0


  # Uncomment next statement to change rotary solution method
  # set mom_kin_rotary_axis_method  "ZERO"


  # Uncomment next statement, if any parameter above has changed.
  # MOM_reload_kinematics
}


#=============================================================
proc PB_CMD_rotate_cycle_coordinate { } {
#=============================================================
# This command is used to handle variable-axis drilling cycles.
# If coordinate isn't set as csys rotation and tool axis is not along Zaxis. Frame rotation codes
# TRANS/AROT or cycle800 will be output acoording to tool axis direction.
# For dual table machine without tool tip control, this command will be ignored.

# 10-15-13 Allen - Rewrite the command for that if the tool vector turn to be along Z axis,table axis will not return to zero.

  global cycle_init_flag
  global mom_siemens_cycle_count
  global mom_kin_machine_type
  global mom_tool_axis mom_tool_axis_type
  global mom_siemens_5axis_mode
  global mom_siemens_5axis_output
  global mom_siemens_5axis_output_mode
  global mom_pos mom_mcs_goto mom_prev_pos
  global mom_prev_out_angle_pos mom_out_angle_pos
  global mom_siemens_coord_rotation
  global save_mom_kin_machine_type
  global mom_prev_tool_axis
  global coord_angle
  global mom_cycle_rapid_to_pos mom_cycle_retract_to_pos mom_cycle_feed_to_pos
  global mom_cycle_rapid_to mom_cycle_retract_to mom_cycle_feed_to
  global coord_offset mom_current_motion
  global mom_cycle_spindle_axis
  global mom_out_angle_pos mom_prev_out_angle_pos
  global mom_current_motion
  global mom_kin_machine_type
  global coord_ang_A coord_ang_B coord_ang_C
  global mom_siemens_milling_setting
  global mom_result
  global mom_cycle_clearance_pos mom_cycle_clearance_plane

  if { ![string match "*5_axis*" $mom_kin_machine_type] } {
return
  }

  if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation ==1} {
return
  }

  set coord_rot [DPP_GE_COOR_ROT "XYZ" rot_angle offset pos]

  if {$coord_rot == "AUTO_3D"} {
     set mom_siemens_coord_rotation 2
     if {[array exists coord_angle] && ![VEC3_is_equal coord_angle rot_angle]} {
        # Output coordinate rotation code
        VMOV 3 rot_angle coord_angle
        VMOV 3 offset coord_offset
        set coord_ang_A $coord_angle(0);set coord_ang_B $coord_angle(1);set coord_ang_C $coord_angle(2)
        if { [string compare "SWIVELING" $mom_siemens_5axis_mode] } {
           MOM_do_template reset_trans
           set mom_siemens_5axis_mode "TRAORI"
           set mom_siemens_5axis_output "TRAORI"
           set mom_siemens_5axis_output_mode 1
           MOM_do_template traori_trafoof
           MOM_force Once fourth_axis fifth_axis
        }
        PB_CMD_output_trans_arot
        if { [PB_CMD__check_block_CYCLE800] } {
             PB_call_macro CYCLE800_sl
        }
     }
     MOM_force Once X Y Z
     VMOV 3 pos mom_pos
     MOM_reload_variable -a mom_pos
     VMOV 3 mom_pos mom_cycle_rapid_to_pos
     VMOV 3 mom_pos mom_cycle_feed_to_pos
     VMOV 3 mom_pos mom_cycle_retract_to_pos
     VMOV 3 mom_pos mom_cycle_clearance_pos

     set mom_cycle_rapid_to_pos(2) [expr $mom_pos(2)+$mom_cycle_rapid_to]
     set mom_cycle_retract_to_pos(2) [expr $mom_pos(2)+$mom_cycle_retract_to]
     set mom_cycle_feed_to_pos(2) [expr $mom_pos(2)+$mom_cycle_feed_to]
     set mom_cycle_clearance_pos(2) [expr $mom_pos(2)+$mom_cycle_clearance_plane]
  } elseif {$coord_rot == "NONE"} {
     if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
        VMOV 3 rot_angle coord_angle
        VMOV 3 offset coord_offset
        set coord_ang_A $coord_angle(0);set coord_ang_B $coord_angle(1);set coord_ang_C $coord_angle(2)
        if { [string compare "SWIVELING" $mom_siemens_5axis_mode] } {
           MOM_do_template reset_trans
           MOM_do_template trafoof
        } else {
           MOM_do_template reset_cycle800
        }

        # if it's not auto3d condition, restore the kinematics and recalculate mom_pos
        DPP_GE_RESTORE_KINEMATICS
        if {"1" == [MOM_convert_point mom_mcs_goto mom_tool_axis]} {
           set i 0
           foreach value $mom_result {
              set mom_pos($i) $value
              incr i
           }
        }
        MOM_reload_variable -a mom_pos
        MOM_force Once X Y Z fourth_axis fifth_axis
        VMOV 3 mom_pos mom_cycle_rapid_to_pos
        VMOV 3 mom_pos mom_cycle_feed_to_pos
        VMOV 3 mom_pos mom_cycle_retract_to_pos
        VMOV 3 mom_pos mom_cycle_clearance_pos
        set mom_cycle_rapid_to_pos(2) [expr $mom_pos(2)+$mom_cycle_rapid_to]
        set mom_cycle_retract_to_pos(2) [expr $mom_pos(2)+$mom_cycle_retract_to]
        set mom_cycle_feed_to_pos(2) [expr $mom_pos(2)+$mom_cycle_feed_to]
        set mom_cycle_clearance_pos(2) [expr $mom_pos(2)+$mom_cycle_clearance_plane]
        set mom_siemens_coord_rotation 0
     }


  }


}


#=============================================================
proc PB_CMD_rotate_rapid_coordinate { } {
#=============================================================
# This command is used to detect rotary axis change inside operation for 3+2 milling.
# This command will output coordinate rotation code if the rotary axis change the
# position.

# 10-15-13 Allen - Rewrite the command for that if the tool vector turn to be along Z axis,table axis will not return to zero.

  global mom_kin_machine_type
  global mom_tool_axis mom_tool_axis_type
  global mom_siemens_5axis_mode
  global mom_siemens_5axis_output
  global mom_siemens_5axis_output_mode
  global mom_pos mom_mcs_goto mom_prev_pos
  global mom_prev_out_angle_pos mom_out_angle_pos
  global mom_siemens_coord_rotation
  global save_mom_kin_machine_type
  global mom_prev_tool_axis
  global coord_angle
  global coord_offset mom_current_motion
  global mom_out_angle_pos mom_prev_out_angle_pos
  global mom_kin_machine_type
  global dpp_ge
  global coord_ang_A coord_ang_B coord_ang_C
  global mom_siemens_milling_setting
  global mom_result

  if { ![string match "*5_axis*" $mom_kin_machine_type] } {
return
  }
  if {$dpp_ge(toolpath_axis_num) == 5} {
return
  }
  if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation ==1} {
return
  }
  if {![info exists mom_prev_out_angle_pos]} {
     set mom_prev_out_angle_pos(0) 0.0
     set mom_prev_out_angle_pos(1) 0.0
  }
  if {[EQ_is_equal $mom_out_angle_pos(0) $mom_prev_out_angle_pos(0)] && [EQ_is_equal $mom_out_angle_pos(1) $mom_prev_out_angle_pos(1)]} {
return
  }

  set coord_rot [DPP_GE_COOR_ROT "XYZ" rot_angle offset pos]


  if {$coord_rot == "AUTO_3D"} {
     set mom_siemens_coord_rotation 2
     # Output coordinate rotation code
     if {[array exists coord_angle] && ![VEC3_is_equal coord_angle rot_angle]} {
        VMOV 3 rot_angle coord_angle
        VMOV 3 offset coord_offset
        set coord_ang_A $coord_angle(0);set coord_ang_B $coord_angle(1);set coord_ang_C $coord_angle(2)
        if { [string compare "SWIVELING" $mom_siemens_5axis_mode] } {
           MOM_do_template reset_trans
           set mom_siemens_5axis_mode "TRAORI"
           set mom_siemens_5axis_output "TRAORI"
           set mom_siemens_5axis_output_mode 1
           MOM_do_template traori_trafoof
           MOM_force Once fourth_axis fifth_axis
        }
        PB_CMD_output_trans_arot
        if { [PB_CMD__check_block_CYCLE800] } {
          PB_call_macro CYCLE800_sl
        }
        VMOV 3 pos mom_pos
        MOM_reload_variable -a mom_pos
     }
     MOM_force Once X Y Z
  } elseif {$coord_rot == "NONE"} {
     if {[info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 2} {
        VMOV 3 rot_angle coord_angle
        VMOV 3 offset coord_offset
        set coord_ang_A $coord_angle(0);set coord_ang_B $coord_angle(1);set coord_ang_C $coord_angle(2)
        if { [string compare "SWIVELING" $mom_siemens_5axis_mode] } {
           MOM_do_template reset_trans
           MOM_do_template trafoof
        } else {
           MOM_do_template reset_cycle800
        }

        # if it's not auto3d condition, restore the kinematics and recalculate mom_pos
        DPP_GE_RESTORE_KINEMATICS
        if {"1" == [MOM_convert_point mom_mcs_goto mom_tool_axis]} {
           set i 0
           foreach value $mom_result {
              set mom_pos($i) $value
              incr i
           }
        }
        MOM_reload_variable -a mom_pos
        set mom_siemens_coord_rotation 0
        MOM_force Once X Y Z fourth_axis fifth_axis
     }
  }

}


#=============================================================
proc PB_CMD_run_postprocess { } {
#=============================================================
# This is an example showing how MOM_run_postprocess can be used.
# It can be called in the Start of Program event (or anywhere)
# to process the same objects being posted with a secondary post.
#
# ==> It's advisable NOT to use the active post and the same
#     output file for this secondary posting process.
# ==> Ensure legitimate and fully qualified post processor and
#     output file are specified with the command.
#

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# CAUTION - Uncomment next line to activate this function!
return
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++

   MOM_run_postprocess "[file dirname $::mom_event_handler_file_name]/MORI_HORI_Sub.tcl"\
                       "[file dirname $::mom_event_handler_file_name]/MORI_HORI_Sub.def"\
                       "${::mom_output_file_directory}sub_program.out"
}


#=============================================================
proc PB_CMD_save_active_oper_tool_data { } {
#=============================================================
#  This command saves the attributes of the tool used in the current operation
#  to be post-processed before the generation of the tool list.
#
#  This command will be executed automatically in PB_CMD_create_tool_list.
#
#  You may add any desired MOM variable to the list below to be restored
#  later in your post.
#

   global mom_sys_oper_tool_attr_list
   global mom_sys_oper_tool_attr_saved_arr


  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # You may add any MOM variable that needs to be retained for
  # the operation to the list below (using lappend command).
  #++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   set mom_sys_oper_tool_attr_list [list]

   lappend mom_sys_oper_tool_attr_list  mom_tool_number
   lappend mom_sys_oper_tool_attr_list  mom_tool_length_adjust_register
   lappend mom_sys_oper_tool_attr_list  mom_tool_name
   lappend mom_sys_oper_tool_attr_list  mom_operation_name


   foreach mom_var $mom_sys_oper_tool_attr_list {
      global $mom_var
      if [info exists $mom_var] {
         set mom_sys_oper_tool_attr_saved_arr($mom_var) [eval format %s $$mom_var]
      }
   }
}


#=============================================================
proc PB_CMD_set_Sinumerik_default_setting { } {
#=============================================================
# This command is the default Sinumerik milling settings for Mold&Die and Aerospace production.
#
# 22-Dec-2016 shuai - CYCLE832 enhancement.
#                     Update the description for this command.
#

  # To set default coordinate rotation output mode for 3+2 operations.
  global dpp_coord_rotation_output_type
  set dpp_coord_rotation_output_type "TRAORI" ; # SWIVELING / TRAORI (+AROT)

  global sinumerik_version

  if {![info exists sinumerik_version] } {

     return
  }


  # Set the default settings for smoothing.

  global mom_siemens_smoothing

  switch $sinumerik_version {

     "V6" {
        set mom_siemens_smoothing  "G642" ; # G642 / G64
     }

     "V7" -

     "from V26 to V44" -

     "V45" -

     "V47" {
        set mom_siemens_smoothing  "G645" ; # G645 / G60
     }
  }

  # Set the default settings for some variables.
  global mom_siemens_tol_status
  global mom_siemens_compressor
  global mom_siemens_feedforward
  global mom_siemens_top_surface_smooth
  global mom_siemens_5axis_mode
  global mom_siemens_ori_def
  global mom_siemens_rotary_tol
  global mom_siemens_rotary_tol_status

  set mom_siemens_tol_status         "System" ;      # System / User
  set mom_siemens_compressor         "COMPOF" ;      # COMPCAD / COMPOF
  set mom_siemens_feedforward        "FFWON" ;       # FFWON / FFWOF
  set mom_siemens_top_surface_smooth "" ;            # _TOP_SURFACE_SMOOTH_ON / _TOP_SURFACE_SMOOTH_OFF
  set mom_siemens_5axis_mode         "TRAORI" ;      # TRAORI / SWIVELING / TRAFOOF
  set mom_siemens_ori_def            "ROTARY AXES" ; # ROTARY AXES / VECTOR

  # Set the rotary tolerance.
  set mom_siemens_rotary_tol        0.8
  set mom_siemens_rotary_tol_status "System" ; # System / User

  # Set the method type and settings status for milling.
  global mom_siemens_method
  global mom_siemens_milling_setting

  set mom_siemens_method          "DESELECTION"
  set mom_siemens_milling_setting "Default"

  # Disable tool axis vector in 3axis machine.
  global mom_kin_machine_type

  if {[string match "3_axis_mill" $mom_kin_machine_type]} {

     set mom_siemens_5axis_mode "TRAFOOF"

     MOM_disable_address A3 B3 C3
     MOM_disable_address fourth_axis fifth_axis

  } elseif {[string match "4*" $mom_kin_machine_type] || [string match "3_axis_mill_turn" $mom_kin_machine_type]} {

     MOM_disable_address fifth_axis
  }

}


#=============================================================
proc PB_CMD_set_Sinumerik_version { } {
#=============================================================
# This command is used to set the sinumerik_control_version and sinumerik_version.
#
# --------------------------------------------------
# "Sinumerik control version" is used to set the output format for drilling CYCLEs (such as CYCLE81).
# "Sinumerik version" is used to set the output format for CYCLE832.
# --------------------------------------------------
#    Sinumerik control version "Powerline"
# --------------------------------------------------
#       Sinumerik version 5.x - "V5"
#       Sinumerik version 6.x - "V6"
#       Sinumerik version 7.x - "V7"
# --------------------------------------------------
#
# --------------------------------------------------
#    Sinumerik control version "Solutionline"
# --------------------------------------------------
#       Sinumerik version 4.4 - "from V26 to V44"
#       Sinumerik version 4.5 - "V45"
#       Sinumerik version 4.7 - "V47"
# --------------------------------------------------
#
# 22-Dec-2016 shuai - CYCLE832 enhancement.
#                     Update the description for this command.
#

  global sinumerik_control_version
  global sinumerik_version

# set sinumerik_version "V6"
  set sinumerik_version "V7"
# set sinumerik_version "from V26 to V44"
# set sinumerik_version "V45"
# set sinumerik_version "V47"

  if {![string compare "V6" $sinumerik_version] || \
      ![string compare "V7" $sinumerik_version] } {

     set sinumerik_control_version "Powerline"

  } elseif {![string compare "from V26 to V44" $sinumerik_version] || \
            ![string compare "V45" $sinumerik_version] || \
            ![string compare "V47" $sinumerik_version] } {

     set sinumerik_control_version "Solutionline"
  }

}


#=============================================================
proc PB_CMD_set_csys { } {
#=============================================================

}


#=============================================================
proc PB_CMD_set_cycle_plane { } {
#=============================================================
#
# Use this command to determine and output proper plane code
# when G17/18/19 is used in the cycle definition.
#
# <04-15-08 gsl> - Add initialization for protection
# <03-06-08 gsl> - Declare needed global variables
# <02-28-08 gsl> - Make use of mom_spindle_axis
# <06-22-09 gsl> - Call PB_CMD_set_principal_axis
#


 #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 # This option can be set to 1, if the address of cycle's
 # principal axis needs to be suppressed. (Ex. Siemens controller)
 #+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  set suppress_principal_axis 1


 #++++++++++++++++++++++++++++++++++++++++++++++++++++++
 # This option can be set to 1, if the plane code needs
 # to be forced out @ the start of every set of cycles.
 #++++++++++++++++++++++++++++++++++++++++++++++++++++++
  set force_plane_code 0


  global mom_cycle_spindle_axis


   PB_CMD_set_principal_axis


   switch $mom_cycle_spindle_axis {
      0 {
         set principal_axis X
      }
      1 {
         set principal_axis Y
      }
      2 {
         set principal_axis Z
      }
      default {
         set principal_axis ""
      }
   }


   if { $suppress_principal_axis && [string length $principal_axis] > 0 } {
      MOM_suppress once $principal_axis
   }

   if { $force_plane_code } {
      global cycle_init_flag

      if { [info exists cycle_init_flag] && [string match "TRUE" $cycle_init_flag] } {
         MOM_force once G_plane
      }
   }
}


#=============================================================
proc PB_CMD_set_cycle_plane_change { } {
#=============================================================
# 04-28-11 lili   -   add mom_cycle_tool_axis_change and mom_cycle_clearance_plane_change, available in NX754 and later version.
  # mom_cycle_tool_axis_change = 1 means tool axis is changed.
  # mom_cycle_tool_axis_change = 0 menas no tool axis change.
# 05-07-15 Jintao -   add PB_CMD__check_block_cycle_retract


  global mom_cycle_spindle_axis
  global mom_current_motion
  global mom_siemens_coord_rotation
  global mom_siemens_cycle_count
  global mom_programmed_feed_rate
  global cycle_init_flag
  global mom_cycle_clearance_plane_change
  global mom_cycle_tool_axis_change
  global mom_cycle_retract_mode

  set cycle_init_flag TRUE

  if {![info exists mom_cycle_spindle_axis]} {
     set mom_cycle_spindle_axis 2
  }

  if {![info exists mom_cycle_tool_axis_change] || $mom_cycle_tool_axis_change == 0} {
     if {[llength [info command PB_CMD__check_block_cycle_retract]] && [PB_CMD__check_block_cycle_retract]} {
        MOM_do_template cycle_retract
     }
  } else {
     PB_CMD_choose_output_mode
     MOM_force Once G_motion X Y Z
     MOM_do_template cycle_rapid
     MOM_force Once X Y
  }

  if {[llength [info command MOM_abort_event]]} {
     MOM_abort_event
  }

}


#=============================================================
proc PB_CMD_set_fixture_offset { } {
#=============================================================
# This command is used to set fixture offset output value.
# It could be G500/G54-G57/G505-G599

  global mom_fixture_offset_value
  global mom_siemens_fixture_offset_value

  if { [info exists mom_fixture_offset_value] } {
      if {$mom_fixture_offset_value <= 0 } {
         set mom_siemens_fixture_offset_value 500
      } elseif {$mom_fixture_offset_value<=4} {
         set mom_siemens_fixture_offset_value [expr $mom_fixture_offset_value + 53]
      } elseif {$mom_fixture_offset_value>4} {
         set mom_siemens_fixture_offset_value [expr $mom_fixture_offset_value + 500]
      }
  }
}


#=============================================================
proc PB_CMD_set_helix_move { } {
#=============================================================
   global mom_pos_arc_plane
   global mom_sys_cir_vector
   global mom_sys_helix_pitch_type
   global mom_helix_pitch
   global mom_prev_pos mom_pos_arc_center
   global PI

   switch $mom_pos_arc_plane {
      XY { MOM_suppress once K ; set cir_index 2 }
      YZ { MOM_suppress once I ; set cir_index 0 }
      ZX { MOM_suppress once J ; set cir_index 1 }
   }

   switch $mom_sys_helix_pitch_type {
      none { }
      rise_revolution { set pitch $mom_helix_pitch }
      rise_radian { set pitch [expr $mom_helix_pitch / ($PI * 2.0)]}
      other {
#
#    Place your custom helix pitch code here
#
      }
      default { set mom_sys_helix_pitch_type "none" }
   }

   MOM_force once X Y Z

   if { [string compare "none" $mom_sys_helix_pitch_type] } {
      MOM_force once I J K

#<08-01-06 gsl>
      switch $mom_sys_cir_vector {
         "Vector - Arc Center to Start" {
            set mom_prev_pos($cir_index) $pitch
            set mom_pos_arc_center($cir_index) 0.0
         }
         "Vector - Arc Start to Center" -
         "Unsigned Vector - Arc Start to Center" {
            set mom_prev_pos($cir_index) 0.0
            set mom_pos_arc_center($cir_index) $pitch
         }
         "Vector - Absolute Arc Center" {
            set mom_pos_arc_center($cir_index) $pitch
         }
      }
   }


#
# You may need to edit this line if you output more than one block
# or if you have changed the name of your circular_move block template
#
   global mom_pos
   global mom_prev_pos
   global mom_helix_turn_number
   set pitch [expr abs($mom_helix_pitch)]
   set feed_distance [expr abs($mom_pos($cir_index) - $mom_prev_pos($cir_index))]
   if {[EQ_is_zero $pitch]} {
      set mom_helix_turn_number 0
   } else {
      set mom_helix_turn_number [expr floor($feed_distance/$pitch)]
   }

   switch $mom_pos_arc_plane {
      XY { MOM_suppress once K ; MOM_force Once I J }
      YZ { MOM_suppress once I ; MOM_force Once J K }
      ZX { MOM_suppress once J ; MOM_force Once I K }
   }

}


#=============================================================
proc PB_CMD_set_principal_axis { } {
#=============================================================
# This command can be used to determine the principal axis.
#
# => It can be used to determine a proper work plane when the
#    "Work Plane" parameter is not specified with an operation.
#
#
# <06-22-09 gsl> - Extracted from PB_CMD_set_cycle_plane
# <10-09-09 gsl> - Do not define mom_pos_arc_plane unless it doesn't exist.
# <03-10-10 gsl> - Respect tool axis for 3-axis & XZC cases
# <01-21-11 gsl> - Enhance header description
#

   global mom_cycle_spindle_axis
   global mom_spindle_axis
   global mom_cutcom_plane mom_pos_arc_plane


  # Initialization spindle axis
   global mom_kin_spindle_axis
   global mom_sys_spindle_axis
   if { ![info exists mom_kin_spindle_axis] } {
      set mom_kin_spindle_axis(0) 0.0
      set mom_kin_spindle_axis(1) 0.0
      set mom_kin_spindle_axis(2) 1.0
   }
   if { ![info exists mom_sys_spindle_axis] } {
      VMOV 3 mom_kin_spindle_axis mom_sys_spindle_axis
   }
   if { ![info exists mom_spindle_axis] } {
      VMOV 3 mom_sys_spindle_axis mom_spindle_axis
   }


  # Default cycle spindle axis to Z
   set mom_cycle_spindle_axis 2


  #<03-10-10 gsl> pb751 - Respect tool axis for 3-axis & XZC
   global mom_kin_machine_type mom_tool_axis
   if [string match "3_axis*" $mom_kin_machine_type] {
      VMOV 3 mom_tool_axis spindle_axis
   } else {
      VMOV 3 mom_spindle_axis spindle_axis
   }


   if { [EQ_is_equal [expr abs($spindle_axis(0))] 1.0] } {
      set mom_cycle_spindle_axis 0
   }

   if { [EQ_is_equal [expr abs($spindle_axis(1))] 1.0] } {
      set mom_cycle_spindle_axis 1
   }


   # Always output G17 in TRAORI/CYCLE800 mode
   global mom_siemens_5axis_mode
   global mom_siemens_5axis_output_mode
   global mom_siemens_coord_rotation
   if {([info exists mom_siemens_5axis_mode] && [string match $mom_siemens_5axis_mode "SWIVELING"]) \
       || ([info exists mom_siemens_5axis_output_mode] && $mom_siemens_5axis_output_mode == 1) \
       || ([info exists mom_siemens_coord_rotation] && $mom_siemens_coord_rotation == 1)} {
      set mom_cycle_spindle_axis 2
   }

   switch $mom_cycle_spindle_axis {
      0 {
         set mom_cutcom_plane  YZ
      }
      1 {
         set mom_cutcom_plane  ZX
      }
      2 {
         set mom_cutcom_plane  XY
      }
      default {
         set mom_cutcom_plane  UNDEFINED
      }
   }

   # Set arc plane when it's not defined
   if { ![info exists mom_pos_arc_plane] || $mom_pos_arc_plane == "" } {
      set mom_pos_arc_plane $mom_cutcom_plane
   }

}


#=============================================================
proc PB_CMD_set_resolution { } {
#=============================================================
# This command is used to redefine the resolution of linear and rotary axes.
# This command should be used with PB_CMD_reset_output_digits, which located
# in Initial Move and First Move.
#
   global mom_output_unit
   global mom_motion_output_type
   global mom_kin_machine_resolution
   global mom_kin_4th_axis_min_incr
   global mom_kin_5th_axis_min_incr
   global mom_operation_type

   if {[string match $mom_output_unit "MM"]} {
      if {![info exists mom_motion_output_type] || $mom_motion_output_type < 2} {
         if {[string match "Point to Point" $mom_operation_type] || [string match "Hole Making" $mom_operation_type] } {
            set mom_kin_machine_resolution 0.001
            set mom_kin_4th_axis_min_incr  0.00001
            set mom_kin_5th_axis_min_incr  0.00001
            MOM_reload_kinematics
         } else {
            set mom_kin_machine_resolution 0.00001
            set mom_kin_4th_axis_min_incr  0.00001
            set mom_kin_5th_axis_min_incr  0.00001
            MOM_reload_kinematics
         }
      } else {
         set mom_kin_machine_resolution 0.000001
         set mom_kin_4th_axis_min_incr  0.00001
         set mom_kin_5th_axis_min_incr  0.00001
         MOM_reload_kinematics
      }
   } else {
      if {![info exists mom_motion_output_type] || $mom_motion_output_type < 2} {
         if {[string match "Point to Point" $mom_operation_type] || [string match "Hole Making" $mom_operation_type] } {
            set mom_kin_machine_resolution 0.0001
            set mom_kin_4th_axis_min_incr  0.00001
            set mom_kin_5th_axis_min_incr  0.00001
            MOM_reload_kinematics
         } else {
            set mom_kin_machine_resolution 0.000001
            set mom_kin_4th_axis_min_incr  0.00001
            set mom_kin_5th_axis_min_incr  0.00001
            MOM_reload_kinematics
         }
      } else {
         set mom_kin_machine_resolution 0.0000001
         set mom_kin_4th_axis_min_incr  0.00001
         set mom_kin_5th_axis_min_incr  0.00001
         MOM_reload_kinematics
      }
   }
}


#=============================================================
proc PB_CMD_spindle_off { } {
#=============================================================
# This command is used to avoid to trigger spindle for some operation. i.e. Deep Hole Drilling, Back Countersinking.
#
# 2015-12-22 szl - Initial implementation

  if { [info exists ::mom_spindle_startup_status] && [info exists ::mom_spindle_direction] } {
     if { ![string compare "OFF" $::mom_spindle_startup_status] &&\
          ![string compare "OFF" $::mom_spindle_status] } {

        set ::mom_spindle_direction "OFF"
      }
   }
}


#=============================================================
proc PB_CMD_spindle_orient { } {
#=============================================================
# This command is used to add a MOM handler about positioning spindle, should be added to start of program.
# Revisions:
#-----------
# 2015-04-09 Jintao - Initial implementation


 if { ![llength [info commands VECTOR_ROTATE]] } {
uplevel #0 {
     #=============================================================
     proc VECTOR_ROTATE { axis angle input_vector output_vector } {
     #=============================================================
     #This proc is used to rotating a vector about arbitrary axis.
      upvar $axis r; upvar $input_vector input ; upvar $output_vector output
      #set up matrix to rotate about an arbitrary axis
      set m(0) [expr $r(0)*$r(0)*(1-cos($angle))+cos($angle)]
      set m(1) [expr $r(0)*$r(1)*(1-cos($angle))-$r(2)*sin($angle)]
      set m(2) [expr $r(0)*$r(2)*(1-cos($angle))+$r(1)*sin($angle)]
      set m(3) [expr $r(0)*$r(1)*(1-cos($angle))+$r(2)*sin($angle)]
      set m(4) [expr $r(1)*$r(1)*(1-cos($angle))+cos($angle)]
      set m(5) [expr $r(1)*$r(2)*(1-cos($angle))-$r(0)*sin($angle)]
      set m(6) [expr $r(0)*$r(2)*(1-cos($angle))-$r(1)*sin($angle)]
      set m(7) [expr $r(1)*$r(2)*(1-cos($angle))+$r(0)*sin($angle)]
      set m(8) [expr $r(2)*$r(2)*(1-cos($angle))+cos($angle)]
      MTX3_vec_multiply input m output
    }
  };# uplevel
 }

 if { ![llength [info commands SPINDLE_ORIENTATION_ANGLE]] } {
uplevel #0 {
#=======================================================================================================================
proc SPINDLE_ORIENTATION_ANGLE { spindle_orient_ref_axis input_angle rotate_matrix {initial_offset_angle 0} } {
#=======================================================================================================================
# The proc is used to calculate spindle orient output angle value.
# It should be called in MOM_spindle_orient handler.
#
# Input:
#   spindle_orient_ref_axis - X axis of feature csys respect to MCS
#   initial_offset_angle      - initial offset angle between tool insert vector and machine X axis
#                               the default offset angle is 0, post writer can use UDE to customize setting
#   input_angle               - angle between desired insert direction and X axis of feature csys
#   rotate_matrix             - matrix between MTCS and local MCS
#
# Return:
#   angle value of spindle stop position
#
# Revisions:
#-----------
# 2015-04-09 Jintao - Initial implementation
# 2015-09-25 szl    - save_mom_kin_machine_type is set whenever mom_kin_machine_type is faked into "dual-table"(for auto3d)
# 2015-12-22 Jintao - Remove global declaration and account the rotation of feature reference vector for 3axis machine

  upvar $spindle_orient_ref_axis feature_ref_axis
  upvar $rotate_matrix matrix

  set v0 0.0; set v1 1.0
  VEC3_init v1 v0 v0 insert_ref_direction
  VEC3_init v0 v0 v0 insert_rotated_direction
  VEC3_init v0 v0 v0 intermediate_vector


  if { ![info exists ::save_mom_kin_machine_type] } {

     set machine_type $::mom_kin_machine_type
  } else {

     set machine_type $::save_mom_kin_machine_type
  }

  # get rotation angle in case the kinematic has been reloaded
  GET_ROT_ANGLE rot_angle

  # account rotary axis direction and zero offset
  if { [info exists ::mom_kin_4th_axis_type] } {

     if { ![string compare "SIGN_DETERMINES_DIRECTION" $::mom_kin_4th_axis_direction] } {

        set rot_angle(0) [expr abs($rot_angle(0))]
     }
     set rot_angle(0) [expr ($rot_angle(0) - $::mom_kin_4th_axis_zero) * $::DEG2RAD]

     if { [info exists ::save_mom_kin_4th_axis_vector] } {

        VMOV 3 ::save_mom_kin_4th_axis_vector fourth_axis_vector
     } else {

        VMOV 3 ::mom_kin_4th_axis_vector fourth_axis_vector
     }
  }

  if { [info exists ::mom_kin_5th_axis_type] } {

     if { ![string compare "SIGN_DETERMINES_DIRECTION" $::mom_kin_5th_axis_direction] } {

        set rot_angle(1) [expr abs($rot_angle(1))]
      }
     set rot_angle(1) [expr ($rot_angle(1) - $::mom_kin_5th_axis_zero) * $::DEG2RAD]

     if { [info exists ::save_mom_kin_5th_axis_vector] } {

        VMOV 3 ::save_mom_kin_5th_axis_vector fifth_axis_vector
     } else {

        VMOV 3 ::mom_kin_5th_axis_vector fifth_axis_vector
     }
  }

  switch $machine_type {
     5_axis_dual_head {

        if { [info exists ::dpp_ge(coord_rot)] && ![string compare "AUTO_3D" $::dpp_ge(coord_rot)] } {
           set val $rot_angle(0)
           set rot_angle(0) $rot_angle(1)
           set rot_angle(1) $val
        }
        VECTOR_ROTATE fifth_axis_vector $rot_angle(1) insert_ref_direction intermediate_vector
        VECTOR_ROTATE fourth_axis_vector $rot_angle(0) intermediate_vector insert_rotated_direction
     }
     5_axis_head_table -
     5_axis_dual_table {

        VECTOR_ROTATE fourth_axis_vector $rot_angle(0) insert_ref_direction intermediate_vector
        VECTOR_ROTATE fifth_axis_vector $rot_angle(1) intermediate_vector insert_rotated_direction
     }
     4_axis_head -
     4_axis_table {

        VECTOR_ROTATE fourth_axis_vector $rot_angle(0) insert_ref_direction insert_rotated_direction
     }
     3_axis_mill -
     3_axis_mill_turn {
        VMOV 3 insert_ref_direction insert_rotated_direction
     }
     default { return 0.0 }
  }

  MTX3_vec_multiply insert_rotated_direction matrix insert_rotated_direction_rot_mcs
  VEC3_unitize insert_rotated_direction_rot_mcs insert_rotated_direction_rot_mcs

  set dot [VEC3_dot insert_rotated_direction_rot_mcs feature_ref_axis]

  if { [EQ_is_ge $dot 1.0] } {
     set angle 0.0
  } elseif { [EQ_is_le $dot -1.0] } {
   set angle 180.0
  } else {
     set angle [expr $::RAD2DEG * acos($dot)]
  }
  VEC3_cross feature_ref_axis insert_rotated_direction_rot_mcs cross_vector
  set dot [VEC3_dot cross_vector ::mom_tool_axis]
  if {  $dot > 0.0 } { set angle [expr -1 * $angle] }

  set angle [expr $input_angle + $angle - $initial_offset_angle]
  set angle [LIMIT_ANGLE $angle]

  return $angle

}; #SPINDLE_ORIENTATION_ANGLE
 };#uplevel
}

 if { ![llength [info commands GET_ROT_LOCAL]] } {
uplevel #0 {
#=======================================
proc GET_ROT_LOCAL { rot_matrix } {
#======================================
# If the operation is under local CSYS rotation, this proc gets the rotation matrix between current coordinate and its parent coordinate
# Otherwise the rotation matrix is unit matrix.
# Revisions:
#-----------
# 2015-04-09 Jintao - Initial implementation

    global mom_parent_csys_matrix
    global mom_kin_coordinate_system_type

    upvar $rot_matrix matrix

    if {[info exists mom_kin_coordinate_system_type] && ![string compare "CSYS" $mom_kin_coordinate_system_type]} {
          VMOV 9 mom_parent_csys_matrix matrix
      } else {
          set matrix(0) 1; set matrix(1) 0; set matrix(2) 0;
          set matrix(3) 0; set matrix(4) 1; set matrix(5) 0;
          set matrix(6) 0; set matrix(7) 0; set matrix(8) 1;
    }
}
 };#uplevel
}
 if { ![llength [info commands GET_ROT_ANGLE]] } {
uplevel #0 {
#============================================
proc GET_ROT_ANGLE { rot_ang } {
#============================================
# This command is used to get rotary axis angle, if the operation is under local CSYS rotation, we need calculate angles, otherwise
# it is mom_out_angle_pos
# Revisions:
#-----------
# 2015-06-08 Jintao - Initial implementation
  global mom_prev_rot_ang_4th mom_kin_4th_axis_direction
  global mom_kin_4th_axis_leader mom_sys_leader
  global mom_kin_4th_axis_min_limit mom_kin_4th_axis_max_limit
  global mom_prev_rot_ang_5th mom_kin_5th_axis_direction
  global mom_kin_5th_axis_leader
  global mom_kin_5th_axis_min_limit mom_kin_5th_axis_max_limit
  global mom_kin_coordinate_system_type
  global mom_rotary_direction_4th
  global mom_kin_machine_type
  global mom_parent_csys_matrix
  global mom_mcs_goto
  global mom_out_angle_pos
  global mom_alt_pos
  global mom_tool_axis
  global cycle800_dir

  upvar $rot_ang rot_angle
  set rot_angle(0) 0.0; set rot_angle(1) 0.0
  set rot_alt_angle(0) 0.0; set rot_alt_angle(1) 0.0

  if { ![regexp {[0-9]*} $mom_kin_machine_type axis_num] || [EQ_is_lt $axis_num 4] } { return 0 }

  if { [info exists mom_kin_coordinate_system_type] && ![string compare "CSYS" $mom_kin_coordinate_system_type] } {
     MTX3_transpose mom_parent_csys_matrix matrix
     MTX3_vec_multiply mom_tool_axis matrix spindle_axis
     MTX3_vec_multiply mom_mcs_goto matrix mcs_goto
     if { "1" == [MOM_convert_point mcs_goto spindle_axis] } {
        global mom_result
        set i 0
        foreach value $mom_result {
           set pos($i) $value
           incr i
        }
        if { ![info exists mom_prev_rot_ang_4th] } { set mom_prev_rot_ang_4th 0.0 }
        set rot_angle(0)  [ROTSET $pos(3) $mom_prev_rot_ang_4th $mom_kin_4th_axis_direction\
                                  $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                  $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]
        if { [EQ_is_ge $axis_num 5] } {
           if { ![info exists mom_prev_rot_ang_5th] } { set mom_prev_rot_ang_5th 0.0 }
           set rot_angle(1)  [ROTSET $pos(4) $mom_prev_rot_ang_5th $mom_kin_5th_axis_direction\
                                     $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                     $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]
        }
      } else {
        return 0
      }
  } else {
     set rot_angle(0) $mom_out_angle_pos(0)
     set rot_angle(1) $mom_out_angle_pos(1)
  }
  if { [info exists cycle800_dir] } {
     global mom_result1
     if { [info exists mom_result1] && [info exists pos] } {
        set i 0
        foreach value $mom_result1 {
           set pos($i) $value
           incr i
        }
     } else {
        set pos(3) $mom_alt_pos(3)
        set pos(4) $mom_alt_pos(4)
     }
     if { ![info exists mom_prev_rot_ang_4th] } { set mom_prev_rot_ang_4th 0.0 }
     set rot_alt_angle(0)  [ROTSET $pos(3) $mom_prev_rot_ang_4th $mom_kin_4th_axis_direction\
                                   $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                   $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]
     if { [EQ_is_ge $axis_num 5] } {
        if { ![info exists mom_prev_rot_ang_5th] } { set mom_prev_rot_ang_5th 0.0 }
        set rot_alt_angle(1)  [ROTSET $pos(4) $mom_prev_rot_ang_5th $mom_kin_5th_axis_direction\
                                      $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                      $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]
      }
  # choose the solution by cycle800_dir, -1:Lower rotary axis value, 1:Higher rotary axis value
     if { [EQ_is_gt $rot_alt_angle(0) $rot_angle(0)] && [EQ_is_equal $cycle800_dir 1.0] } {
        VMOV 2 rot_alt_angle rot_angle
     } elseif { [EQ_is_lt $rot_alt_angle(0) $rot_angle(0)] && [EQ_is_equal $cycle800_dir -1.0] } {
        VMOV 2 rot_alt_angle rot_angle
     }
  }
  return 1
}
 };#uplevel
}


 if { ![llength [info commands MOM_spindle_orient]] } {
uplevel #0 {
#===============================
proc MOM_spindle_orient { } {
#===============================
# In the back sinking operation, initial tool insert tip is positioned to Machine coordinate X axis positive direction,
# which means the default value of initial offset angle is 0. the post writer can use UDE to customize offset angle
# Revisions:
#-----------
# 2015-04-09 Jintao - Initial implementation
   global mom_spindle_orient_angle
   global mom_spindle_orient_angle_defined
   global mom_spindle_orient_ref_axis
   global mom_msys_matrix

# if mom_kin_coordinate_system_type is "CSYS", then rotate_matrix is mom_parent_csys_matrix. Otherwise it is unit matrix.
#
   GET_ROT_LOCAL rotate_matrix
   MTX3_vec_multiply mom_spindle_orient_ref_axis mom_msys_matrix spindle_orient_ref_axis
   set mom_spindle_orient_angle [SPINDLE_ORIENTATION_ANGLE spindle_orient_ref_axis $mom_spindle_orient_angle rotate_matrix]

   MOM_do_template spindle_orient

} ;# MOM_spindle_orient
 } ;# uplevel
}
}


#=============================================================
proc PB_CMD_start_of_alignment_character { } {
#=============================================================
 # This command can be used to output a special sequence number character.
 # Replace the ":" with any character that you require.
 # You must use the command "PB_CMD_end_of_alignment_character" to reset
 # the sequence number back to the original setting.

  global mom_sys_leader saved_seq_num
  set saved_seq_num $mom_sys_leader(N)
  set mom_sys_leader(N) ":"
}


#=============================================================
proc PB_CMD_start_of_extcall_operation { } {
#=============================================================
#  This command is used to create sub program files.
#  Please put it at top of Start of Path.

   global mom_siemens_program_control
   global ptp_file_name mom_sys_ptp_output
   global mom_output_file_directory
   global mom_operation_name
   global mom_sequence_number mom_sequence_increment mom_sequence_frequency
   global mom_group_name

   if { ![string match "ON" $mom_sys_ptp_output] || ![info exists ptp_file_name] } {
return
   }

   if { [info exists mom_siemens_program_control] && [string match "TRUE" $mom_siemens_program_control] } {
      set output_extn ".spf"
      set subroutine_name "${mom_output_file_directory}${mom_operation_name}${output_extn}"
      global mom_post_in_simulation
      if {[info exists mom_post_in_simulation] && [string match "CSE" $mom_post_in_simulation]} {
         global mom_part_name
         set part_dir "[file dirname $mom_part_name]/"
         if {[catch {file mkdir ${part_dir}cse_files/subprog/}]} {
            MOM_output_to_listing_device "${part_dir}cse_files: No write access! Subprogram file is in $mom_output_file_directory"
         } else {
            set subprog_dir ${part_dir}cse_files/subprog/
            if {[file isdirectory $subprog_dir]} {
               set subroutine_name [file nativename "${subprog_dir}${mom_operation_name}${output_extn}"]
            }
         }
      }
      if { [file exists $subroutine_name] } {
         MOM_remove_file $subroutine_name
      }
      MOM_open_output_file $subroutine_name
      SEQNO_RESET
      MOM_reset_sequence $mom_sequence_number $mom_sequence_increment $mom_sequence_frequency
      MOM_set_seq_on
      #<2011-09-20 lili> MOM_start_subroutine only works for CSE simulation, no effect to post.
      MOM_start_subroutine $mom_operation_name
      #start_output_flag is used to output start of program NC codes.
      #If it is 0, NC codes for start of program will be output.
      global start_output_flag
      set start_output_flag 0
   }
}


#=============================================================
proc PB_CMD_start_of_operation_force_addresses { } {
#=============================================================
  MOM_force once X Y Z F S
}


#=============================================================
proc PB_CMD_unclamp_fifth_axis { } {
#=============================================================
#  This command is used by auto clamping to output the code
#  needed to unclamp the fifth axis.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#
  MOM_output_literal "M13"
}


#=============================================================
proc PB_CMD_unclamp_fourth_axis { } {
#=============================================================
#  This command is used by auto clamping to output the code
#  needed to unclamp the fourth axis.
#
#  --> Do NOT attach this command to any event marker!
#  --> Do NOT change the name of this command!
#
  MOM_output_literal "M11"
}


#=============================================================
proc PB_CMD_uplevel_ROTARY_AXIS_RETRACT { } {
#=============================================================
  if { ![CMD_EXIST PB_ROTARY_AXIS_RETRACT] && [CMD_EXIST ROTARY_AXIS_RETRACT]} {
     rename ROTARY_AXIS_RETRACT PB_ROTARY_AXIS_RETRACT
  } else {
return
  }

uplevel #0 {
#==============
proc ROTARY_AXIS_RETRACT {} {
#==============
  global mom_prev_pos
  global mom_prev_mcs_goto
  global mom_prev_alt_pos
  global mom_siemens_5axis_output_mode

  if {[info exists mom_siemens_5axis_output_mode] && $mom_siemens_5axis_output_mode == 1} {
     VMOV 3 mom_prev_mcs_goto mom_prev_pos
     VMOV 3 mom_prev_mcs_goto mom_prev_alt_pos
  }
  PB_ROTARY_AXIS_RETRACT

}
};#uplevel 0


}


#=============================================================
proc ABORT_EVENT_CHECK { } {
#=============================================================
# pb_post_base -
#
# Called by every motion event to abort its handler based on
# the setting of mom_sys_abort_next_event.
#
   if { [info exists ::mom_sys_abort_next_event] && $::mom_sys_abort_next_event } {
      if { [CMD_EXIST PB_CMD_kin_abort_event] } {
         PB_CMD_kin_abort_event
      }
   }
}


#=============================================================
proc ACCOUNT_HEAD_OFFSETS { POS flag } {
#=============================================================
# Command to account for the offsets of angled-head attachment.
# There'll be no effect, if head attachment is not in use or
# offsets are zeros.
#
# - Called by LOCK_AXIS & UNLOCK_AXIS
#
# Inputs:
#
#   POS  : Array name (reference) of a position
#   flag : Type of operation
#           1 = Add offsets
#           0 = Remove offsets
#
# Outputs:
#   Updated POS
#
#<04-16-2014 gsl> Inception
#

   upvar $POS pos

   global mom_kin_machine_type
   global mom_head_gauge_point

   if { [info exists mom_head_gauge_point] } {
      set len [VEC3_mag mom_head_gauge_point]

      if [EQ_is_gt $len 0.0] {
         switch $flag {
            1 {
              # Adding offsets
               VEC3_add pos mom_head_gauge_point pos
            }

            0 -
            default {
              # Subtract offsets
               VEC3_sub pos mom_head_gauge_point pos
            }
         }
      }
   }
}


#=============================================================
proc ANGLE_CHECK { a axis } {
#=============================================================
# called by ROTARY_AXIS_RETRACT
#
#   Return:
#     1: Within limits
#    -1: Out of limits
#     0: Special condition (0 ~ 360 & MAGNITUDE_DETERMINES_DIRECTION)
#

   upvar $a ang

   global mom_kin_4th_axis_max_limit
   global mom_kin_5th_axis_max_limit
   global mom_kin_4th_axis_min_limit
   global mom_kin_5th_axis_min_limit
   global mom_kin_4th_axis_direction
   global mom_kin_5th_axis_direction

   if { $axis == 4 } {
      set min $mom_kin_4th_axis_min_limit
      set max $mom_kin_4th_axis_max_limit
      set dir $mom_kin_4th_axis_direction
   } else {
      set min $mom_kin_5th_axis_min_limit
      set max $mom_kin_5th_axis_max_limit
      set dir $mom_kin_5th_axis_direction
   }

   if { [EQ_is_equal $min 0.0] && [EQ_is_equal $max 360.0] &&\
       ![string compare "MAGNITUDE_DETERMINES_DIRECTION" $dir] } {

      return 0

   } else {

      while { $ang > $max && $ang > [expr $min + 360.0] } { set ang [expr $ang - 360.0] }
      while { $ang < $min && $ang < [expr $max - 360.0] } { set ang [expr $ang + 360.0] }

      if { $ang > $max || $ang < $min } {

         return -1

      } else {

         return 1
      }
   }
}


#=============================================================
proc ARCTAN { y x } {
#=============================================================
# pb_base -
#
   global PI

   if { [EQ_is_zero $y] } { set y 0 }
   if { [EQ_is_zero $x] } { set x 0 }

   if { [expr $y == 0] && [expr $x == 0] } {
      return 0
   }

   set ang [expr atan2($y,$x)]

   if { $ang < 0 } {
      return [expr $ang + $PI*2]
   } else {
      return $ang
   }
}


#=============================================================
proc ARR_sort_array_to_list { ARR {by_value 0} {by_decr 0} } {
#=============================================================
# pb_base -
#
# This command will sort and build a list of elements of an array.
#
#   ARR      : Array Name
#   by_value : 0 Sort elements by names (default)
#              1 Sort elements by values
#   by_decr  : 0 Sort into increasing order (default)
#              1 Sort into decreasing order
#
#   Return a list of {name value} couplets
#
#-------------------------------------------------------------
# Feb-24-2016 gsl - Added by_decr flag
#
   upvar $ARR arr

   set list [list]
   foreach { e v } [array get arr] {
      lappend list "$e $v"
   }

   set val [lindex [lindex $list 0] $by_value]

   if { $by_decr } {
      set trend "decreasing"
   } else {
      set trend "increasing"
   }

   if [expr $::tcl_version > 8.1] {
      if [string is integer "$val"] {
         set list [lsort -integer    -$trend -index $by_value $list]
      } elseif [string is double "$val"] {
         set list [lsort -real       -$trend -index $by_value $list]
      } else {
         set list [lsort -dictionary -$trend -index $by_value $list]
      }
   } else {
      set list    [lsort -dictionary -$trend -index $by_value $list]
   }

return $list
}


#=============================================================
proc ARR_sort_array_vals { ARR } {
#=============================================================
# This command will sort and build a list of elements of an array.
#
   upvar $ARR arr

   set list [list]
   foreach a [lsort -dictionary [array names arr]] {
      if ![catch {expr $arr($a)}] {
         set val [format "%+.5f" $arr($a)]
      } else {
         set val $arr($a)
      }
      lappend list ($a) $val
   }
return $list
}


#=============================================================
proc AUTO_CLAMP { } {
#=============================================================
#  This command is used to automatically output clamp and unclamp
#  codes.  This command must be called in the the command
#  << PB_CMD_kin_before_motion >>.  By default this command will
#  output M10 or M11 to do clamping or unclamping for the 4th axis or
#  M12 or M13 for the 5th axis.
#

  # Must be called by PB_CMD_kin_before_motion
   if { ![CALLED_BY "PB_CMD_kin_before_motion"] } {
return
   }


   global mom_pos
   global mom_prev_pos

   global mom_sys_auto_clamp

   if { ![info exists mom_sys_auto_clamp] || ![string match "ON" $mom_sys_auto_clamp] } {
return
   }

   set rotary_out [EQ_is_equal $mom_pos(3) $mom_prev_pos(3)]

   AUTO_CLAMP_1 $rotary_out

   set rotary_out [EQ_is_equal $mom_pos(4) $mom_prev_pos(4)]

   AUTO_CLAMP_2 $rotary_out
}


#=============================================================
proc AUTO_CLAMP_1 { out } {
#=============================================================
# called by AUTO_CLAMP & MOM_rotate

   global clamp_rotary_fourth_status

   if { ![info exists clamp_rotary_fourth_status] ||\
       ( $out == 0 && ![string match "UNCLAMPED" $clamp_rotary_fourth_status] ) } {

      PB_CMD_unclamp_fourth_axis
      set clamp_rotary_fourth_status "UNCLAMPED"

   } elseif { $out == 1 && ![string match "CLAMPED" $clamp_rotary_fourth_status] } {

      PB_CMD_clamp_fourth_axis
      set clamp_rotary_fourth_status "CLAMPED"
   }
}


#=============================================================
proc AUTO_CLAMP_2 { out } {
#=============================================================
# called by AUTO_CLAMP & MOM_rotate

   global mom_kin_machine_type

   set machine_type [string tolower $mom_kin_machine_type]
   switch $machine_type {
      5_axis_dual_table -
      5_axis_dual_head  -
      5_axis_head_table { }

      default           {
return
      }
   }

   global clamp_rotary_fifth_status

   if { ![info exists clamp_rotary_fifth_status] ||\
        ( $out == 0 && ![string match "UNCLAMPED" $clamp_rotary_fifth_status] ) } {

      PB_CMD_unclamp_fifth_axis
      set clamp_rotary_fifth_status "UNCLAMPED"

   } elseif { $out == 1 && ![string match "CLAMPED" $clamp_rotary_fifth_status] } {

      PB_CMD_clamp_fifth_axis
      set clamp_rotary_fifth_status "CLAMPED"
   }
}


#=============================================================
proc AXIS_SET { axis } {
#=============================================================
# Called by MOM_rotate & SET_LOCK to detect if the given axis is the 4th or 5th rotary axis.
# It returns 0, if no match has been found.
#

  global mom_sys_leader

   if { ![string compare "[string index $mom_sys_leader(fourth_axis) 0]AXIS" $axis] } {
      return 3
   } elseif { ![string compare "[string index $mom_sys_leader(fifth_axis) 0]AXIS" $axis] } {
      return 4
   } else {
      return 0
   }
}


#=============================================================
proc CALC_CYLINDRICAL_RETRACT_POINT { refpt axis dist ret_pt } {
#=============================================================
# called by ROTARY_AXIS_RETRACT

  upvar $refpt rfp ; upvar $axis ax ; upvar $ret_pt rtp

#
# Return 0: parallel or lies on plane
#        1: unique intersection
#


#
# Create plane canonical form
#
   VMOV 3 ax plane
   set plane(3) $dist

   set num [expr $plane(3) - [VEC3_dot rfp plane]]
   set dir [VEC3_dot ax plane]

   if { [EQ_is_zero $dir] } {
return 0
   }

   for { set i 0 } { $i < 3 } { incr i } {
      set rtp($i) [expr $rfp($i) + $ax($i)*$num/$dir]
   }

return [RETRACT_POINT_CHECK rfp ax rtp]
}


#=============================================================
proc CALC_SPHERICAL_RETRACT_POINT { refpt axis cen_sphere rad_sphere int_pts } {
#=============================================================
# called by ROTARY_AXIS_RETRACT

  upvar $refpt rp ; upvar $axis ta ; upvar $cen_sphere cs
  upvar $int_pts ip

   set rad [expr $rad_sphere*$rad_sphere]
   VEC3_sub rp cs v1

   set coeff(2) 1.0
   set coeff(1) [expr ($v1(0)*$ta(0) + $v1(1)*$ta(1) + $v1(2)*$ta(2))*2.0]
   set coeff(0) [expr $v1(0)*$v1(0) + $v1(1)*$v1(1) + $v1(2)*$v1(2) - $rad]

   set num_sol [SOLVE_QUADRATIC coeff roots iroots status degree]
   if { $num_sol == 0 } { return 0 }

   if { [expr $roots(0)] > [expr $roots(1)] || $num_sol == 1 } {
      set d $roots(0)
   } else {
      set d $roots(1)
   }

   set ip(0) [expr $rp(0) + $d*$ta(0)]
   set ip(1) [expr $rp(1) + $d*$ta(1)]
   set ip(2) [expr $rp(2) + $d*$ta(2)]

return [RETRACT_POINT_CHECK rp ta ip]
}


#=============================================================
proc CALLED_BY { caller {out_warn 0} args } {
#=============================================================
# pb_base -
#
# This command can be used in the beginning of a command
# to designate a specific caller for the command in question.
#
# - Users can set the optional flag "out_warn" to "1" to output
#   warning message when a command is being called by a
#   non-designated caller. By default, warning message is suppressed.
#
#  Syntax:
#    if { ![CALLED_BY "cmd_string"] } { return ;# or do something }
#  or
#    if { ![CALLED_BY "cmd_string" 1] } { return ;# To output warning }
#
# Revisions:
#-----------
# 05-25-10 gsl - Initial implementation
# 03-09-11 gsl - Enhanced description
#

   if { ![string compare "$caller" [info level -2] ] } {
return 1
   } else {
      if { $out_warn } {
         CATCH_WARNING "\"[info level -1]\" can not be executed in \"[info level -2]\". \
                        It must be called by \"$caller\"!"
      }
return 0
   }
}


#=============================================================
proc CATCH_WARNING { msg {output 1} } {
#=============================================================
# pb_base -
#
# This command is called in a post to spice up the message to be output to the warning file.
#
   global mom_warning_info
   global mom_motion_event
   global mom_event_number
   global mom_motion_type
   global mom_operation_name


   if { $output == 1 } {

      set level [info level]
      set call_stack ""
      for { set i 1 } { $i < $level } { incr i } {
         set call_stack "$call_stack\[ [lindex [info level $i] 0] \]"
      }

      global mom_o_buffer
      if { ![info exists mom_o_buffer] } {
         set mom_o_buffer ""
      }

      if { ![info exists mom_motion_event] } {
         set mom_motion_event ""
      }

      if { [info exists mom_operation_name] && [string length $mom_operation_name] } {
         set mom_warning_info "$msg\n\  Operation $mom_operation_name - Event $mom_event_number [MOM_ask_event_type] :\
                               $mom_motion_event ($mom_motion_type)\n\    $mom_o_buffer\n\      $call_stack"
      } else {
         set mom_warning_info "$msg\n\  Event $mom_event_number [MOM_ask_event_type] :\
                               $mom_motion_event ($mom_motion_type)\n\    $mom_o_buffer\n\      $call_stack"
      }

      MOM_catch_warning
   }

   # Restore mom_warning_info for subsequent use
   set mom_warning_info $msg
}


#=============================================================
proc CHECK_LOCK_ROTARY_AXIS { axis mtype } {
#=============================================================
# called by SET_LOCK

   global mom_sys_leader

   set is_valid 0
   set lock_axis_leader ""

   if { $mtype == 4 } {
      # For 4-axis machine, the locked rotary axis must be the fourth axis.
      if { [string match "FIFTH" $axis] } {
         return $is_valid
      }

      set lock_axis_leader [string index $mom_sys_leader(fourth_axis) 0]

   } elseif { $mtype == 5 } {
      # For 5-axis machine, the locked rotary axis must be the fifth axis.
      if { [string match "FOURTH" $axis] } {
         return $is_valid
      }

      set lock_axis_leader [string index $mom_sys_leader(fifth_axis) 0]

   } else {

      return $is_valid
   }

   # Handle the case when axis is "AAXIS", "BAXIS" or "CAXIS"
   set cur_axis_leader [string index $axis 0]
   switch $cur_axis_leader {
      A -
      B -
      C {
         if { [string match $lock_axis_leader $cur_axis_leader] } {
            # The specified rotary axis is valid
            set is_valid 1
         }
      }
      default {
         set is_valid 1
      }
   }

   return $is_valid
}


#=============================================================
proc CMD_EXIST { cmd {out_warn 0} args } {
#=============================================================
# pb_base -
#
# This command can be used to detect the existence of a command
# before executing it.
# - Users can set the optional flag "out_warn" to "1" to output
#   warning message when a command to be called doesn't exist.
#   By default, warning message is suppressed.
#
#  Syntax:
#    if { [CMD_EXIST "cmd_string"] } { cmd_string }
#  or
#    if { [CMD_EXIST "cmd_string" 1] } { cmd_string ;# To output warning }
#
# Revisions:
#-----------
# 05-25-10 gsl - Initial implementation
# 03-09-11 gsl - Enhanced description
#

   if { [llength [info commands "$cmd"] ] } {
return 1
   } else {
      if { $out_warn } {
         CATCH_WARNING "Command \"$cmd\" called by \"[info level -1]\" does not exist!"
      }
return 0
   }
}


#=============================================================================
proc COMPARE_NX_VERSION { this_ver target_ver } {
#=============================================================================
# Compare a given NX version with target version.
# ==> Number of fields will be compared based on the number of "." contained in target.
#
# Return 1: Newer
#        0: Same
#       -1: Older
#

   set vlist_1 [split $this_ver   "."]
   set vlist_2 [split $target_ver "."]

   set ver_check 0

   set idx 0
   foreach v2 $vlist_2 {

      if { $ver_check == 0 } {
         set v1 [lindex $vlist_1 $idx]
         if { $v1 > $v2 } {
            set ver_check 1
         } elseif { $v1 == $v2 } {
            set ver_check 0
         } else {
            set ver_check -1
         }
      }

      if { $ver_check != 0 } {
         break
      }

      incr idx
   }

return $ver_check
}


#=============================================================
proc CYCLE_SET { } {
#=============================================================
   WORKPLANE_SET
}


#=============================================================
proc DELAY_TIME_SET { } {
#=============================================================
  global mom_sys_delay_param mom_delay_value
  global mom_delay_revs mom_delay_mode delay_time

   # post builder provided format for the current mode:
    if {[info exists mom_sys_delay_param(${mom_delay_mode},format)] != 0} {
      MOM_set_address_format dwell $mom_sys_delay_param(${mom_delay_mode},format)
    }

    switch $mom_delay_mode {
      SECONDS {set delay_time $mom_delay_value}
      default {set delay_time $mom_delay_revs}
    }
}


#=============================================================
proc DPP_GE_CALCULATE_COOR_ROT_ANGLE { mode MATRIX ANG } {
#=============================================================
# The command can be used to to calculate the coordinate system rotation angles
# and support coordinate rotation functions such as G68/ROT/AROT G68.2/CYCLE800/PLANE SPATIAL.
#
# Input:
#   mode   - Coordinate rotation mode: XYZ, ZXY, ZXZ, ZYX
#   MATRIX - Reference to an array of (0:8) defining a local coordinate system of 3x3 matrix
#
# Output:
#   ANG    - Reference to an array of (0:2) defining rotation angles in order
#            ang(0) - first rotation angle value
#            ang(1) - second rotation angle value
#            ang(2) - third rotation angle value
#
# Return:
#   1 - mode is available, 0 - mode is not available
#
# Revisions:
#-----------
# 2013-05-22 lili - Initial implementation
# 2106-02-02 gsl  - Clean up
# 08-09-2016 lili - Fix ZYX rotation angle calculation issue. zero resolution was too high.
#

   upvar $MATRIX rotation_matrix
   upvar $ANG rot_ang

   global RAD2DEG

   set m0 $rotation_matrix(0)
   set m1 $rotation_matrix(1)
   set m2 $rotation_matrix(2)
   set m3 $rotation_matrix(3)
   set m4 $rotation_matrix(4)
   set m5 $rotation_matrix(5)
   set m6 $rotation_matrix(6)
   set m7 $rotation_matrix(7)
   set m8 $rotation_matrix(8)

   set status UNDEFINED

   if { $mode == "XYZ" } {

      set cos_b_sq [expr $m0*$m0 + $m3*$m3]

      if { [EQ_is_equal $cos_b_sq 0.0] } {

         set cos_b 0.0
         set cos_a 1.0
         set sin_a 0.0
         set cos_c $m4
         set sin_c [expr -1*$m1]

         if { [expr $m6 < 0.0] } {
            set sin_b 1.0
         } else {
            set sin_b -1.0
         }

      } else {

         set cos_b [expr sqrt($cos_b_sq)]
         set sin_b [expr -$m6]

         set cos_a [expr $m8/$cos_b]
         set sin_a [expr $m7/$cos_b]

         set cos_c [expr $m0/$cos_b]
         set sin_c [expr $m3/$cos_b]
      }

      set A [expr -atan2($sin_a,$cos_a)*$RAD2DEG]
      set B [expr -atan2($sin_b,$cos_b)*$RAD2DEG]
      set C [expr -atan2($sin_c,$cos_c)*$RAD2DEG]

      set rot_ang(0) $A; set rot_ang(1) $B; set rot_ang(2) $C
      set status OK

   } elseif { $mode == "ZXY" } {

      set cos_a_sq [expr $m3*$m3 + $m4*$m4]

      if { [EQ_is_equal $cos_a_sq 0.0] } {

         set cos_a 0.0
         set cos_c 1.0
         set sin_c 0.0
         set sin_b $m6
         set cos_b $m0

         if { [expr $m5 < 0.0] } {
            set sin_a -1.0
         } else {
            set sin_a 1.0
         }

      } else {

         set cos_a [expr sqrt($cos_a_sq)]
         set sin_a [expr $m5]

         set cos_b [expr $m8/$cos_a]
         set sin_b [expr -$m2/$cos_a]

         set cos_c [expr $m4/$cos_a]
         set sin_c [expr -$m3/$cos_a]
      }

      set A [expr atan2($sin_a,$cos_a)*$RAD2DEG]
      set B [expr atan2($sin_b,$cos_b)*$RAD2DEG]
      set C [expr atan2($sin_c,$cos_c)*$RAD2DEG]

      set rot_ang(0) $C; set rot_ang(1) $A; set rot_ang(2) $B
      set status OK

   } elseif { $mode == "ZYX" } {

     #<Aug-15-2016 gsl> Replaced with new revision of <08-09-2016 lili>
     if 0 {

      if { [EQ_is_equal [expr abs($m2)] 1.0] } {
         set C [expr atan2([expr -1*$m3],$m4)]
      } else {
         set C [expr atan2($m1,$m0)]
      }

      set length [expr sqrt($m0*$m0 + $m1*$m1)]
      set B [expr -1*atan2($m2,$length)]
      set cos_B [expr cos($B)]

      if { ![EQ_is_zero $cos_B] } {
         set A [expr atan2($m5/$cos_B,$m8/$cos_B)]
      } else {
         set A 0.0
      }

      set A [expr $A*$RAD2DEG]
      set B [expr $B*$RAD2DEG]
      set C [expr $C*$RAD2DEG]

     } else {

      set cos_b_sq [expr $m0*$m0 + $m1*$m1]

      if { [EQ_is_equal $cos_b_sq 0.0] } {

         set cos_b 0.0
         set cos_a 1.0
         set sin_a 0.0
         set sin_c [expr -1*$m3]
         set cos_c $m4

         if { $m2 < 0.0 } {
            set sin_b 1.0
         } else {
            set sin_b -1.0
         }

      } else {

         set cos_b [expr sqrt($cos_b_sq)]
         set sin_b [expr -1*$m2]

         set cos_a [expr $m8/$cos_b]
         set sin_a [expr $m5/$cos_b]

         set cos_c [expr $m0/$cos_b]
         set sin_c [expr $m1/$cos_b]
      }

      set A [expr atan2($sin_a,$cos_a)*$RAD2DEG]
      set B [expr atan2($sin_b,$cos_b)*$RAD2DEG]
      set C [expr atan2($sin_c,$cos_c)*$RAD2DEG]

     }  ;# revision of <08-09-2016 lili>

      set rot_ang(0) $C; set rot_ang(1) $B; set rot_ang(2) $A
      set status OK

   } elseif { $mode == "ZXZ" } {

      set sin_b_sq [expr $m2*$m2 + $m5*$m5]

      if { [EQ_is_equal $sin_b_sq 0.0] } {

         set cos_b 1.0
         set sin_b 0.0
         set sin_c 0.0
         set cos_c 1.0
         set sin_a $m1

         if { [expr $m8 > 0.0] } {
            set cos_b 1.0
            set cos_a $m0
         } else {
            set cos_b -1.0
            set cos_a -$m4
         }

      } else {

         set sin_b [expr sqrt($sin_b_sq)]
         set cos_b [expr $m8]

         set cos_a [expr -$m7/$sin_b]
         set sin_a [expr $m6/$sin_b]

         set cos_c [expr $m5/$sin_b]
         set sin_c [expr $m2/$sin_b]
      }

      set A [expr atan2($sin_a,$cos_a)*$RAD2DEG]
      set B [expr atan2($sin_b,$cos_b)*$RAD2DEG]
      set C [expr atan2($sin_c,$cos_c)*$RAD2DEG]

      set rot_ang(0) $A; set rot_ang(1) $B; set rot_ang(2) $C
      set status OK
   }

   if { $status == "OK" } {
 return 1
   } else {
 return 0
   }
}


#=============================================================
proc DPP_GE_COOR_ROT { ang_mode rot_angle offset pos } {
#=============================================================
# This proc is used to detect if operation has coordinate rotation.
# DPP_GE_COOR_ROT_LOCAL, DPP_GE_COOR_ROT_AUTO3D, DPP_GE_CALCULATE_COOR_ROT_ANGLE are called in this proc.
#
# Input:
#   ang_mode -  coordinate matrix rotation method. Possible value: XYZ, ZXY, ZXZ, ZYX
#
# Output:
#   rot_angle - rotation angle array
#               rot_angle(0) is first rotation angle value
#               rot_angle(1) is second rotation angle value
#               rot_angle(2) is third rotation angle value
#   coord_offset - linear coordinate offset from current local CSYS rotation coordinate to parent coordinate.
#   pos - linear axes position respect to rotated cooridnate
#
# Return:
#   detected coordinate mode. Possible value: NONE, LOCAL, AUTO_3D
#   NONE - no coordinate rotation
#   LOCAL - coordinate rotation set up by LOCAL CSYS MCS
#   AUTO_3D - coordinate rotation set up by tilt work plane
#
# Revisions:
#-----------
# 2013-05-22 lili - Initial implementation
#

   upvar $rot_angle angle
   upvar $pos rot_pos
   upvar $offset coord_offset

   global mom_pos
   VMOV 3 mom_pos rot_pos

   set v0 0
   VEC3_init v0 v0 v0 coord_offset

   if {[DPP_GE_COOR_ROT_LOCAL rot_matrix coord_offset]} {
      set coord_rot "LOCAL"
   } elseif {[DPP_GE_COOR_ROT_AUTO3D rot_matrix rot_pos]} {
      set coord_rot "AUTO_3D"
   } else {
      set coord_rot "NONE"
   }

   if {[string compare "NONE" $coord_rot]} {
      DPP_GE_CALCULATE_COOR_ROT_ANGLE $ang_mode rot_matrix angle
   } else {
      set angle(0) 0.0
      set angle(1) 0.0
      set angle(2) 0.0
   }
   return $coord_rot
}


#=============================================================
proc DPP_GE_COOR_ROT_AUTO3D { rot_matrix rot_pos } {
#=============================================================
# This proc is used to detect if operation is 3+2 operation without Local CSYS rotation coordinate system.
# It will return rotation matrix and current position respect to rotated coordinate system. The machine kinemtaics
# will be reloaded to dual table machine.
# Rotation matrix calculated by current rotary axes angle and 4th,5th axis vector.
#
# Output:
#   rot_matrix - rotation matrix, mapping from the current rotation coordinate to parent coordinate(G54,G55..).
#   rot_pos    - current position respect to rotated coordinate system
#   * kinemtics - machine's kinematics will be reloaded to 5_axis_dual_table
#
# Return:
#   1 - operation is 3+2 operation without Local CSYS rotation coordinate system.
#   0 - operation is not 3+2 operation without Local CSYS rotation coordinate system.
#
# Revisions:
#-----------
# 2013-05-22 lili - Initial implementation
# 2013-10-16 levi - Reload mom_prev_pos when exchanging the pos of 4th axis and 5th axis for dual head machine.
# 2014-12-04 lili - Fix mom_kin_xth_axis_zero issue.
   upvar $rot_matrix matrix
   upvar $rot_pos pos

   global mom_kin_coordinate_system_type
   global mom_kin_machine_type
   global mom_kin_4th_axis_point mom_kin_5th_axis_point
   global mom_kin_4th_axis_vector mom_kin_5th_axis_vector
   global mom_out_angle_pos mom_prev_out_angle_pos
   global DEG2RAD
   global mom_pos mom_mcs_goto mom_prev_pos
   global mom_kin_4th_axis_zero mom_kin_5th_axis_zero

   set v0 0.0; set v1 1.0
   VEC3_init v1 v0 v0 X
   VEC3_init v0 v1 v0 Y
   VEC3_init v0 v0 v1 Z
   MTX3_init_x_y_z X Y Z matrix
   VMOV 3 mom_pos pos

   if { ![string match "*5_axis*" $mom_kin_machine_type] } {
      return 0
   }

   if {[info exists mom_kin_coordinate_system_type] && ![string compare "CSYS" $mom_kin_coordinate_system_type]} {
      return 0
   } else {
      if {(![EQ_is_zero $mom_out_angle_pos(0)] && ![VEC3_is_equal mom_kin_4th_axis_vector Z]) || \
          (![EQ_is_zero $mom_out_angle_pos(1)] && ![VEC3_is_equal mom_kin_5th_axis_vector Z]) } {
      } else {
         return 0
      }
   }


   # Save kinematics
   DPP_GE_SAVE_KINEMATICS

   # get rotation angle
   if { [string match "5_axis_dual_head" $mom_kin_machine_type] } {
      # Swap rotary axes kinematics for dual head machine
      DPP_GE_SWAP_4TH_5TH_KINEMATICS
      set ang_pos(0) $mom_out_angle_pos(1)
      set ang_pos(1) $mom_out_angle_pos(0)
      # Swap rotary axes value due to kinemtics switched
      set mom_out_angle_pos(0) $ang_pos(0)
      set mom_out_angle_pos(1) $ang_pos(1)
      set mom_prev_out_angle_pos(0) $ang_pos(0)
      set mom_prev_out_angle_pos(1) $ang_pos(1)
      set mom_pos(3) $ang_pos(0)
      set mom_pos(4) $ang_pos(1)
      set mom_prev_pos(3) $ang_pos(0)
      set mom_prev_pos(4) $ang_pos(1)
      MOM_reload_variable -a mom_out_angle_pos
      MOM_reload_variable -a mom_prev_out_angle_pos
      MOM_reload_variable -a mom_pos
      MOM_reload_variable -a mom_prev_pos
   } else {
      set ang_pos(0) $mom_out_angle_pos(0)
      set ang_pos(1) $mom_out_angle_pos(1)
   }

   set rot0 [expr ($ang_pos(0)-$mom_kin_4th_axis_zero)*$DEG2RAD]
   set rot1 [expr ($ang_pos(1)-$mom_kin_5th_axis_zero)*$DEG2RAD]

   # Reolad kinematics to dual-table machine
   if { ![string match "5_axis_dual_table" $mom_kin_machine_type] } {
     set mom_kin_machine_type "5_axis_dual_table"
   }

   set v0 0.0
   VEC3_init v0 v0 v0 mom_kin_4th_axis_point
   VEC3_init v0 v0 v0 mom_kin_5th_axis_point
   MOM_reload_kinematics

   # Get current position respect to rotated coordinate
   VECTOR_ROTATE mom_kin_5th_axis_vector [expr -1*$rot1] mom_mcs_goto V
   VECTOR_ROTATE mom_kin_4th_axis_vector [expr -1*$rot0] V pos

if {0} {
   # recalculate Z value for driling cycle initial move without clearance plane.
   global cycle_init_flag mom_current_motion mom_cycle_rapid_to
   if {[info exists cycle_init_flag] && $cycle_init_flag == "TRUE"} {
      if { ![string compare "initial_move" $mom_current_motion]} {
         set pos(2) [expr $pos(2) + $mom_cycle_rapid_to]
      }
   }
}

  # Calculate rotation matrix
   VECTOR_ROTATE mom_kin_4th_axis_vector $rot0 X V1
   VECTOR_ROTATE mom_kin_4th_axis_vector $rot0 Y V2
   VECTOR_ROTATE mom_kin_4th_axis_vector $rot0 Z V3

   VECTOR_ROTATE mom_kin_5th_axis_vector $rot1 V1 X
   VECTOR_ROTATE mom_kin_5th_axis_vector $rot1 V2 Y
   VECTOR_ROTATE mom_kin_5th_axis_vector $rot1 V3 Z

   MTX3_init_x_y_z X Y Z matrix

   return 1

}


#=============================================================
proc DPP_GE_COOR_ROT_LOCAL { rot_matrix coord_offset } {
#=============================================================
# This proc is used to detect if operation is under local CSYS rotation and if the coordinate is rotated.
# It will return rotation matrix.
#
# Output:
#   rot_matrix - rotation matrix, mapping from the current local CSYS rotation coordinate to parent coordinate.
#   coord_offset - linear coordinate offset from current local CSYS rotation coordinate to parent coordinate.
#
# Return:
#   1 - operation is under local CSYS rotation coordinate system and the coordinate is rotated.
#   0 - operation is not under local CSYS rotation coordinate system or the coordinate is not rotated.
#
# Revisions:
#-----------
# 2013-05-22 lili - Initial implementation
#
   upvar $rot_matrix matrix
   upvar $coord_offset offset

   global mom_csys_matrix mom_csys_origin
   global mom_kin_coordinate_system_type
   global mom_parent_csys_matrix
   global mom_part_unit mom_output_unit

   set v0 0; set v1 1
   VEC3_init v1 v0 v0 VX
   VEC3_init v0 v1 v0 VY
   VEC3_init v0 v0 v1 VZ
   MTX3_init_x_y_z VX VY VZ matrix
   MTX3_init_x_y_z VX VY VZ rr_matrix

   if {[info exists mom_kin_coordinate_system_type] && ![string compare "CSYS" $mom_kin_coordinate_system_type]} {
      if {[array exists mom_parent_csys_matrix]} {
         VMOV 9 mom_parent_csys_matrix matrix

         if {![string compare $mom_part_unit $mom_output_unit]} {
            set unit_conversion 1
         } elseif { ![string compare "IN" $mom_output_unit] } {
            set unit_conversion [expr 1.0/25.4]
         } else {
            set unit_conversion 25.4
         }
         set offset(0) [expr $unit_conversion*$mom_parent_csys_matrix(9)]
         set offset(1) [expr $unit_conversion*$mom_parent_csys_matrix(10)]
         set offset(2) [expr $unit_conversion*$mom_parent_csys_matrix(11)]

      } else {
         VMOV 9 mom_csys_matrix matrix
         VMOV 3 mom_csys_origin offset
      }
      if {[MTX3_is_equal matrix rr_matrix]} {
         return 0
      } else {
         return 1
      }
   } else {
      return 0
   }

}


#=============================================================
proc DPP_GE_DEBUG { args } {
#=============================================================
#This proc is used to debug.
#<12-03-2012 Allen> - Initial version
   foreach dpp_input_var  $args {
     upvar $dpp_input_var  dpp_output_var
     MOM_output_to_listing_device " [format "%-30s  %-40s %-30s " $dpp_input_var  $dpp_output_var [info level [expr [info level]-1]] ]"
   }
}


#=============================================================
proc DPP_GE_DETECT_5AXIS_TOOL_PATH { } {
#=============================================================
# This proc is used to detect the if operation is 5 axis simultaneous milling operation.
# In this command, tool path type is detected by mom_operation_type, mom_tool_path_type and mom_tool_axis_type
# The result may not always match 5-axis simultaneous milling. It is more tolerance.
#
# Return:
#   1 - tool path is 5 axis simultaneous
#   0 - tool path is not 5 axis simultaneous
#
# Revisions:
#-----------
# 2013-05-22 lili - Initial implementation
#

  global mom_tool_axis_type
  global mom_tool_path_type
  global mom_operation_type

  if { ![info exists mom_tool_axis_type] } {
     set mom_tool_axis_type 0
  }
  if {![info exists mom_tool_path_type]} {
     set mom_tool_path_type "undefined"
  }

  if { [DPP_GE_DETECT_HOLE_CUTTING_OPERATION]} {
     return 0
  } elseif { ($mom_tool_axis_type >=2 && [string match "Variable-axis *" $mom_operation_type]) ||\
          ![string compare "Sequential Mill Main Operation" $mom_operation_type] || \
          (![string compare "variable_axis" $mom_tool_path_type] && ![string match "Variable-axis *" $mom_operation_type])} {
     return 1
  } else {
     return 0
  }

}


#=============================================================
proc DPP_GE_DETECT_HOLE_CUTTING_OPERATION { } {
#=============================================================
# This proc is used to detect if the operation is a hole cutting operation.
# Hole cutting operation includs Cylinder Milling, Thread Milling, Point to Point,
# Hole Making, Drilling
#
# Return:
#   1 - operation is hole cutting operation
#   0 - operation is not hole cutting operation
#
# Revisions:
#-----------
# 2013-05-22 lili - Initial implementation
# 2015-04-22 Jintao -   add Chamfer Milling and Radial Groove Milling
#

  global mom_operation_type
  if {![string compare "Hole Making" $mom_operation_type] || ![string compare "Point to Point" $mom_operation_type] || \
      ![string compare "Cylinder Milling" $mom_operation_type] || ![string compare "Thread Milling" $mom_operation_type] || \
      ![string compare "Drilling" $mom_operation_type] || ![string compare "Chamfer Milling" $mom_operation_type] || \
      ![string compare "Radial Groove Milling" $mom_operation_type]} {
     return 1
  } else {
     return 0
  }

}


#=============================================================
proc DPP_GE_DETECT_TOOL_PATH_TYPE { } {
#=============================================================
# This proc is used to set dpp_ge(toolpath_axis_num)

  global dpp_ge
  if {[DPP_GE_DETECT_5AXIS_TOOL_PATH]} {
     set dpp_ge(toolpath_axis_num) 5
  } else {
     set dpp_ge(toolpath_axis_num) 3
  }
}


#=============================================================
proc DPP_GE_RESTORE_KINEMATICS { } {
#=============================================================
#This proc is used to restore original kinematics variables and sys variables.
# 2013-10-16 levi - Exchange the pos of 4th axis and 5th axis when restore kinematics for dual head machine.
# 2014-05-20 lili - remove out mom_kin_arc_output_mode and mom_kin_helical_arc_output_mode, they affect the compressor mode.
# 2015-07-31 szl  - PR6988503 remove mom_kin_helical_arc_output_mode
# 2015-09-16 szl  - Added save_kin_machine_type exist check.

 global save_mom_kin_machine_type
 global mom_kin_machine_type
 global mom_out_angle_pos
 global mom_pos
 global mom_prev_out_angle_pos
 global mom_prev_pos

 if { ![info exists save_mom_kin_machine_type] } {
    return
 }

# if it's dual-head machine, exchange the angle pos for 4th axis and 5th axis for the first point after auto3d
################### for drillling first on tilt plane then on XY plane.####################
 if { [string match "5_axis_dual_head" $save_mom_kin_machine_type] && ![string match $save_mom_kin_machine_type $mom_kin_machine_type]} {
    set temp $mom_out_angle_pos(0)
    set mom_out_angle_pos(0) $mom_out_angle_pos(1)
    set mom_out_angle_pos(1) $temp
 }
 VMOV 2 mom_out_angle_pos mom_prev_out_angle_pos
 set mom_pos(3) $mom_out_angle_pos(0)
 set mom_pos(4) $mom_out_angle_pos(1)
 set mom_prev_pos(3) $mom_out_angle_pos(0)
 set mom_prev_pos(4) $mom_out_angle_pos(1)
 MOM_reload_variable -a mom_out_angle_pos
 MOM_reload_variable -a mom_prev_out_angle_pos
 MOM_reload_variable -a mom_pos
 MOM_reload_variable -a mom_prev_pos
 set kin_list {  mom_sys_4th_axis_has_limits   mom_sys_5th_axis_has_limits  mom_kin_machine_type \
                 mom_kin_4th_axis_ang_offset   mom_kin_5th_axis_ang_offset      mom_kin_4th_axis_direction \
                 mom_kin_4th_axis_incr_switch  mom_kin_4th_axis_leader      mom_kin_4th_axis_limit_action \
                 mom_kin_4th_axis_max_limit    mom_kin_4th_axis_min_incr    mom_kin_4th_axis_min_limit \
                 mom_kin_4th_axis_plane        mom_kin_4th_axis_rotation    mom_kin_4th_axis_type \
                 mom_kin_5th_axis_zero         mom_kin_4th_axis_zero        mom_kin_5th_axis_direction \
                 mom_kin_5th_axis_incr_switch  mom_kin_5th_axis_leader      mom_kin_5th_axis_limit_action \
                 mom_kin_5th_axis_max_limit    mom_kin_5th_axis_min_incr    mom_kin_5th_axis_min_limit \
                 mom_kin_5th_axis_plane        mom_kin_5th_axis_rotation    mom_kin_5th_axis_type \
               }

  set kin_array_list { mom_kin_4th_axis_center_offset  mom_kin_5th_axis_center_offset   mom_kin_4th_axis_point \
                       mom_kin_5th_axis_point          mom_kin_4th_axis_vector          mom_kin_5th_axis_vector \
                       mom_kin_spindle_axis }



 foreach kin_var $kin_list {
    global $kin_var save_$kin_var
    if {[info exists save_$kin_var]} {
       set value [set save_$kin_var]
       set $kin_var $value
       #unset save_$kin_var
    }
 }

 foreach kin_var $kin_array_list {
    global $kin_var save_$kin_var
    if {[array exists save_$kin_var]} {
       set save_var save_$kin_var
       VMOV 3 $save_var $kin_var
       #UNSET_VARS $save_var
    }
 }

 global mom_sys_leader save_mom_sys_leader
 if {[info exists mom_kin_4th_axis_leader] && [info exists mom_kin_5th_axis_leader]} {
    set mom_sys_leader(fourth_axis) $mom_kin_4th_axis_leader
    set mom_sys_leader(fifth_axis) $mom_kin_5th_axis_leader
 }
 if {[info exists mom_kin_4th_axis_leader] && [info exists mom_kin_5th_axis_leader]} {
    set mom_sys_leader(fourth_axis) $mom_kin_4th_axis_leader
    set mom_sys_leader(fifth_axis) $mom_kin_5th_axis_leader
 }

  if {[info exists save_mom_sys_leader(fourth_axis_home)]} {
     set mom_sys_leader(fourth_axis_home) $save_mom_sys_leader(fourth_axis_home)
  }
  if {[info exists save_mom_sys_leader(fifth_axis_home)]} {
     set mom_sys_leader(fifth_axis_home) $save_mom_sys_leader(fifth_axis_home)
  }

  MOM_reload_kinematics
}


#=============================================================
proc DPP_GE_SAVE_KINEMATICS { } {
#=============================================================
#This proc is used to save original kinematics variables

  set kin_list { mom_sys_4th_axis_has_limits   mom_sys_5th_axis_has_limits  mom_kin_machine_type \
                 mom_kin_4th_axis_ang_offset   mom_kin_arc_output_mode      mom_kin_4th_axis_direction \
                 mom_kin_4th_axis_incr_switch  mom_kin_4th_axis_leader      mom_kin_4th_axis_limit_action \
                 mom_kin_4th_axis_max_limit    mom_kin_4th_axis_min_incr    mom_kin_4th_axis_min_limit \
                 mom_kin_4th_axis_plane        mom_kin_4th_axis_rotation    mom_kin_4th_axis_type \
                 mom_kin_5th_axis_zero         mom_kin_4th_axis_zero        mom_kin_5th_axis_direction \
                 mom_kin_5th_axis_incr_switch  mom_kin_5th_axis_leader      mom_kin_5th_axis_limit_action \
                 mom_kin_5th_axis_max_limit    mom_kin_5th_axis_min_incr    mom_kin_5th_axis_min_limit \
                 mom_kin_5th_axis_plane        mom_kin_5th_axis_rotation    mom_kin_5th_axis_type \
                 mom_kin_5th_axis_ang_offset   mom_kin_helical_arc_output_mode }
  set kin_array_list { mom_kin_4th_axis_center_offset  mom_kin_5th_axis_center_offset   mom_kin_4th_axis_point \
                       mom_kin_5th_axis_point          mom_kin_4th_axis_vector          mom_kin_5th_axis_vector }


  foreach kin_var $kin_list {
    global $kin_var save_$kin_var
    if {[info exists $kin_var] && ![info exists save_$kin_var]} {
       set value [set $kin_var]
       set save_$kin_var $value
    }
  }

  foreach kin_var $kin_array_list {
    global $kin_var save_$kin_var
    if {[array exists $kin_var] && ![array exists save_$kin_var]} {
       set save_var save_$kin_var
       VMOV 3 $kin_var $save_var
    }
  }

  global mom_sys_leader save_mom_sys_leader
  if {[info exists mom_sys_leader(fourth_axis_home)] && ![info exists save_mom_sys_leader(fourth_axis_home)]} {
     set save_mom_sys_leader(fourth_axis_home) $mom_sys_leader(fourth_axis_home)
  }
  if {[info exists mom_sys_leader(fifth_axis_home)] && ![info exists save_mom_sys_leader(fifth_axis_home)]} {
     set save_mom_sys_leader(fifth_axis_home) $mom_sys_leader(fifth_axis_home)
  }


}


#=============================================================
proc DPP_GE_SWAP_4TH_5TH_KINEMATICS { } {
#=============================================================
#This proc is used to swap 4th and 5th axis kinematics variables
  set kin_list { ang_offset   direction leader  incr_switch  \
                 limit_action max_limit min_incr min_limit \
                 plane        rotation  zero}

  set kin_array_list { center_offset point vector}

 foreach kin_var $kin_list {
    global mom_kin_4th_axis_$kin_var save_mom_kin_4th_axis_$kin_var
    global mom_kin_5th_axis_$kin_var save_mom_kin_5th_axis_$kin_var
    if {[info exists save_mom_kin_4th_axis_$kin_var] && [info exists save_mom_kin_5th_axis_$kin_var]} {
       set mom_kin_4th_axis_$kin_var [set save_mom_kin_5th_axis_[set kin_var]]
       set mom_kin_5th_axis_$kin_var [set save_mom_kin_4th_axis_[set kin_var]]
    }
 }

 foreach kin_var $kin_array_list {
    global mom_kin_4th_axis_$kin_var save_mom_kin_4th_axis_$kin_var
    global mom_kin_5th_axis_$kin_var save_mom_kin_5th_axis_$kin_var
    if {[array exists save_mom_kin_4th_axis_$kin_var] && [array exists save_mom_kin_5th_axis_$kin_var]} {
       VMOV 3 save_mom_kin_4th_axis_$kin_var mom_kin_5th_axis_$kin_var
       VMOV 3 save_mom_kin_5th_axis_$kin_var mom_kin_4th_axis_$kin_var
    }
 }

 global mom_sys_4th_axis_has_limits save_mom_sys_5th_axis_has_limits
 global mom_sys_5th_axis_has_limits save_mom_sys_4th_axis_has_limits
 global mom_sys_leader save_mom_sys_leader
 if {[info exists save_mom_sys_4th_axis_has_limits] && [info exists save_mom_sys_5th_axis_has_limits]} {
    set mom_sys_4th_axis_has_limits $save_mom_sys_5th_axis_has_limits
    set mom_sys_5th_axis_has_limits $save_mom_sys_4th_axis_has_limits
 }
 if {[info exists save_mom_kin_4th_axis_leader] && [info exists save_mom_kin_5th_axis_leader]} {
    set mom_sys_leader(fourth_axis) $save_mom_kin_5th_axis_leader
    set mom_sys_leader(fifth_axis) $save_mom_kin_4th_axis_leader
 }
 if {[info exists save_mom_sys_leader(fourth_axis_home)] && [info exists save_mom_sys_leader(fifth_axis_home)]} {
    set mom_sys_leader(fourth_axis_home) $save_mom_sys_leader(fifth_axis_home)
    set mom_sys_leader(fifth_axis_home)  $save_mom_sys_leader(fourth_axis_home)
 }

 MOM_reload_kinematics
}


#=============================================================
proc DPP_GE_UNSET_KINEMATICS { } {
#=============================================================
#This proc is used to unset saved kinematics variables

  set kin_list { mom_sys_4th_axis_has_limits   mom_sys_5th_axis_has_limits  mom_kin_machine_type \
                 mom_kin_4th_axis_ang_offset   mom_kin_arc_output_mode      mom_kin_4th_axis_direction \
                 mom_kin_4th_axis_incr_switch  mom_kin_4th_axis_leader      mom_kin_4th_axis_limit_action \
                 mom_kin_4th_axis_max_limit    mom_kin_4th_axis_min_incr    mom_kin_4th_axis_min_limit \
                 mom_kin_4th_axis_plane        mom_kin_4th_axis_rotation    mom_kin_4th_axis_type \
                 mom_kin_5th_axis_zero         mom_kin_4th_axis_zero        mom_kin_5th_axis_direction \
                 mom_kin_5th_axis_incr_switch  mom_kin_5th_axis_leader      mom_kin_5th_axis_limit_action \
                 mom_kin_5th_axis_max_limit    mom_kin_5th_axis_min_incr    mom_kin_5th_axis_min_limit \
                 mom_kin_5th_axis_plane        mom_kin_5th_axis_rotation    mom_kin_5th_axis_type \
                 mom_kin_5th_axis_ang_offset   mom_kin_helical_arc_output_mode }

  set kin_array_list { mom_kin_4th_axis_center_offset  mom_kin_5th_axis_center_offset   mom_kin_4th_axis_point \
                       mom_kin_5th_axis_point          mom_kin_4th_axis_vector          mom_kin_5th_axis_vector }


  foreach kin_var $kin_list {
    global save_$kin_var
    if {[info exists save_$kin_var]} {
       unset save_$kin_var
    }
  }

  foreach kin_var $kin_array_list {
    global save_$kin_var
    if [array exists save_$kin_var] {
      UNSET_VARS save_$kin_var
    }
  }

  global mom_sys_leader save_mom_sys_leader
  if {[info exists save_mom_sys_leader(fourth_axis_home)]} {
     unset save_mom_sys_leader(fourth_axis_home)
  }
  if {[info exists save_mom_sys_leader(fifth_axis_home)]} {
     unset save_mom_sys_leader(fifth_axis_home)
  }
}


#=============================================================
proc EXEC { command_string {__wait 1} } {
#=============================================================
# pb_base -
#
# This command can be used in place of the intrinsic Tcl "exec" command
# of which some problems have been reported under Win64 O/S and multi-core
# processors environment.
#
#
# Input:
#   command_string -- command string
#   __wait         -- optional flag
#                     1 (default)   = Caller will wait until execution is complete.
#                     0 (specified) = Caller will not wait.
#
# Return:
#   Results of execution
#
#
# Revisions:
#-----------
# 05-19-10 gsl - Initial implementation
#

   global tcl_platform


   if { $__wait } {

      if { [string match "windows" $tcl_platform(platform)] } {

         global env mom_logname

        # Create a temporary file to collect output
         set result_file "$env(TEMP)/${mom_logname}__EXEC_[clock clicks].out"

        # Clean up existing file
         regsub -all {\\} $result_file {/}  result_file
        #regsub -all { }  $result_file {\ } result_file

         if { [file exists "$result_file"] } {
            file delete -force "$result_file"
         }

        #<11-05-2013> Escape spaces
         set cmd [concat exec $command_string > \"$result_file\"]
         regsub -all {\\} $cmd {\\\\} cmd
         regsub -all { }  $result_file {\\\ } result_file

         eval $cmd

        # Return results & clean up temporary file
         if { [file exists "$result_file"] } {
            set fid [open "$result_file" r]
            set result [read $fid]
            close $fid

            file delete -force "$result_file"

           return $result
         }

      } else {

         set cmd [concat exec $command_string]

        return [eval $cmd]
      }

   } else {

      if { [string match "windows" $tcl_platform(platform)] } {

         set cmd [concat exec $command_string &]
         regsub -all {\\} $cmd {\\\\} cmd

        return [eval $cmd]

      } else {

        return [exec $command_string &]
      }
   }
}




#=============================================================
proc GET_SPINDLE_AXIS { input_tool_axis } {
#=============================================================
# called by ROTARY_AXIS_RETRACT

   upvar $input_tool_axis axis

   global mom_kin_4th_axis_type
   global mom_kin_4th_axis_plane
   global mom_kin_5th_axis_type
   global mom_kin_spindle_axis
   global mom_sys_spindle_axis

   if { ![string compare "Table" $mom_kin_4th_axis_type] } {
      VMOV 3 mom_kin_spindle_axis mom_sys_spindle_axis
   } elseif { ![string compare "Table" $mom_kin_5th_axis_type] } {
      VMOV 3 axis vec
      if { ![string compare "XY" $mom_kin_4th_axis_plane] } {
         set vec(2) 0.0
      } elseif { ![string compare "ZX" $mom_kin_4th_axis_plane] } {
         set vec(1) 0.0
      } elseif { ![string compare "YZ" $mom_kin_4th_axis_plane] } {
         set vec(0) 0.0
      }
      set len [VEC3_unitize vec mom_sys_spindle_axis]
      if { [EQ_is_zero $len] } { set mom_sys_spindle_axis(2) 1.0 }
   } else {
      VMOV 3 axis mom_sys_spindle_axis
   }
}


#=============================================================
proc HANDLE_FIRST_LINEAR_MOVE { } {
#=============================================================
# pb_post_base -
#
# Called by MOM_linear_move to handle the 1st linear move of an operation.
#
   if { ![info exists ::first_linear_move] } {
      set ::first_linear_move 0
   }
   if { !$::first_linear_move } {
      PB_first_linear_move
      incr ::first_linear_move
   }
}


#=============================================================
proc INFO { args } {
#=============================================================
# pb_base -
#
   MOM_output_to_listing_device [join $args]
}


#=============================================================
proc LIMIT_ANGLE { a } {
#=============================================================
# pb_base -
#
   set a [expr fmod($a,360)]
   set a [expr ($a < 0) ? ($a + 360) : $a]

return $a
}


#=============================================================
proc LINEARIZE_LOCK_MOTION { } {
#=============================================================
# called by LOCK_AXIS_MOTION
#
#  This command linearizes the move between two positions that
#  have both linear and rotary motion.  The rotary motion is
#  created by LOCK_AXIS from the coordinates in the locked plane.
#  The combined linear and rotary moves result in non-linear
#  motion.  This command will break the move into shorter moves
#  that do not violate the tolerance.
#
#<04-08-2014 gsl> - Corrected error with use of mom_outangle_pos.
#<12-03-2014 gsl> - Declaration of global unlocked_pos & unlocked_prev_pos were commented out in pb903.
#<09-09-2015 ljt> - Ensure mom_prev_pos is locked, and raise warning
#                   when linearization iteration does not complete.

   global mom_pos
   global mom_prev_pos
   global unlocked_pos
   global unlocked_prev_pos
   global mom_kin_linearization_tol
   global mom_kin_machine_resolution
   global mom_out_angle_pos

   VMOV 5 mom_pos locked_pos

   # <09-Sep-2015 ljt> Make sure mom_prev_pos is locked. If mom_pos has been reloaded and
   #                   when MOM_POST_convert_point is called in core result can be wrong.
   # VMOV 5 mom_prev_pos locked_prev_pos
   LOCK_AXIS mom_prev_pos locked_prev_pos ::mom_prev_out_angle_pos

   UNLOCK_AXIS locked_pos unlocked_pos
   UNLOCK_AXIS locked_prev_pos unlocked_prev_pos

   VMOV 5 unlocked_pos save_unlocked_pos
   VMOV 5 locked_pos save_locked_pos

   set loop 0
   set count 0

   set tol $mom_kin_linearization_tol

   while { $loop == 0 } {

      for { set i 3 } { $i < 5 } { incr i } {
         set del [expr $locked_pos($i) - $locked_prev_pos($i)]
         if { $del > 180.0 } {
            set locked_prev_pos($i) [expr $locked_prev_pos($i) + 360.0]
         } elseif { $del < -180.0 } {
            set locked_prev_pos($i) [expr $locked_prev_pos($i) - 360.0]
         }
      }

      set loop 1

      for { set i 0 } { $i < 5 } { incr i } {
         set mid_unlocked_pos($i) [expr ( $unlocked_pos($i) + $unlocked_prev_pos($i) )/2.0]
         set mid_locked_pos($i) [expr ( $locked_pos($i) + $locked_prev_pos($i) )/2.0]
      }

      UNLOCK_AXIS mid_locked_pos temp

      VEC3_sub temp mid_unlocked_pos work

      set error [VEC3_mag work]

      if { $count > 20 } {

         VMOV 5 locked_pos mom_pos
         VMOV 5 unlocked_pos mom_prev_pos

         CATCH_WARNING "LINEARIZATION ITERATION FAILED."

         LINEARIZE_LOCK_OUTPUT $count

      } elseif { $error < $tol } {

         VMOV 5 locked_pos mom_pos
         VMOV 5 unlocked_pos mom_prev_pos

         CATCH_WARNING "LINEARIZATION ITERATION FAILED."

         LINEARIZE_LOCK_OUTPUT $count

         VMOV 5 unlocked_pos unlocked_prev_pos
         VMOV 5 locked_pos locked_prev_pos

         if { $count != 0 } {
            VMOV 5 save_unlocked_pos unlocked_pos
            VMOV 5 save_locked_pos locked_pos
            set loop 0
            set count 0
         }

      } else {

         if { $error < $mom_kin_machine_resolution } {
            set error $mom_kin_machine_resolution
         }

         set error [expr sqrt( $tol*.98/$error )]

         if { $error < .5 } { set error .5 }

         for { set i 0 } { $i < 5 } { incr i } {
            set locked_pos($i)   [expr $locked_prev_pos($i)   + ( $locked_pos($i)   - $locked_prev_pos($i)   )*$error]
            set unlocked_pos($i) [expr $unlocked_prev_pos($i) + ( $unlocked_pos($i) - $unlocked_prev_pos($i) )*$error]
         }

        #<04-08-2014 gsl> mom_out_angle_pos was mom_outangle_pos.
         LOCK_AXIS unlocked_pos locked_pos mom_out_angle_pos

         set loop 0
         incr count
      }
   }

#<04-08-2014 gsl> Didn't make difference
#   MOM_reload_variable -a mom_pos
#   MOM_reload_variable -a mom_prev_pos
#   MOM_reload_variable -a mom_out_angle_pos
}


#=============================================================
proc LINEARIZE_LOCK_OUTPUT { count } {
#=============================================================
# called by LOCK_AXIS_MOTION & LINEARIZE_LOCK_MOTION
# "count > 0" will cause output.
#
# Jul-16-2013     - pb1003
# Oct-15-2015 ljt - PR6789060, account for reversed rotation, reload mom_prev_rot_ang_4/5th
#
   global mom_out_angle_pos
   global mom_pos
   global mom_prev_rot_ang_4th
   global mom_prev_rot_ang_5th
   global mom_kin_4th_axis_direction
   global mom_kin_5th_axis_direction
   global mom_kin_4th_axis_leader
   global mom_kin_5th_axis_leader
   global mom_sys_leader
   global mom_prev_pos
   global mom_mcs_goto
   global mom_prev_mcs_goto
   global mom_motion_distance
   global mom_feed_rate_number
   global mom_feed_rate
   global mom_kin_machine_resolution
   global mom_kin_max_frn
   global mom_kin_machine_type
   global mom_kin_4th_axis_min_limit mom_kin_4th_axis_max_limit
   global mom_kin_5th_axis_min_limit mom_kin_5th_axis_max_limit
   global mom_out_angle_pos
   global unlocked_pos unlocked_prev_pos



   set mom_out_angle_pos(0)  [ROTSET $mom_pos(3) $mom_prev_rot_ang_4th $mom_kin_4th_axis_direction\
                                     $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                     $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]

  # Make sure previous angles are correct which will be used in next ROTSET.
   set mom_prev_rot_ang_4th $mom_out_angle_pos(0)
   MOM_reload_variable mom_prev_rot_ang_4th

   if { [string match "5_axis_*table" $mom_kin_machine_type] } {

      # Account for reversed rotation, mom_kin_5th_axis_vector is always the positive direction of x/y/z,
      # only fifth axis can be locked for five axis post, and the tool axis is parallel to mom_kin_5th_axis_vector
      # if the tool axis leads to the negative direction, the angle need to be reversed.
      if { [string match "MAGNITUDE_DETERMINES_DIRECTION" $mom_kin_5th_axis_direction]\
           && [VEC3_dot ::mom_tool_axis ::mom_kin_5th_axis_vector] < 0 } {

         set mom_pos(4) [expr -1 * $mom_pos(4)]
      }

      set mom_out_angle_pos(1)  [ROTSET $mom_pos(4) $mom_prev_rot_ang_5th $mom_kin_5th_axis_direction\
                                        $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                        $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]

      set mom_prev_rot_ang_5th $mom_out_angle_pos(1)
      MOM_reload_variable mom_prev_rot_ang_5th
   }

#
#  Re-calcualte the distance and feed rate number
#
   if { $count < 0 } {
      VEC3_sub mom_mcs_goto mom_prev_mcs_goto delta
   } else {
      VEC3_sub unlocked_pos unlocked_prev_pos delta
   }

   set mom_motion_distance [VEC3_mag delta]

   if { [EQ_is_lt $mom_motion_distance $mom_kin_machine_resolution] } {
      set mom_feed_rate_number $mom_kin_max_frn
   } else {
      set mom_feed_rate_number [expr $mom_feed_rate / $mom_motion_distance]
   }

   set mom_pos(3) $mom_out_angle_pos(0)

  # Is it only needed for a 5-axis?
   set mom_pos(4) $mom_out_angle_pos(1)


   FEEDRATE_SET

   if { $count > 0 } { PB_CMD_linear_move }
}


#=============================================================
proc LOCK_AXIS { input_point output_point output_rotary } {
#=============================================================
# called by LOCK_AXIS_MOTION & LINEARIZE_LOCK_MOTION
#
# (pb903)
# 09-06-13 Allen - PR6932644 - implement lock axis for 4 axis machine.
# 04-16-14 gsl   - Account for offsets resulted from right-angled head attachment
# 09-09-15 ljt   - Replace mom_kin_4/5th_axis_center_offset with mom_kin_4/5th_axis_point
# 10-15-15 ljt   - PR6789060, account for reversed rotation of table not perpendicular to spindle axis.

   upvar $input_point in_pos ; upvar $output_point out_pos ; upvar $output_rotary or

   global mom_kin_4th_axis_center_offset
   global mom_kin_5th_axis_center_offset
   global mom_sys_lock_value
   global mom_sys_lock_plane
   global mom_sys_lock_axis
   global mom_sys_unlocked_axis
   global mom_sys_4th_axis_index
   global mom_sys_5th_axis_index
   global mom_sys_linear_axis_index_1
   global mom_sys_linear_axis_index_2
   global mom_sys_rotary_axis_index
   global mom_kin_machine_resolution
   global mom_prev_lock_angle
   global mom_out_angle_pos
   global mom_prev_rot_ang_4th
   global mom_prev_rot_ang_5th
   global positive_radius
   global DEG2RAD
   global RAD2DEG
   global mom_kin_4th_axis_rotation
   global mom_kin_5th_axis_rotation
   global mom_kin_machine_type
   global mom_kin_4th_axis_point
   global mom_kin_5th_axis_point
   global mom_origin


   if { ![info exists positive_radius] } { set positive_radius 0 }

   if { $mom_sys_rotary_axis_index == 3 } {
      if { ![info exists mom_prev_rot_ang_4th] } { set mom_prev_rot_ang_4th 0.0 }
      set mom_prev_lock_angle $mom_prev_rot_ang_4th
   } else {
      if { ![info exists mom_prev_rot_ang_5th] } { set mom_prev_rot_ang_5th 0.0 }
      set mom_prev_lock_angle $mom_prev_rot_ang_5th
   }

  #<04-16-2014 gsl> Add offsets of angled-head attachment to input point
   VMOV 5 in_pos ip
   ACCOUNT_HEAD_OFFSETS ip 1


   # <09-Sep-2015 ljt> Add offsets of 4/5th axis rotary center
   VMOV 3 ip temp
   if { [CMD_EXIST MOM_validate_machine_model] \
        && [string match "TRUE" [MOM_validate_machine_model]] } {

      if { [string match "5_axis_*table" $mom_kin_machine_type] && [info exists mom_kin_5th_axis_point] } {

         VEC3_sub temp mom_kin_5th_axis_point temp

      } elseif { ( [string match "4_axis_table" $mom_kin_machine_type] || [string match "*mill_turn" $mom_kin_machine_type] ) \
                 && [info exists mom_kin_4th_axis_point] } {

         VEC3_sub temp mom_kin_4th_axis_point temp
      }

   } else {

      # mom_origin is a vector from table center to destination MCS
      if { [info exists mom_origin] } {
         VEC3_add temp mom_origin temp
      }

      if { [info exists mom_kin_4th_axis_center_offset] } {
         VEC3_sub temp mom_kin_4th_axis_center_offset temp
      }

      if { [info exists mom_kin_5th_axis_center_offset ] } {
         VEC3_sub temp mom_kin_5th_axis_center_offset temp
      }
   }

   set temp(3) $ip(3)
   set temp(4) $ip(4)

   if { $mom_sys_lock_axis > 2 } {

      set angle [expr ($mom_sys_lock_value - $temp($mom_sys_lock_axis))*$DEG2RAD]
      ROTATE_VECTOR $mom_sys_lock_plane $angle temp temp1
      VMOV 3 temp1 temp
      set temp($mom_sys_lock_axis) $mom_sys_lock_value

   } else {

      # <15-Oct-15 ljt> lock plane is 5th axis plane for 5axis machine
      if { [string match "5_axis_*table" $mom_kin_machine_type] } {
         set angle [expr ($temp(4))*$DEG2RAD]

         # <03-11-10 wbh> 6308668 Check the rotation mode
         if [string match "reverse" $mom_kin_5th_axis_rotation] {
            set angle [expr -$angle]
         }

         ROTATE_VECTOR $mom_sys_5th_axis_index $angle temp temp1
         VMOV 3 temp1 temp
         set temp(4) 0.0
      }


      #<09-06-13 Allen> Fix PR6932644 to implement lock axis for 4 axis machine.
      #<11-15-2013 gsl> ==> Rotation seemed to be reversed!
      if { [string match "4_axis_*" $mom_kin_machine_type] } {
         if { ![string compare $mom_sys_lock_plane $mom_sys_4th_axis_index] } {
            set angle [expr $temp(3)*$DEG2RAD]
            if [string match "reverse" $mom_kin_4th_axis_rotation] {
               set angle [expr -$angle]
            }

            ROTATE_VECTOR $mom_sys_4th_axis_index $angle temp temp1

            VMOV 3 temp1 temp
            set temp(3) 0.0
         }
      }


      set rad [expr sqrt($temp($mom_sys_linear_axis_index_1)*$temp($mom_sys_linear_axis_index_1) +\
                         $temp($mom_sys_linear_axis_index_2)*$temp($mom_sys_linear_axis_index_2))]

      set angle [ARCTAN $temp($mom_sys_linear_axis_index_2) $temp($mom_sys_linear_axis_index_1)]

      # <03-11-10 wbh> 6308668 Check the rotation mode
      # <15-Oct-15 ljt> lock plane is 5th axis plane for 5axis machine
      if { [string match "5_axis_*table" $mom_kin_machine_type] } {
         if [string match "reverse" $mom_kin_5th_axis_rotation] {
            set angle [expr -$angle]
         }
      } elseif { ![string compare $mom_sys_lock_plane $mom_sys_4th_axis_index] } {
         if [string match "reverse" $mom_kin_4th_axis_rotation] {
            set angle [expr -$angle]
         }
      }

      if { $rad < [expr abs($mom_sys_lock_value) + $mom_kin_machine_resolution] } {
         if { $mom_sys_lock_value < 0.0 } {
            set temp($mom_sys_lock_axis) [expr -$rad]
         } else {
            set temp($mom_sys_lock_axis) $rad
         }
      } else {
         set temp($mom_sys_lock_axis) $mom_sys_lock_value
      }

      set temp($mom_sys_unlocked_axis)  [expr sqrt($rad*$rad - $temp($mom_sys_lock_axis)*$temp($mom_sys_lock_axis))]

      VMOV 5 temp temp1
      set temp1($mom_sys_unlocked_axis) [expr -$temp($mom_sys_unlocked_axis)]
      set ang1 [ARCTAN $temp($mom_sys_linear_axis_index_2)  $temp($mom_sys_linear_axis_index_1)]
      set ang2 [ARCTAN $temp1($mom_sys_linear_axis_index_2) $temp1($mom_sys_linear_axis_index_1)]
      set temp($mom_sys_rotary_axis_index)  [expr ($angle - $ang1)*$RAD2DEG]
      set temp1($mom_sys_rotary_axis_index) [expr ($angle - $ang2)*$RAD2DEG]
      set ang1 [LIMIT_ANGLE [expr $mom_prev_lock_angle - $temp($mom_sys_rotary_axis_index)]]
      set ang2 [LIMIT_ANGLE [expr $mom_prev_lock_angle - $temp1($mom_sys_rotary_axis_index)]]

      if { $ang1 > 180.0 } { set ang1 [LIMIT_ANGLE [expr -$ang1]] }
      if { $ang2 > 180.0 } { set ang2 [LIMIT_ANGLE [expr -$ang2]] }

      if { $positive_radius == 0 } {
         if { $ang1 > $ang2 } {
            VMOV 5 temp1 temp
            set positive_radius "-1"
         } else {
            set positive_radius "1"
         }
      } elseif { $positive_radius == -1 } {
         VMOV 5 temp1 temp
      }

     #+++++++++++++++++++++++++++++++++++++++++
     # NOT needed!!! <= will cause misbehavior
     # VMOV 5 temp1 temp
   }


   # <09-Sep-2015 ljt> Remove offsets of  4/5th axis rotary center
   VMOV 3 temp op
   if { [CMD_EXIST MOM_validate_machine_model] \
        && [string match "TRUE" [MOM_validate_machine_model]] } {

      if { [string match "5_axis_*table" $mom_kin_machine_type] && [info exists mom_kin_5th_axis_point] } {

         VEC3_add op mom_kin_5th_axis_point op

      } elseif { ( [string match "4_axis_table" $mom_kin_machine_type] || [string match "*mill_turn" $mom_kin_machine_type] ) \
                 && [info exists mom_kin_4th_axis_point] } {

         VEC3_add op mom_kin_4th_axis_point op
      }

   } else {

      if { [info exists mom_origin] } {
         VEC3_sub op mom_origin op
      }

      if { [info exists mom_kin_4th_axis_center_offset] } {
         VEC3_add op mom_kin_4th_axis_center_offset op
      }

      if { [info exists mom_kin_5th_axis_center_offset] } {
         VEC3_add op mom_kin_5th_axis_center_offset op
      }

   }

   if { ![info exists or] } {
      set or(0) 0.0
      set or(1) 0.0
   }

   set mom_prev_lock_angle $temp($mom_sys_rotary_axis_index)
   set op(3) $temp(3)
   set op(4) $temp(4)


  #<04-16-2014 gsl> Remove offsets of angled-head attachment from output point
   ACCOUNT_HEAD_OFFSETS op 0
   VMOV 5 op out_pos
}


#=============================================================
proc LOCK_AXIS_INITIALIZE { } {
#=============================================================
# called by MOM_lock_axis
# ==> It's only used by MOM_lock_axis, perhaps it should be defined within.

   global mom_sys_lock_plane
   global mom_sys_lock_axis
   global mom_sys_unlocked_axis
   global mom_sys_unlock_plane
   global mom_sys_4th_axis_index
   global mom_sys_5th_axis_index
   global mom_sys_linear_axis_index_1
   global mom_sys_linear_axis_index_2
   global mom_sys_rotary_axis_index
   global mom_kin_4th_axis_plane
   global mom_kin_5th_axis_plane
   global mom_kin_machine_type

   if { $mom_sys_lock_plane == -1 } {
      if { ![string compare "XY" $mom_kin_4th_axis_plane] } {
         set mom_sys_lock_plane 2
      } elseif { ![string compare "ZX" $mom_kin_4th_axis_plane] } {
         set mom_sys_lock_plane 1
      } elseif { ![string compare "YZ" $mom_kin_4th_axis_plane] } {
         set mom_sys_lock_plane 0
      }
   }

   set mom_sys_4th_axis_index -1
   if { ![string compare "XY" $mom_kin_4th_axis_plane] } {
      set mom_sys_4th_axis_index 2
   } elseif { ![string compare "ZX" $mom_kin_4th_axis_plane] } {
      set mom_sys_4th_axis_index 1
   } elseif { ![string compare "YZ" $mom_kin_4th_axis_plane] } {
      set mom_sys_4th_axis_index 0
   }


  # Check whether the machine type is 5-axis.
   set mom_sys_5th_axis_index -1
   if { [string match "5_axis_*" $mom_kin_machine_type] && [info exists mom_kin_5th_axis_plane] } {
      if { ![string compare "XY" $mom_kin_5th_axis_plane] } {
         set mom_sys_5th_axis_index 2
      } elseif { ![string compare "ZX" $mom_kin_5th_axis_plane] } {
         set mom_sys_5th_axis_index 1
      } elseif { ![string compare "YZ" $mom_kin_5th_axis_plane] } {
         set mom_sys_5th_axis_index 0
      }
   }


   if { $mom_sys_lock_plane == 0 } {
      set mom_sys_linear_axis_index_1 1
      set mom_sys_linear_axis_index_2 2
   } elseif { $mom_sys_lock_plane == 1 } {
      set mom_sys_linear_axis_index_1 2
      set mom_sys_linear_axis_index_2 0
   } elseif { $mom_sys_lock_plane == 2 } {
      set mom_sys_linear_axis_index_1 0
      set mom_sys_linear_axis_index_2 1
   }

   # Can only lock the last rotary axis
   if { $mom_sys_5th_axis_index == -1 } {
      set mom_sys_rotary_axis_index 3
   } else {
      set mom_sys_rotary_axis_index 4
   }

   set mom_sys_unlocked_axis [expr $mom_sys_linear_axis_index_1 +\
                                   $mom_sys_linear_axis_index_2 -\
                                   $mom_sys_lock_axis]


#MOM_output_text "( >>> mom_sys_lock_plane          : $mom_sys_lock_plane )"
#MOM_output_text "( >>> mom_sys_lock_axis           : $mom_sys_lock_axis )"
#MOM_output_text "( >>> mom_sys_unlocked_axis       : $mom_sys_unlocked_axis )"
#MOM_output_text "( >>> mom_sys_4th_axis_index      : $mom_sys_4th_axis_index )"
#MOM_output_text "( >>> mom_sys_5th_axis_index      : $mom_sys_5th_axis_index )"
#MOM_output_text "( >>> mom_sys_linear_axis_index_1 : $mom_sys_linear_axis_index_1 )"
#MOM_output_text "( >>> mom_sys_linear_axis_index_2 : $mom_sys_linear_axis_index_2 )"
#MOM_output_text "( >>> mom_sys_rotary_axis_index   : $mom_sys_rotary_axis_index )"
#MOM_output_text "( >>> mom_kin_4th_axis_plane      : $mom_kin_4th_axis_plane )"
#MOM_output_text "( >>> mom_kin_5th_axis_plane      : $mom_kin_5th_axis_plane )"
#MOM_output_text "( >>> mom_kin_machine_type        : $mom_kin_machine_type )"
}


#=============================================================
proc LOCK_AXIS_MOTION { } {
#=============================================================
# called by PB_CMD_kin_before_motion
#
#  The UDE lock_axis must be specified in the tool path
#  for the post to lock the requested axis.  The UDE lock_axis may only
#  be used for four and five axis machine tools.  A four axis post may
#  only lock an axis in the plane of the fourth axis.  For five axis
#  posts, only the fifth axis may be locked.  Five axis will only
#  output correctly if the fifth axis is rotated so it is perpendicular
#  to the spindle axis.
#
# Mar-29-2016    - Of NX/PB v11.0
#

  # Must be called by PB_CMD_kin_before_motion
   if { ![CALLED_BY "PB_CMD_kin_before_motion"] } {
return
   }


   if { [string match "circular_move" $::mom_current_motion] } {
return
   }



   global mom_sys_lock_status

   if { [string match "ON" $mom_sys_lock_status] } {

      global mom_pos mom_out_angle_pos
      global mom_motion_type
      global mom_cycle_feed_to_pos
      global mom_cycle_feed_to mom_tool_axis
      global mom_motion_event
      global mom_cycle_rapid_to_pos
      global mom_cycle_retract_to_pos
      global mom_cycle_rapid_to
      global mom_cycle_retract_to
      global mom_prev_pos
      global mom_kin_4th_axis_type
      global mom_kin_spindle_axis
      global mom_kin_5th_axis_type
      global mom_kin_4th_axis_plane
      global mom_sys_cycle_after_initial
      global mom_kin_4th_axis_min_limit
      global mom_kin_4th_axis_max_limit
      global mom_kin_5th_axis_min_limit
      global mom_kin_5th_axis_max_limit
      global mom_prev_rot_ang_4th
      global mom_prev_rot_ang_5th
      global mom_kin_4th_axis_direction
      global mom_kin_5th_axis_direction
      global mom_kin_4th_axis_leader
      global mom_kin_5th_axis_leader
      global mom_kin_machine_type


      if { ![info exists mom_sys_cycle_after_initial] } {
         set mom_sys_cycle_after_initial "FALSE"
      }

      if { [string match "FALSE" $mom_sys_cycle_after_initial] } {
         LOCK_AXIS mom_pos mom_pos mom_out_angle_pos
      }

      if { [string match "CYCLE" $mom_motion_type] } {

         if { [string match "Table" $mom_kin_4th_axis_type] } {

           # "mom_spindle_axis" would have the head attachment incorporated.
            global mom_spindle_axis
            if [info exists mom_spindle_axis] {
               VMOV 3 mom_spindle_axis mom_sys_spindle_axis
            } else {
               VMOV 3 mom_kin_spindle_axis mom_sys_spindle_axis
            }

         } elseif { [string match "Table" $mom_kin_5th_axis_type] } {

            VMOV 3 mom_tool_axis vec

           # Zero component of rotating axis
            switch $mom_kin_4th_axis_plane {
               XY {
                  set vec(2) 0.0
               }
               ZX {
                  set vec(1) 0.0
               }
               YZ {
                  set vec(0) 0.0
               }
            }

           # Reworked logic to prevent potential error
            set len [VEC3_mag vec]
            if { [EQ_is_gt $len 0.0] } {
               VEC3_unitize vec mom_sys_spindle_axis
            } else {
               set mom_sys_spindle_axis(0) 0.0
               set mom_sys_spindle_axis(1) 0.0
               set mom_sys_spindle_axis(2) 1.0
            }

         } else {

            VMOV 3 mom_tool_axis mom_sys_spindle_axis
         }

         set mom_cycle_feed_to_pos(0)    [expr $mom_pos(0) + $mom_cycle_feed_to    * $mom_sys_spindle_axis(0)]
         set mom_cycle_feed_to_pos(1)    [expr $mom_pos(1) + $mom_cycle_feed_to    * $mom_sys_spindle_axis(1)]
         set mom_cycle_feed_to_pos(2)    [expr $mom_pos(2) + $mom_cycle_feed_to    * $mom_sys_spindle_axis(2)]

         set mom_cycle_rapid_to_pos(0)   [expr $mom_pos(0) + $mom_cycle_rapid_to   * $mom_sys_spindle_axis(0)]
         set mom_cycle_rapid_to_pos(1)   [expr $mom_pos(1) + $mom_cycle_rapid_to   * $mom_sys_spindle_axis(1)]
         set mom_cycle_rapid_to_pos(2)   [expr $mom_pos(2) + $mom_cycle_rapid_to   * $mom_sys_spindle_axis(2)]

         set mom_cycle_retract_to_pos(0) [expr $mom_pos(0) + $mom_cycle_retract_to * $mom_sys_spindle_axis(0)]
         set mom_cycle_retract_to_pos(1) [expr $mom_pos(1) + $mom_cycle_retract_to * $mom_sys_spindle_axis(1)]
         set mom_cycle_retract_to_pos(2) [expr $mom_pos(2) + $mom_cycle_retract_to * $mom_sys_spindle_axis(2)]
      }


      global mom_kin_linearization_flag

      if { ![string compare "TRUE"       $mom_kin_linearization_flag] &&\
            [string compare "RAPID"      $mom_motion_type]            &&\
            [string compare "CYCLE"      $mom_motion_type]            &&\
            [string compare "rapid_move" $mom_motion_event] } {

         LINEARIZE_LOCK_MOTION

      } else {

         if { ![info exists mom_prev_rot_ang_4th] } { set mom_prev_rot_ang_4th 0.0 }
         if { ![info exists mom_prev_rot_ang_5th] } { set mom_prev_rot_ang_5th 0.0 }

         LINEARIZE_LOCK_OUTPUT -1
      }


     #VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
     # > Do not reload mom_pos here!
     # MOM_reload_variable -a mom_pos

   } ;# mom_sys_lock_status
}


#=============================================================
proc LOCK_AXIS_SUB { axis } {
#=============================================================
# called by SET_LOCK

  global mom_pos mom_lock_axis_value_defined mom_lock_axis_value

   if { $mom_lock_axis_value_defined == 1 } {
      return $mom_lock_axis_value
   } else {
      return $mom_pos($axis)
   }
}


#=============================================================
proc LOCK_AXIS__pb901 { input_point output_point output_rotary } {
#=============================================================
# called by LOCK_AXIS_MOTION & LINEARIZE_LOCK_MOTION

   upvar $input_point ip ; upvar $output_point op ; upvar $output_rotary or

   global mom_kin_machine_type
   global mom_kin_4th_axis_center_offset
   global mom_kin_5th_axis_center_offset
   global mom_sys_lock_value
   global mom_sys_lock_plane
   global mom_sys_lock_axis
   global mom_sys_unlocked_axis
   global mom_sys_4th_axis_index
   global mom_sys_5th_axis_index
   global mom_sys_linear_axis_index_1
   global mom_sys_linear_axis_index_2
   global mom_sys_rotary_axis_index
   global mom_kin_machine_resolution
   global mom_prev_lock_angle
   global mom_out_angle_pos
   global mom_prev_rot_ang_4th
   global mom_prev_rot_ang_5th
   global positive_radius
   global DEG2RAD
   global RAD2DEG
   global mom_kin_4th_axis_rotation
   global mom_kin_5th_axis_rotation

   if { ![info exists positive_radius] } { set positive_radius 0 }

   if { $mom_sys_rotary_axis_index == 3 } {
      if { ![info exists mom_prev_rot_ang_4th] } { set mom_prev_rot_ang_4th 0.0 }
      set mom_prev_lock_angle $mom_prev_rot_ang_4th
   } else {
      if { ![info exists mom_prev_rot_ang_5th] } { set mom_prev_rot_ang_5th 0.0 }
      set mom_prev_lock_angle $mom_prev_rot_ang_5th
   }

   if { ![info exists mom_kin_4th_axis_center_offset] } {
      set temp(0) $ip(0)
      set temp(1) $ip(1)
      set temp(2) $ip(2)
   } else {
      VEC3_sub ip mom_kin_4th_axis_center_offset temp
   }

   if { [info exists mom_kin_5th_axis_center_offset] } {
      VEC3_sub temp mom_kin_5th_axis_center_offset temp
   }

   set temp(3) $ip(3)
   set temp(4) $ip(4)

   if { $mom_sys_lock_axis > 2 } {
      set angle [expr ( $mom_sys_lock_value - $temp($mom_sys_lock_axis) )*$DEG2RAD]
      ROTATE_VECTOR $mom_sys_lock_plane $angle temp temp1
      VMOV 3 temp1 temp
      set temp($mom_sys_lock_axis) $mom_sys_lock_value
   } else {
      if { ![string compare $mom_sys_lock_plane $mom_sys_5th_axis_index] } {
         set angle [expr $temp(4)*$DEG2RAD]

         # <03-11-10 wbh> 6308668 Check the rotation mode
         if [string match "reverse" $mom_kin_5th_axis_rotation] {
            set angle [expr -$angle]
         }

         ROTATE_VECTOR $mom_sys_5th_axis_index $angle temp temp1
         VMOV 3 temp1 temp
         set temp(4) 0.0
      }

      #<09-06-13 Allen> Lock axis for 4-axis machine.
      if { [string match "4_axis_*" $mom_kin_machine_type] } {
         if { ![string compare $mom_sys_lock_plane $mom_sys_4th_axis_index] } {
            set angle [expr $temp(3) * $DEG2RAD]
            if [string match "reverse" $mom_kin_4th_axis_rotation] {
               set angle [expr -$angle]
            }

            ROTATE_VECTOR $mom_sys_4th_axis_index $angle temp temp1
            VMOV 3 temp1 temp
            set temp(3) 0.0
         }
      }

      set rad [expr sqrt( $temp($mom_sys_linear_axis_index_1) * $temp($mom_sys_linear_axis_index_1) +\
                          $temp($mom_sys_linear_axis_index_2) * $temp($mom_sys_linear_axis_index_2) )]
      set angle [ARCTAN $temp($mom_sys_linear_axis_index_2) $temp($mom_sys_linear_axis_index_1)]

      # <03-11-10 wbh> 6308668 Check the rotation mode
      if { ![string compare $mom_sys_lock_plane $mom_sys_5th_axis_index] } {
         if [string match "reverse" $mom_kin_5th_axis_rotation] {
            set angle [expr -$angle]
         }
      } elseif { ![string compare $mom_sys_lock_plane $mom_sys_4th_axis_index] } {
         if [string match "reverse" $mom_kin_4th_axis_rotation] {
            set angle [expr -$angle]
         }
      }

      if { $rad < [expr abs($mom_sys_lock_value) + $mom_kin_machine_resolution] } {
         if { $mom_sys_lock_value < 0.0 } {
            set temp($mom_sys_lock_axis) [expr -$rad]
         } else {
            set temp($mom_sys_lock_axis) $rad
         }
      } else {
         set temp($mom_sys_lock_axis) $mom_sys_lock_value
      }

      set temp($mom_sys_unlocked_axis)  [expr sqrt($rad*$rad - $temp($mom_sys_lock_axis)*$temp($mom_sys_lock_axis))]

      VMOV 5 temp temp1
      set temp1($mom_sys_unlocked_axis) [expr -$temp($mom_sys_unlocked_axis)]

      set ang1 [ARCTAN $temp($mom_sys_linear_axis_index_2) $temp($mom_sys_linear_axis_index_1)]
      set ang2 [ARCTAN $temp1($mom_sys_linear_axis_index_2) $temp1($mom_sys_linear_axis_index_1)]

      set temp($mom_sys_rotary_axis_index) [expr ($angle-$ang1)*$RAD2DEG]
      set temp1($mom_sys_rotary_axis_index) [expr ($angle-$ang2)*$RAD2DEG]

      set ang1 [LIMIT_ANGLE [expr $mom_prev_lock_angle - $temp($mom_sys_rotary_axis_index)]]
      set ang2 [LIMIT_ANGLE [expr $mom_prev_lock_angle - $temp1($mom_sys_rotary_axis_index)]]

      if { $ang1 > 180.0 } { set ang1 [LIMIT_ANGLE [expr -$ang1]] }
      if { $ang2 > 180.0 } { set ang2 [LIMIT_ANGLE [expr -$ang2]] }

      if { $positive_radius == 0 } {
         if { $ang1 > $ang2 } {
            VMOV 5 temp1 temp
            set positive_radius "-1"
         } else {
            set positive_radius "1"
         }
      } elseif { $positive_radius == -1 } {
         VMOV 5 temp1 temp
      }
   }

   if { [info exists mom_kin_4th_axis_center_offset] } {
      VEC3_add temp mom_kin_4th_axis_center_offset op
   } else {
      set op(0) $temp(0)
      set op(1) $temp(1)
      set op(2) $temp(2)
   }

   if { [info exists mom_kin_5th_axis_center_offset] } {
      VEC3_add op mom_kin_5th_axis_center_offset op
   }

   if { ![info exists or] } {
      set or(0) 0.0
      set or(1) 0.0
   }

   set mom_prev_lock_angle $temp($mom_sys_rotary_axis_index)
   set op(3) $temp(3)
   set op(4) $temp(4)
}


#=============================================================
proc MAXMIN_ANGLE { a max min {tol_flag 0} } {
#=============================================================
# pb_base -
#
   if { $tol_flag == 0 } { ;# Direct comparison

      while { $a < $min } { set a [expr $a + 360.0] }
      while { $a > $max } { set a [expr $a - 360.0] }

   } else { ;# Tolerant comparison

      while { [EQ_is_lt $a $min] } { set a [expr $a + 360.0] }
      while { [EQ_is_gt $a $max] } { set a [expr $a - 360.0] }
   }

return $a
}


#=============================================================
proc MCS_VECTOR { input_vector output_vector } {
#=============================================================
# This proc is used to transform vector from machine coordinate to work coordinate
#
   upvar $input_vector u ; upvar $output_vector v
   global mom_machine_mode
   global mom_kin_machine_type

   if {$mom_machine_mode != "MILL"} {
return
   }
   if {[string match "*3_axis*" $mom_kin_machine_type] || ![string match "*table*" $mom_kin_machine_type]} {
      VMOV 3 u v
   } else {
      global mom_kin_4th_axis_type mom_kin_5th_axis_type
      global mom_kin_4th_axis_vector mom_kin_5th_axis_vector
      global mom_out_angle_pos mom_pos DEG2RAD
      if {[info exists mom_kin_4th_axis_type] && [string match "Table" $mom_kin_4th_axis_type]} {
         set angle $mom_pos(3)*$DEG2RAD
         VECTOR_ROTATE mom_kin_4th_axis_vector $angle u v
         VMOV 3 v w
      } else {
         VMOV 3 u w
      }
      if {[info exists mom_kin_5th_axis_type] && [string match "Table" $mom_kin_5th_axis_type]} {
         set angle $mom_pos(4)*$DEG2RAD
         VECTOR_ROTATE mom_kin_5th_axis_vector $angle w v
      }
   }
}


#=============================================================
proc OPERATOR_MSG { msg {seq_no 0} } {
#=============================================================
# pb_base -
#
# This command will output a single or a set of operator message(s).
#
#   msg    : Message(s separated by new-line character)
#   seq_no : 0 Output message without sequence number (Default)
#            1 Output message with sequence number
#

   foreach s [split $msg \n] {
      set s1 "$::mom_sys_control_out $s $::mom_sys_control_in"
      if { [string length $s] > 0 } {
         if { !$seq_no } {
            MOM_suppress once N
            MOM_output_literal $s1
         } else {
            MOM_output_literal $s1
         }
      }
   }

   set ::mom_o_buffer ""
}


#=============================================================
proc PAUSE { args } {
#=============================================================
# pb_base -
#
# Revisions:
#-----------
# 05-19-10 gsl - Use EXEC command
#

   global env

   if { [info exists env(PB_SUPPRESS_UGPOST_DEBUG)]  &&  $env(PB_SUPPRESS_UGPOST_DEBUG) == 1 } {
  return
   }


   global gPB

   if { [info exists gPB(PB_disable_MOM_pause)]  &&  $gPB(PB_disable_MOM_pause) == 1 } {
  return
   }


   global tcl_platform

   set cam_aux_dir  [MOM_ask_env_var UGII_CAM_AUXILIARY_DIR]

   if { [string match "*windows*" $tcl_platform(platform)] } {
      set ug_wish "ugwish.exe"
   } else {
      set ug_wish ugwish
   }

   if { [file exists ${cam_aux_dir}$ug_wish]  &&  [file exists ${cam_aux_dir}mom_pause.tcl] } {

      set title ""
      set msg ""

      if { [llength $args] == 1 } {
         set msg [lindex $args 0]
      }

      if { [llength $args] > 1 } {
         set title [lindex $args 0]
         set msg [lindex $args 1]
      }

      set command_string [concat \"${cam_aux_dir}$ug_wish\" \"${cam_aux_dir}mom_pause.tcl\" \"$title\" \"$msg\"]

      set res [EXEC $command_string]


      switch [string trim $res] {
         no {
            set gPB(PB_disable_MOM_pause) 1
         }
         cancel {
            set gPB(PB_disable_MOM_pause) 1

            uplevel #0 {
               MOM_abort "*** User Abort Post Processing *** "
            }
         }
         default {
            return
         }
      }

   } else {

      CATCH_WARNING "PAUSE not executed -- \"$ug_wish\" or \"mom_pause.tcl\" not found"
   }
}


#=============================================================
proc PAUSE_win64 { args } {
#=============================================================
# pb_base -
#
   global env
   if { [info exists env(PB_SUPPRESS_UGPOST_DEBUG)]  &&  $env(PB_SUPPRESS_UGPOST_DEBUG) == 1 } {
  return
   }

   global gPB
   if { [info exists gPB(PB_disable_MOM_pause)]  &&  $gPB(PB_disable_MOM_pause) == 1 } {
  return
   }


   set cam_aux_dir  [MOM_ask_env_var UGII_CAM_AUXILIARY_DIR]
   set ug_wish "ugwish.exe"

   if { [file exists ${cam_aux_dir}$ug_wish] &&\
        [file exists ${cam_aux_dir}mom_pause_win64.tcl] } {

      set title ""
      set msg ""

      if { [llength $args] == 1 } {
         set msg [lindex $args 0]
      }

      if { [llength $args] > 1 } {
         set title [lindex $args 0]
         set msg [lindex $args 1]
      }


     ######
     # Define a scratch file and pass it to mom_pause_win64.tcl script -
     #
     #   A separated process will be created to construct the Tk dialog.
     #   This process will communicate with the main process via the state of a scratch file.
     #   This scratch file will collect the messages that need to be conveyed from the
     #   child process to the main process.
     ######
      global mom_logname
      set pause_file_name "$env(TEMP)/${mom_logname}_mom_pause_[clock clicks].txt"


     ######
     # Path names should be per unix style for "open" command
     ######
      regsub -all {\\} $pause_file_name {/}  pause_file_name
      regsub -all { }  $pause_file_name {\ } pause_file_name
      regsub -all {\\} $cam_aux_dir {/}  cam_aux_dir
      regsub -all { }  $cam_aux_dir {\ } cam_aux_dir

      if [file exists $pause_file_name] {
         file delete -force $pause_file_name
      }


     ######
     # Note that the argument order for mom_pasue.tcl has been changed
     # The assumption at this point is we will always have the communication file as the first
     # argument and optionally the title and message as the second and third arguments
     ######
      open "|${cam_aux_dir}$ug_wish ${cam_aux_dir}mom_pause_win64.tcl ${pause_file_name} {$title} {$msg}"


     ######
     # Waiting for the mom_pause to complete its process...
     # - This is indicated when the scratch file materialized and became read-only.
     ######
      while { ![file exists $pause_file_name] || [file writable $pause_file_name] } { }


     ######
     # Delay a 100 milli-seconds to ensure that sufficient time is given for the other process to complete.
     ######
      after 100


     ######
     # Open the scratch file to read and process the information.  Close it afterward.
     ######
      set fid [open "$pause_file_name" r]

      set res [string trim [gets $fid]]
      switch $res {
         no {
            set gPB(PB_disable_MOM_pause) 1
         }
         cancel {
            close $fid
            file delete -force $pause_file_name

            set gPB(PB_disable_MOM_pause) 1

            uplevel #0 {
               MOM_abort "*** User Abort Post Processing *** "
            }
         }
         default {}
      }


     ######
     # Delete the scratch file
     ######
      close $fid
      file delete -force $pause_file_name
   }
}


#=============================================================
proc PAUSE_x { args } {
#=============================================================
# pb_base -
#
   global env
   if { [info exists env(PB_SUPPRESS_UGPOST_DEBUG)]  &&  $env(PB_SUPPRESS_UGPOST_DEBUG) == 1 } {
  return
   }

   global gPB
   if { [info exists gPB(PB_disable_MOM_pause)]  &&  $gPB(PB_disable_MOM_pause) == 1 } {
  return
   }



  #==========
  # Win64 OS
  #
   global tcl_platform

   if { [string match "*windows*" $tcl_platform(platform)] } {
      global mom_sys_processor_archit

      if { ![info exists mom_sys_processor_archit] } {
         set pVal ""
         set env_vars [array get env]
         set idx [lsearch $env_vars "PROCESSOR_ARCHITE*"]
         if { $idx >= 0 } {
            set pVar [lindex $env_vars $idx]
            set pVal [lindex $env_vars [expr $idx + 1]]
         }
         set mom_sys_processor_archit $pVal
      }

      if { [string match "*64*" $mom_sys_processor_archit] } {

         PAUSE_win64 $args
  return
      }
   }



   set cam_aux_dir  [MOM_ask_env_var UGII_CAM_AUXILIARY_DIR]


   if { [string match "*windows*" $tcl_platform(platform)] } {
     set ug_wish "ugwish.exe"
   } else {
     set ug_wish ugwish
   }

   if { [file exists ${cam_aux_dir}$ug_wish] && [file exists ${cam_aux_dir}mom_pause.tcl] } {

      set title ""
      set msg ""

      if { [llength $args] == 1 } {
         set msg [lindex $args 0]
      }

      if { [llength $args] > 1 } {
         set title [lindex $args 0]
         set msg [lindex $args 1]
      }

      set res [exec ${cam_aux_dir}$ug_wish ${cam_aux_dir}mom_pause.tcl $title $msg]
      switch $res {
         no {
            set gPB(PB_disable_MOM_pause) 1
         }
         cancel {
            set gPB(PB_disable_MOM_pause) 1

            uplevel #0 {
               MOM_abort "*** User Abort Post Processing *** "
            }
         }
         default { return }
      }
   }
}


#=============================================================
proc PREFERRED_SOLUTION { } {
#=============================================================
# To be called by PB_CMD_kin_before_motion
# ==> Perhaps, after the 4-axis output validation!
# ==> Not yet released officially
#
#  UDE "Set Preferred Solution" can be specified with the operation in question.
#  This event will be handled before "Lock Axis" to choose, possibly,
#  the alternate solution of a 5-axis motion based on the perferred
#  delimiter (mom_preferred_zone_flag) such as X/Y-plus(or minus) or
#  4th/5th-angle etc. Choices can be
#
#    [XPLUS | XMINUS | YPLUS | YMINUS | FOURTH | FIFTH].
#
#
#  => Should this flag be in effect forever until cancelled by
#     another instance of the same UDE that turns it off?
#  => Initial rotary angle can be influenced by using a "Rotate" UDE.
#
#
   if [CMD_EXIST PB_CMD__choose_preferred_solution] {
      PB_CMD__choose_preferred_solution
   }
}


#=============================================================
proc REPOSITION_ERROR_CHECK { warn } {
#=============================================================
# not called in this script

   global mom_kin_4th_axis_max_limit mom_kin_4th_axis_min_limit
   global mom_kin_5th_axis_max_limit mom_kin_5th_axis_min_limit
   global mom_pos mom_prev_pos mom_alt_pos mom_alt_prev_pos
   global mom_sys_rotary_error mom_warning_info mom_kin_machine_type

   if { [string compare "secondary rotary position being used" $warn] || [string index $mom_kin_machine_type 0] != 5 } {
      set mom_sys_rotary_error $warn
return
   }

   set mom_sys_rotary_error 0

   set a4 [expr $mom_alt_pos(3)+360.0]
   set a5 [expr $mom_alt_pos(4)+360.0]

   while { [expr $a4-$mom_kin_4th_axis_min_limit] > 360.0 } { set a4 [expr $a4-360.0] }
   while { [expr $a5-$mom_kin_5th_axis_min_limit] > 360.0 } { set a5 [expr $a5-360.0] }

   if { $a4 <= $mom_kin_4th_axis_max_limit && $a5 <= $mom_kin_5th_axis_max_limit } {
return
   }

   for { set i 0 } { $i < 2 } { incr i } {
      set rot($i) [expr $mom_pos([expr $i+3]) - $mom_prev_pos([expr $i+3])]
      while { $rot($i) > 180.0 } { set rot($i) [expr $rot($i)-360.0] }
      while { $rot($i) < 180.0 } { set rot($i) [expr $rot($i)+360.0] }
      set rot($i) [expr abs($rot($i))]

      set rotalt($i) [expr $mom_alt_pos([expr $i+3]) - $mom_prev_pos([expr $i+3])]
      while { $rotalt($i) > 180.0 } { set rotalt($i) [expr $rotalt($i)-360.0] }
      while { $rotalt($i) < 180.0 } { set rotalt($i) [expr $rotalt($i)+360.0] }
      set rotalt($i) [expr abs($rotalt($i))]
   }

   if { [EQ_is_equal [expr $rot(0)+$rot(1)] [expr $rotalt(0)+$rotalt(1)]] } {
return
   }

   set mom_sys_rotary_error $warn
}


#=============================================================
proc RESET_ROTARY_SIGN { ang pre_ang axis } {
#=============================================================
# Called by ROTARY_AXIS_RETRACT
#
# The input parameters "ang" & "pre_ang" must use same unit. (Both in degree or radian)

   global mom_kin_4th_axis_direction mom_kin_5th_axis_direction
   global mom_kin_4th_axis_rotation mom_kin_5th_axis_rotation
   global mom_rotary_direction_4th mom_rotary_direction_5th

   set abs_ang [expr abs($ang)]
   set abs_pre [expr abs($pre_ang)]
   if { $axis == 3 && ![string compare "SIGN_DETERMINES_DIRECTION" $mom_kin_4th_axis_direction] } {
    # The fourth axis.
      if { $abs_ang > $abs_pre } {
         set mom_rotary_direction_4th 1
      } elseif { $abs_ang < $abs_pre } {
         set mom_rotary_direction_4th -1
      }
   } elseif { $axis == 4 && ![string compare "SIGN_DETERMINES_DIRECTION" $mom_kin_5th_axis_direction] } {
    # The fifth axis.
      if { $abs_ang > $abs_pre } {
         set mom_rotary_direction_5th 1
      } elseif { $abs_ang < $abs_pre } {
         set mom_rotary_direction_5th -1
      }
   }
}


#=============================================================
proc RETRACT_POINT_CHECK { refpt axis retpt } {
#=============================================================
# called by CALC_SPHERICAL_RETRACT_POINT & CALC_CYLINDRICAL_RETRACT_POINT

  upvar $refpt rfp ; upvar $axis ax ; upvar $retpt rtp

#
#  determine if retraction point is "below" the retraction plane
#  if the tool is already in a safe position, do not retract
#
#  return 0    no retract needed
#         1     retraction needed
#

   VEC3_sub rtp rfp vec
   if { [VEC3_is_zero vec] } {
return 0
   }

   set x [VEC3_unitize vec vec1]
   set dir [VEC3_dot ax vec1]

   if { $dir <= 0.0 } {
return 0
   } else {
return 1
   }
}


#=============================================================
proc ROTARY_AXIS_RETRACT { } {
#=============================================================
# called by PB_CMD_kin_before_motion

#  This command is used by four and five axis posts to retract
#  from the part when the rotary axis become discontinuous.  This
#  command is activated by setting the axis limit violation
#  action to "retract / re-engage".
#

  #(pb903) Removed restriction below; command may be used in other situations
  # Must be called by PB_CMD_kin_before_motion
  if 0 {
   if { ![CALLED_BY "PB_CMD_kin_before_motion"] } {
 return
   }
  }

   global mom_sys_rotary_error
   global mom_motion_event


   if { ![info exists mom_sys_rotary_error] } {
return
   }

   set rotary_error_code $mom_sys_rotary_error

  # Make sure mom_sys_rotary_error is always unset.
   unset mom_sys_rotary_error


   if { [info exists mom_motion_event] } {
      if { $rotary_error_code != 0 && ![string compare "linear_move" $mom_motion_event] } {
        #<06-25-12 gsl> The above conditions have been checked in PB_CMD_kin_before_motion already.
        #               We should consider removing these conditions for performance sake!!!
         global mom_kin_reengage_distance
         global mom_kin_rotary_reengage_feedrate
         global mom_kin_rapid_feed_rate
         global mom_pos
         global mom_prev_pos
         global mom_prev_rot_ang_4th mom_prev_rot_ang_5th
         global mom_kin_4th_axis_direction mom_kin_4th_axis_leader
         global mom_out_angle_pos mom_kin_5th_axis_direction mom_kin_5th_axis_leader
         global mom_kin_4th_axis_center_offset mom_kin_5th_axis_center_offset
         global mom_sys_leader mom_tool_axis mom_prev_tool_axis mom_kin_4th_axis_type
         global mom_kin_spindle_axis
         global mom_alt_pos mom_prev_alt_pos mom_feed_rate
         global mom_kin_rotary_reengage_feedrate
         global mom_feed_engage_value mom_feed_cut_value
         global mom_kin_4th_axis_limit_action mom_warning_info
         global mom_kin_4th_axis_min_limit mom_kin_4th_axis_max_limit
         global mom_kin_5th_axis_min_limit mom_kin_5th_axis_max_limit

        #
        #  Check for the limit action being warning only.  If so, issue warning and leave
        #
         if { ![string compare "Warning" $mom_kin_4th_axis_limit_action] } {
            CATCH_WARNING "Rotary axis limit violated, discontinuous motion may result."

            return

         } elseif { ![string compare "User Defined" $mom_kin_4th_axis_limit_action] } {
          #<04-17-09 wbh> add the case for user defined
            PB_user_def_axis_limit_action

            return
         }

        #
        #  The previous rotary info is only available after the first motion.
        #
         if { ![info exists mom_prev_rot_ang_4th] } {
            set mom_prev_rot_ang_4th [MOM_ask_address_value fourth_axis]
         }
         if { ![info exists mom_prev_rot_ang_5th] } {
            set mom_prev_rot_ang_5th [MOM_ask_address_value fifth_axis]
         }

        #
        #  Determine the type of rotary violation encountered.  There are
        #  three distinct possibilities.
        #
        #  "ROTARY CROSSING LIMIT" and a four axis machine tool.  The fourth
        #      axis will be repositioned by either +360 or -360 before
        #      re-engaging. (roterr = 0)
        #
        #  "ROTARY CROSSING LIMIT" and a five axis machine tool.  There are two
        #      possible solutions.  If the axis that crossed a limit can be
        #      repositioned by adding or subtracting 360, then that solution
        #      will be used.  (roterr = 0) If there is only one position available and it is
        #      not in the valid travel limits, then the alternate position will
        #      be tested.  If valid, then the "secondary rotary position being used"
        #      method will be used. (roterr = 2)
        #      If the aternate position cannot be used a warning will be given.
        #
        #  "secondary rotary position being used".  Can only occur with a five
        #      axis machine tool.  The tool will reposition to the alternate
        #      current rotary position and re-engage to the alternate current
        #      linear position.  (roterr = 1)
        #
        #
        #    roterr = 0 :
        #      Rotary Reposition : mom_prev_pos(3,4) +- 360
        #      Linear Re-Engage :  mom_prev_pos(0,1,2)
        #      Final End Point :   mom_pos(0-4)
        #
        #    roterr = 1 :
        #      Rotary Reposition : mom_prev_alt_pos(3,4)
        #      Linear Re-Engage :  mom_prev_alt_pos(0,1,2)
        #      Final End Point :   mom_pos(0-4)
        #
        #    roterr = 2 :
        #      Rotary Reposition : mom_prev_alt_pos(3,4)
        #      Linear Re-Engage :  mom_prev_alt_pos(0,1,2)
        #      Final End Point :   mom_alt_pos(0-4)
        #
        #    For all cases, a warning will be given if it is not possible to
        #    to cut from the re-calculated previous position to move end point.
        #    For all valid cases the tool will, retract from the part, reposition
        #    the rotary axis and re-engage back to the part.
        #

         if { ![string compare "ROTARY CROSSING LIMIT." $rotary_error_code] } {
            global mom_kin_machine_type

            set machine_type [string tolower $mom_kin_machine_type]
            switch $machine_type {
               5_axis_dual_table -
               5_axis_dual_head  -
               5_axis_head_table {

                  set d [expr $mom_out_angle_pos(0) - $mom_prev_rot_ang_4th]

                  if { [expr abs($d)] > 180.0 } {
                     set min $mom_kin_4th_axis_min_limit
                     set max $mom_kin_4th_axis_max_limit
                     if { $d > 0.0 } {
                        set ang [expr $mom_prev_rot_ang_4th + 360.0]
                     } else {
                        set ang [expr $mom_prev_rot_ang_4th - 360.0]
                     }
                  } else {
                     set min $mom_kin_5th_axis_min_limit
                     set max $mom_kin_5th_axis_max_limit
                     set d [expr $mom_out_angle_pos(1) - $mom_prev_rot_ang_5th]
                     if { $d > 0.0 } {
                        set ang [expr $mom_prev_rot_ang_5th + 360.0]
                     } else {
                        set ang [expr $mom_prev_rot_ang_5th - 360.0]
                     }
                  }

                  if { $ang >= $min && $ang <= $max } { ;# ==> 5th axis min/max will be used here(?)
                     set roterr 0
                  } else {
                     set roterr 2
                  }
               }

               default { set roterr 0 }
            }
         } else {

            set roterr 1
         }

        #
        #  Retract from part
        #
         VMOV 5 mom_pos save_pos
         VMOV 5 mom_prev_pos save_prev_pos
         VMOV 2 mom_out_angle_pos save_out_angle_pos
         set save_feedrate $mom_feed_rate

         global mom_kin_output_unit mom_part_unit
         if { ![string compare $mom_kin_output_unit $mom_part_unit] } {
            set mom_sys_unit_conversion "1.0"
         } elseif { ![string compare "IN" $mom_kin_output_unit] } {
            set mom_sys_unit_conversion [expr 1.0/25.4]
         } else {
            set mom_sys_unit_conversion 25.4
         }

        #<01-07-10 wbh> Fix pr6192146.
        # Declare/Set the variables used to convert the feed rate from MMPR/IPR to MMPM/IPM.
         global mom_spindle_rpm
         global mom_feed_approach_unit mom_feed_cut_unit
         global mom_feed_engage_unit mom_feed_retract_unit
         set mode_convert_scale "1.0"
         if { [info exists mom_spindle_rpm] && [EQ_is_gt $mom_spindle_rpm 0.0] } {
            set mode_convert_scale $mom_spindle_rpm
         }

         global mom_sys_spindle_axis
         GET_SPINDLE_AXIS mom_prev_tool_axis

         global mom_kin_retract_type
         global mom_kin_retract_distance
         global mom_kin_retract_plane

         if { ![info exists mom_kin_retract_distance] } {
            if { [info exists mom_kin_retract_plane] } {
              # Convert legacy variable
               set mom_kin_retract_distance $mom_kin_retract_plane
            } else {
               set mom_kin_retract_distance 10.0
            }
         }

         if { ![info exists mom_kin_retract_type] } {
            set mom_kin_retract_type "DISTANCE"
         }

        #
        #  Pre-release type conversion
        #
         if { [string match "PLANE" $mom_kin_retract_type] } {
            set mom_kin_retract_type "SURFACE"
         }

         switch $mom_kin_retract_type {
            SURFACE {
               set cen(0) 0.0
               set cen(1) 0.0
               set cen(2) 0.0
               if { [info exists mom_kin_4th_axis_center_offset] } {
                  VEC3_add cen mom_kin_4th_axis_center_offset cen
               }

               if { ![string compare "Table" $mom_kin_4th_axis_type] } {
                  set num_sol [CALC_CYLINDRICAL_RETRACT_POINT mom_prev_pos mom_kin_spindle_axis\
                                                              $mom_kin_retract_distance ret_pt]
               } else {
                  set num_sol [CALC_SPHERICAL_RETRACT_POINT   mom_prev_pos mom_prev_tool_axis cen\
                                                              $mom_kin_retract_distance ret_pt]
               }
               if {$num_sol != 0} {VEC3_add ret_pt cen mom_pos}
            }

            DISTANCE -
            default {
               set mom_pos(0) [expr $mom_prev_pos(0) + $mom_kin_retract_distance*$mom_sys_spindle_axis(0)]
               set mom_pos(1) [expr $mom_prev_pos(1) + $mom_kin_retract_distance*$mom_sys_spindle_axis(1)]
               set mom_pos(2) [expr $mom_prev_pos(2) + $mom_kin_retract_distance*$mom_sys_spindle_axis(2)]
               set num_sol 1
            }
         }


         global mom_motion_distance
         global mom_feed_rate_number
         global mom_feed_retract_value
         global mom_feed_approach_value


         set dist [expr $mom_kin_reengage_distance*2.0]

         if { $num_sol != 0 } {

        #
        #  Retract from the part at rapid feed rate.  This is the same for all conditions.
        #
            MOM_suppress once fourth_axis fifth_axis
            set mom_feed_rate [expr $mom_feed_retract_value*$mom_sys_unit_conversion]
           #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
            if { [info exists mom_feed_retract_unit] && [string match "*pr" $mom_feed_retract_unit] } {
               set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
            }
            if { [EQ_is_equal $mom_feed_rate 0.0] } {
               set mom_feed_rate [expr $mom_kin_rapid_feed_rate*$mom_sys_unit_conversion]
            }
            VEC3_sub mom_pos mom_prev_pos del_pos
            set dist [VEC3_mag del_pos]

           #<03-13-08 gsl> Replaced next call
           # global mom_sys_frn_factor
           # set mom_feed_rate_number [expr ($mom_sys_frn_factor*$mom_feed_rate)/ $dist]
            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $dist $mom_feed_rate]
            FEEDRATE_SET
            set retract "yes"
         } else {
            CATCH_WARNING "Retraction geometry is defined inside of the current point.\n\
                           No retraction will be output. Set the retraction distance to a greater value."
            set retract "no"
         }

         if { $roterr == 0 } {
#
#  This section of code handles the case where a limit forces a reposition to an angle
#  by adding or subtracting 360 until the new angle is within the limits.
#  This is either a four axis case or a five axis case where it is not a problem
#  with the inverse kinematics forcing a change of solution.
#  This is only a case of "unwinding" the table.
#
            if { ![string compare "yes"  $retract] } {
               PB_CMD_retract_move
            }

           #
           #  Move to previous rotary position
           #  <04-01-2013 gsl> mom_rev_pos(3,4) may have not been affected, we may just borrow them
           #                   as mom_out_angle_pos for subsequent output instead of recomputing them thru ROTSET(?)
           #
            if { [info exists mom_kin_4th_axis_direction] } {
               set mom_out_angle_pos(0) [ROTSET $mom_prev_pos(3) $mom_out_angle_pos(0) $mom_kin_4th_axis_direction\
                                                $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                                $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]
            }
            if { [info exists mom_kin_5th_axis_direction] } {
               set mom_out_angle_pos(1) [ROTSET $mom_prev_pos(4) $mom_out_angle_pos(1) $mom_kin_5th_axis_direction\
                                                $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                                $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]
            }

            PB_CMD_reposition_move

           #
           #  Position back to part at approach feed rate
           #
            GET_SPINDLE_AXIS mom_prev_tool_axis
            for { set i 0 } { $i < 3 } { incr i } {
               set mom_pos($i) [expr $mom_prev_pos($i) + $mom_kin_reengage_distance * $mom_sys_spindle_axis($i)]
            }
            set mom_feed_rate [expr $mom_feed_approach_value * $mom_sys_unit_conversion]
           #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
            if { [info exists mom_feed_approach_unit] && [string match "*pr" $mom_feed_approach_unit] } {
               set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
            }
            if { [EQ_is_equal $mom_feed_rate 0.0] } {
               set mom_feed_rate [expr $mom_kin_rapid_feed_rate*$mom_sys_unit_conversion]
            }
            set dist [expr $dist-$mom_kin_reengage_distance]
            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $dist $mom_feed_rate]
            FEEDRATE_SET
            MOM_suppress once fourth_axis fifth_axis
            PB_CMD_linear_move

           #
           #  Feed back to part at engage feed rate
           #
            MOM_suppress once fourth_axis fifth_axis
            if { $mom_feed_engage_value  > 0.0 } {
               set mom_feed_rate [expr $mom_feed_engage_value*$mom_sys_unit_conversion]
              #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
               if { [info exists mom_feed_engage_unit] && [string match "*pr" $mom_feed_engage_unit] } {
                  set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
               }
            } elseif { $mom_feed_cut_value  > 0.0 } {
               set mom_feed_rate [expr $mom_feed_cut_value*$mom_sys_unit_conversion]
              #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
               if { [info exists mom_feed_cut_unit] && [string match "*pr" $mom_feed_cut_unit] } {
                  set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
               }
            } else {
               set mom_feed_rate [expr 10.0*$mom_sys_unit_conversion]
            }

            VEC3_sub mom_pos mom_prev_pos del_pos
            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $mom_kin_reengage_distance $mom_feed_rate]
            FEEDRATE_SET
            VMOV 3 mom_prev_pos mom_pos
            PB_CMD_linear_move

            VEC3_sub mom_pos save_pos del_pos
            set dist [VEC3_mag del_pos]
            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $dist $mom_feed_rate]
            FEEDRATE_SET

            VMOV 5 save_pos mom_pos
            VMOV 5 save_prev_pos mom_prev_pos
            VMOV 2 save_out_angle_pos mom_out_angle_pos

         } else {
#
#  This section of code handles the case where there are two solutions to the tool axis inverse kinematics.
#  The post is forced to change from one solution to the other.  This causes a discontinuity in the tool path.
#  The post needs to retract, rotate to the new rotaries, then position back to the part using the alternate
#  solution.
#
            #
            #  Check for rotary axes in limits before retracting
            #
            set res [ANGLE_CHECK mom_prev_alt_pos(3) 4]
            if { $res == 1 } {
               set mom_out_angle_pos(0) [ROTSET $mom_prev_alt_pos(3) $mom_prev_rot_ang_4th $mom_kin_4th_axis_direction\
                                                $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                                $mom_kin_4th_axis_min_limit  $mom_kin_4th_axis_max_limit 1]
            } elseif { $res == 0 } {
               set mom_out_angle_pos(0) $mom_prev_alt_pos(3)
            } else {
               CATCH_WARNING "Not possible to position to alternate rotary axis positions. Gouging may result"
               VMOV 5 save_pos mom_pos

             return
            }

            set res [ANGLE_CHECK mom_prev_alt_pos(4) 5]
            if { $res == 1 } {
               set mom_out_angle_pos(1) [ROTSET $mom_prev_alt_pos(4) $mom_prev_rot_ang_5th $mom_kin_5th_axis_direction\
                                                $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                                $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit 1]
            } elseif { $res == 0 } {
               set mom_out_angle_pos(1) $mom_prev_alt_pos(4)
            } else {
               CATCH_WARNING "Not possible to position to alternate rotary axis positions. Gouging may result"
               VMOV 5 save_pos mom_pos

             return
            }

            set mom_prev_pos(3) $mom_pos(3)
            set mom_prev_pos(4) $mom_pos(4)
            FEEDRATE_SET

            if { ![string compare "yes" $retract] } { PB_CMD_retract_move }
           #
           #  Move to alternate rotary position
           #
            set mom_pos(3) $mom_prev_alt_pos(3)
            set mom_pos(4) $mom_prev_alt_pos(4)
            set mom_prev_rot_ang_4th $mom_out_angle_pos(0)
            set mom_prev_rot_ang_5th $mom_out_angle_pos(1)
            VMOV 3 mom_prev_pos mom_pos
            FEEDRATE_SET
            PB_CMD_reposition_move

           #
           #  Position back to part at approach feed rate
           #
            set mom_prev_pos(3) $mom_pos(3)
            set mom_prev_pos(4) $mom_pos(4)
            for { set i 0 } { $i < 3 } { incr i } {
              set mom_pos($i) [expr $mom_prev_alt_pos($i)+$mom_kin_reengage_distance*$mom_sys_spindle_axis($i)]
            }
            MOM_suppress once fourth_axis fifth_axis
            set mom_feed_rate [expr $mom_feed_approach_value*$mom_sys_unit_conversion]

           #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
            if { [info exists mom_feed_approach_unit] && [string match "*pr" $mom_feed_approach_unit] } {
               set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
            }
            if { [EQ_is_equal $mom_feed_rate 0.0] } {
              set mom_feed_rate [expr $mom_kin_rapid_feed_rate * $mom_sys_unit_conversion]
            }
            set dist [expr $dist-$mom_kin_reengage_distance]
            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $dist $mom_feed_rate]
            FEEDRATE_SET
            PB_CMD_linear_move

           #
           #  Feed back to part at engage feed rate
           #
            MOM_suppress once fourth_axis fifth_axis
            if { $mom_feed_engage_value  > 0.0 } {
               set mom_feed_rate [expr $mom_feed_engage_value*$mom_sys_unit_conversion]
              #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
               if { [info exists mom_feed_engage_unit] && [string match "*pr" $mom_feed_engage_unit] } {
                  set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
               }
            } elseif { $mom_feed_cut_value  > 0.0 } {
               set mom_feed_rate [expr $mom_feed_cut_value*$mom_sys_unit_conversion]
              #<01-07-10 wbh> Convert the feed rate from MMPR/IPR to MMPM/IPM
               if { [info exists mom_feed_cut_unit] && [string match "*pr" $mom_feed_cut_unit] } {
                  set mom_feed_rate [expr $mom_feed_rate * $mode_convert_scale]
               }
            } else {
              # ???
               set mom_feed_rate [expr 10.0*$mom_sys_unit_conversion]
            }

            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $mom_kin_reengage_distance $mom_feed_rate]
            VMOV 3 mom_prev_alt_pos mom_pos
            FEEDRATE_SET
            PB_CMD_linear_move

            VEC3_sub mom_pos save_pos del_pos
            set dist [VEC3_mag del_pos]
            if { $dist <= 0.0 } { set dist $mom_kin_reengage_distance }
            set mom_feed_rate_number [SET_FEEDRATE_NUMBER $dist $mom_feed_rate]
            FEEDRATE_SET

            if { $roterr == 2 } {
               VMOV 5 mom_alt_pos mom_pos
            } else {
               VMOV 5 save_pos mom_pos
            }

           #<01-07-10 wbh> Reset the rotary sign
            RESET_ROTARY_SIGN $mom_pos(3) $mom_out_angle_pos(0) 3
            RESET_ROTARY_SIGN $mom_pos(4) $mom_out_angle_pos(1) 4

            set mom_out_angle_pos(0) [ROTSET $mom_pos(3) $mom_out_angle_pos(0) $mom_kin_4th_axis_direction\
                                             $mom_kin_4th_axis_leader mom_sys_leader(fourth_axis)\
                                             $mom_kin_4th_axis_min_limit $mom_kin_4th_axis_max_limit]
            set mom_out_angle_pos(1) [ROTSET $mom_pos(4) $mom_out_angle_pos(1) $mom_kin_5th_axis_direction\
                                             $mom_kin_5th_axis_leader mom_sys_leader(fifth_axis)\
                                             $mom_kin_5th_axis_min_limit $mom_kin_5th_axis_max_limit]

            MOM_reload_variable -a mom_out_angle_pos
            MOM_reload_variable -a mom_pos
            MOM_reload_variable -a mom_prev_pos
         }

         set mom_feed_rate $save_feedrate
         FEEDRATE_SET
      }
   }
}


#=============================================================
proc ROTATE_VECTOR { plane angle input_vector output_vector } {
#=============================================================
# Called by LOCK_AXIS & UNLOCK_AXIS

  upvar $output_vector v ; upvar $input_vector v1

   switch $plane {
      0 {
         set v(0) $v1(0)
         set v(1) [expr $v1(1)*cos($angle) - $v1(2)*sin($angle)]
         set v(2) [expr $v1(2)*cos($angle) + $v1(1)*sin($angle)]
      }

      1 {
         set v(0) [expr $v1(0)*cos($angle) + $v1(2)*sin($angle)]
         set v(1) $v1(1)
         set v(2) [expr $v1(2)*cos($angle) - $v1(0)*sin($angle)]
      }

      default {
         set v(0) [expr $v1(0)*cos($angle) - $v1(1)*sin($angle)]
         set v(1) [expr $v1(1)*cos($angle) + $v1(0)*sin($angle)]
         set v(2) $v1(2)
      }
   }
}


#=============================================================
proc ROTSET { angle prev_angle dir kin_leader sys_leader min max {tol_flag 0} } {
#=============================================================
#  This command will take an input angle and format for a specific machine.
#  It will also validate that the angle is within the specified limits of
#  machine.
#
#  angle        angle to be output.
#  prev_angle   previous angle output.  It should be mom_out_angle_pos
#  dir          can be either MAGNITUDE_DETERMINES_DIRECTION or
#               SIGN_DETERMINES_DIRECTION
#  kin_leader   leader (usually A, B or C) defined by Post Builder
#  sys_leader   leader that is created by ROTSET.  It could be "C-".
#  min          minimum degrees of travel for current axis
#  max          maximum degrees of travel for current axis
#
#  tol_flag     performance comparison with tolerance
#                 0 : No (default)
#                 1 : Yes
#
#
# - This command is called by the following functions:
#   RETRACT_ROTARY_AXIS, LOCK_AXIS_MOTION, LINEARIZE_LOCK_OUTPUT,
#   MOM_rotate, LINEARIZE_OUTPUT and MILL_TURN.
#
#=============================================================
# Revisions
# 02-25-2009 mzg - Added optional argument tol_flag to allow
#                  performing comparisions with tolerance
# 03-13-2012 gsl - (pb850) LIMIT_ANGLE should be called by using its return value
#                - Allow comparing max/min with tolerance
# 10-27-2015 gsl - Initialize mom_rotary_direction_4th & mom_rotary_direction_5th
#=============================================================

   upvar $sys_leader lead

  #
  #  Make sure angle is 0~360 to start with.
  #
   set angle [LIMIT_ANGLE $angle]
   set check_solution 0

   if { ![string compare "MAGNITUDE_DETERMINES_DIRECTION" $dir] } {

   #
   #  If magnitude determines direction and total travel is less than or equal
   #  to 360, we can assume there is at most one valid solution.  Find it and
   #  leave.  Check for the total travel being less than 360 and give a warning
   #  if a valid position cannot be found.
   #
      set travel [expr abs($max - $min)]

      if { $travel <= 360.0 } {

         set check_solution 1

      } else {

         if { $tol_flag == 0 } { ;# Exact comparison
            while { [expr abs([expr $angle - $prev_angle])] > 180.0 } {
               if { [expr $angle - $prev_angle] < -180.0 } {
                  set angle [expr $angle + 360.0]
               } elseif { [expr $angle - $prev_angle] > 180.0 } {
                  set angle [expr $angle - 360.0]
               }
            }
         } else { ;# Tolerant comparison
            while { [EQ_is_gt [expr abs([expr $angle - $prev_angle])] 180.0] } {
               if { [EQ_is_lt [expr $angle - $prev_angle] -180.0] } {
                  set angle [expr $angle + 360.0]
               } elseif { [EQ_is_gt [expr $angle - $prev_angle] 180.0] } {
                  set angle [expr $angle - 360.0]
               }
            }
         }
      }

      #<03-13-12 gsl> Fit angle within limits
      if { $tol_flag == 1 } { ;# Tolerant comparison
         while { [EQ_is_lt $angle $min] } { set angle [expr $angle + 360.0] }
         while { [EQ_is_gt $angle $max] } { set angle [expr $angle - 360.0] }
      } else { ;# Legacy direct comparison
         while { $angle < $min } { set angle [expr $angle + 360.0] }
         while { $angle > $max } { set angle [expr $angle - 360.0] }
      }

   } elseif { ![string compare "SIGN_DETERMINES_DIRECTION" $dir] } {

   #
   #  Sign determines direction.  Determine whether the shortest distance is
   #  clockwise or counterclockwise.  If counterclockwise append a "-" sign
   #  to the address leader.
   #
      set check_solution 1

      #<09-15-09 wbh> If angle is negative, we add 360 to it instead of getting the absolute value of it.
      if { $angle < 0 } {
         set angle [expr $angle + 360]
      }

      set minus_flag 0
     # set angle [expr abs($angle)]  ;# This line was not in ROTSET of xzc post.

      set del [expr $angle - $prev_angle]
      if { $tol_flag == 0 } { ;# Exact comparison
         if { ($del < 0.0 && $del > -180.0) || $del > 180.0 } {
           # set lead "$kin_leader-"
            set minus_flag 1
         } else {
            set lead $kin_leader
         }
      } else { ;# Tolerant comparison
         if { ([EQ_is_lt $del 0.0] && [EQ_is_gt $del -180.0]) || [EQ_is_gt $del 180.0] } {
           # set lead "$kin_leader-"
            set minus_flag 1
         } else {
            set lead $kin_leader
         }
      }

      #<04-27-11 wbh> 1819104 Check the rotary axis is 4th axis or 5th axis
      global mom_kin_4th_axis_leader mom_kin_5th_axis_leader
      global mom_rotary_direction_4th mom_rotary_direction_5th
      global mom_prev_rotary_dir_4th mom_prev_rotary_dir_5th

      set is_4th 1
      if { [info exists mom_kin_5th_axis_leader] && [string match "$mom_kin_5th_axis_leader" "$kin_leader"] } {
         set is_4th 0
      }

      if { ![info exists mom_rotary_direction_4th] } { set mom_rotary_direction_4th 1 }
      if { ![info exists mom_rotary_direction_5th] } { set mom_rotary_direction_5th 1 }

      #<09-15-09 wbh>
      if { $minus_flag && [EQ_is_gt $angle 0.0] } {
         set lead "$kin_leader-"

         #<04-27-11 wbh> Since the leader should add a minus, the rotary direction need be reset
         if { $is_4th } {
            set mom_rotary_direction_4th -1
         } else {
            set mom_rotary_direction_5th -1
         }
      }

      #<04-27-11 wbh> If the delta angle is 0 or 180, there has no need to change the rotary direction,
      #               we should reset the current direction with the previous direction
      if { [EQ_is_zero $del] || [EQ_is_equal $del 180.0] || [EQ_is_equal $del -180.0] } {
         if { $is_4th } {
            if { [info exists mom_prev_rotary_dir_4th] } {
               set mom_rotary_direction_4th $mom_prev_rotary_dir_4th
            }
         } else {
            if { [info exists mom_prev_rotary_dir_5th] } {
               set mom_rotary_direction_5th $mom_prev_rotary_dir_5th
            }
         }
      } else {
         # Set the previous direction
         if { $is_4th } {
            set mom_prev_rotary_dir_4th $mom_rotary_direction_4th
         } else {
            set mom_prev_rotary_dir_5th $mom_rotary_direction_5th
         }
      }
   }

   #<03-13-12 gsl> Check solution
   #
   #  There are no alternate solutions.
   #  If the position is out of limits, give a warning and leave.
   #
   if { $check_solution } {
      if { $tol_flag == 1 } {
         if { [EQ_is_gt $angle $max] || [EQ_is_lt $angle $min] } {
            CATCH_WARNING "$kin_leader-axis is under minimum or over maximum. Assumed default."
         }
      } else {
         if { ($angle > $max) || ($angle < $min) } {
            CATCH_WARNING "$kin_leader-axis is under minimum or over maximum. Assumed default."
         }
      }
   }

return $angle
}


#=============================================================
proc SET_FEEDRATE_NUMBER { dist feed } {
#=============================================================
# called by ROTARY_AXIS_RETRACT

#<03-13-08 gsl> FRN factor should not be used here! Leave it to PB_CMD_FEEDRATE_NUMBER
# global mom_sys_frn_factor

  global mom_kin_max_frn

  if { [EQ_is_zero $dist] } {
return $mom_kin_max_frn
  } else {
    set f [expr $feed / $dist ]
    if { [EQ_is_lt $f $mom_kin_max_frn] } {
return $f
    } else {
return $mom_kin_max_frn
    }
  }
}


#=============================================================
proc SET_LOCK { axis plane value } {
#=============================================================
# called by MOM_lock_axis

  upvar $axis a ; upvar $plane p ; upvar $value v

  global mom_kin_machine_type mom_lock_axis mom_lock_axis_plane mom_lock_axis_value
  global mom_warning_info

   set machine_type [string tolower $mom_kin_machine_type]
   switch $machine_type {
      4_axis_head       -
      4_axis_table      -
      3_axis_mill_turn  -
      mill_turn         { set mtype 4 }
      5_axis_dual_table -
      5_axis_dual_head  -
      5_axis_head_table { set mtype 5 }
      default {
         set mom_warning_info "Set lock only vaild for 4 and 5 axis machines"
return "error"
      }
   }

   # Check the locked rotary axis.
   # If the rotary axis is the locked axis, it must be the 4th axis for 4-axis machine,
   # or the 5th axis for 5-axis machine.
   if { ![CHECK_LOCK_ROTARY_AXIS $mom_lock_axis $mtype] } {
      set mom_warning_info "Specified rotary axis is invalid as the lock axis"
      return "error"
   }

   set p -1

   global mom_sys_lock_arc_save
   global mom_kin_arc_output_mode

   switch $mom_lock_axis {
      OFF {
         if { [info exists mom_sys_lock_arc_save] } {
             set mom_kin_arc_output_mode $mom_sys_lock_arc_save
             unset mom_sys_lock_arc_save
             MOM_reload_kinematics
         }
         return "OFF"
      }
      XAXIS {
         set a 0
         switch $mom_lock_axis_plane {
            XYPLAN {
               set v [LOCK_AXIS_SUB $a]
               set p 2
            }
            YZPLAN {
               set mom_warning_info "Invalid plane for lock axis"
               return "error"
            }
            ZXPLAN {
               set v [LOCK_AXIS_SUB $a]
               set p 1
            }
            NONE {
               if { $mtype == 5 } {
                  set mom_warning_info "Must specify lock axis plane for 5 axis machine"
                  return "error"
               } else {
                  set v [LOCK_AXIS_SUB $a]
               }
            }
         }
      }
      YAXIS {
         set a 1
         switch $mom_lock_axis_plane {
            XYPLAN {
               set v [LOCK_AXIS_SUB $a]
               set p 2
            }
            YZPLAN {
               set v [LOCK_AXIS_SUB $a]
               set p 0
            }
            ZXPLAN {
               set mom_warning_info "Invalid plane for lock axis"
               return "error"
            }
            NONE {
               if { $mtype == 5 } {
                  set mom_warning_info "Must specify lock axis plane for 5 axis machine"
                  return "error"
               } else {
                  set v [LOCK_AXIS_SUB $a]
               }
            }
         }
      }
      ZAXIS {
         set a 2
         switch $mom_lock_axis_plane {
            YZPLAN {
               set v [LOCK_AXIS_SUB $a]
               set p 0
            }
            ZXPLAN {
               set v [LOCK_AXIS_SUB $a]
               set p 1
            }
            XYPLAN {
               set mom_warning_info "Invalid plane for lock axis"
               return "error"
            }
            NONE {
               if { $mtype == 5 } {
                  set mom_warning_info "Must specify lock axis plane for 5 axis machine"
                  return "error"
               } else {
                  set v [LOCK_AXIS_SUB $a]
               }
            }
         }
      }
      FOURTH {
         set a 3
         set v [LOCK_AXIS_SUB $a]
      }
      FIFTH {
         set a 4
         set v [LOCK_AXIS_SUB $a]
      }
      AAXIS {
         set a [AXIS_SET $mom_lock_axis]
         set v [LOCK_AXIS_SUB $a]
      }
      BAXIS {
         set a [AXIS_SET $mom_lock_axis]
         set v [LOCK_AXIS_SUB $a]
      }
      CAXIS {
         set a [AXIS_SET $mom_lock_axis]
         set v [LOCK_AXIS_SUB $a]
      }
   }

   if { ![info exists mom_sys_lock_arc_save] } {
      set mom_sys_lock_arc_save $mom_kin_arc_output_mode
   }

   set mom_kin_arc_output_mode "LINEAR"
   MOM_reload_kinematics

return "ON"
}


#=============================================================
proc SOLVE_QUADRATIC { coeff rcomp icomp status degree } {
#=============================================================
# called by CALC_SPHERICAL_RETRACT_POINT

   upvar $coeff c ; upvar $rcomp rc ; upvar $icomp ic
   upvar $status st ; upvar $degree deg

   set st 1
   set deg 0
   set rc(0) 0.0 ; set rc(1) 0.0
   set ic(0) 0.0 ; set ic(1) 0.0
   set mag [VEC3_mag c]
   if { [EQ_is_zero $mag] } { return 0 }

   set acoeff [expr $c(2)/$mag]
   set bcoeff [expr $c(1)/$mag]
   set ccoeff [expr $c(0)/$mag]

   if { ![EQ_is_zero $acoeff] } {
      set deg 2
      set denom [expr $acoeff*2.]
      set dscrm [expr $bcoeff*$bcoeff - $acoeff*$ccoeff*4.0]
      if { [EQ_is_zero $dscrm] } {
         set dsqrt1 0.0
      } else {
         set dsqrt1 [expr sqrt(abs($dscrm))]
      }
      if { [EQ_is_ge $dscrm 0.0] } {
         set rc(0) [expr (-$bcoeff + $dsqrt1)/$denom]
         set rc(1) [expr (-$bcoeff - $dsqrt1)/$denom]
         set st 3
         return 2
      } else {
         set rc(0) [expr -$bcoeff/$denom]
         set rc(1) $rc(0)
         set ic(0) [expr $dsqrt1/$denom]
         set ic(1) $ic(0)
         set st 2
         return 0
      }
   } elseif { ![EQ_is_zero $bcoeff] } {
      set st 3
      set deg 1
      set rc(0) [expr -$ccoeff/$bcoeff]
      return 1
   } elseif { [EQ_is_zero $ccoeff] } {
      return 0
   } else {
      return 0
   }
}


#=============================================================
proc STR_MATCH { VAR str {out_warn 0} } {
#=============================================================
# pb_base -
#
# This command will match a variable with a given string.
#
# - Users can set the optional flag "out_warn" to "1" to produce
#   warning message when the variable is not defined in the scope
#   of the caller of this function.
#
   upvar $VAR var

   if { [info exists var] && [string match "$var" "$str"] } {
return 1
   } else {
      if { $out_warn } {
         CATCH_WARNING "Variable $VAR is not defined in \"[info level -1]\"!"
      }
return 0
   }
}


#=============================================================
proc TRACE { {up_level 0} } {
#=============================================================
# pb_base -
#
# up_level to be a negative integer
#
   set start_idx 1

   set str ""
   set level [expr [info level] - int(abs($up_level))]
   for { set i $start_idx } { $i <= $level } { incr i } {
      if { $i < $level } {
         set str "${str}[lindex [info level $i] 0]\n"
      } else {
         set str "${str}[lindex [info level $i] 0]"
      }
   }

return $str
}


#=============================================================
proc UNLOCK_AXIS { locked_point unlocked_point } {
#=============================================================
# called by LINEARIZE_LOCK_MOTION
#
# (pb903)
# 04-16-14 gsl - Account for offsets resulted from right-angled head attachment
# 09-09-15 ljt - Replace mom_kin_4/5th_axis_center_offset with mom_kin_4/5th_axis_point
#
# (pb1101)
# 08-11-16 gsl - Correct error for removing offsets
#

   upvar $locked_point in_pos ; upvar $unlocked_point out_pos

   global mom_sys_lock_plane
   global mom_sys_linear_axis_index_1
   global mom_sys_linear_axis_index_2
   global mom_sys_rotary_axis_index
   global mom_kin_4th_axis_center_offset
   global mom_kin_5th_axis_center_offset
   global mom_kin_4th_axis_point
   global mom_kin_5th_axis_point
   global mom_kin_machine_type
   global mom_origin
   global DEG2RAD


  #<04-16-2014 gsl> Add offsets of angled-head attachment to input point
   VMOV 5 in_pos ip
   ACCOUNT_HEAD_OFFSETS ip 1


   #<09-Sep-2015 ljt> Add offsets of 4/5th axis rotary center
   VMOV 3 ip temp
   if { [CMD_EXIST MOM_validate_machine_model] \
        && [string match "TRUE" [MOM_validate_machine_model]] } {

      if { [string match "5_axis_*table" $mom_kin_machine_type] && [info exists mom_kin_5th_axis_point] } {

         VEC3_sub temp mom_kin_5th_axis_point temp

      } elseif { ( [string match "4_axis_table" $mom_kin_machine_type] || [string match "*mill_turn" $mom_kin_machine_type] )\
                 && [info exists mom_kin_4th_axis_point] } {

         VEC3_sub temp mom_kin_4th_axis_point temp
      }

   } else {

      if { [info exists mom_origin] } {
         VEC3_sub temp mom_origin temp
      }

      if { [info exists mom_kin_4th_axis_center_offset] } {
         VEC3_add temp mom_kin_4th_axis_center_offset temp
      }

      if { [info exists mom_kin_5th_axis_center_offset] } {
         VEC3_add temp mom_kin_5th_axis_center_offset temp
      }
   }

   set op(3) $ip(3)
   set op(4) $ip(4)

   set ang [expr $op($mom_sys_rotary_axis_index)*$DEG2RAD]
   ROTATE_VECTOR $mom_sys_lock_plane $ang temp op

   set op($mom_sys_rotary_axis_index) 0.0


   #<09-Sep-2015 ljt> Remove offsets of 4/5th axis rotary center
   if { [CMD_EXIST MOM_validate_machine_model] &&\
        [string match "TRUE" [MOM_validate_machine_model]] } {

      if { [string match "5_axis_*table" $mom_kin_machine_type] && [info exists mom_kin_5th_axis_point] } {

         VEC3_add op mom_kin_5th_axis_point op

      } elseif { ( [string match "4_axis_table" $mom_kin_machine_type] || [string match "*mill_turn" $mom_kin_machine_type] ) && \
                 [info exists mom_kin_4th_axis_point] } {

         VEC3_add op mom_kin_4th_axis_point op
      }

   } else {

     #<Aug-11-2016> Reverse next 3 operations
      if { [info exists mom_origin] } {
         VEC3_sub op mom_origin op
      }

      if { [info exists mom_kin_4th_axis_center_offset] } {
         VEC3_add op mom_kin_4th_axis_center_offset op
      }

      if { [info exists mom_kin_5th_axis_center_offset] } {
         VEC3_add op mom_kin_5th_axis_center_offset op
      }
   }


  #<04-16-2014 gsl> Remove offsets of angled-head attachment from output point
   ACCOUNT_HEAD_OFFSETS op 0
   VMOV 5 op out_pos
}


#=============================================================
proc UNLOCK_AXIS__pb901 { locked_point unlocked_point } {
#=============================================================
# called by LINEARIZE_LOCK_MOTION

   upvar $locked_point ip ; upvar $unlocked_point op

   global mom_sys_lock_plane
   global mom_sys_linear_axis_index_1
   global mom_sys_linear_axis_index_2
   global mom_sys_rotary_axis_index
   global mom_kin_4th_axis_center_offset
   global mom_kin_5th_axis_center_offset
   global DEG2RAD


   if { [info exists mom_kin_4th_axis_center] } {
       VEC3_add ip mom_kin_4th_axis_center_offset temp
   } else {
       set temp(0) $ip(0)
       set temp(1) $ip(1)
       set temp(2) $ip(2)
   }
   if { [info exists mom_kin_5th_axis_center_offset] } {
      VEC3_add temp mom_kin_5th_axis_center_offset temp
   }

   set op(3) $ip(3)
   set op(4) $ip(4)

   set ang [expr $op($mom_sys_rotary_axis_index)*$DEG2RAD]
   ROTATE_VECTOR $mom_sys_lock_plane $ang temp op

   set op($mom_sys_rotary_axis_index) 0.0

   if { [info exists mom_kin_4th_axis_center_offset] } {
      VEC3_sub op mom_kin_4th_axis_center_offset op
   }
   if { [info exists mom_kin_5th_axis_center_offset] } {
      VEC3_sub op mom_kin_5th_axis_center_offset op
   }
}


#=============================================================
proc UNSET_VARS { args } {
#=============================================================
# pb_base -
#
# Inputs: List of variable names
#

   if { [llength $args] == 0 } {
return
   }

   foreach VAR $args {
      upvar $VAR var

      if { [array exists var] } {
         if { [expr $::tcl_version > 8.1] } {
            array unset var
         } else {
            foreach a [array names var] {
               if { [info exists var($a)] } {
                  unset var($a)
               }
            }
            unset var
         }
      }

      if { [info exists var] } {
         unset var
      }
   }
}


#=============================================================
proc VALIDATE_MOTION { } {
#=============================================================
# To be called by PB_CMD_kin_before_motion

   if [CMD_EXIST PB_CMD__validate_motion] {
return [PB_CMD__validate_motion]
   } else {
      # Assume OK, when no validation is done.
return 1
   }
}


#=============================================================
proc VECTOR_ROTATE { axis angle input_vector output_vector } {
#=============================================================
#This proc is used to rotating a vector about arbitrary axis.
   upvar $axis r; upvar $input_vector input ; upvar $output_vector output
   #set up matrix to rotate about an arbitrary axis
   set m(0) [expr $r(0)*$r(0)*(1-cos($angle))+cos($angle)]
   set m(1) [expr $r(0)*$r(1)*(1-cos($angle))-$r(2)*sin($angle)]
   set m(2) [expr $r(0)*$r(2)*(1-cos($angle))+$r(1)*sin($angle)]
   set m(3) [expr $r(0)*$r(1)*(1-cos($angle))+$r(2)*sin($angle)]
   set m(4) [expr $r(1)*$r(1)*(1-cos($angle))+cos($angle)]
   set m(5) [expr $r(1)*$r(2)*(1-cos($angle))-$r(0)*sin($angle)]
   set m(6) [expr $r(0)*$r(2)*(1-cos($angle))-$r(1)*sin($angle)]
   set m(7) [expr $r(1)*$r(2)*(1-cos($angle))+$r(0)*sin($angle)]
   set m(8) [expr $r(2)*$r(2)*(1-cos($angle))+cos($angle)]
   MTX3_vec_multiply input m output
}


#=============================================================
proc VMOV { n p1 p2 } {
#=============================================================
# pb_base -
#
  upvar $p1 v1 ; upvar $p2 v2

   for { set i 0 } { $i < $n } { incr i } {
      set v2($i) $v1($i)
   }
}


#=============================================================
proc WORKPLANE_SET { } {
#=============================================================
   global mom_cycle_spindle_axis
   global mom_sys_spindle_axis
   global traverse_axis1 traverse_axis2

   if { ![info exists mom_sys_spindle_axis] } {
      set mom_sys_spindle_axis(0) 0.0
      set mom_sys_spindle_axis(1) 0.0
      set mom_sys_spindle_axis(2) 1.0
   }

   if { ![info exists mom_cycle_spindle_axis] } {
      set x $mom_sys_spindle_axis(0)
      set y $mom_sys_spindle_axis(1)
      set z $mom_sys_spindle_axis(2)

      if { [EQ_is_zero $y] && [EQ_is_zero $z] } {
         set mom_cycle_spindle_axis 0
      } elseif { [EQ_is_zero $x] && [EQ_is_zero $z] } {
         set mom_cycle_spindle_axis 1
      } else {
         set mom_cycle_spindle_axis 2
      }
   }

   if { $mom_cycle_spindle_axis == 2 } {
      set traverse_axis1 0 ; set traverse_axis2 1
   } elseif { $mom_cycle_spindle_axis == 0 } {
      set traverse_axis1 1 ; set traverse_axis2 2
   } elseif { $mom_cycle_spindle_axis == 1 } {
      set traverse_axis1 0 ; set traverse_axis2 2
   }
}


#=============================================================
proc PB_DEFINE_MACROS { } {
#=============================================================
   global mom_pb_macro_arr

   set mom_pb_macro_arr(CYCLE81) \
       [list {CYCLE81 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4}}]

   set mom_pb_macro_arr(CYCLE82) \
       [list {CYCLE82 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_dtb} 1 4 2 1 1 6 4}}]

   set mom_pb_macro_arr(CYCLE83_Deep) \
       [list {CYCLE83 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {} \
         {{$mom_cycle_step1} 1 4 5 1 1 9 4} \
         {{$mom_cycle_step2} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_dtb} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_dts} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_frf} 1 3 5 1 1 8 3} \
         {1 0} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_cycle_step3} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_o_dtd} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_dis1} 1 4 5 1 1 9 4}}]

   set mom_pb_macro_arr(CYCLE83_Break_Chip) \
       [list {CYCLE83 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {} \
         {{$mom_siemens_cycle_fdpr} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_dam} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_dtb} 1 3 5 1 1 8 3} \
         {} \
         {{$mom_siemens_cycle_frf} 1 3 5 1 1 8 3} \
         {0 0} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_cycle_step3} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_o_vrt} 1 4 2 1 1 6 4} \
         {{$mom_siemens_cycle_o_dtd} 1 3 5 1 1 8 3}}]

   set mom_pb_macro_arr(CYCLE84) \
       [list {CYCLE84 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdac} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_mpit} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_pit} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_poss} 1 3 5 1 1 8 3} \
         {{$mom_spindle_speed} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_sst1} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_ptab} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_techno} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_o_var1} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_dam} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_vrt} 1 3 5 1 1 8 3}}]

   set mom_pb_macro_arr(CYCLE840) \
       [list {CYCLE840 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdr} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_sdac} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_enc} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_mpit} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_pit} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_ptab} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_techno} 1 0 2 0 0 2}}]

   set mom_pb_macro_arr(CYCLE85_Bore) \
       [list {CYCLE85 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {} \
         {{$feed} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_rff} 1 2 7 1 1 9 2}}]

   set mom_pb_macro_arr(CYCLE85_Bore_Dwell) \
       [list {CYCLE85 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$feed} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_rff} 1 2 7 1 1 9 2}}]

   set mom_pb_macro_arr(CYCLE86) \
       [list {CYCLE86 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdir} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_rpa} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_rpo} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_rpap} 1 4 5 1 1 9 4} \
         {{$mom_cycle_orient} 1 3 5 1 1 8 3}}]

   set mom_pb_macro_arr(CYCLE87) \
       [list {CYCLE87 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_sdir} 1 0 1 0 0 1}}]

   set mom_pb_macro_arr(CYCLE88) \
       [list {CYCLE88 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdir} 1 0 1 0 0 1}}]

   set mom_pb_macro_arr(CYCLE89) \
       [list {CYCLE89 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3}}]

   set mom_pb_macro_arr(CYCLE800) \
       [list {CYCLE800 ( , ) 0 {}} \
        {{1 0} \
         {{$cycle800_tc} 0} \
         {{$cycle800_st} 1 0 5 0 0 5} \
         {{$cycle800_mode} 1 0 2 0 0 2} \
         {{$coord_offset(0)} 1 6 5 1 1 11 6} \
         {{$coord_offset(1)} 1 6 5 1 1 11 6} \
         {{$coord_offset(2)} 1 6 5 1 1 11 6} \
         {{$coord_ang_1} 1 5 5 1 1 10 5} \
         {{$coord_ang_2} 1 5 5 1 1 10 5} \
         {{$coord_ang_3} 1 5 5 1 1 10 5} \
         {0 1 3 5 1 1 8 3} \
         {0 1 3 5 1 1 8 3} \
         {0 1 3 5 1 1 8 3} \
         {{$cycle800_dir} 1 0 2 0 0 2} \
         {{$cycle800_inc_retract} 1 5 5 1 1 10 5}}]

   set mom_pb_macro_arr(CYCLE832) \
       [list {CYCLE832 ( , ) 0 {}} \
        {{_camtolerance 0} \
         {{$cycle832_tolm} 1 0 6 0 0 6}}]

   set mom_pb_macro_arr(CYCLE832_v7) \
       [list {CYCLE832 ( , ) 0 {}} \
        {{_camtolerance 0} \
         {{$cycle832_tolm} 1 0 6 0 0 6} \
         {{$cycle832_v832} 0}}]

   set mom_pb_macro_arr(CYCLE832_v7_1) \
       [list {CYCLE832 ( , ) 0 {}} \
        {{{$cycle832_tol} 0} \
         {{$cycle832_tolm} 0} \
         {{$cycle832_otol} 1 2 1 1 1 3 2}}]

   set mom_pb_macro_arr(MCALL) \
       [list {MCALL {} {} {} 0 {}} \
        {}]

   set mom_pb_macro_arr(ORIRESET) \
       [list {ORIRESET ( , ) 0 {}} \
        {{{$mom_out_angle_pos(0)} 1 5 5 1 1 10 5} \
         {{$mom_out_angle_pos(1)} 1 5 5 1 1 10 5}}]

   set mom_pb_macro_arr(CYCLE86_sl) \
       [list {CYCLE86 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_dtb} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdir} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_rpa} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_rpo} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_rpap} 1 4 5 1 1 9 4} \
         {{$mom_cycle_orient} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_gmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_dmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_amode} 1 0 2 0 0 2}}]

   set mom_pb_macro_arr(CYCLE81_sl) \
       [list {CYCLE81 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_dtb} 1 4 2 1 1 6 4} \
         {{$mom_siemens_cycle_gmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_dmode} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_amode} 1 0 2 0 0 2}}]

   set mom_pb_macro_arr(CYCLE82_sl) \
       [list {CYCLE82 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_dtb} 1 4 2 1 1 6 4} \
         {{$mom_siemens_cycle_gmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_dmode} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_amode} 1 0 2 0 0 2}}]

   set mom_pb_macro_arr(CYCLE83_Deep_sl) \
       [list {CYCLE83 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {} \
         {{$mom_cycle_step1} 1 4 5 1 1 9 4} \
         {{$mom_cycle_step2} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_dtb} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_dts} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_frf} 1 3 5 1 1 8 3} \
         {1 0} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_cycle_step3} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_o_dtd} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_dis1} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_gmode} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_dmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_amode} 1 0 8 0 0 8}}]

   set mom_pb_macro_arr(CYCLE83_Break_Chip_sl) \
       [list {CYCLE83 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {} \
         {{$mom_siemens_cycle_fdpr} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_dam} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_dtb} 1 3 5 1 1 8 3} \
         {} \
         {{$mom_siemens_cycle_frf} 1 3 5 1 1 8 3} \
         {0 0} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_cycle_step3} 1 4 5 1 1 9 4} \
         {{$mom_siemens_cycle_o_vrt} 1 4 2 1 1 6 4} \
         {{$mom_siemens_cycle_o_dtd} 1 3 5 1 1 8 3} \
         {} \
         {{$mom_siemens_cycle_gmode} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_dmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_amode} 1 0 8 0 0 8}}]

   set mom_pb_macro_arr(CYCLE84_sl) \
       [list {CYCLE84 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdac} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_mpit} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_pit} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_poss} 1 3 5 1 1 8 3} \
         {{$mom_spindle_speed} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_sst1} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_ptab} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_techno} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_o_var1} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_dam} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_vrt} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_pitm} 0} \
         {{$mom_siemens_cycle_o_ptab_sl} 0} \
         {{$mom_siemens_cycle_o_ptaba} 0} \
         {{$mom_siemens_cycle_gmode} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_dmode} 1 0 4 0 0 4} \
         {{$mom_siemens_cycle_amode} 1 0 7 0 0 7}}]

   set mom_pb_macro_arr(CYCLE840_sl) \
       [list {CYCLE840 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_cycle_delay} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_sdr} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_sdac} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_enc} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_mpit} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_pit} 1 3 5 1 1 8 3} \
         {{$mom_siemens_cycle_o_axn} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_ptab} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_o_techno} 1 0 2 0 0 2} \
         {{$mom_siemens_cycle_o_pitm} 0} \
         {{$mom_siemens_cycle_o_ptab_sl} 0} \
         {{$mom_siemens_cycle_o_ptaba} 1 4 2 1 1 6 4} \
         {} \
         {{$mom_siemens_cycle_dmode} 1 0 4 0 0 4} \
         {{$mom_siemens_cycle_amode} 1 0 1 0 0 1}}]

   set mom_pb_macro_arr(CYCLE85_Bore_sl) \
       [list {CYCLE85 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {} \
         {{$feed} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_rff} 1 2 7 1 1 9 2} \
         {} \
         {{$mom_siemens_cycle_dmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_amode} 1 0 2 0 0 2}}]

   set mom_pb_macro_arr(CYCLE85_Bore_Dwell_sl) \
       [list {CYCLE85 ( , ) 0 {}} \
        {{{$mom_cycle_retract_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {{$mom_cycle_clearance_plane} 1 4 5 1 1 9 4} \
         {{$mom_cycle_feed_to_pos($mom_cycle_spindle_axis)} 1 4 5 1 1 9 4} \
         {} \
         {{$mom_siemens_cycle_dtb} 1 3 5 1 1 8 3} \
         {{$feed} 1 2 7 1 1 9 2} \
         {{$mom_siemens_cycle_rff} 1 2 7 1 1 9 2} \
         {} \
         {{$mom_siemens_cycle_dmode} 1 0 1 0 0 1} \
         {{$mom_siemens_cycle_amode} 1 0 2 0 0 2}}]

   set mom_pb_macro_arr(CYCLE800_sl) \
       [list {CYCLE800 ( , ) 0 {}} \
        {{1 0} \
         {{$cycle800_tc} 0} \
         {{$cycle800_st} 1 0 5 0 0 5} \
         {{$cycle800_mode} 1 0 2 0 0 2} \
         {{$coord_offset(0)} 1 6 5 1 1 11 6} \
         {{$coord_offset(1)} 1 6 5 1 1 11 6} \
         {{$coord_offset(2)} 1 6 5 1 1 11 6} \
         {{$coord_angle(0)} 1 5 5 1 1 10 5} \
         {{$coord_angle(1)} 1 5 5 1 1 10 5} \
         {{$coord_angle(2)} 1 5 5 1 1 10 5} \
         {0 1 3 5 1 1 8 3} \
         {0 1 3 5 1 1 8 3} \
         {0 1 3 5 1 1 8 3} \
         {{$cycle800_dir} 1 0 2 0 0 2} \
         {{$cycle800_inc_retract} 1 5 5 1 1 10 5} \
         {{$mom_siemens_cycle_dmode} 1 0 1 0 0 1}}]
}


#=============================================================
proc PB_call_macro { macro_name { prefix "" } { suppress_seqno 0 } args } {
#=============================================================
   global mom_pb_macro_arr mom_warning_info

   if { ![info exists mom_pb_macro_arr($macro_name)] } {
      CATCH_WARNING "Macro $macro_name is not defined."
      return
   }

   set macro_attr_list $mom_pb_macro_arr($macro_name)

   set com_attr_list  [lindex $macro_attr_list 0]
   set disp_name      [lindex $com_attr_list 0]
   set start_char     [lindex $com_attr_list 1]
   set separator_char [lindex $com_attr_list 2]
   set end_char       [lindex $com_attr_list 3]
   set link_flag      [lindex $com_attr_list 4]
   set link_char      [lindex $com_attr_list 5]

   set param_list     [lindex $macro_attr_list 1]

   set text_string ""
   if { [string compare $prefix ""] != 0 } {
       append text_string $prefix " "
   }

   append text_string $disp_name $start_char

   set g_vars_list [list]
   set param_text_list [list]
   set last_index 0
   set count 0
   foreach param_attr $param_list {
      incr count
      if { [llength $param_attr] > 0 } {
         set exp [lindex $param_attr 0]
         if { $exp == "" } {
            lappend param_text_list ""
            continue
         }

         set dtype [lindex $param_attr 1]
         if { $dtype } {
            set temp_cmd "set data_val \[expr \$exp\]"
         } else {
            set temp_cmd "set data_string \"$exp\""
         }

         set break_flag 0
         while { 1 } {
            if { [catch {eval $temp_cmd} res_val] } {
               if [string match "*no such variable*" $res_val] {
                  set __idx [string first ":" $res_val]
                  if { $__idx >= 0 } {
                     set temp_res [string range $res_val 0 [expr int($__idx - 1)]]
                     set temp_var [lindex $temp_res end]
                     set temp_var [string trim $temp_var "\""]
                     if { [string index $temp_var [expr [string length $temp_var] - 1]] == ")" } {
                        set __idx [string first "(" $temp_var]
                        set temp_var [string range $temp_var 0 [expr int($__idx - 1)]]
                     }

                     foreach one $g_vars_list {
                        if { [string compare $temp_var $one] == 0 } {
                           set break_flag 1
                        }
                     }
                     lappend g_vars_list $temp_var
                     global $temp_var
                  } else {
                     set break_flag 1
                  }
               } elseif [string match "*no such element*" $res_val] {
                  set break_flag 1
               } else {
                  CATCH_WARNING "Error to evaluate expression $exp in $macro_name: $res_val"
                  return
               }
            } else {
               break
            }

            if $break_flag {
               CATCH_WARNING "Error to evaluate expression $exp in $macro_name: $res_val"
               set data_string ""
               break
            }
         }

         if { !$break_flag && $dtype } {
            set is_double [lindex $param_attr 2]
            set int_width [lindex $param_attr 3]
            set is_decimal [lindex $param_attr 4]

            set max_val "1"
            set min_val "-1"
            set zero_char [string range "000000000" 0 [expr $int_width - 1]]
            append max_val $zero_char
            append min_val $zero_char

            if { [catch { expr $data_val >= $max_val } comp_res] } {
               set data_string ""
               CATCH_WARNING "Wrong data type to evaluate expression $exp in $macro_name: $comp_res"
            } elseif { $comp_res } {
               set data_string [expr $max_val - 1]
               CATCH_WARNING "MAX/MIN WARNING to evaluate expression $exp in $macro_name: MAX: $data_string"
            } elseif { [expr $data_val <= $min_val] } {
               set data_string [expr $min_val + 1]
               CATCH_WARNING "MAX/MIN WARNING to evaluate expression $exp in $macro_name: MIN: $data_string"
            } else {
               if { $is_double } {
                  set total_width [expr $int_width + $is_double]
                  catch { set data_string [format "%${total_width}.${is_double}f" $data_val] }
                  set data_string [string trimleft $data_string]
                  set data_string [string trimright $data_string 0]
                  if { !$is_decimal } {
                     set dec_index [string first . $data_string]
                     set dec_str [string range $data_string 0 [expr $dec_index - 1]]
                     append dec_str [string range $data_string [expr $dec_index + 1] end]
                     set data_string $dec_str
                  }
               } else {
                  set int_data [expr { int($data_val) }]
                  catch { set data_string [format "%${int_width}d" $int_data] }
                  set data_string [string trimleft $data_string]
                  if { $is_decimal } {
                     append data_string "."
                  }
               }
            }
         }

         if { $link_flag } {
            set temp_str ""
            append temp_str [lindex $param_attr end] $link_char $data_string
            set data_string $temp_str
         }
         lappend param_text_list $data_string

         if ![string match "" $data_string] {
            set last_index $count
         }
      } else {
         lappend param_text_list ""
      }
   }

   if { $last_index > 0 } {
      if { $last_index < $count } {
         set param_text_list [lreplace $param_text_list $last_index end]
      }
      append text_string [join $param_text_list $separator_char]
   }

   append text_string $end_char

   if { $suppress_seqno } {
      MOM_suppress once N
      MOM_output_literal $text_string
   } else {
      MOM_output_literal $text_string
   }
}


#=============================================================
proc PB_load_alternate_unit_settings { } {
#=============================================================
   global mom_output_unit mom_kin_output_unit

  # Skip this function when output unit agrees with post unit.
   if { ![info exists mom_output_unit] } {
      set mom_output_unit $mom_kin_output_unit
return
   } elseif { ![string compare $mom_output_unit $mom_kin_output_unit] } {
return
   }


   global mom_event_handler_file_name

  # Set unit conversion factor
   if { ![string compare $mom_output_unit "MM"] } {
      set factor 25.4
   } else {
      set factor [expr 1/25.4]
   }

  # Define unit dependent variables list
   set unit_depen_var_list [list mom_kin_x_axis_limit mom_kin_y_axis_limit mom_kin_z_axis_limit \
                                 mom_kin_pivot_gauge_offset mom_kin_ind_to_dependent_head_x \
                                 mom_kin_ind_to_dependent_head_z]

   set unit_depen_arr_list [list mom_kin_4th_axis_center_offset \
                                 mom_kin_5th_axis_center_offset \
                                 mom_kin_machine_zero_offset \
                                 mom_kin_4th_axis_point \
                                 mom_kin_5th_axis_point \
                                 mom_sys_home_pos]

  # Load unit dependent variables
   foreach var $unit_depen_var_list {
      if { ![info exists $var] } {
         global $var
      }
      if { [info exists $var] } {
         set $var [expr [set $var] * $factor]
         MOM_reload_variable $var
      }
   }

   foreach var $unit_depen_arr_list {
      if { ![info exists $var] } {
         global $var
      }
      foreach item [array names $var] {
         if { [info exists ${var}($item)] } {
            set ${var}($item) [expr [set ${var}($item)] * $factor]
         }
      }

      MOM_reload_variable -a $var
   }


  # Source alternate unit post fragment
   uplevel #0 {
      global mom_sys_alt_unit_post_name
      set alter_unit_post_name \
          "[file join [file dirname $mom_event_handler_file_name] [file rootname $mom_sys_alt_unit_post_name]].tcl"

      if { [file exists $alter_unit_post_name] } {
         source "$alter_unit_post_name"
      }
      unset alter_unit_post_name
   }

   if { [llength [info commands PB_load_address_redefinition]] > 0 } {
      PB_load_address_redefinition
   }

   MOM_reload_kinematics
}


if [info exists mom_sys_start_of_program_flag] {
   if [llength [info commands PB_CMD_kin_start_of_program] ] {
      PB_CMD_kin_start_of_program
   }
} else {
   set mom_sys_head_change_init_program 1
   set mom_sys_start_of_program_flag 1
}


set cam_post_user_tcl "simulation_ini.tcl"




#***************************
# Source in user's tcl file.
#***************************
set cam_post_dir [MOM_ask_env_var UGII_CAM_POST_DIR]
set ugii_version [string trimleft [MOM_ask_env_var UGII_VERSION] v]

if { [catch {
   if { $ugii_version >= 5 } {
      if { [file exists "[file dirname [info script]]/$cam_post_user_tcl"] } {
        # From directory relative to that of current post
         source "[file dirname [info script]]/$cam_post_user_tcl"
      } elseif { [file exists "${cam_post_dir}$cam_post_user_tcl"] } {
        # From directory relative to UGII_CAM_POST_DIR
         source "${cam_post_dir}$cam_post_user_tcl"
      } elseif { [file exists "$cam_post_user_tcl"] } {
        # From the specified directory
         source "$cam_post_user_tcl"
      } else {
         MOM_output_to_listing_device "User's Tcl: $cam_post_user_tcl not found!"
      }
   } else {
      if { [file exists "${cam_post_dir}$cam_post_user_tcl"] } {
         source "${cam_post_dir}$cam_post_user_tcl"
      } else {
         MOM_output_to_listing_device "User's Tcl: ${cam_post_dir}$cam_post_user_tcl not found!"
      }
   }
} err] } {
   MOM_output_to_listing_device "User's Tcl: An error occured while sourcing $cam_post_user_tcl!\n$err"
   MOM_abort "User's Tcl: An error occured while sourcing $cam_post_user_tcl!\n$err"
}


