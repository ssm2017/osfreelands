// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013-2017. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

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
string _HACK_ATTEMPT = "Hack attempt";
string _WRONG_PASSWORD = "Wrong password";
string _TO = "to";
// http request
string _REQUESTING_URL = "Requesting the url";
string _URL_SUCCESS = "Url request success";
string _URL_ERROR = "Url request error";
string _PING_REQUESTED = "Ping requested";
// http errors
string _HTTP_ERROR = "http error";
string _REQUEST_TIMED_OUT = "Request timed out";
string _FORBIDDEN_ACCESS = "Forbidden access";
string _PAGE_NOT_FOUND = "Page not found";
string _INTERNET_EXPLODED = "the internet exploded!!";
string _SERVER_ERROR = "Server error";
// terminal
string _RENTING_PARCEL = "Renting parcel";
// ============================================================
//      NOTHING SHOULD BE MODIFIED UNDER THIS LINE
// ============================================================
string terminal_url = "";
string parcels = "";
key default_owner;
string default_title = "Free land";
string default_desc = "This place is for free";
string terminal_password = "";
// ********************
//      Constants
// ********************
// common
integer RESET = 70000;
integer SET_ERROR = 70016;
// http
integer HTTP_REQUEST_GET_URL = 70204;
integer HTTP_REQUEST_URL_SUCCESS = 70205;
// regions
integer SET_PARCELS_LIST = 71011;
integer SET_DEFAULT_TITLE = 71021;
integer SET_DEFAULT_DESC = 71023;
integer SET_TERMINAL_PASSWORD = 71024;
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
// helper used to remove the first unused = in http query
string right(string src, string divider) {
    integer index = llSubStringIndex( src, divider );
    if(~index)
        return llDeleteSubString( src, 0, index + llStringLength(divider) - 1);
    return src;
}
logging(integer logging_level, string message) {
    llMessageLinked(LINK_THIS, logging_level, message, NULL_KEY);
}
// check password
integer passwordIsValid(string pass_given) {
    if (pass_given == terminal_password) {
      return 1;
    }
    return 0;
}
// get parcel infos
string getParcelInfos(string parcel_coords_str) {
    // retrieve the parcel coords
    vector parcel_coords = (vector)llUnescapeURL(parcel_coords_str);
    // get the parcel infos
    list details = llGetParcelDetails(parcel_coords, [PARCEL_DETAILS_NAME, PARCEL_DETAILS_DESC, PARCEL_DETAILS_OWNER, PARCEL_DETAILS_AREA, PARCEL_DETAILS_ID]);
    string output = "{"
            + "\"parcel_name\":\"" + llList2String(details ,0) + "\","
            + "\"parcel_desc\":\"" + llList2String(details ,1) + "\","
            + "\"parcel_owner\":\"" + llList2String(details ,2) + "\","
            + "\"parcel_area\":\"" + llList2String(details ,3) + "\","
            + "\"parcel_uuid\":\"" + llList2String(details ,4) + "\"}";
    return llStringToBase64(output);
}
// rent parcel
string rentParcel(vector parcel_coords, key owner_uuid) {
    logging(LOGGING_DEBUG, _RENTING_PARCEL + " " +(string)parcel_coords + " " + _TO + " " + (string)owner_uuid);
    list rules =[PARCEL_DETAILS_OWNER, owner_uuid, PARCEL_DETAILS_GROUP, NULL_KEY];
    osSetParcelDetails(parcel_coords, rules);
    return getParcelInfos((string)parcel_coords);
}
// reset parcel
string resetParcel(string parcel_coords_str) {
    // retrieve the parcel coords
    vector parcel_coords = (vector)llUnescapeURL(parcel_coords_str);
    list rules =[
            PARCEL_DETAILS_NAME, default_title,
            PARCEL_DETAILS_DESC, default_desc,
            PARCEL_DETAILS_OWNER, default_owner,
            PARCEL_DETAILS_GROUP, NULL_KEY];
    osSetParcelDetails(parcel_coords, rules);
    return getParcelInfos((string)parcel_coords);
}
// manage messages
manageMessages(integer num, string str, key id) {
    if (num == RESET) {
        llResetScript();
    }
    else if (num == HTTP_REQUEST_GET_URL) {
        logging(LOGGING_INFO, _SYMBOL_ARROW+ " "+ _REQUESTING_URL);
        logging(LOGGING_NOTICE, _REQUESTING_URL);
        llRequestURL();
    }
    else if (num == SET_PARCELS_LIST) {
        parcels = str;
    }
    else if (num == SET_DEFAULT_OWNER) {
        default_owner = id;
    }
    else if (num == SET_DEFAULT_TITLE) {
        default_title = str;
    }
    else if (num == SET_DEFAULT_DESC) {
        default_desc = str;
    }
    else if (num == SET_TERMINAL_PASSWORD) {
        terminal_password = str;
    }
}
// ***********************
//  INIT PROGRAM
// ***********************
default {
    state_entry() {
        logging(LOGGING_DEBUG, "http_in enter default state");
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if (sender_num != 0) {
            logging(LOGGING_ERROR, _HACK_ATTEMPT);
        }
        else {
            if (num == SET_ERROR) {
                state idle;
            }
            else {
                manageMessages(num, str, id);
            }
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == URL_REQUEST_GRANTED) {
            terminal_url = Body;
            logging(LOGGING_INFO, _URL_SUCCESS+" : "+Body);
            logging(LOGGING_NOTICE, _URL_SUCCESS);
            llMessageLinked(LINK_THIS, HTTP_REQUEST_URL_SUCCESS, terminal_url, NULL_KEY);
            state run;
        }
        else if (Method == URL_REQUEST_DENIED) {
            logging(LOGGING_ERROR, _URL_ERROR);
        }
    }
}

