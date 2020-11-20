using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Position;
using Toybox.Application;
using Toybox.Time;
using Toybox.Math;


class windspeeddirectionView extends WatchUi.DataField {

    var positionInfo;
    var heading;
    var relativeWindDirection = 0;

    function initialize() {
        System.println("View - Initialize");
        DataField.initialize();
    }

    // function onLayout(dc) {
    // }

    // function compute(info) {
    // }

    // find point along arc that fits within datafield dimensions
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

        // center horizontally on left half of view
        var xOffset = (width / 4);
        // center vertically in view
        var yOffset = (height / 2);

        // calculate a point along a circle with 3 o'clock as the starting
        // point of the arc
        var x = (radius * (Math.cos(radians))) + xOffset;
        var y = (radius * (Math.sin(radians))) + yOffset;

        return [x,y];
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        System.println("View - Onupdate");

        var width = dc.getWidth();
        var height = dc.getHeight();
        var textCenter = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var backgroundColor = getBackgroundColor();
        var windSpeedDisplay = "--";

        // set background color
        dc.setColor(backgroundColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 0, width, height);
        dc.setColor((backgroundColor == Graphics.COLOR_BLACK) ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        // datafield label
        dc.drawText(width - 35, height / 2 - 20, Graphics.FONT_TINY, "Wind", textCenter);
        
        // call gps for position info
        if (Position.getInfo() != null) {
            positionInfo = Position.getInfo();
        }

        if (positionInfo.heading != null){
            // Position.Info.heading guide
            // https://forums.garmin.com/developer/connect-iq/f/discussion/238145/wind-direction-indicator
            // North is 0 radians (zero degrees)
            // East is +PI/2 radians (90deg CW)
            // West is -PI/2 radians (90deg CCW)
            // South is PI (180 deg)
            
            // convert heading from radians to degrees
            heading = Math.toDegrees(positionInfo.heading);

            // calculate relativeWindDirection in degrees
            relativeWindDirection = (windDirection) - heading;

            // check if windGust data is available
            if (windGust != 0 && windGust != windSpeed) {
                windSpeedDisplay = windSpeed.format("%d") + "(" + windGust.format("%d") + ")";
            } else {
                windSpeedDisplay = windSpeed.format("%d");
            }
        } else {
            return;
        }

        // show relativeWindDirection as arrow
        var arrow1 = pointOnCircle(relativeWindDirection, 0, width, height);
        var arrow2 = pointOnCircle((relativeWindDirection - 145), 0, width, height);
        var arrow3 = pointOnCircle((relativeWindDirection + 180), 0.45, width, height);
        var arrow4 = pointOnCircle((relativeWindDirection + 145), 0, width, height);
        dc.fillPolygon([arrow1, arrow2, arrow3, arrow4]);
        
        // wind speed and wind gust (if available), in mph
        dc.drawText(width - 35, (height / 2) + 1, Graphics.FONT_MEDIUM, windSpeedDisplay, textCenter);

        if (lastUpdated == null) {
            dc.drawText(width - 35, (height / 2) + 22, Graphics.FONT_TINY, "NO DATA", textCenter);
        } else {
            var lastUpdatedDisplay = lastUpdated.subtract(Time.now());
            if ((lastUpdatedDisplay.value() / 60) >= 1) {
                dc.drawText(width - 35, (height / 2) + 22, Graphics.FONT_TINY, (lastUpdatedDisplay.value() / 60), textCenter);
            }
        }
    }

}
