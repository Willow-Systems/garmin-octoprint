//
// Copyright 2015-2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//
using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.Application;
using Toybox.Timer;
using Toybox.Lang;
using Toybox.Math;

class OctoprintView extends Ui.View {

    hidden var mPrompt;
    hidden var mLabel;

    // Initialize the View
    function initialize() {
        // Call the superclass initialize
        // mLabel = null;
        // mPrompt = Ui.loadResource(Rez.Strings.prompt);
        View.initialize();

    }

    // Load your resources here
    function onUpdate(dc) {
        // Cache the label away
        View.onUpdate(dc);

        
        //Setup variables etc from printer data
        var printer_progress = 0;
        var printer_status = "Connecting";
        var printer_eta = "";
        var printer_tool_temp = "Unknown";
        var printer_bed_temp = "Unknown";
        var printer_file_name = "";
        
        if (printerData["ready"] == true) {

            if (printerData["commsError"]) {
                printer_status = "Error";
            }

            var state = printerData["job"]["state"];

            if (state.find("Offline") != null) {

                printer_status = "Printer Offline";

            } else {

                //Bundle OK states together

                printer_status = state;

                if (state.equals("Operational")) {

                    //Ready but not printing
                    printer_status = "Printer Ready";
            
                }

                printer_bed_temp = getPrinterTempData("bed");
                printer_tool_temp = getPrinterTempData("tool0");



                if (printerData["job"]["progress"]["completion"] != null) {
                    printer_progress = printerData["job"]["progress"]["completion"];

                    printer_file_name = printerData["job"]["job"]["file"]["display"];

                    printer_eta = printerData["job"]["progress"]["printTimeLeft"];

                    var printer_eta_m = 0;
                    var printer_eta_h = 0;

                    if (printer_eta > 60) {
                        printer_eta_m = Math.floor(printer_eta / 60);
                        printer_eta = printer_eta % 60;
                    }

                    if (printer_eta_m > 60) {
                        printer_eta_h = Math.floor(printer_eta_m / 60);
                        printer_eta_m = printer_eta_m % 60;
                    }


                    //Covert to happy string
                    if (printer_eta_m == 0) {
                        //Less than a min
                        printer_eta = "<1 min";
                    } else {
                        printer_eta = printer_eta_m;
                        if (printer_eta_m < 10) {
                            printer_eta = "0" + printer_eta;
                        }

                        printer_eta = printer_eta_h + ":" + printer_eta;
                        if (printer_eta_h < 10) {
                            printer_eta = "0" + printer_eta;
                        }
                    }


                }

            }

        } else {

            //Errors
            if (printerData["error"] != null) {
                printer_status = printerData["error"];
            }

        }

        var width = dc.getWidth();
		var height = dc.getHeight();
        var w = 0;

        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);
        dc.clear();

        //Time background
        dc.fillRectangle(0, 0, width, 30);

        //Temp background
        dc.fillRectangle(0, height - 70, width, 80);

