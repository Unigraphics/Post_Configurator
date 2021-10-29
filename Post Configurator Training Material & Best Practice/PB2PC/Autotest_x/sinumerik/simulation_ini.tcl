##############################################################
# This file is used to output ini file for CSE simulaiton. It
# should be sourced in postprocessor as a user tcl file.
#
# <lili 2016-04-26> NX11 update - don't convert unit for inch.
# <lili 2016-08-26> NX1102 - change tool data index.
# <lili 2016-12-22> NX1102 - support multi-tool and refine tool
#                            data output of turret carrier.
###############################################################

proc ISV_ini_convert_unit {var} {
#<lili 2016-04-26> NX11 update - add return at start
return
   global mom_kin_output_unit
   global mom_part_units
   if {![info exists mom_part_units]} {
return
   }
   upvar 1 $var value
   if {[string compare $mom_part_units "metric"]} {
      set value [expr $value * 25.4]
   }
}
     
     
#----------------------------------------------------------------
#Return the type num for tool;
#default mill tool 121;
#default lathe tool 500;
#default drill tool 200.
#----------------------------------------------------------------
proc ISV_ini_map_tool_type {tool_index} {
   global mom_tool_ug_subtype
   global mom_tool_ug_type
   global mom_tool_diameter
   global mom_tool_length
   global mom_tool_corner1_radius
   global mom_tool_taper_angle mom_tool_name mom_tool_tip_angle
       
   global mom_isv_tool_type
   global mom_isv_tool_diameter
   global mom_isv_tool_x_correction
   global mom_isv_tool_r_correction
   global mom_isv_tool_corner1_radius
   global mom_isv_tool_point_angle
   
   switch $mom_isv_tool_type($tool_index) {
      "Milling" {       
          if { [info exists mom_isv_tool_corner1_radius($tool_index)] && $mom_isv_tool_corner1_radius($tool_index) > 0.0 } {
          #121 End mill (with fillet)
   return 121
          } else {
          #120 End mill (without fillet)
   return 120
          }            
      }
      "Drilling" {
   return 200
      }
      "Turning" {
   return 500
      }
      "Grooving" {
   return 520
      }
      "Threading" {
   return 540
      }
      default {
   return 100
      }
   }
}
      
