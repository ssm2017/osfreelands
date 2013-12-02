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
    state error;
}
// parsing
string parseParcels() {
    // output example : [["550e8400-e29b-41d4-a716-446655440000","<127,127,127>","4096", "name1","desc1"],["550e8400-e29b-41d4-a716-446655440001","<127,127,127>","4096","name2","desc2"],["550e8400-e29b-41d4-a716-446655440002","<127,127,127>","4096","name3","desc3"]]
    integer i;
    list details;
    string position;
    string temp = "[";
    integer length = llGetListLength(parcels);
    do {
        // get parcels details
        position = llList2String(parcels, i);
        details = llGetParcelDetails(position, [PARCEL_DETAILS_ID, PARCEL_DETAILS_AREA, PARCEL_DETAILS_NAME, PARCEL_DETAILS_DESC]);
        temp += "["
            + llList2String(details, 0) + ","
            + position + ","
            + llList2String(details, 1) + ","
            + llList2String(details, 2) + ","
            + llList2String(details, 3) + "]";
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
    on_rez(integer number) {
        reset();
    }

    state_entry() {
        owner = llGetOwner();
        default_owner = owner;
        llMessageLinked(LINK_THIS, HTTP_REQUEST_GET_URL, "", NULL_KEY);
    }

    touch_start(integer total_number) {
        if (llDetectedKey(0) == owner) {
            reset();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            reset();
        }
    }

    link_message(integer sender_num, integer num, string str, key id) {
        if (num == SET_ERROR) {
            state error;
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
    on_rez(integer change) {
        reset();
    }

    state_entry() {
        // check if the notecard exists
        if (llGetInventoryType("config") != INVENTORY_NOTECARD) {
            error(_MISSING_NOTECARD + " : config");
        }
        // read the config notecard
        i_line=0;
        config_notecard = llGetNotecardLine("config",i_line);
        llOwnerSay(_SYMBOL_HOR_BAR_1);
        llOwnerSay(_SYMBOL_ARROW+ " "+ _START_READING_CONFIG);
        llSetText(_START_READING_CONFIG, <1.0,1.0,0.0>,1);
    }

    touch_start(integer number) {
        if ( llDetectedKey(0) == owner ) {
            reset();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            reset();
        }
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
                }
                //state updateWebsite;
            }
        }
    }
}

// ************
//      RUN
// ************
state run {
    on_rez(integer change) {
        reset();
    }

    state_entry() {
        llSetText(_READY, <0.0,1.0,0.0>,1);
    }

    touch_start(integer number) {
        if ( llDetectedKey(0) == owner ) {
            reset();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            reset();
        }
    }
}

// **************
//      Error
// **************
state error {
    on_rez(integer change) {
        reset();
    }

    touch_start(integer number) {
        if ( llDetectedKey(0) == owner ) {
            reset();
        }
    }
}
