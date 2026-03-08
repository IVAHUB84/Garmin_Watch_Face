import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Time;
import Toybox.Time.Gregorian;

class WatchFaceView extends WatchUi.WatchFace {

    private var _cx as Number = 0;
    private var _cy as Number = 0;
    private var _vaultBoy as WatchUi.BitmapResource or Null = null;

    private const C_BRIGHT = 0x00FF41;
    private const C_MED    = 0x00AA00;
    private const C_DIM    = 0x004400;
    private const C_AMBER  = 0xFFB000;

    function initialize() {
        WatchFace.initialize();
        _vaultBoy = WatchUi.loadResource(Rez.Drawables.VaultBoy) as WatchUi.BitmapResource;
    }

    function onLayout(dc as Dc) as Void {
        _cx = dc.getWidth()  / 2;
        _cy = dc.getHeight() / 2;
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var clockTime = System.getClockTime();
        var today     = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var stats     = System.getSystemStats();
        var battery   = stats.battery.toNumber();

        // ── TAB NAV: CLOCK | STATS | MAP ──────────
        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_cx - 105, _cy - 147, _cx - 105, _cy - 136);
        dc.drawLine(_cx - 105, _cy - 147, _cx - 95,  _cy - 147);
        dc.drawLine(_cx - 40,  _cy - 147, _cx - 30,  _cy - 147);
        dc.drawLine(_cx - 30,  _cy - 147, _cx - 30,  _cy - 136);

        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx - 68, _cy - 138, Graphics.FONT_TINY, "CLOCK",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx + 22, _cy - 138, Graphics.FONT_TINY, "STATS",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_cx + 88, _cy - 138, Graphics.FONT_TINY, "MAP",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawLine(_cx - 125, _cy - 127, _cx + 125, _cy - 127);

        // ── ДЕНЬ НЕДЕЛИ + ДАТА ────
        var days = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
        var dayStr = days[today.day_of_week - 1];

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(_cx - 175, _cy - 116, 52, 26);
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx - 149, _cy - 103, Graphics.FONT_TINY, dayStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.drawText(_cx - 149, _cy - 65, Graphics.FONT_SMALL,
            today.day.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(_cx - 164, _cy - 41, _cx - 134, _cy - 41);

        // ── ВРЕМЯ ──────────
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx - 48, _cy - 53, Graphics.FONT_NUMBER_HOT,
            clockTime.hour.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_cx - 48, _cy + 60, Graphics.FONT_NUMBER_HOT,
            clockTime.min.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx + 10, _cy + 100, Graphics.FONT_TINY,
            "." + clockTime.sec.format("%02d"),
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── VAULT BOY (bitmap) ────────────────────
        if (_vaultBoy != null) {
            dc.drawBitmap(_cx + 18, _cy - 80, _vaultBoy);
        }

        // ── БАТАРЕЯ ────────────────────────────────
        dc.setColor(C_BRIGHT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx - 108, _cy + 120, Graphics.FONT_TINY, "PWR",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var filledBlocks = battery * 8 / 100;
        for (var i = 0; i < 8; i++) {
            var bx = _cx - 68 + i * 14;
            if (i < filledBlocks) {
                dc.setColor(battery > 20 ? C_BRIGHT : C_AMBER, Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(bx, _cy + 113, 11, 14);
            } else {
                dc.setColor(C_DIM, Graphics.COLOR_TRANSPARENT);
                dc.drawRectangle(bx, _cy + 113, 11, 14);
            }
        }

        dc.setColor(C_MED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx + 48, _cy + 120, Graphics.FONT_TINY,
            battery.format("%d") + "/100",
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        // ── ПУЛЬС + ШАГИ ───────────────────────────
        var actInfo = Activity.getActivityInfo();
        var hrStr = "HP:---";
        if (actInfo != null && actInfo.currentHeartRate != null) {
            hrStr = "HP:" + actInfo.currentHeartRate.toString();
        }
        var monInfo = ActivityMonitor.getInfo();
        var stStr = "ST:0";
        if (monInfo != null) {
            stStr = "ST:" + monInfo.steps.toString();
        }

        dc.setColor(C_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_cx - 48, _cy + 144, Graphics.FONT_TINY, hrStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(_cx + 55, _cy + 144, Graphics.FONT_TINY, stStr,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}
