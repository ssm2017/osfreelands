// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

// Optionnal variables
key default_owner;
string default_title = "Free land";
string default_desc = "This place is for free";
// *********************************
//      STRINGS
// *********************************
// symbols
string _SYMBOL_RIGHT = "✔";
string _SYMBOL_WRONG = "✖";
string _SYMBOL_WARNING = "⚠";
string _SYMBOL_RESTART = "⟲";
string _SYMBOL_HOR_BAR_1 = "⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌";
string _SYMBOL_HOR_BAR_2 = "⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊";
string _SYMBOL_ARROW = "⤷";
// common
string _INVENTORY_HAS_CHANGED = "Inventory has changed";
string _RESET = "Reset";
string _THE_SCRIPT_WILL_STOP = "The script will stop";
string _STOPPED = "Stopped";
string _READY = "Ready";
// checks
string _MISSING_NOTECARD = "Missing notecard";
string _MISSING_VAR_NAMED = "Missing var named";
string _IN_SCRIPT_NAMED = "in script named";
string _CHECKING_THE_TEXTURE = "Checking the texture ...";
string _RESET_VALUES = "Reseting the renting values";
string _MISSING_VARS = "Missing vars";
// config
string _START_READING_CONFIG = "Starting reading config";
string _SET_TO = "is set to";
string _CONFIG_READ = "Config read";

// ============================================================
//      NOTHING SHOULD BE MODIFIED UNDER THIS LINE
// ============================================================
string PARAM_SEPARATOR = "||";
key owner;
list parcels = [];
// notecard vars
integer i_line;
key config_notecard;
// ********************
//      Constants
// ********************
// common
integer RESET = 70000;
integer SET_ERROR = 70016;
// http
integer HTTP_REQUEST_GET_URL = 70064;
// notecard
integer READ_NOTECARD = 70063;
// regions
integer SET_PARCELS_LIST = 71011;
// *********************
//      FUNCTIONS
// *********************
// reset
reset() {
    llOwnerSay(_SYMBOL_HOR_BAR_2);
    llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
    llMessageLinked(LINK_SET, RESET, "", NULL_KEY);
    llResetScript();
}
// error
error(string message) {
    llOwnerSay(_SYMBOL_WARNING+ " "+ message + "."+ _THE_SCRIPT_WILL_STOP);
    llSetText(message, <1.0,0.0,0.0>,1);
    llMessageLinked(LINK_SET, SET_ERROR, "", NULL_KEY);
}
// parsing
string parseParcels() {
    // output example : [["<127,127,127>","<127,127,127>","<127,127,127>"]]
    string temp = "[";
    integer i;
    integer length = llGetListLength(parcels);
    do {
        // get parcels details
        temp += "\""+llList2String(parcels, i)+"\"";
        if (i < (length-1)) {
            temp += ",";
        }
    }
    while(++i < length);
    temp += "]";
    llOwnerSay(temp);
    return llStringToBase64(temp);
}
// ***********************
//  INIT PROGRAM
// ***********************
default {
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
        else if (num == SET_ERROR) {
            state idle;
        }
        else if (num == READ_NOTECARD) {
            state readNotecard;
        }
    }
}
// *************************
//      READ THE NOTECARD
// *************************
state readNotecard {
    state_entry() {
        // check if the notecard exists
        if (llGetInventoryType("config") != INVENTORY_NOTECARD) {
            error(_MISSING_NOTECARD + " : config");
            state idle;
        }
        // read the config notecard
        i_line=0;
        config_notecard = llGetNotecardLine("config",i_line);
        llOwnerSay(_SYMBOL_HOR_BAR_1);
        llOwnerSay(_SYMBOL_ARROW+ " "+ _START_READING_CONFIG);
        llSetText(_START_READING_CONFIG, <1.0,1.0,0.0>,1);
    }

    dataserver(key queryId, string data) {
        if ( queryId == config_notecard ) {
            if (data != EOF) {
                if ( llGetSubString( data, 0, 1) != "//" ) {
                    if ( data != "" ) {
                        list parsed = llParseString2List( data, [ "=" ], [] );
                        string cfg_command = llStringTrim(llToLower(llList2String( parsed, 0 )), STRING_TRIM);
                        string cfg_value = llStringTrim(llList2String( parsed, 1 ), STRING_TRIM);
                        if (cfg_value != "") {
                            // fill the values
                            if ( cfg_command == "default_owner" ) {
                                default_owner = cfg_value;
                                llOwnerSay(_SYMBOL_RIGHT+ " "+ "\"default_owner\""+ " "+ _SET_TO + " : "+default_owner);
                            }
                            else if ( cfg_command == "default_title" ) {
                                default_title = cfg_value;
                                llOwnerSay(_SYMBOL_RIGHT+ " "+ "\"default_title\""+ " "+ _SET_TO + " : "+default_title);
                            }
                            else if ( cfg_command == "default_desc" ) {
                                default_desc = cfg_value;
                                llOwnerSay(_SYMBOL_RIGHT+ " "+ "\"default_desc\""+ " "+ _SET_TO + " : "+default_desc);
                            }
                            else if ( cfg_command == "parcel" ) {
                                parcels += cfg_value;
                                llOwnerSay(_SYMBOL_RIGHT+ " "+ "\"parcel\""+ " "+ _SET_TO + " : "+cfg_value);
                            }
                        }
                    }
                }
                config_notecard = llGetNotecardLine("config",++i_line);
            }
            else {
                llOwnerSay(_SYMBOL_ARROW+ " "+ _CONFIG_READ+"...");
                llOwnerSay(_SYMBOL_HOR_BAR_1);
                llSetText(_CONFIG_READ, <0.0,1.0,0.0>,1);
                integer check = 1;
                if ( llGetListLength(parcels) == 0 ) {
                    llOwnerSay(_SYMBOL_WARNING+ " "+ _MISSING_VAR_NAMED+ " \"parcel\"");
                    check = 0;
                }
                if (!check) {
                    error(_MISSING_VARS);
                    state idle;
                }
                llMessageLinked(LINK_SET, SET_PARCELS_LIST, parseParcels(), NULL_KEY);
                state run;
            }
        }
    }
}

// ************
//      RUN
// ************
state run {
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
        else if (num == SET_ERROR) {
            state idle;
        }
    }
}

// **************
//      Error
// **************
state idle {
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }
}
