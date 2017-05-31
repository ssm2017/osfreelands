// @version osFreeLands
// @package osfreelands
// @copyright Copyright wene / ssm2017 Binder (C) 2013-2017. All rights reserved.
// @license http://www.gnu.org/licenses/gpl-2.0.html GNU/GPL, see LICENSE.php
// osfreelands is free software and parts of it may contain or be derived from the
// GNU General Public License or other free or open source software licenses.

integer logging_level = 6;
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
// ============================================================
//      NOTHING SHOULD BE MODIFIED UNDER THIS LINE
// ============================================================
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
// ********************
//      Constants
// ********************
// common
integer RESET = 70000;
integer SET_ERROR = 70016;

default {
    state_entry() {
        if (logging_level == 7) {
            llOwnerSay("Logging enter default state");
        }
    }
    link_message(integer sender_num, integer num, string str, key id) {
        if (num == LOGGING_DEBUG && logging_level > 6) {
            llOwnerSay(_SYMBOL_ARROW+ " DEBUG : "+ str);
        }
        else if (num == LOGGING_INFO && logging_level > 5) {
            llOwnerSay("INFO : "+ str);
        }
        else if (num == LOGGING_NOTICE && logging_level > 4) {
            llOwnerSay(_SYMBOL_RIGHT+ "NOTICE : "+ str);
            llSetText(str, <0.0,1.0,0.0>,1);
        }
        else if (num == LOGGING_WARNING && logging_level > 3) {
            llOwnerSay(_SYMBOL_WARNING+ "WARNING : "+ str);
        }
        else if (num == LOGGING_ERROR && logging_level > 2) {
            llOwnerSay(_SYMBOL_WRONG+ "ERROR : "+ str);
            llSetText(str, <1.0,0.0,0.0>,1);
            llMessageLinked(LINK_THIS, SET_ERROR, "", NULL_KEY);
        }
        else if (num == RESET) {
            llResetScript();
        }
    }
}