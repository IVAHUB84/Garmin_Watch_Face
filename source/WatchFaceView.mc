import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.SensorHistory;

// Layout (454x454):
//  y=50   DATE: MON · DD · MON · YYYY  (center)
//  y=85   SPECIAL panel (x=49, w=150), 7 rows x 38px
//         row: LABEL(left) VALUE(right) + BAR below
//  x=209  vertical divider
//  x=217  CLOCK: HH(y=155) / line+SEC(y=232) / MM(y=308)
//  y=390  BOTTOM: STEPS | KCAL | DIST  (70% centered)

class WatchFaceView extends WatchUi.WatchFace {

    private var _w  as Number = 454;
    private var _cx as Number = 227;
    private var _sc as Float  = 1.0;

    private const C_BRIGHT = 0x3DFF6E;
    private const C_MED    = 0x1A8C35;
    private const C_DIM    = 0x072010;
    private const C_BG     = 0x010804;

    private const DAYS   = ["SUN","MON","TUE","WED","THU","FRI","SAT"] as Array<String>;
    private const MONTHS = ["JAN","FEB","MAR","APR","MAY","JUN",
                            "JUL","AUG","SEP","OCT","NOV","DEC"] as Array<String>;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _w  = dc.getWidth();
        _cx = _w / 2;
        _sc = _w.toFloat() / 454.0;
    }

    function s(v as Number) as Number {
        return (_sc * v.toFloat()).toNumber();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(C_BG, C_BG);
        dc.clear();

        var jc = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        var jl = Graphics.TEXT_JUSTIFY_LEFT   | Graphics.TEXT_JUSTIFY_VCENTER;
        var jr = Graphics.TEXT_JUSTIFY_RIGHT  | Graphics.TEXT_JUSTIFY_VCENTER;

        // ── DATA ─────────────────────────────────────────
        var clockTime = System.getClockTime();
        var today     = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var sysStat   = System.getSystemStats();
        var actInfo   = Activity.getActivityInfo();
        var monInfo   = ActivityMonitor.getInfo();

        var battery  = sysStat.battery.toNumber();
        var hr       = (actInfo != null && actInfo.currentHeartRate != null)
                        ? actInfo.currentHeartRate : 0;
        var cadence  = (actInfo != null && actInfo.currentCadence != null)
                        ? actInfo.currentCadence : 0;
        var steps    = (monInfo != null && monInfo.steps != null)
                        ? monInfo.steps : 0;
        var calories = (monInfo != null && monInfo.calories != null)
                        ? monInfo.calories : 0;
        var distCm   = (monInfo != null && monInfo.distance != null)
                        ? monInfo.distance : 0;
        var floors   = (monInfo != null && monInfo.floorsClimbed != null)
                        ? monInfo.floorsClimbed : 0;

        var bodyBatt = null;
        var stress   = null;
        var spo2     = null;
        if (Toybox has :SensorHistory) {
            if (SensorHistory has :getBodyBatteryHistory) {
                var it = SensorHistory.getBodyBatteryHistory(
                    {:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
                if (it != null) {
                    var sm = it.next();
                    if (sm != null && sm.data != null) { bodyBatt = sm.data; }
                }
            }
            if (SensorHistory has :getStressHistory) {
                var it = SensorHistory.getStressHistory(
                    {:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
                if (it != null) {
                    var sm = it.next();
                    if (sm != null && sm.data != null) { stress = sm.data; }
                }
            }
            if (SensorHistory has :getOxygenSaturationHistory) {
                var it = SensorHistory.getOxygenSaturationHistory(
                    {:period => 1, :order => SensorHistory.ORDER_NEWEST_FIRST});
                if (it != null) {
                    var sm = it.next();
                    if (sm != null && sm.data != null) { spo2 = sm.data; }
                }
            }
        }

        // ── ZONE 1: DATE ─────────────────────────────────
        var dateStr = DAYS[today.day_of_week - 1] + " · " +
                      today.day.format("%02d") + " · " +
                      MONTHS[today.month - 1] + " · " +
                      today.year.format("%d");
        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx, s(65), Graphics.FONT_XTINY, dateStr, jc);

        // ── ZONE 2: SPECIAL PANEL ─────────────────────────
        var spX  = s(49);
        var spW  = s(150);
        var spY0 = s(85);
        var rowH = s(38);
        var barH = s(5);
        var barOff = s(13);

        var labels = ["HR", "BATT", "BODY", "STR", "FLOOR", "SPO2", "CDN"] as Array<String>;

        var valHr    = hr > 0         ? hr.format("%d")            : "--";
        var valBatt  = battery.format("%d") + "%";
        var valBody  = bodyBatt != null ? bodyBatt.format("%d")    : "--";
        var valStr   = stress   != null ? stress.format("%d") + "%" : "--";
        var valFloor = floors > 0      ? floors.format("%d")       : "--";
        var valSpo2  = spo2   != null  ? spo2.format("%d") + "%"   : "--";
        var valCdn   = cadence > 0     ? cadence.format("%d")      : "--";

        var values = [valHr, valBatt, valBody, valStr, valFloor, valSpo2, valCdn] as Array<String>;

        var pHr    = hr > 0         ? (hr * 100 / 220)       : 0;
        var pBatt  = battery;
        var pBody  = bodyBatt != null ? bodyBatt              : 0;
        var pStr   = stress   != null ? stress                : 0;
        var pFloor = floors > 0      ? (floors * 100 / 20)   : 0;
        var pSpo2  = spo2   != null  ? spo2                   : 0;
        var pCdn   = cadence > 0     ? (cadence * 100 / 200) : 0;

        var pcts = [pHr, pBatt, pBody, pStr, pFloor, pSpo2, pCdn] as Array<Number>;

        for (var i = 0; i < 7; i++) {
            var ry = spY0 + i * rowH;

            dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
            dc.drawText(spX, ry, Graphics.FONT_XTINY, labels[i], jl);

            dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
            dc.drawText(spX + spW, ry, Graphics.FONT_XTINY, values[i], jr);

            var by = ry + barOff;
            dc.setColor(C_DIM, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(spX, by, spW, barH);

            var pct = pcts[i];
            if (pct > 100) { pct = 100; }
            if (pct > 0) {
                dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(spX, by, (spW * pct / 100).toNumber(), barH);
            }
        }

        // ── DIVIDER ───────────────────────────────────────
        var divX = spX + spW + s(8);
        dc.setColor(C_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(divX, s(68), divX, s(358));

        // ── ZONE 3: CLOCK ─────────────────────────────────
        var clkX = divX + s(9);
        var clkW = _w - s(26) - clkX;
        var hmX  = clkX + (clkW.toFloat() * 0.10).toNumber();

        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hmX, s(155), Graphics.FONT_NUMBER_HOT,
            clockTime.hour.format("%02d"), jl);

        var midY = s(232);
        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(clkX, midY, _w - s(26), midY);

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_w - s(60), midY - s(9), Graphics.FONT_XTINY, "SEC", jc);
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_w - s(55), midY + s(10), Graphics.FONT_TINY,
            clockTime.sec.format("%02d"), jc);

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(hmX, s(308), Graphics.FONT_NUMBER_HOT,
            clockTime.min.format("%02d"), jl);

        // ── ZONE 4: BOTTOM STATS ──────────────────────────
        var botY = s(378);
        var botW = (_w.toFloat() * 0.60).toNumber();
        var botX = (_w - botW) / 2;
        var col  = botW / 3;

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(botX, botY - s(22), botX + botW, botY - s(22));
        dc.drawLine(botX + col,     botY - s(18), botX + col,     botY + s(18));
        dc.drawLine(botX + col * 2, botY - s(18), botX + col * 2, botY + s(18));

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(botX + col / 2, botY - s(8), Graphics.FONT_XTINY, "STEPS", jc);
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(botX + col / 2, botY + s(9), Graphics.FONT_TINY,
            steps.format("%d"), jc);

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(botX + col + col / 2, botY - s(8), Graphics.FONT_XTINY, "KCAL", jc);
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(botX + col + col / 2, botY + s(9), Graphics.FONT_TINY,
            calories.format("%d"), jc);

        var distKm = distCm.toFloat() / 100000.0;
        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(botX + col * 2 + col / 2, botY - s(8), Graphics.FONT_XTINY, "DIST", jc);
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(botX + col * 2 + col / 2, botY + s(9), Graphics.FONT_TINY,
            distKm.format("%.1f") + "k", jc);
    }
}
