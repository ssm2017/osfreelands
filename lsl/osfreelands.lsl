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
        if (num == RESET) {
            llResetScript();
        }
        else if (num == SET_ERROR) {
            state idle;
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
    on_rez(integer change) {
        reset();
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

    link_message(integer sender_num, integer num, string str, key id) {
        if (num == RESET) {
            llResetScript();
        }
    }
}
