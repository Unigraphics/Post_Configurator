

set nondecrypted 1

proc postcon_initialize_sys_service {} {

	uplevel #0 {

#STAY#		########## SYSTEM VARIABLE DECLARATIONS ##############
#STAY#		set mom_sys_cir_vector                        "Vector - Arc Start to Center"
#STAY#  	set mom_sys_helix_pitch_type                  "rise_revolution"
#STAY#		set mom_sys_zero                              "0"
#STAY#		set mom_sys_opskip_block_leader               "/"
#STAY#		set mom_sys_seqnum_start                      "10"
#STAY#		set mom_sys_seqnum_incr                       "10"
#STAY#		set mom_sys_seqnum_freq                       "1"
#STAY#		set mom_sys_seqnum_max                        "9999"
#STAY#		set mom_sys_lathe_x_factor                    "1"
#STAY#		set mom_sys_lathe_y_factor                    "1"
#STAY#		set mom_sys_lathe_z_factor                    "1"
#STAY#		set mom_sys_lathe_i_factor                    "1"
#STAY#		set mom_sys_lathe_j_factor                    "1"
#STAY#		set mom_sys_lathe_k_factor                    "1"
#STAY#		set mom_sys_leader(N)                         "N"
#STAY#		set mom_sys_cycle_feed_mode                   "MMPM"
#STAY#		set mom_sys_feed_param(IPM,format)            "Feed_IPM"
#STAY#		set mom_sys_feed_param(IPR,format)            "Feed_IPR"
#STAY#		set mom_sys_feed_param(FRN,format)            "Feed_INV"
#STAY#		set mom_sys_contour_feed_mode(ROTARY)         "MMPM"
#STAY#		set mom_sys_contour_feed_mode(LINEAR_ROTARY)  "MMPM"
#STAY#		set mom_sys_feed_param(DPM,format)            "Feed_DPM"
#STAY#		set mom_sys_rapid_feed_mode(ROTARY)           "MMPM"
#STAY#		set mom_sys_rapid_feed_mode(LINEAR_ROTARY)    "MMPM"
#STAY#		set mom_sys_feed_param(MMPM,format)           "Feed_MMPM"
#STAY#		set mom_sys_feed_param(MMPR,format)           "Feed_MMPR"
#STAY#		set mom_sys_linearization_method              "angle"
#STAY#
#STAY#		####### KINEMATIC VARIABLE DECLARATIONS ##############
#STAY#		set mom_kin_4th_axis_direction                "MAGNITUDE_DETERMINES_DIRECTION"
#STAY#		set mom_kin_4th_axis_incr_switch              "OFF"
#STAY#		set mom_kin_4th_axis_rotation                 "standard"
#STAY#		set mom_kin_5th_axis_direction                "MAGNITUDE_DETERMINES_DIRECTION"
#STAY#		set mom_kin_5th_axis_incr_switch              "OFF"
#STAY#		set mom_kin_5th_axis_rotation                 "standard"
#STAY#		set mom_kin_clamp_time                        "2.0"
#STAY#		set mom_kin_cycle_plane_change_per_axis       "0"
#STAY#		set mom_kin_cycle_plane_change_to_lower       "0"
#STAY#		set mom_kin_flush_time                        "2.0"
#STAY#		set mom_kin_linearization_flag                "1"
#STAY#		set mom_kin_linearization_tol                 "0.01"
#STAY#		set mom_kin_max_dpm                           "10000"
#STAY#		set mom_kin_max_fpm                           "15000"
#STAY#		set mom_kin_max_fpr                           "1000"
#STAY#		set mom_kin_max_frn                           "1000"
#STAY#		set mom_kin_min_dpm                           "0.0"
#STAY#		set mom_kin_min_fpm                           "0.1"
#STAY#		set mom_kin_min_fpr                           "0.1"
#STAY#		set mom_kin_min_frn                           "0.01"
#STAY#		set mom_kin_pivot_gauge_offset                "0.0"
#STAY#		set mom_kin_rapid_feed_rate                   "10000"
#STAY#		set mom_kin_retract_distance                  "500"
#STAY#		set mom_kin_rotary_axis_method                "PREVIOUS"
#STAY#		set mom_kin_tool_change_time                  "12.0"
#STAY#		set mom_kin_x_axis_limit                      "1000"
#STAY#		set mom_kin_y_axis_limit                      "1000"
#STAY#		set mom_kin_z_axis_limit                      "1000"

	}
}

postcon_initialize_sys_service
CONF_CTRL_setting set local_ns_output 1
