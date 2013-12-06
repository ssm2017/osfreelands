// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

string password = "1234";
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
// common
string _SYMBOL_ARROW = "⤷";
string _RESET = "Reset";
string _THE_SCRIPT_WILL_STOP = "The script will stop";
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
// ============================================================
//      NOTHING SHOULD BE MODIFIED UNDER THIS LINE
// ============================================================
string terminal_url = "";
string parcels = "";
string default_owner;
string default_title = "Free land";
string default_desc = "This place is for free";
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
// users
integer SET_DEFAULT_OWNER = 70310;
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
// error
error(string message) {
    llOwnerSay(_SYMBOL_WARNING+ " "+ message + "."+ _THE_SCRIPT_WILL_STOP);
    llSetText(message, <1.0,0.0,0.0>,1);
    llMessageLinked(LINK_SET, SET_ERROR, "", NULL_KEY);
}
// check password
integer passwordIsValid(string pass_given, integer key_given) {
    if (pass_given == llMD5String(password, key_given)) {
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
        llOwnerSay(_SYMBOL_ARROW+ " "+ _REQUESTING_URL);
        llSetText(_REQUESTING_URL, <1.0,1.0,0.0>,1);
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
}
// ***********************
//  INIT PROGRAM
// ***********************
default {

    link_message(integer sender_num, integer num, string str, key id) {
        if (num == SET_ERROR) {
            state idle;
        }
        else {
            manageMessages(num, str, id);
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == URL_REQUEST_GRANTED) {
            terminal_url = Body;
            llOwnerSay(_URL_SUCCESS+" : "+Body);
            llSetText(_URL_SUCCESS, <0.0,1.0,0.0>,1);
            llMessageLinked(LINK_THIS, HTTP_REQUEST_URL_SUCCESS, terminal_url, NULL_KEY);
            state run;
        }
        else if (Method == URL_REQUEST_DENIED) {
            error(_URL_ERROR);
            state idle;
        }
    }
}

// *****************
//      Run
// *****************
state run {
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == SET_ERROR) {
            state idle;
        }
        else {
            manageMessages(num, str, id);
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == "GET") {
            string path = llGetHTTPHeader(ID, "x-path-info");
            if (path == "/ping") {
                llOwnerSay(_PING_REQUESTED);
                llHTTPResponse(ID, 200, "pong");
            }
            else if (path == "/get-parcels-list") {
                llHTTPResponse(ID, 200, parcels);
            }
            else if (path == "/get-parcel-infos") {
                llHTTPResponse(ID, 200, getParcelInfos(right(llGetHTTPHeader(ID, "x-query-string"), "=")));
            }
            else if (path == "/rent-parcel") {
                // parse the http request query
                list args = llParseString2List(right(llGetHTTPHeader(ID, "x-query-string"), "="), ["+"],[]);
                // check the password
                if (passwordIsValid(llList2String(args, 0), llList2Integer(args, 1))) {
                    llHTTPResponse(ID, 200, rentParcel((vector)llUnescapeURL(llList2String(args, 2)), llList2Key(args, 3)));
                }
                else {
                    llHTTPResponse(ID, 403, "Access denied !");
                }
            }
            else if (path == "/reset-parcel") {
                llHTTPResponse(ID, 200, resetParcel(right(llGetHTTPHeader(ID, "x-query-string"), "=")));
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
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == "GET") {
            string path = llGetHTTPHeader(ID, "x-path-info");
            if (path == "/ping") {
                llHTTPResponse(ID, 200, "idle");
            }
            else {
                llHTTPResponse(ID, 403, "Access denied !");
            }
        }
    }
}