#=============================================================
proc ISV_ini_get_mcs_info { } {
#=============================================================
   
   global mom_sys_tool_list_output_type
   global isv_ini_mcs_info
   global mom_kin_output_unit
   global mom_part_unit
   global mom_operation_name_list
   global mom_mcsname_attach_opr
   global mom_mcs_info
   global mom_post_in_simulation
   
   catch {MOM_ask_mcs_info}
   #get operations' mcs list
   set mcs_list [list]
   if {[info exists mom_operation_name_list]} {
      foreach operation $mom_operation_name_list {
         if {[llength $mcs_list] == 0} {
            lappend mcs_list $mom_mcsname_attach_opr($operation)
         } else {
            set flag 0
            foreach mcs_name $mcs_list {               
               if {[string match $mcs_name $mom_mcsname_attach_opr($operation)]} { set flag 1}            
            } 
            if {$flag ==0} {
               lappend mcs_list $mom_mcsname_attach_opr($operation)
            }       
         }         
      }
   } 
   
 
   # get Machine zero matrix and origin
   global mom_sim_result mom_sim_result1
   catch {MOM_ask_machine_zero_junction_name}
   if {[info exists mom_sim_result] && $mom_sim_result != ""} {
      MOM_ask_init_junction_xform $mom_sim_result
   } else {
      if {[info exists mom_post_in_simulation] && ($mom_post_in_simulation == "CSE" || $mom_post_in_simulation == "SYN")} {
         MOM_output_to_listing_device "No machine zero junction!"
      }
      return
   }
 
   set i 0
   foreach value $mom_sim_result {
      set main_mcs_matrix($i) $value
      incr i
   }
   
   set i 0
   foreach value $mom_sim_result1 {
      set main_mcs_origin($i) $value
      incr i
   }
    

   #get fixture MCS list
   set fixture_list [list]
   foreach mcs $mcs_list {
     # MOM_output_to_listing_device "[info exists mom_mcs_info($mcs,offset_val)]"
     # MOM_output_to_listing_device "parent [info exists mom_mcs_info($mom_mcs_info($mcs,parent),offset_val)]"

     #<lili 2013-05-01> Update conditions to get fixture offset coordinate name
     #                  Related to PR6845685, cannot use  $mom_mcs_info($mom_mcs_info($mcs,parent),offset_val)!=0
      while { $mcs != "" && $mom_mcs_info($mcs,parent) != "" && $mom_mcs_info($mcs,purpose)==0 && $mom_mcs_info($mcs,output_type)!=2 } {
         set mcs $mom_mcs_info($mcs,parent)
      }

      if {$mcs != "" && $mom_mcs_info($mcs,purpose)==0 && $mom_mcs_info($mcs,output_type)==2} {
         if {[llength $fixture_list]==0} {         
            lappend fixture_list $mcs
         } else {    
            set flag 0
            foreach fixture $fixture_list {
               if {![string compare $fixture $mcs]} {set flag 1}
            }
            if {$flag ==0} {
               lappend fixture_list $mcs
            } 
         }
      }
   }

   #<lili 2015-03-12> Don't output Y offset for lathe machine. 
   global ini_file_channel_number
   global mom_kin_machine_type
   set isv_ini_mcs_info(0) ""
   set isv_ini_mcs_info(1) ""
   set isv_ini_mcs_info(2) ""
   if {[info exists ini_file_channel_number] && $ini_file_channel_number ==2} {
      append isv_ini_mcs_info(1) "\n\$P_UIFR\[0\]=CTRANS(X1,0.0,Y1,0.0,Z1,0.0)\n"
      append isv_ini_mcs_info(2) "\n\$P_UIFR\[0\]=CTRANS(X2,0.0,Z2,0.0)\n"
   } else {
      if {[info exists mom_kin_machine_type] && [string match "*lathe*" $mom_kin_machine_type] } {
         append isv_ini_mcs_info(0) "\n\$P_UIFR\[0\]=CTRANS(X,0.0,Z,0.0)\n"
      } else {
         append isv_ini_mcs_info(0) "\n\$P_UIFR\[0\]=CTRANS(X,0.0,Y,0.0,Z,0.0)\n"
      }
   }
   

   foreach mcs $fixture_list {     
      #Convert offset from ABS to Machine MCS
      set origin_v(0) [expr $mom_mcs_info($mcs,org,0) - $main_mcs_origin(0)]
      set origin_v(1) [expr $mom_mcs_info($mcs,org,1) - $main_mcs_origin(1)]
      set origin_v(2) [expr $mom_mcs_info($mcs,org,2) - $main_mcs_origin(2)]
      MTX3_vec_multiply origin_v main_mcs_matrix temp_offset 

      #<lili 2013-06-20> Update unit convertion for origin offset
	  #<lili 2016-04-26> Remove unit convertion in NX11.

      global mom_output_unit
      if {$mom_output_unit == "IN" && 0} {
         set temp_x_offset [format "%-.6f" [expr 25.4*$temp_offset(0)]]
         set temp_y_offset [format "%-.6f" [expr 25.4*$temp_offset(1)]]
         set temp_z_offset [format "%-.6f" [expr 25.4*$temp_offset(2)]]
      } else {
         set temp_x_offset [format "%-.6f" $temp_offset(0)]
         set temp_y_offset [format "%-.6f" $temp_offset(1)]
         set temp_z_offset [format "%-.6f" $temp_offset(2)]
      }
      
      if {[info exists ini_file_channel_number] && $ini_file_channel_number ==2} {
         append isv_ini_mcs_info(1) "\$P_UIFR\[$mom_mcs_info($mcs,offset_val)\]=CTRANS(X1,$temp_x_offset,Y1,$temp_y_offset,Z1,$temp_z_offset)\n"
         append isv_ini_mcs_info(2) "\$P_UIFR\[$mom_mcs_info($mcs,offset_val)\]=CTRANS(X2,$temp_x_offset,Z2,$temp_z_offset)\n"
      } else {
         if {[info exists mom_kin_machine_type] && [string match "*lathe*" $mom_kin_machine_type] } {
            append isv_ini_mcs_info(0) "\$P_UIFR\[$mom_mcs_info($mcs,offset_val)\]=CTRANS(X,$temp_x_offset,Z,$temp_z_offset)\n"
         } else {
            append isv_ini_mcs_info(0) "\$P_UIFR\[$mom_mcs_info($mcs,offset_val)\]=CTRANS(X,$temp_x_offset,Y,$temp_y_offset,Z,$temp_z_offset)\n"
         }
      }
   }
}