        //Invert colors
        dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_BLACK);

        //Time string
        var timeNow = System.getClockTime();
        var timeLbl = timeNow.hour.format("%02d") + ":" + timeNow.min.format("%02d");
        w = dc.getTextWidthInPixels(timeLbl, Gfx.FONT_XTINY);
        dc.drawText(width/2-(w/2), 8, Gfx.FONT_XTINY, timeLbl, Gfx.TEXT_JUSTIFY_LEFT);

        //Hotend temp
        dc.setColor(getColorForTempDevice("tool0"), Gfx.COLOR_BLACK);
        w = dc.getTextWidthInPixels("Tool Temp: " + printer_tool_temp, Gfx.FONT_XTINY);
        dc.drawText(width/2-(w/2), height - 60, Gfx.FONT_XTINY, "Tool Temp: " + printer_tool_temp, Gfx.TEXT_JUSTIFY_LEFT);

        //Bed temp
        dc.setColor(getColorForTempDevice("bed"), Gfx.COLOR_BLACK);
        w = dc.getTextWidthInPixels("Bed Temp: " + printer_bed_temp, Gfx.FONT_XTINY);
        dc.drawText(width/2-(w/2), height - 40, Gfx.FONT_XTINY, "Bed Temp: " + printer_bed_temp, Gfx.TEXT_JUSTIFY_LEFT);

        //Revert colours
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);

        //Main status
        w = dc.getTextWidthInPixels(printer_status, Gfx.FONT_LARGE);
        dc.drawText(width/2-(w/2), 60, Gfx.FONT_LARGE, printer_status, Gfx.TEXT_JUSTIFY_LEFT);

        //Smol lbls color
        dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_WHITE);

        //Progress %
        var progress_percent_lbl = removeDecimals(printer_progress) + "%";
        if (printer_progress < 1) {
            progress_percent_lbl = "";
        }
        dc.drawText(20, height - 100, Gfx.FONT_XTINY, progress_percent_lbl, Gfx.TEXT_JUSTIFY_LEFT);

        //ETA
        w = dc.getTextWidthInPixels(printer_eta, Gfx.FONT_XTINY);
        dc.drawText(width - 20 - w, height - 100, Gfx.FONT_XTINY, printer_eta, Gfx.TEXT_JUSTIFY_LEFT);

        //Filename
        w = dc.getTextWidthInPixels(printer_file_name, Gfx.FONT_XTINY);
        dc.drawText(width/2-(w/2), 110, Gfx.FONT_XTINY, printer_file_name, Gfx.TEXT_JUSTIFY_LEFT);

        //Progress bar
        var progColour = statusToColour(printer_status);
        dc.setColor(progColour, Gfx.COLOR_WHITE);
        var progress_width = (width / 100) * printer_progress;
        //Weird bug alert.... width (which is 218) / 100 * 100 apparently equals 200? Gets rounded when / then *...
        if (printer_progress > 99) {
            progress_width = width;
        }
        dc.fillRectangle(10, height - 80, progress_width, 10);

        //Back to normal colours
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_WHITE);

    }

    function statusToColour(status) {
        status = status.toLower();
        if (status.equals("printing")) {
            return Gfx.COLOR_DK_GREEN;
        } else {
            return Gfx.COLOR_ORANGE;
        }
    }

    function getColorForTempDevice(device) {
        var temp = getPrinterTempDataFloat(device, "actual");
        var targetTemp = getPrinterTempDataFloat(device, "target");

        if ((targetTemp - temp) < 2) {
            return Gfx.COLOR_WHITE;
        } else {
            return Gfx.COLOR_ORANGE;
        }
    }

    

    function removeDecimals(str) {
        str = str.toString();
        var decimalPos = str.find(".");
        if (decimalPos == null) {
            return str;
        } else {
            return str.substring(0, decimalPos);
        }
    }

    function getPrinterTempData(obj) {
        if (printerData["printer"] != null && printerData["printer"]["temperature"] != null && printerData["printer"]["temperature"][obj] != null && printerData["printer"]["temperature"][obj]["actual"] != null) {
            return removeDecimals(printerData["printer"]["temperature"][obj]["actual"].toString()) + "°C";
        } else {
            return "Unknown";
        }
    }

    function getPrinterTempDataFloat(obj, tempType) {
        if (printerData["printer"] != null && printerData["printer"]["temperature"] != null && printerData["printer"]["temperature"][obj] != null && printerData["printer"]["temperature"][obj][tempType] != null) {
            return printerData["printer"]["temperature"][obj][tempType];
        } else {
            return 0;
        }
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
    }

    // Update the view
    // function onUpdate(dc) {
    //     // Call the parent onUpdate function to redraw the layout
    //     View.onUpdate(dc);
    // }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
    }

    // Handler for the timer callback
    function onTimer() {
        Ui.requestUpdate();
    }

}