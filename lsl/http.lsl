// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.


string url="http://home.ssm2017.com";
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
// common
string _SYMBOL_ARROW = "⤷";
string _RESET = "Reset";
string _THE_SCRIPT_WILL_STOP = "The script will stop";
// checks
string _MISSING_VAR_NAMED = "Missing var named";
string _MISSING_VARS = "Missing vars";
// terminal
string _UPDATING_TERMINAL = "Updating terminal";
string _UPDATE_ERROR = "Update error";
// http request
string _REQUESTING_URL = "Requesting the url";
string _URL_SUCCESS = "Url request success";
string _URL_ERROR = "Url request error";
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
// error
error(string message) {
    llOwnerSay(_SYMBOL_WARNING+ " "+ message + "."+ _THE_SCRIPT_WILL_STOP);
    llSetText(message, <1.0,0.0,0.0>,1);
    llMessageLinked(LINK_SET, SET_ERROR, "", NULL_KEY);
    state error;
}
// update server
string terminal_url = "";
string outputType = "message";
key updateTerminalId;
updateTerminal(string cmd, string args) {
    llOwnerSay(_SYMBOL_HOR_BAR_2);
    llOwnerSay(_SYMBOL_ARROW+ " "+ _UPDATING_TERMINAL);

    // building password
    integer keypass = (integer)llFrand(9999)+1;
    string md5pass = llMD5String(password, keypass);
    // sending values
    updateTerminalId = llHTTPRequest( url+"/metaverse-framework", [HTTP_METHOD, "POST", HTTP_MIMETYPE, "application/x-www-form-urlencoded"],
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

    state_entry() {
        integer check = 1;
        if ( url == "" ) {
            llOwnerSay(_SYMBOL_WARNING+ " "+ _MISSING_VAR_NAMED+ " \"url\"");
            check = 0;
        }
        if ( password == "" ) {
            llOwnerSay(_SYMBOL_WARNING+ " "+ _MISSING_VAR_NAMED+ " \"password\"");
            check = 0;
        }
        if (!check) {
            error(_MISSING_VARS);
        }
    }

    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
        else if (num == HTTP_REQUEST_GET_URL) {
            llSetText(_REQUESTING_URL, <1.0,1.0,0.0>,1);
            llRequestURL();
        }
    }

    http_request(key ID, string Method, string Body) {
        if (Method == URL_REQUEST_GRANTED) {
            terminal_url = Body;
            llOwnerSay(_URL_SUCCESS+" : "+Body);
            llSetText(_URL_SUCCESS, <0.0,1.0,0.0>,1);
            updateTerminal("save_terminal", "terminal_url="+llStringToBase64(terminal_url));
        }
        else if (Method == URL_REQUEST_DENIED) {
            error(_URL_ERROR);
        }
    }

    http_response(key request_id, integer status, list metadata, string body) {
        if ( status != 200 ) {
            getServerAnswer(status, body);
            error(_HTTP_ERROR);
        }
        else {
            body = llStringTrim( body , STRING_TRIM);
            list data = llParseString2List(body, [";"],[]);
            string command = llList2String(data,0);
            llOwnerSay(_SYMBOL_HOR_BAR_2);
            if ( command == "success" ) {
                llOwnerSay(_SYMBOL_ARROW+ " "+ llList2String(data,1));
                llMessageLinked(LINK_THIS, READ_NOTECARD, "", NULL_KEY);
            }
            else {
                llOwnerSay(body);
                error(_UPDATE_ERROR);
            }
        }
    }
}

// *****************
//      Run
// *****************
state run {
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }
}

// **************
//      Error
// **************
state error {
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }
}