#=============================================================
proc ISV_ini_get_tool_info { } {
#=============================================================
   global mom_isv_tool_count
   global mom_isv_tool_name
   global mom_isv_tool_type
   global mom_isv_tool_number
   global mom_isv_tool_carrier_id
   global mom_isv_tool_type
   global mom_isv_tool_flute_length
   global mom_isv_tool_x_correction
   global mom_isv_tool_y_correction
   global mom_isv_tool_z_correction
   global mom_isv_tool_r_correction
   global mom_isv_tool_carrier_name
   global mom_isv_tool_pocket_id
   global mom_isv_tool_diameter
   global mom_isv_tool_nose_radius
   global mom_isv_tool_corner1_radius
   global mom_isv_tool_adjust_register
   global mom_isv_tracking_point_count
   global isv_ini_tool_info 
   global isv_ini_tool_count
   global mom_isv_tool_channel_id
   global mom_isv_tool_p_number
   global mom_multi_channel_mode
   global mom_isv_tool_device_name
   global mom_isv_tool_adjust_reg_toggle
   global mom_isv_tool_multitool_index
   global mom_isv_multitool_name
   global mom_isv_tool_multitool_index_notch
   global mom_isv_tool_device_name
   global mom_isv_device_name
   global mom_isv_device_count
   global mom_isv_device_type
   global isv_tool_device_type
   
   set isv_ini_tool_count(0) 0
   set isv_ini_tool_count(1) 0
   set isv_ini_tool_count(2) 0
   
   set isv_ini_tool_info(0) [list]
   set isv_ini_tool_info(1) [list]
   set isv_ini_tool_info(2) [list]

   set tool_data_list [list]
   set tool_number_list [list]
 
  #<lili 2014-07-01> Don't output duplicated tool data  
  #                  Don't output data with tool number/register number is zero
  #<lili 2014-09-09> Last tool tracking point of milling and drilling tool comes from tool tab.
  #                  revised warning message.

   for {set i 0} {$i<$mom_isv_tool_count} {incr i} {

      set tool_tp_list($i) [list]
      set tool_tp_number_list [list]
   
      # check if there are duplicated tool number data and zero number
      # tool on turret carrier could have duplicated tool number for same location

      if {$mom_isv_tool_number($i) == 0} {
         MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) has tool number zero! Its info is not output into to_ini.ini file."

      } else {        
         set isv_tool_device_type($i) "None"

         # <lili 2016-10-10> Add check for multi-tool. Multi-tool should only attached on upper spindle.
         if {[info exists mom_isv_tool_multitool_index($i)] && $mom_isv_tool_multitool_index($i) >=0 } {

            if {![info exists isv_multitool_number($mom_isv_tool_multitool_index($i))]} {
               if {[lsearch $tool_number_list $mom_isv_tool_number($i)] >=0 } {
                  MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) has tool number $mom_isv_tool_number($i) duplicated with other tool! Its info is not output into to_in.ini file."
                  continue
               }
               set isv_multitool_number($mom_isv_tool_multitool_index($i)) $mom_isv_tool_number($i) 
            } else {
               if {$mom_isv_tool_number($i) != $isv_multitool_number($mom_isv_tool_multitool_index($i))} {
                  MOM_output_to_listing_device "Multi-tool notch $mom_isv_tool_name($i) has differernt tool number than other notch. It could cause NC code and simulation wrong."
               }
            }

         } else {

            # Tools on same device should have same tool number,except device is HEAD.
            for {set ii 0} {$ii < $mom_isv_device_count} {incr ii} {
               if {$mom_isv_device_name($ii) == $mom_isv_tool_device_name($i)} {
                  set isv_tool_device_type($i) $mom_isv_device_type($ii)
                  break
               }
            }

            if {[info exists mom_isv_tool_device_name($i)] && $mom_isv_tool_device_name($i) != "n/a" && $isv_tool_device_type($i) != "HEAD"} {

               if {[info exists isv_tool_device_number($mom_isv_tool_device_name($i))]} {
                  if {$mom_isv_tool_number($i) != $isv_tool_device_number($mom_isv_tool_device_name($i))} {
                     MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) has different tool number than other tools on device $mom_isv_tool_device_name($i) ! It could cause NC code and simulation wrong."
                  }
               } else {
                  if {[lsearch $tool_number_list $mom_isv_tool_number($i)] >=0 } {
                     MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) has tool number $mom_isv_tool_number($i) duplicated with other tool! Its info is not output into to_in.ini file."
                     continue
                  }
                  set isv_tool_device_number($mom_isv_tool_device_name($i)) $mom_isv_tool_number($i)
               }

            } else {
                 
               if {[lsearch $tool_number_list $mom_isv_tool_number($i)] >=0 } {
                  MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) has tool number $mom_isv_tool_number($i) duplicated with other tool! Its info is not output into to_in.ini file."
                  continue
               }  
            }
         }


         # check if there are duplicated tool adjust register number or zero number for tracking point
         if {[string match "Milling" $mom_isv_tool_type($i)] ||[string match "Drilling" $mom_isv_tool_type($i)]} {
            set tracking_point_count($i) [expr $mom_isv_tracking_point_count($i) -1]
         } else {
            set tracking_point_count($i) $mom_isv_tracking_point_count($i)
         }

         set tracking_point_flag 0
         for {set j 0} {$j<$tracking_point_count($i)} {incr j} {

            if {$mom_isv_tool_adjust_register($i,$j) == 0} {
               if {![info exists mom_isv_tool_adjust_reg_toggle($i,$j)] || $mom_isv_tool_adjust_reg_toggle($i,$j) == 1} {
                  set tracking_point_flag 1 
               }
            } elseif { [lsearch $tool_tp_number_list $mom_isv_tool_adjust_register($i,$j)] >=0} {   
                  MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) adjust register number $mom_isv_tool_adjust_register($i,$j) is duplicated!"
                  MOM_output_to_listing_device "The tracking point's data is not output into to_ini.ini file!" 
            } else {
               lappend tool_tp_number_list $mom_isv_tool_adjust_register($i,$j)
               lappend tool_tp_list($i) $j
            }
         }

         if {[string match "Milling" $mom_isv_tool_type($i)] ||[string match "Drilling" $mom_isv_tool_type($i)]} {
            if {$mom_isv_tool_adjust_register($i,$tracking_point_count($i)) !=0 && [lsearch $tool_tp_number_list $mom_isv_tool_adjust_register($i,$tracking_point_count($i))] <0} {
               lappend tool_tp_number_list $mom_isv_tool_adjust_register($i,$tracking_point_count($i))
               lappend tool_tp_list($i) $tracking_point_count($i)
            }
         }

         if {[llength $tool_tp_list($i)] == 0} {
            set tracking_point_flag 2 
         } else {
            lappend tool_number_list $mom_isv_tool_number($i)
            lappend tool_data_list $i
         }

         if {$tracking_point_flag == 1} {
            MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) has tracking points with adjust register number as zero."
            MOM_output_to_listing_device "These tracking points are not output into to_ini.ini file! Adjust register from tool tab will be output."
         } elseif {$tracking_point_flag == 2} {
            MOM_output_to_listing_device "Tool $mom_isv_tool_name($i) is not output into to_ini.ini file because all adjust registers are zero!"
         }
      } 
   }

   set index 0 
   set index_count 0
   foreach i $tool_data_list {
       set tool_info ""

       # Get multi-tool index and name
       if {[info exists mom_isv_tool_multitool_index($i)] && $mom_isv_tool_multitool_index($i) >=0} {

          if {![info exists multi_tool_index($mom_isv_tool_multitool_index($i))]} {
             incr index_count
             set index $index_count
             set multi_tool_index($mom_isv_tool_multitool_index($i)) $index
             append tool_info "\$TC_TP1\[$index\]=$mom_isv_tool_number($i)\n" 
             append tool_info "\$TC_TP2\[$index\]=\"$mom_isv_multitool_name($mom_isv_tool_multitool_index($i))\"\n" 
             append tool_info "\$TC_TP8\[$index\]=10\n"      
          } else {
             set index $multi_tool_index($mom_isv_tool_multitool_index($i))
          }

       } else {
        # Tools on same device will have same index number and use device name as tool name, except device is "HEAD".
          if {[info exists mom_isv_tool_device_name($i)] && $mom_isv_tool_device_name($i) != "n/a" && $isv_tool_device_type($i) != "HEAD"} {
             if {[info exists isv_device_tool_index($mom_isv_tool_device_name($i))]} {
                set index $isv_device_tool_index($mom_isv_tool_device_name($i))
             } else {
                incr index_count
                set index $index_count
                set isv_device_tool_index($mom_isv_tool_device_name($i)) $index
                append tool_info "\$TC_TP1\[$index\]=$mom_isv_tool_number($i)\n"  
                append tool_info "\$TC_TP2\[$index\]=\"$mom_isv_tool_device_name($i)\"\n" 
                append tool_info "\$TC_TP8\[$index\]=10\n"
             }
          } else {            
             incr index_count
             set index $index_count
             append tool_info "\$TC_TP1\[$index\]=$mom_isv_tool_number($i)\n"  
             append tool_info "\$TC_TP2\[$index\]=\"$mom_isv_tool_name($i)\"\n" 
             append tool_info "\$TC_TP8\[$index\]=10\n"    
          }
       }

       if {$mom_isv_tracking_point_count($i)==0} {set mom_isv_tracking_point_count($i) 1}

       foreach j $tool_tp_list($i) {

          if {![info exists mom_isv_tool_adjust_register($i,$j)]} {set mom_isv_tool_adjust_register($i,$j) 1}

          # Get multi-tool notch angle
          if {[info exists mom_isv_tool_multitool_index($i)] && $mom_isv_tool_multitool_index($i) >=0} {
             append tool_info "\$TC_DP_NOTCH\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$mom_isv_tool_multitool_index_notch($i)\n"
          }

          append tool_info "\$TC_DP1\[$index,$mom_isv_tool_adjust_register($i,$j)\]=[ISV_ini_map_tool_type $i]\n" 

          if {([string match "Milling" $mom_isv_tool_type($i)] ||[string match "Drilling" $mom_isv_tool_type($i)]) && \
              [info exists mom_isv_tool_flute_length($i)] } {
             set temp $mom_isv_tool_flute_length($i)
             catch {ISV_ini_convert_unit temp}
             set temp [format "%-.4f" $temp]
             append tool_info "\$TC_DP2\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
          } elseif {[info exists mom_isv_tool_p_number($i,$j)]} {
             append tool_info "\$TC_DP2\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$mom_isv_tool_p_number($i,$j)\n"
          }
	  
          #<lili 2016-03-28> use mom_isv_tool_x(y)(Z)_mount instead of mom_isv_tool_x(y)(z)_correction for tool on RAH.
	  global mom_isv_tool_x_mount mom_isv_tool_y_mount mom_isv_tool_z_mount          
          if {$isv_tool_device_type($i) == "HEAD"} {
             if { [info exists mom_isv_tool_x_mount($i,$j)] } {
                set temp $mom_isv_tool_x_mount($i,$j)
                catch {ISV_ini_convert_unit temp}
                set temp [format "%-.4f" $temp]
                append tool_info "\$TC_DP3\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
             }
          } else {
             if { [info exists mom_isv_tool_x_correction($i,$j)] } {
                set temp $mom_isv_tool_x_correction($i,$j)
                catch {ISV_ini_convert_unit temp}
                set temp [format "%-.4f" $temp]
                append tool_info "\$TC_DP3\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
             }
          }
          
          if {$isv_tool_device_type($i) == "HEAD"} {
             if { [info exists mom_isv_tool_y_mount($i,$j)] } {
                set temp $mom_isv_tool_y_mount($i,$j)
                catch {ISV_ini_convert_unit temp}
                set temp [format "%-.4f" $temp]
                append tool_info "\$TC_DP4\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
             }
          } else {
             if { [info exists mom_isv_tool_y_correction($i,$j)] } {
                set temp $mom_isv_tool_y_correction($i,$j)
                catch {ISV_ini_convert_unit temp}
                set temp [format "%-.4f" $temp]
                append tool_info "\$TC_DP4\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
             }
          }

          if {$isv_tool_device_type($i) == "HEAD"} {
             if { [info exists mom_isv_tool_z_mount($i,$j)] } {
                set temp $mom_isv_tool_z_mount($i,$j)
                catch {ISV_ini_convert_unit temp}
                set temp [format "%-.4f" $temp]
                append tool_info "\$TC_DP5\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
             }
          } else {
             if { [info exists mom_isv_tool_z_correction($i,$j)] } {
                set temp $mom_isv_tool_z_correction($i,$j)
                catch {ISV_ini_convert_unit temp}
                set temp [format "%-.4f" $temp]
                append tool_info "\$TC_DP5\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
             }
          }

          if {([string match "Milling" $mom_isv_tool_type($i)] ||[string match "Drilling" $mom_isv_tool_type($i)]) && \
              [info exists mom_isv_tool_r_correction($i,$j)]} {

             set temp $mom_isv_tool_r_correction($i,$j)
             catch {ISV_ini_convert_unit temp}
             set temp [format "%-.4f" $temp]
             append tool_info "\$TC_DP6\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"

          } elseif {[info exists mom_isv_tool_nose_radius($i)]} {

             set temp $mom_isv_tool_nose_radius($i)
             catch {ISV_ini_convert_unit temp }
             set temp [format "%-.4f" $temp]
             append tool_info "\$TC_DP6\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
          }

          if { [info exists mom_isv_tool_corner1_radius($i)] } {
             set temp $mom_isv_tool_corner1_radius($i)
             catch {ISV_ini_convert_unit temp}
             set temp [format "%-.4f" $temp]
             append tool_info "\$TC_DP7\[$index,$mom_isv_tool_adjust_register($i,$j)\]=$temp\n"
          }
       }

       #<lili 2013-06-20> Fix below check condition. 
       #<szl 2016-06-29> Add a check condition to see if pocket id is 0

       if {![info exists mom_isv_tool_pocket_id($i)] || [string length [string trim $mom_isv_tool_pocket_id($i)]] == 0 || \
            $mom_isv_tool_pocket_id($i) == "n/a" || $mom_isv_tool_pocket_id($i) == 0 } {
          append tool_info "\$TC_MPP6\[1,1\]=$index\n\n\n"
       } else {
          append tool_info "\$TC_MPP6\[1,$mom_isv_tool_pocket_id($i)\]=$index\n\n\n"
       }
       if {$mom_isv_tool_channel_id($i) == 1} {
          append isv_ini_tool_info(1) $tool_info
          incr isv_ini_tool_count(1)
       } elseif {$mom_isv_tool_channel_id($i) == 2} {
          append isv_ini_tool_info(2) $tool_info
          incr isv_ini_tool_count(2)
       } else {
          append isv_ini_tool_info(0) $tool_info
          incr isv_ini_tool_count(0)
       }
   }

   global ini_file_channel_number
   if {![info exists mom_multi_channel_mode]} {        
      set ini_file_channel_number 1 
      if {$isv_ini_tool_count(2)>0 || $isv_ini_tool_count(1)>0  } {
         set ini_file_channel_number 2
      }
   } else {
      set ini_file_channel_number 2
   }
}

