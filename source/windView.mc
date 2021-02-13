using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Position;
using Toybox.Time;
using Toybox.Math;
using Toybox.System;

class windView extends WatchUi.DataField {

    var positionInfo;
    var heading;
    var relativeWindDirection = 0;

    function initialize() {
        DataField.initialize();
    }

    // function onLayout(dc) {
    // }

    // function compute(info) {
    // }

    // Finds point along arc that fits within datafield dimensions
    // width and height of datafield dimensions
    function pointOnCircle(degree, radiusOffset, width, height) {
        var radius;
        var radians = Math.toRadians(degree + 90);

        // determine radius based on datafield dimension
        if ((width / 2) < height) {
            radius = (width / 4) - 5;
        } else {
            radius = (height / 2) - 5;
        }

        // for setting a "notch" in arrow
        radius -= (radius * (radiusOffset));

        var xOffset = (width / 4);
        var yOffset = (height / 2);

        // calculate a point along a circle with 3 o'clock as the starting point
        var x = (radius * (Math.cos(radians))) + xOffset;
        var y = (radius * (Math.sin(radians))) + yOffset;

        return [x,y];
    }
    
    function getArrowPoints(degree, width, height) {
        var arrow1 = pointOnCircle(degree, 0, width, height);
        var arrow2 = pointOnCircle((degree - 145), 0, width, height);
        var arrow3 = pointOnCircle((degree + 180), 0.45, width, height);
        var arrow4 = pointOnCircle((degree + 145), 0, width, height);
        return [arrow1, arrow2, arrow3, arrow4];
    }

    function onUpdate(dc) {
        var width = dc.getWidth();
        var height = dc.getHeight();
        var textCenter = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var windSpeedDisplay = "--";

        var backgroundColor = getBackgroundColor();
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height);
        dc.setColor((backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        positionInfo = Position.getInfo();
        if (positionInfo.heading != null){
            // Position.Info.heading guide
            // https://forums.garmin.com/developer/connect-iq/f/discussion/238145/wind-direction-indicator
            // North is 0 radians (zero degrees)
            // East is +PI/2 radians (90deg CW)
            // West is -PI/2 radians (90deg CCW)
            // South is PI (180 deg)
            
            // calculate relativeWindDirection in degrees
            relativeWindDirection = ($.windDirection) - Math.toDegrees(positionInfo.heading);

            windSpeedDisplay = $.windSpeed.format("%d");
            if ($.windGust != 0 && $.windGust != $.windSpeed) {
                // check if $.windGust data is available
                windSpeedDisplay = windSpeedDisplay + "(" + $.windGust.format("%d") + ")";
            }
        } else {
            return;
        }

        // connection status info
        var message = "";
        if (!System.getDeviceSettings().connectionAvailable) {
            message = "NO CONN";
        } else if ($.mostRecentData["last_updated"] != null) {
            var lastUpdated = $.mostRecentData["last_updated"].subtract(Time.now()).value();
            if (lastUpdated / 60 >= 15) {
                message = (lastUpdated / 60) + " MIN";
            }
        } else {
            message = "NO DATA";
        }

        dc.fillPolygon(getArrowPoints(relativeWindDirection, width, height));
        dc.drawText(width - 35, height / 2 - 20, Graphics.FONT_TINY, $.unitsType, textCenter);
        dc.drawText(width - 35, (height / 2) + 1, Graphics.FONT_MEDIUM, windSpeedDisplay, textCenter);
        dc.drawText(width - 35, (height / 2) + 22, Graphics.FONT_TINY, message, textCenter);
    }
}
