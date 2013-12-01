// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

string url="http://www.beta.francogrid.org";
string password = "0000";
integer website_refresh_time = 3600;
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
// http request
string _REQUESTING_URL = "Requesting the url";
string _URL_SUCCESS = "Url request success";
string _URL_ERROR = "Url request error";
// box
string _UPDATING_BOX = "Updating box";
string _UPDATE_ERROR = "Update error";
// http errors
string _REQUEST_TIMED_OUT = "Request timed out";
string _FORBIDDEN_ACCESS = "Forbidden access";
string _PAGE_NOT_FOUND = "Page not found";
string _INTERNET_EXPLODED = "the internet exploded!!";
string _SERVER_ERROR = "Server error";
// ============================================================
//      NOTHING SHOULD BE MODIFIED UNDER THIS LINE
// ============================================================
string PARAM_SEPARATOR = "||";
key owner;
key default_owner;
string default_title = "Free land";
string default_desc = "This place is for free";
list parcels = [];
// notecard vars
integer i_line;
key config_notecard;
// *********************************
//      FUNCTIONS
// *********************************
// update server
string box_url = "";
string outputType = "message";
key updateBoxId;
updateBox(string cmd, string args) {
    llOwnerSay(_SYMBOL_HOR_BAR_2);
    llOwnerSay(_SYMBOL_ARROW+ " "+ _UPDATING_BOX);

    // building password
    integer keypass = (integer)llFrand(9999)+1;
    string md5pass = llMD5String(password, keypass);
    // sending values
    updateBoxId = llHTTPRequest( url+"/mvtf", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"],
                    "app=osfreelands"
                    +"&cmd="+ cmd
                    +"&output_type="+outputType
                    +"&arg="+args
                    );
}
// get server answer
getServerAnswer(integer status, string body) {
    llOwnerSay(_SYMBOL_HOR_BAR_2);
    if (status == 499) {
        llOwnerSay(_SYMBOL_WARNING+ " "+ (string)status+ " "+ _REQUEST_TIMED_OUT);
    }
    else if (status == 403) {
        llOwnerSay(_SYMBOL_WARNING+ " "+ (string)status+ " "+ _FORBIDDEN_ACCESS);
    }
    else if (status == 404) {
        llOwnerSay(_SYMBOL_WARNING+ " "+ (string)status+ " "+ _PAGE_NOT_FOUND);
    }
    else if (status == 500) {
        llOwnerSay(_SYMBOL_WARNING+ " "+ (string)status+ " "+ _SERVER_ERROR);
    }
    else if (status != 403 && status != 404 && status != 500) {
        llOwnerSay(_SYMBOL_WARNING+ " "+ (string)status+ " "+ _INTERNET_EXPLODED);
        llOwnerSay(body);
    }
}
// ***********************
//  INIT PROGRAM
// ***********************
default {
    on_rez(integer number) {
        llOwnerSay(_SYMBOL_HOR_BAR_2);
        llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
        llResetScript();
    }

    state_entry() {
        owner = llGetOwner();
        default_owner = owner;
        llSetText(_REQUESTING_URL, <1.0,1.0,0.0>,1);
        llRequestURL();
    }

    touch_start(integer total_number) {
        if (llDetectedKey(0) == owner) {
            llOwnerSay(_SYMBOL_HOR_BAR_2);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == URL_REQUEST_GRANTED) {
            box_url = Body;
            llOwnerSay(_URL_SUCCESS+" : "+Body);
            llSetText(_URL_SUCCESS, <0.0,1.0,0.0>,1);
            state readNotecard;
        }
        else if (Method == URL_REQUEST_DENIED) {
            llOwnerSay(_SYMBOL_WARNING+ " "+ _URL_ERROR + "."+ _THE_SCRIPT_WILL_STOP);
            llSetText(_URL_ERROR, <1.0,0.0,0.0>,1);
            return;
        }
    }
}
// *************************
//      READ THE NOTECARD
// *************************
state readNotecard {
    on_rez(integer change) {
        llOwnerSay(_SYMBOL_HOR_BAR_2);
        llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
        llResetScript();
    }

    state_entry() {
        // check if the notecard exists
        if (llGetInventoryType("config") != INVENTORY_NOTECARD) {
            llOwnerSay(_SYMBOL_WARNING+ " "+ _MISSING_NOTECARD+ " : config");
            llOwnerSay(_SYMBOL_ARROW+ " "+ _THE_SCRIPT_WILL_STOP);
            llSetText(_MISSING_NOTECARD+ " : config", <1.0,0.0,0.0>,1);
            return;
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
            llOwnerSay(_SYMBOL_HOR_BAR_2);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
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
                if ( url == "" ) {
                    llOwnerSay(_SYMBOL_WARNING+ " "+ _MISSING_VAR_NAMED+ " \"url\"");
                    check = 0;
                }
                if ( password == "" ) {
                    llOwnerSay(_SYMBOL_WARNING+ " "+ _MISSING_VAR_NAMED+ " \"password\"");
                    check = 0;
                }
                if (!check) {
                    llOwnerSay(_SYMBOL_ARROW+ " "+ _THE_SCRIPT_WILL_STOP);
                    llSetText(_MISSING_VARS, <1.0,0.0,0.0>,1);
                    return;
                }
                state updateWebsite;
            }
        }
    }
}

// *************************
//      UPDATE WEBSITE
// *************************
state updateWebsite {
    on_rez(integer change) {
        llOwnerSay(_SYMBOL_HOR_BAR_2);
        llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
        llResetScript();
    }

    state_entry() {
        llSetText(_UPDATING_BOX, <1.0,1.0,0.0>,1);
        updateBox("init", "");
    }

    touch_start(integer number) {
        if ( llDetectedKey(0) == owner ) {
            llOwnerSay(_SYMBOL_HOR_BAR_2);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        if ( status != 200 ) {
            getServerAnswer(status, body);
        }
        else {
            body = llStringTrim( body , STRING_TRIM);
            list data = llParseString2List(body, [";"],[]);
            string command = llList2String(data,0);
            llOwnerSay(_SYMBOL_HOR_BAR_2);
            if ( command == "success" ) {
                llOwnerSay(_SYMBOL_ARROW+ " "+ llList2String(data,1));
                state run;
            }
            else {
                llOwnerSay(body);
                llOwnerSay(_SYMBOL_ARROW+ " "+ _THE_SCRIPT_WILL_STOP);
                llSetText(_UPDATE_ERROR, <1.0,0.0,0.0>,1);
                return;
            }
        }
    }
}

// ************
//      RUN
// ************
state run {
    on_rez(integer change) {
        llOwnerSay(_SYMBOL_HOR_BAR_2);
        llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
        llResetScript();
    }

    state_entry() {
        llSetText(_READY, <0.0,1.0,0.0>,1);
    }

    touch_start(integer number) {
        if ( llDetectedKey(0) == owner ) {
            llOwnerSay(_SYMBOL_HOR_BAR_2);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }

    changed(integer change) {
        if (change & CHANGED_INVENTORY) {
            llOwnerSay(_SYMBOL_ARROW+ " "+ _INVENTORY_HAS_CHANGED);
            llOwnerSay(_SYMBOL_RESTART+ " "+ _RESET);
            llResetScript();
        }
    }
}