#==============================================================
proc ISV_ini_get_env_dir_info {} {
#===============================================================
#2014-05-14-Allen - The proc it is used to get env dir path.
#2015-11-20 szl   - Change the warning message while ENV Var UGII_CAM_CSE_USER_DIR is not set
  global mom_part_name 
  #Check to see if ENV Var UGII_CAM_CSE_USER_DIR exists - if so then use this for temp file location otherwise use dirname obtained from mom_definition_file_name.
  set part_dir [MOM_ask_env_var UGII_CAM_CSE_USER_DIR]
  if {$part_dir == ""} {
     #ENV var UGII_CAM_CSE_USER_DIR is NOT set!
     MOM_output_to_listing_device "Environment variable UGII_CAM_CSE_USER_DIR is not set! to_ini.ini file will be generated in default dir [pwd]!"
  } else {
     set part_dir2 "[MOM_ask_env_var UGII_CAM_CSE_USER_DIR]/" 
     regsub -all {\\} $part_dir2 {/} part_dir
  }
  return $part_dir
}

#=============================================================
proc ISV_ini_output_ini_file { } {
#=============================================================
   global mom_output_file_basename
   global mom_part_name
   global mom_event_handler_file_name
   global isv_ini_tool_info
   global isv_ini_mcs_info
   global mom_kin_output_unit
   global mom_warning_info
   global isv_ini_file_dir
   global mom_sinumerik_ini_existing
   global mom_sinumerik_ini_location
   global isv_ini_tool_count
   global mom_multi_channel_mode
   global mom_definition_file_name
   
   #2014-05-14-Allen - Check to see if mom_part_name contains '\.prt' char - if so must not be runnning in Teamcenter (IMAN type string)	
   set extension [file extension $mom_part_name]
   if { [string match  "\.prt" $extension ] } {
      set isv_ini_run_mode "NATIVE"
   } else {
      set isv_ini_run_mode "TEAMCENTER"
   }

   #Get ini file output directory
   #2015-11-20 szl - Enhance ini file output directory handling
   #2016-01-15 lili - Reset mom_sinumerik_ini_location by checking if UGII_CSE_USER_DIR is set up
   #                  UGII_CSE_USER_DIR is setup  --  set mom_sinumerik_ini_location to ENV
   if {![info exists mom_sinumerik_ini_location]} {set mom_sinumerik_ini_location "Part"} 
   if {[MOM_ask_env_var UGII_CAM_CSE_USER_DIR] != ""} {
      set mom_sinumerik_ini_location "ENV"
   }

   switch $mom_sinumerik_ini_location {
      "CSE" {
          set post_dir "[file dirname $mom_definition_file_name]/"
          regsub "/postprocessor/" $post_dir "/cse_driver/" ini_dir
      }
      "ENV" {
          set ini_dir [ISV_ini_get_env_dir_info]
      }
      "Part" - 
      default {
          if {$isv_ini_run_mode == "TEAMCENTER"} {
             set part_dir [ISV_ini_get_env_dir_info]
          } else {
             set part_dir "[file dirname $mom_part_name]/"
          }
          
          if {($part_dir != "") && ($isv_ini_run_mode == "TEAMCENTER")} {
             set ini_dir $part_dir
          } else {   
             if {[catch {file mkdir ${part_dir}cse_files/}]} {
                MOM_output_to_listing_device "$part_dir : No write access!"
             return
             }
             set ini_dir ${part_dir}cse_files/
          }   
       }
   }
   if {[catch {file mkdir ${ini_dir}subprog/}]} {
      MOM_output_to_listing_device "$ini_dir : No write access!"
return
   }
   set ini_dir ${ini_dir}subprog/
   if {![file isdirectory $ini_dir]} {
      MOM_output_to_listing_device "$ini_dir : Directory does not exist!"
return
   }

   #Handle exsiting ini files in place where the one will be created.
   if {$isv_ini_tool_count(1)!=0 || ![info exists mom_multi_channel_mode]} {
      set current_dir [pwd]       
      if {![info exists mom_sinumerik_ini_existing]} {set mom_sinumerik_ini_existing "Rename"}
      switch $mom_sinumerik_ini_existing {
         "Keep" {}
         "Delete" { 
             cd $ini_dir
             set ini_file_list [glob -nocomplain *.ini]
             foreach existing_file $ini_file_list { 
                if {![info exists mom_multi_channel_mode] || [string compare $existing_file to_ini_2.ini]} {
                   if {[catch {file delete $existing_file }]} {
                      MOM_output_to_listing_device "$existing_file : No write access!"
                      cd $current_dir
return
                   }
                }
             }
             cd $current_dir
         }
         "Rename" - 
         default {
             cd $ini_dir
             set ini_file_list [glob -nocomplain *.ini]
             foreach backup $ini_file_list {
                if {![info exists mom_multi_channel_mode] || [string compare $backup to_ini_2.ini]} {
                   if {[catch {file rename -force $backup $backup.bck}]} {
                      MOM_output_to_listing_device "$backup : No write access!"
                      cd $current_dir
return
                   }
                }
             }
             cd $current_dir
         }
      }
   } else {
       if {[string compare $mom_sinumerik_ini_existing "Keep"] && [string compare $mom_sinumerik_ini_existing "Delete"]} {             
          set current_dir [pwd]
          cd $ini_dir
          if {[file exists "to_ini_2.ini"]} {
             if {[catch {file rename -force "to_ini_2.ini" "to_ini_2.ini.bck"}]} {
                MOM_output_to_listing_device "$backup : No write access!"
                cd $current_dir
return
             }
          }
          cd $current_dir
       }
   }   

   #Output ini file 
   global ini_file_channel_number
   if {$ini_file_channel_number==1} {
      set ini_file_name "${ini_dir}to_ini.ini"
      if {[catch {open "$ini_file_name" w} ini_file]} {
         MOM_output_to_listing_device "$ini_file_name : No write access!"
return
      }           
      if {[info exists isv_ini_mcs_info(0)]} {
         puts $ini_file $isv_ini_mcs_info(0)
      }
      if {[info exists isv_ini_tool_info(0)]} {
         puts $ini_file $isv_ini_tool_info(0)
      }
      puts $ini_file "M17"
      close $ini_file
      set isv_ini_file_dir $ini_dir
   } else {
      for {set i 1} {$i<=2} {incr i} {
         if {$isv_ini_tool_count($i)!=0 || ![info exists mom_multi_channel_mode]} {            
            set ini_file_name "${ini_dir}to_ini_$i.ini"
            if {[catch {open "$ini_file_name" w} ini_file]} {
               MOM_output_to_listing_device "$ini_file_name : No write access!"
   return
            }        
            puts $ini_file "CHANDATA($i)"  
            if {[info exists isv_ini_mcs_info($i)]} {            
               puts $ini_file $isv_ini_mcs_info($i)
            }
            if {[info exists isv_ini_tool_info($i)]} {
               puts $ini_file $isv_ini_tool_info($i)
            }
            puts $ini_file "M17"
            close $ini_file
            set isv_ini_file_dir $ini_dir
         }
      }
   } 
}
 
