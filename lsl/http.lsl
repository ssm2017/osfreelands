// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013-2017. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

string url="http://beta.francogrid.org";
integer website_refresh_time = 3600;
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
string _SYMBOL_ARROW = "⤷";
string _SYMBOL_HOR_BAR_1 = "⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌⚌";
string _SYMBOL_HOR_BAR_2 = "⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊⚊";
// common
string _RESET = "Reset";
string _THE_SCRIPT_WILL_STOP = "The script will stop";
string _HACK_ATTEMPT = "Hack attempt";
// checks
string _MISSING_VAR_NAMED = "Missing var named";
string _MISSING_VARS = "Missing vars";
// terminal
string _UPDATING_TERMINAL = "Updating terminal";
string _UPDATE_ERROR = "Update error";
// http errors
string _HTTP_ERROR = "http error";
string _REQUEST_TIMED_OUT = "Request timed out";
string _FORBIDDEN_ACCESS = "Forbidden access";
string _PAGE_NOT_FOUND = "Page not found";
string _INTERNET_EXPLODED = "the internet exploded!!";
string _SERVER_ERROR = "Server error";
// ============================================================
//      NOTHING SHOULD BE MODIFIED UNDER THIS LINE
// ============================================================
string ARGS_SEPARATOR = "||";
key default_owner;
// ********************
//      Constants
// ********************
// common
integer RESET = 70000;
integer SET_ERROR = 70016;
// terminal
integer TERMINAL_SAVE = 70101;
integer TERMINAL_SAVED = 70102;
integer SET_TERMINAL_PASSWORD = 71024;
integer SET_MAX_PARCELS_PER_USER = 71025;
integer SET_RENTING_DURATION = 71026;
// http
integer HTTP_REQUEST_URL_SUCCESS = 70205;
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
logging(integer logging_level, string message) {
    llMessageLinked(LINK_THIS, logging_level, message, NULL_KEY);
}
// update server
string terminal_url = "";
string outputType = "message";
key call_website_id;
callWebsite(string cmd, string args) {
    logging(LOGGING_INFO, _SYMBOL_HOR_BAR_2);
    logging(LOGGING_INFO, _SYMBOL_ARROW+ " "+ _UPDATING_TERMINAL);

    // sending values
    call_website_id = llHTTPRequest( url+"/metaverse-framework", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"],
                    "app=osfreelands"
                    +"&cmd="+ cmd
                    +"&output_type="+outputType
                    +"&args_separator="+ARGS_SEPARATOR
                    +"&arg="+args
                    );
}
// get server answer
getServerAnswer(integer status, string body) {
    logging(LOGGING_INFO, _SYMBOL_HOR_BAR_2);
    if (status == 499) {
        logging(LOGGING_WARNING, (string)status+ " "+ _REQUEST_TIMED_OUT);
    }
    else if (status == 403) {
        logging(LOGGING_WARNING, (string)status+ " "+ _FORBIDDEN_ACCESS);
    }
    else if (status == 404) {
        logging(LOGGING_WARNING, (string)status+ " "+ _PAGE_NOT_FOUND);
    }
    else if (status == 500) {
        logging(LOGGING_WARNING, (string)status+ " "+ _SERVER_ERROR);
    }
    else if (status != 403 && status != 404 && status != 500) {
        logging(LOGGING_WARNING, (string)status+ " "+ _INTERNET_EXPLODED);
        logging(LOGGING_DEBUG, body);
    }
}
// ***********************
//  INIT PROGRAM
// ***********************
default {
    state_entry() {
        logging(LOGGING_DEBUG, "http enter default state");
        integer check = 1;
        if ( url == "" ) {
            logging(LOGGING_WARNING, _MISSING_VAR_NAMED+ " \"url\"");
            check = 0;
        }
        if (!check) {
            logging(LOGGING_ERROR, _MISSING_VARS);
        }
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
            else if (num == HTTP_REQUEST_URL_SUCCESS) {
                terminal_url = str;
            }
            else if (num == SET_DEFAULT_OWNER) {
                default_owner = id;
            }
            else if (num == SET_TERMINAL_PASSWORD) {
                terminal_password = str;
            }
            else if (num == SET_MAX_PARCELS_PER_USER) {
                max_parcels_per_user = str;
            }
            else if (num == SET_RENTING_DURATION) {
                renting_duration = str;
            }
            else if (num == TERMINAL_SAVE) {
                callWebsite("save_terminal",
                    "default_owner="+(string)default_owner+ARGS_SEPARATOR+
                    "terminal_password="+terminal_password+ARGS_SEPARATOR+
                    "max_parcels_per_user="+max_parcels_per_user+ARGS_SEPARATOR+
                    "renting_duration="+renting_duration+ARGS_SEPARATOR+
                    "terminal_url="+llStringToBase64(terminal_url)
                );
            }
        }
    }
    http_response(key request_id, integer status, list metadata, string body) {
        if ( status != 200 ) {
            getServerAnswer(status, body);
            logging(LOGGING_ERROR, _HTTP_ERROR);
        }
        else {
            body = llStringTrim( body , STRING_TRIM);
            list data = llParseString2List(body, [";"],[]);
            string command = llList2String(data,0);
            logging(LOGGING_INFO, _SYMBOL_HOR_BAR_2);
            if ( command == "success" ) {
                logging(LOGGING_INFO, _SYMBOL_ARROW+ " "+ llList2String(data,1));
                llMessageLinked(LINK_THIS, TERMINAL_SAVED, "", NULL_KEY);
            }
            else {
                logging(LOGGING_DEBUG, body);
                logging(LOGGING_ERROR, _UPDATE_ERROR);
            }
        }
    }
}

// **************
//      Error
// **************
state idle {
    state_entry() {
        logging(LOGGING_DEBUG, "http enter idle state");
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }
}