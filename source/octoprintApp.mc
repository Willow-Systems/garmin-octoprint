using Toybox.Application as App;
using Toybox.WatchUi as Ui;
using Toybox.Communications;
using Toybox.Timer;

var printerData = {
    "ready" => false
};
var dataRefreshTimer = new Timer.Timer();

class OctoprintApp extends App.AppBase {

    var key = App.getApp().getProperty("api_key");

    var url = "https://octopi.local";

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state) {

        getPrinterStateOne();
        dataRefreshTimer.start(method(:timerCallback), 10000, true);

    }

    // onStop() is called when your application is exiting
    function onStop(state) {
        dataRefreshTimer.stop();
    }

    // Return the initial view of your application here
    function getInitialView() {
        return [ new OctoprintView(), new OctoprintDelegate() ];
    }

    function timerCallback() {
        getPrinterStateOne();
    }

    function getPrinterStateOne() {

        if (key == null) {
            printerData["error"] = "API Key not set";
            return;
        }

        var headers = {};
        headers.put("X-Api-Key", key);
        headers.put("Accept","application/json");
    
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :headers => headers,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        System.println("Call " + url + "/api/job");
        Communications.makeWebRequest(url + "/api/job", null, options, method(:getPrinterStateOne_cb));

    }

    function getPrinterStateOne_cb(responseCode, data) {

        System.println(responseCode);
        System.println(data);

        if (responseCode != 200) {
            printerData["commsError"] = true;
        }


        //Handle data from part one
        printerData["job"] = data;


        // Call part 2
        var headers = {};
        headers.put("X-Api-Key",key);
        headers.put("Accept","application/json");
    
        var options = {
          :method => Communications.HTTP_REQUEST_METHOD_GET,
          :headers => headers,
          :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
        };
        Communications.makeWebRequest(url + "/api/printer", null, options, method(:getPrinterStateTwo_cb));

    }

    function getPrinterStateTwo_cb(responseCode, data) {

        printerData["two"] = responseCode;

        if (responseCode == -400) {

            System.println("Got -400, printer probably offline");

        } else {

            System.println(responseCode);
            System.println(data);

            printerData["printer"] = data;

        }

        printerData["ready"] = true;
        Ui.requestUpdate();
    }

}