if {[llength [info commands OPEN_files]] && ![llength [info commands sys_OPEN_files]]} {
   global mom_cse_ini_file_initialized
   set mom_cse_ini_file_initialized 0
   rename OPEN_files sys_OPEN_files
   
   uplevel #0 {
      proc OPEN_files {} {
         global mom_cse_ini_file_initialized
         global mom_sinumerik_ini_create
         global mom_sinumerik_ini_location
         global mom_sinumerik_ini_existing
         global mom_sinumerik_ini_end_status
    
         set mom_sinumerik_ini_create "Yes"
         set mom_sinumerik_ini_location "Part"
         set mom_sinumerik_ini_existing "Rename"
         set mom_sinumerik_ini_end_status "Keep"

         if {[info exists mom_cse_ini_file_initialized] && $mom_cse_ini_file_initialized == 0} {
            if {[llength [info commands PB_CMD_init_ini_files] ]} { 
               catch {PB_CMD_init_ini_files}
            }
            switch $mom_sinumerik_ini_create {
               "No" {}
               "Yes" -
               default {
                  if {[catch {ISV_ini_get_tool_info} result]} {
                     MOM_output_to_listing_device "$result"
                  }
                  if {[catch {ISV_ini_get_mcs_info} result]} {
                     MOM_output_to_listing_device "$result"
                  }
                  catch {ISV_ini_output_ini_file}
                  set mom_cse_ini_file_initialized 1
               }
            }
         }
         sys_OPEN_files
      }
   };#uplevel
}