// *****************
//      Run
// *****************
state run {
    state_entry() {
        logging(LOGGING_DEBUG, "http_in enter run state");
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if (sender_num != 0) {
            logging(LOGGING_ERROR, _HACK_ATTEMPT);
        }
        else {
            if (num == SET_ERROR) {
                state idle;
            }
            else {
                manageMessages(num, str, id);
            }
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == "GET") {
            // parse the http request query
            list args = llParseString2List(right(llGetHTTPHeader(ID, "x-query-string"), "="), ["&"],[]);
            string query = llList2String(args, 0);
            logging(LOGGING_DEBUG, "query = "+query);
            // controller
            if (query == "ping") {
                logging(LOGGING_DEBUG, _PING_REQUESTED);
                llHTTPResponse(ID, 200, "pong");
            }
            else if (query == "get-parcels-list") {
                logging(LOGGING_DEBUG, "get-parcels-list");
                llHTTPResponse(ID, 200, parcels);
            }
            else if (query == "get-parcel-infos") {
                logging(LOGGING_DEBUG, "get-parcel-infos");
                llHTTPResponse(ID, 200, getParcelInfos(right(llList2String(args, 1), "parcel=")));
            }
            else if (query == "rent-parcel") {
                logging(LOGGING_DEBUG, "rent-parcel");
                // check the password
                if (passwordIsValid(right(llList2String(args, 1), "password="))) {
                    llHTTPResponse(ID, 200, rentParcel((vector)llUnescapeURL(right(llList2String(args, 2), "parcel=")), right(llList2Key(args, 3), "owner=")));
                }
                else {
                    logging(LOGGING_WARNING, _WRONG_PASSWORD);
                    llHTTPResponse(ID, 403, "Access denied !");
                }
            }
            else if (query == "reset-parcel") {
                logging(LOGGING_DEBUG, "reset-parcel");
                logging(LOGGING_DEBUG, "parcel coords = "+ llUnescapeURL(right(llList2String(args, 1), "parcel=")));
                llHTTPResponse(ID, 200, resetParcel(llUnescapeURL(right(llList2String(args, 1), "parcel="))));
            }
            else {
                llHTTPResponse(ID, 403, "Access denied !");
            }
        }
    }
}

// **************
//      Error
// **************
state idle {
    state_entry() {
        logging(LOGGING_DEBUG, "http_in enter idle state");
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == "GET") {
            // parse the http request query
            list args = llParseString2List(right(llGetHTTPHeader(ID, "x-query-string"), "="), ["&"],[]);
            string query = llList2String(args, 0);
            if (query == "ping") {
                logging(LOGGING_DEBUG, _PING_REQUESTED);
                llHTTPResponse(ID, 200, "idle");
            }
            else {
                llHTTPResponse(ID, 403, "Access denied !");
            }
        }
    }
}