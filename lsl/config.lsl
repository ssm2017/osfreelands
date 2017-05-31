// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013-2017. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

// Optionnal variables
key default_owner;
string default_title = "Free land";
string default_desc = "This place is for free";
string terminal_password = "";
string max_parcels_per_user = "1";
string renting_duration = "1";
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
string _RESET = "Reset";
string _THE_SCRIPT_WILL_STOP = "The script will stop";
string _STOPPED = "Stopped";
string _READY = "Ready";
string _HACK_ATTEMPT = "Hack attempt";
// checks
string _MISSING_NOTECARD = "Missing notecard";
string _MISSING_VAR_NAMED = "Missing var named";
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
// notecard
integer READ_NOTECARD = 70501;
integer NOTECARD_READ = 70502;
// terminal
integer SET_PARCELS_LIST = 71011;
integer SET_DEFAULT_TITLE = 71021;
integer SET_DEFAULT_DESC = 71023;
integer SET_TERMINAL_PASSWORD = 71024;
integer SET_MAX_PARCELS_PER_USER = 71025;
integer SET_RENTING_DURATION = 71026;
// users
integer SET_DEFAULT_OWNER = 70310;
// ********************
//    Logging levels
// ********************
integer LOGGING_EMERGENCY = 0;
integer LOGGING_ALERT = 1;
integer LOGGING_CRITICAL = 2;
integer LOGGING_ERROR = 3;
integer LOGGING_WARNING = 4;
integer LOGGING_NOTICE = 5;
integer LOGGING_INFO = 6;
integer LOGGING_DEBUG = 7;
// *********************
//      FUNCTIONS
// *********************
// reset
reset() {
    llOwnerSay(_SYMBOL_HOR_BAR_2);
    llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
    llMessageLinked(LINK_THIS, RESET, "", NULL_KEY);
    llResetScript();
}
logging(integer logging_level, string message) {
    llMessageLinked(LINK_THIS, logging_level, message, NULL_KEY);
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
    return llStringToBase64(temp);
}
// ***********************
//  INIT PROGRAM
// ***********************
default {
    state_entry() {
        logging(LOGGING_DEBUG, "config enter default state");
        default_owner = llGetOwner();
    }

    link_message(integer sender_num, integer num, string str, key id) {
        if (sender_num != 0) {
            logging(LOGGING_ERROR, _HACK_ATTEMPT);
        }
        else {
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
}
// *************************
//      READ THE NOTECARD
// *************************
state readNotecard {
    state_entry() {
        logging(LOGGING_DEBUG, "config enter readNotecard state");
        // check if the notecard exists
        if (llGetInventoryType("config") != INVENTORY_NOTECARD) {
            logging(LOGGING_ERROR, _MISSING_NOTECARD + " : config");
            state idle;
        }
        // read the config notecard
        i_line=0;
        config_notecard = llGetNotecardLine("config",i_line);
        logging(LOGGING_INFO, _SYMBOL_HOR_BAR_1);
        logging(LOGGING_INFO, _SYMBOL_ARROW+ " "+ _START_READING_CONFIG);
        logging(LOGGING_NOTICE, _START_READING_CONFIG);
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
                            if (cfg_command == "default_owner") {
                                default_owner = cfg_value;
                                logging(LOGGING_INFO, "\"default_owner\""+ " "+ _SET_TO + " : "+default_owner);
                            }
                            else if (cfg_command == "default_title") {
                                default_title = cfg_value;
                                logging(LOGGING_INFO, "\"default_title\""+ " "+ _SET_TO + " : "+default_title);
                            }
                            else if (cfg_command == "default_desc") {
                                default_desc = cfg_value;
                                logging(LOGGING_INFO, "\"default_desc\""+ " "+ _SET_TO + " : "+default_desc);
                            }
                            else if (cfg_command == "max_parcels_per_user") {
                                max_parcels_per_user = cfg_value;
                                logging(LOGGING_INFO, "\"max_parcels_per_user\""+ " "+ _SET_TO + " : "+max_parcels_per_user);
                            }
                            else if (cfg_command == "renting_duration") {
                                renting_duration = cfg_value;
                                logging(LOGGING_INFO, "\"renting_duration\""+ " "+ _SET_TO + " : "+renting_duration);
                            }
                            else if (cfg_command == "terminal_password") {
                                terminal_password = cfg_value;
                                logging(LOGGING_INFO, "\"terminal_password\""+ " "+ _SET_TO + " : "+terminal_password);
                            }
                            else if (cfg_command == "parcel") {
                                parcels += cfg_value;
                                logging(LOGGING_INFO, "\"parcel\""+ " "+ _SET_TO + " : "+cfg_value);
                            }
                        }
                    }
                }
                config_notecard = llGetNotecardLine("config",++i_line);
            }
            else {
                logging(LOGGING_INFO, _SYMBOL_ARROW+ " "+ _CONFIG_READ+"...");
                logging(LOGGING_INFO, _SYMBOL_HOR_BAR_1);
                logging(LOGGING_NOTICE, _CONFIG_READ);
                integer check = 1;
                if ( llGetListLength(parcels) == 0 ) {
                    logging(LOGGING_WARNING,  _MISSING_VAR_NAMED+ " \"parcel\"");
                    check = 0;
                }
                if ( terminal_password == "" ) {
                    logging(LOGGING_WARNING, _MISSING_VAR_NAMED+ " \"terminal_password\"");
                    check = 0;
                }
                if (!check) {
                    logging(LOGGING_ERROR, _MISSING_VARS);
                    state idle;
                }
                llMessageLinked(LINK_THIS, SET_PARCELS_LIST, parseParcels(), NULL_KEY);
                llMessageLinked(LINK_THIS, SET_DEFAULT_OWNER, "", default_owner);
                llMessageLinked(LINK_THIS, SET_DEFAULT_TITLE, default_title, NULL_KEY);
                llMessageLinked(LINK_THIS, SET_DEFAULT_DESC, default_desc, NULL_KEY);
                llMessageLinked(LINK_THIS, SET_TERMINAL_PASSWORD, terminal_password, NULL_KEY);
                llMessageLinked(LINK_THIS, SET_MAX_PARCELS_PER_USER, max_parcels_per_user, NULL_KEY);
                llMessageLinked(LINK_THIS, SET_RENTING_DURATION, renting_duration, NULL_KEY);
                llMessageLinked(LINK_THIS, NOTECARD_READ, "", NULL_KEY);
                state idle;
            }
        }
    }
}

// **************
//      Idle
// **************
state idle {
    state_entry() {
        logging(LOGGING_DEBUG, "config enter idle state");
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }
}