if {[llength [info commands MOM__halt]] && ![llength [info commands MOM__sys_halt]]} {
   rename MOM__halt MOM__sys_halt
}
proc MOM__halt {} {   
   if {[llength [info commands MOM__sys_halt]]} {
      MOM__sys_halt
   }
   global isv_ini_file_dir
   set ini_file_name [list]
   if {[info exists isv_ini_file_dir]} {
      global mom_sinumerik_ini_end_status
      global isv_ini_tool_count
      global mom_multi_channel_mode
      global ini_file_channel_number
      if {$ini_file_channel_number==1} {
         lappend ini_file_name "${isv_ini_file_dir}to_ini.ini"
      } else {
         lappend ini_file_name "${isv_ini_file_dir}to_ini_1.ini"
         lappend ini_file_name "${isv_ini_file_dir}to_ini_2.ini"
      }
      if {![info exists mom_multi_channel_mode]} {      
         if {[info exists mom_sinumerik_ini_end_status]} {
            if {![string compare $mom_sinumerik_ini_end_status "Rename"]} {
               foreach file_name $ini_file_name {
                  catch {file rename -force $file_name $file_name.bck}
               }
            } elseif {![string compare $mom_sinumerik_ini_end_status "Delete"]} {
               foreach file_name $ini_file_name {
                  catch {file delete $file_name}
               }
            } 
         }
      }
   }
}
