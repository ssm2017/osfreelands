The script is separated in few files :
  * config.lsl
    This file is managing the notecard config
  * http.lsl
    This file is sending requests to the web site
  * http_in.lsl
    This file is receiving requests from the web site
  * osfreelands.lsl
    This file is the main running script
  * logging.lsl
    This file is managing text display
  * osfreelands.notecard
    This is a notecard example for the parcels config

## Installation
  * Put these scripts in a box and a notecard named "config".
  * Fill the notecard following the procedure explained later in this document.

## Running
  * Click on the box to reset it.
  * If there are errors, the box will tell you.
  * If everything is fine, forget the box and everything else is managed from the website.

## Notecard config
The notecard is filled with one parameter by line.
Lines beginning with // are not interpreted (you can use them to add comments)

### Default values
The default values are set to the land when the renting is cancelled.
  * default_owner=
    This param accepts an uuid for the default owner.
  * default_title=Free Land
  * default_desc=This place is for free.
  * terminal_password=toto
  * max_parcels_per_user=1
  * renting_duration=1

### Parcels
You can add every parcel coordinates (one by line)
You only need to add <x,y,z> coordinates located inside of the dedicated parcel.
These coordinates can be anywhere inside the parcel.
  * parcel=<32,32,0>
  * parcel=<96,32,0>
  * ...
