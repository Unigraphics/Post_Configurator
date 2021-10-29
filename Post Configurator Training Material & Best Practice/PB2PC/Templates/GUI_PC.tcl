#############################################################################################
#
#	Rapid Customizing Layer
#
#############################################################################################
#
#	Copyright 2020 Siemens Digital Industries Software
#				All Rights Reserved.
#
#############################################################################################
# Description
# Generic layer for reuse controller independent. To reuse import the layer in
# an existing post processor by the Layer Import option from Post Configurator.
#############################################################################################
# History
# 02 Feb 2020   TJ   Initial version
#
#############################################################################################
#============================================================================================================================
#Following Additional Properties created for overriding existing output and to do custumization before/after required output
#=============================================================================================================================
LIB_GE_CREATE_obj splm_tree {UI_TREE} {
    LIB_GE_property_ui_name        "UIName"
    LIB_GE_property_ui_tooltip     "UITooltip"

set id "splm_root"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Post Builder Import}}
    set descr($id)          {{Node description}}
    set group_status($id)   0
    set ui_parent($id)      "root"
    set ui_sequence($id)    -1

set id "splm_pgmst_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Start of Program}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    0

set id "splm_pgmst_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for Start of program}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_pgmst_node"
    set ui_sequence($id)    0

set id "splm_sop_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Start of Path}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    1
    
set id "splm_sop_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for Start of path}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_sop_node"
    set ui_sequence($id)    1

set id "splm_toolchange_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Tool Change}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    2
    
set id "splm_toolchange_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for Tool Change}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_toolchange_node"
    set ui_sequence($id)    2

set id "splm_inimov_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{Initial Move}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    3
    
set id "splm_inimov_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for Initial Move}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_inimov_node"
    set ui_sequence($id)    3

set id "splm_firstmov_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{First Move}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    4
    
set id "splm_firstmov_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for First Move}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_firstmov_node"
    set ui_sequence($id)    4

set id "splm_eop_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{End of Path}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    5
    
set id "splm_eop_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for End of Path}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_eop_node"
    set ui_sequence($id)    5

set id "splm_pgmend_node"
    set $id "0"
    set datatype($id)       "NODE"
    set access($id)         222
    set dialog($id)         {{End of Program}}
    set descr($id)          {{Node description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_root"
    set ui_sequence($id)    6
    
set id "splm_pgmend_group"
    set $id "0"
    set datatype($id)       "GROUP"
    set access($id)         222
    set dialog($id)         {{Customization for End of Program}}
    set descr($id)          {{Group description}}
    set group_status($id)   1
    set ui_parent($id)      "splm_pgmend_node"
    set ui_sequence($id)    6

}

LIB_GE_CREATE_obj splm_rapid_properties {} {
    LIB_GE_property_ui_name        "Name"
    LIB_GE_property_ui_tooltip     "Tooltip"

set id "splm_pgmst_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before start of program}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_pgmst_group"
    set ui_sequence($id)    -1

set id "splm_pgmst_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after start of program}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_pgmst_group"
    set ui_sequence($id)    -1


set id "splm_sop_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before start of path}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_sop_group"
    set ui_sequence($id)    -1

set id "splm_sop_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after start of path}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_sop_group"
    set ui_sequence($id)    -1
    
    set id "splm_toolchange_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before Toolchange}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_toolchange_group"
    set ui_sequence($id)    -1
    
set id "splm_toolchange_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after Toolchange}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_toolchange_group"
    set ui_sequence($id)    -1

set id "splm_inimov_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before Initial Move}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_inimov_group"
    set ui_sequence($id)    -1

set id "splm_inimo_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after Initial Move}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_inimov_group"
    set ui_sequence($id)    -1

set id "splm_firstmov_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before first Move}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_firstmov_group"
    set ui_sequence($id)    -1

set id "splm_firstmov_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after first Move}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_firstmov_group"
    set ui_sequence($id)    -1


set id "splm_eop_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before End of path}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_eop_group"
    set ui_sequence($id)    -1

set id "splm_eop_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after End of path}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_eop_group"
    set ui_sequence($id)    -1

set id "splm_pgmend_before"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization before End of program}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_pgmend_group"
    set ui_sequence($id)    -1

set id "splm_pgmend_after"
    set $id ""
    set options($id)        {Specify}
    set options_ids($id)    {*VALUE*}
    set datatype($id)       "COMMANDBLOCK"
    set access($id)         222
    set dialog($id)         {{Customization after End of program}}
    set descr($id)          {{A commandblock Property}}
    set ui_parent($id)      "splm_pgmend_group"
    set ui_sequence($id)    -1

}

LIB_GE_command_buffer_edit_prepend MOM_start_of_program_LIB MOM_start_of_program_LIB_ENTRY_start {LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_pgmst_before} _RapidCstPSBefore
LIB_GE_command_buffer_edit_append MOM_start_of_program_LIB MOM_start_of_program_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_pgmst_after } _RapidCstPSAfter
LIB_GE_command_buffer_edit_prepend MOM_start_of_path_LIB MOM_start_of_path_LIB_ENTRY_start { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_sop_before } _RapidCstSopBefore
LIB_GE_command_buffer_edit_append MOM_start_of_path_LIB MOM_start_of_path_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_sop_after } _RapidCstSopAfter
LIB_GE_command_buffer_edit_prepend MOM_tool_change_LIB MOM_tool_change_LIB_ENTRY_start { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_toolchange_before } _RapidCstTcBefore
LIB_GE_command_buffer_edit_prepend MOM_tool_change_LIB MOM_tool_change_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_toolchange_after } _RapidCstTcAfter
LIB_GE_command_buffer_edit_prepend MOM_initial_move_LIB MOM_initial_move_LIB_ENTRY_start { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_inimov_before } _RapidCstIniMovBefore 
LIB_GE_command_buffer_edit_append MOM_initial_move_LIB MOM_initial_move_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_inimo_after } _RapidCstIniMovAfter
LIB_GE_command_buffer_edit_prepend MOM_first_move_LIB MOM_first_move_LIB_ENTRY_start { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_firstmov_before } _RapidCstFirstMovBefore
LIB_GE_command_buffer_edit_append MOM_first_move_LIB MOM_first_move_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_firstmov_after } _rapidCstFirstMovAfter
LIB_GE_command_buffer_edit_prepend MOM_end_of_path_LIB MOM_end_of_path_LIB_ENTRY_start { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_eop_before } _RapidCstEopBefore
LIB_GE_command_buffer_edit_append MOM_end_of_path_LIB MOM_end_of_path_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_eop_after } _RapidCstEopAfter
LIB_GE_command_buffer_edit_prepend MOM_end_of_program_LIB MOM_end_of_program_LIB_ENTRY_start { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_pgmend_before } _RapidCstPgmEndBefore
LIB_GE_command_buffer_edit_append MOM_end_of_program_LIB MOM_end_of_program_LIB_ENTRY_end { LIB_CONF_do_prop_custom_proc splm_rapid_properties splm_pgmend_after } _RapidCstPgmEndAfter
LIB_GE_command_buffer_edit_append MOM_start_of_program_LIB MOM_start_of_program_LIB_ENTRY_start { MOM_set_turbo_before_motion ON } _ActivateAdditionalTurboModeOptions
