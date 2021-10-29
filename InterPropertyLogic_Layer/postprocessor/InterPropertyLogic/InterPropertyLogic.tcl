#############################################################################################
#
#    InterPropertyLogic (IPL) Layer
#
#############################################################################################
#
#    Copyright 2020 Siemens Digital Industries Software
#                All Rights Reserved.
#
#############################################################################################
#
# Description
# Layer that defines some IPL conditions to change UI apperance based on some property settings
# 
#############################################################################################
# History
# 08 07 2020    LL    Initial Version
#############################################################################################

#Controller Capabilities

##Sinumerik Controller Capabliities
if {$lib_controller_main == "ctrl_sinumerik_base"} {
LIB_GE_CONF_define_IPL_conditions CONF_S840D_controller sinumerik_control_version if {$propValue == "Standard"} {
   {visibility "CONF_S840D_controller" "sinumerik_version sinumerik_version_sl" "false"}
} elseif {$propValue == "Solutionline"} {
   {visibility "CONF_S840D_controller" "sinumerik_version_sl" "true"}
   {visibility "CONF_S840D_controller" "sinumerik_version" "false"}
} elseif {$propValue == "Powerline"} {
   {visibility "CONF_S840D_controller" "sinumerik_version" "true"} 
   {visibility "CONF_S840D_controller" "sinumerik_version_sl" "false"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_setting op_representation_structured if {$propValue == 1} {
   {visibility "CONF_CTRL_setting" "op_representation_postname" "true"}
} else {
   {visibility "CONF_CTRL_setting" "op_representation_postname" "false"}
}
}

##Fanuc Controller Capabilities
if {$lib_controller_type == "FANUC"} {
LIB_GE_CONF_define_IPL_conditions CONF_FANUC_G68 rotate_dir if {$propValue != 0} {
    {value "CONF_FANUC_G68" "rotate_before" 1}
	}
}

##All Controllers
LIB_GE_CONF_define_IPL_conditions CONF_SPF_machine machine_mode if {$propValue == "MILL"} {
    {visibility "CONF_CTRL_setting" "x_factor_mill" "true"}
   {visibility "CONF_CTRL_setting" "x_factor" "false"}
   {visibility "CONF_CTRL_setting" "3d_cutcom_output" "true"}
   {visibility "CONF_SPF_setting" "output_ball_center" "true"}

} elseif {$propValue == "TURN"} {
   {visibility "CONF_CTRL_setting" "x_factor" "true"}
    {visibility "CONF_CTRL_setting" "x_factor_mill" "false"}
   {visibility "CONF_CTRL_setting" "3d_cutcom_output" "false"}
      {visibility "CONF_SPF_setting" "output_ball_center" "false"}

} elseif {[string match "*MILL_TURN*" $propValue]} {
    {visibility "CONF_CTRL_setting" "x_factor_mill" "true"}
   {visibility "CONF_CTRL_setting" "x_factor" "true"}
   {visibility "CONF_CTRL_setting" "3d_cutcom_output" "true"}
      {visibility "CONF_SPF_setting" "output_ball_center" "true"}

} else {
   {visibility "CONF_CTRL_setting" "x_factor" "false"}
    {visibility "CONF_CTRL_setting" "x_factor_mill" "false"}
   {visibility "CONF_CTRL_setting" "3d_cutcom_output" "false"}
      {visibility "CONF_SPF_setting" "output_ball_center" "false"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_setting absolute_output_mode if {$propValue == "ALL"} {
   {visibility "CONF_CTRL_setting" "absolute_output absolute_ref_point" "true"}
} else {
   {visibility "CONF_CTRL_setting" "absolute_output absolute_ref_point" "false"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_setting plane_output_supported if {$propValue == "NONE"} {
   {visibility "CONF_CTRL_setting" "plane_output" "false"}
} else {
   {visibility "CONF_CTRL_setting" "plane_output" "true"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_setting tcpm_output_supported if {$propValue == "NONE"} {
   {visibility "CONF_CTRL_setting" "tcpm_mode tcpm_output" "false"}
} else {
   {visibility "CONF_CTRL_setting" "tcpm_mode tcpm_output" "true"}
}

#General Setting
LIB_GE_CONF_define_IPL_conditions CONF_CTRL_clamp status if {$propValue == 0} {
   {visibility "CONF_CTRL_clamp" "fourth_axis fifth_axis" "false"} 
} else {
   {visibility "CONF_CTRL_clamp" "fourth_axis fifth_axis" "true"} 
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_spindle range if {$propValue == 0} {
   {visibility "CONF_CTRL_spindle" "ranges_number" "false"}
} else {
   {visibility "CONF_CTRL_spindle" "ranges_number" "true"}
}

LIB_GE_CONF_define_IPL_conditions CONF_SPF_file create_cse_ini_file if {$propValue == 1} {
    {visibility "CONF_SPF_file" "ctrl_ini_location ctrl_ini_existing ctrl_ini_get_mcs_info ctrl_ini_get_tool_info ctrl_ini_end_status output_unit_to_ini" "true"}
} else {
    {visibility "CONF_SPF_file" "ctrl_ini_location ctrl_ini_existing ctrl_ini_get_mcs_info ctrl_ini_get_tool_info ctrl_ini_end_status output_unit_to_ini" "false"}
}

#Motion Setting
LIB_GE_CONF_define_IPL_conditions CONF_CTRL_moves decompose_first_move if {$propValue == 0} {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMSUL" "false"}
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMSLU" "false"}
} else {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMSUL" "true"}
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMSLU" "true"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_moves decompose_first_move_pos if {$propValue == 0} {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMPUL" "false"}
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMPLU" "false"}
} else {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMPUL" "true"}
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMPLU" "true"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_moves decompose_first_move_sim if {$propValue == 0} {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMSO" "false"}
} else {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMSO" "true"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_moves decompose_first_move_turn if {$propValue == 0} {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMTO" "false"}
} else {
   {visibility "General_UI_tree" "@CUI_MotionSettingOOrderGroupFMTO" "true"}
}

#Kinematics Setting
LIB_GE_CONF_define_IPL_conditions KinContainer_MTB mom_kin_machine_type if {[string index $propValue 0] < 4 || $propValue == "4_axis_wedm" } {
    # 4th axis settings visible
    {visibility "General_UI_tree" "@CUI_MachKin4th" "false"}
    {visibility "CONF_CTRL_clamp" "fourth_axis" "false"}
    {visibility "General_UI_tree" "@CUI_TCPMKin" "false"}
    {visibility "General_UI_tree" "@CUI_TiltingKin" "false"}
    {visibility "General_UI_tree" "@CUI_MotionSettingPolar" "false"}
    {visibility "CONF_SPF_cycle" "combine_rapid_arc_motion" "false"}
    {visibility "General_UI_tree" "@CUI_CtrlOutModePlane" "false"}
    {visibility "General_UI_tree" "@CUI_CtrlOutModeTCPM" "false"}
    {visibility "Heidenhain_UI_tree" "@CUI_PlaneSpatial" "false"}
    # 5th axis settings invisible
    {visibility "General_UI_tree" "@CUI_MachKin5th" "false"}
    {visibility "KinContainer_MTB" "mom_kin_rotary_axis_solution" "false"}
    {visibility "General_UI_tree" "@CUI_MachkinPreferOutput" "false"}
    {visibility "CONF_CTRL_clamp" "fifth_axis" "false"}
} elseif {[string index $propValue 0] == 4} {
    # 4th axis settings visible
    {visibility "General_UI_tree" "@CUI_MachKin4th" "true"}
    {visibility "CONF_CTRL_clamp" "fourth_axis" "true"}
    {visibility "General_UI_tree" "@CUI_TCPMKin" "true"}
    {visibility "General_UI_tree" "@CUI_TiltingKin" "true"}
    {visibility "General_UI_tree" "@CUI_MotionSettingPolarGroup" "true"}
    {visibility "CONF_SPF_cycle" "combine_rapid_arc_motion" "true"}
    {visibility "General_UI_tree" "@CUI_CtrlOutModePlane" "true"}
    {visibility "General_UI_tree" "@CUI_CtrlOutModeTCPM" "true"}
    {visibility "Heidenhain_UI_tree" "@CUI_PlaneSpatial" "true"}
    # 5th axis settings invisible
    {visibility "General_UI_tree" "@CUI_MachKin5th" "false"}
    {visibility "KinContainer_MTB" "mom_kin_rotary_axis_solution" "false"}
    {visibility "General_UI_tree" "@CUI_MachkinPreferOutput" "false"}
    {visibility "CONF_CTRL_clamp" "fifth_axis" "false"}
} else {
    # 4th axis settings visible
    {visibility "General_UI_tree" "@CUI_MachKin4th" "true"}
    {visibility "CONF_CTRL_clamp" "fourth_axis" "true"}
    {visibility "General_UI_tree" "@CUI_TCPMKin" "true"}
    {visibility "General_UI_tree" "@CUI_TiltingKin" "true"}
    {visibility "General_UI_tree" "@CUI_MotionSettingPolarGroup" "true"}
    {visibility "CONF_SPF_cycle" "combine_rapid_arc_motion" "true"}
    {visibility "General_UI_tree" "@CUI_CtrlOutModePlane" "true"}
    {visibility "General_UI_tree" "@CUI_CtrlOutModeTCPM" "true"}
    {visibility "Heidenhain_UI_tree" "@CUI_PlaneSpatial" "true"}
    # 5th axis settings invisible
    {visibility "General_UI_tree" "@CUI_MachKin5th" "true"}
    {visibility "KinContainer_MTB" "mom_kin_rotary_axis_solution" "true"}
    {visibility "General_UI_tree" "@CUI_MachkinPreferOutput" "true"}
    {visibility "CONF_CTRL_clamp" "fifth_axis" "true"}
}

LIB_GE_CONF_define_IPL_conditions KinContainer_MTB mom_kin_machine_type if {$propValue == "3_axis_mill" } {
    {visibility "CONF_SPF_advanced_settings" "optimized_mode" "true"}
} elseif {$propValue == "2_axis_lathe"} {
    {visibility "CONF_SPF_advanced_settings" "optimized_mode" "false"}
} else {
    {visibility "CONF_SPF_advanced_settings" "optimized_mode" "false"}
}

LIB_GE_CONF_define_IPL_conditions CONF_CTRL_setting local_ns_output if {$propValue == 1 || [KinContainer_MTB mom_kin_machine_type] < 4 || [KinContainer_MTB mom_kin_machine_type] == "4_axis_wedm"} {
    {visibility "General_UI_tree" "@CUI_TCPMKin" "false"}
    {visibility "General_UI_tree" "@CUI_TiltingKin" "false"}
} else {
    {visibility "General_UI_tree" "@CUI_TCPMKin" "true"}
    {visibility "General_UI_tree" "@CUI_TiltingKin" "true"}
}


