import os

repo = os.path.abspath("patro")

def clean_file(filename):
    path = os.path.join(repo, filename)
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    clean_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith(".pragma") or stripped.startswith(".import"):
            clean_lines.append("")
        else:
            clean_lines.append(line)
    return "".join(clean_lines)

calendar_data = clean_file("CalendarData.js")
astro = clean_file("Astro.js")
nepali = clean_file("Nepali.js")
observances = clean_file("Observances.js")
bikram = clean_file("Bikram.js")

patro_app_helpers = """
var PatroApp = {
  getToday: function(nowMs, lang, numStyle) {
    lang = lang || "Nepali";
    numStyle = numStyle || "Devanagari";
    var d = nowMs ? new Date(nowMs) : new Date();
    var greg = { year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate() };
    var bs = Bikram.fromGregorian(greg.year, greg.month, greg.day);
    if (!bs) return null;
    var wd = Bikram.weekdayOf(bs.year, bs.month, bs.day);
    var tithiNum = Astro.tithiForDate(greg.year, greg.month, greg.day);
    var tithiStr = Nepali.tithiLabel(tithiNum, Astro.pakshaOf(tithiNum), lang);
    var tName = Nepali.tithiName(tithiNum, lang);
    var obs = Observances.forDate(bs, greg, tithiNum);
    var obsNamed = Observances.named(obs);
    
    var yearDev = Nepali.numerals(bs.year, numStyle);
    var monthDev = Nepali.monthName(bs.month, lang);
    var dayDev = Nepali.numerals(bs.day, numStyle);
    
    // Clean default: "१७ कात्तिक २०८३"
    var cleanYearLabel = dayDev + " " + monthDev + " " + yearDev;
    var cleanWithTithi = cleanYearLabel + " · " + tithiStr;
    var fullLabel = Nepali.formatDate(bs, {
      language: lang, numerals: numStyle, format: "Full", showWeekday: true, weekday: wd
    });
    var compactLabel = Nepali.formatDate(bs, {
      language: lang, numerals: numStyle, format: "Compact", showWeekday: false
    });
    var numericLabel = Nepali.formatDate(bs, {
      language: lang, numerals: numStyle, format: "Numeric", showWeekday: false
    });
    
    return {
      year: bs.year,
      month: bs.month,
      day: bs.day,
      yearText: yearDev,
      monthName: monthDev,
      dayText: dayDev,
      weekday: wd,
      weekdayName: Nepali.weekdayName(wd, lang),
      weekdayShort: Nepali.weekdayShort(wd, lang),
      gregorian: greg,
      cleanYearLabel: cleanYearLabel,
      cleanWithTithi: cleanWithTithi,
      fullLabel: fullLabel,
      compactLabel: compactLabel,
      numericLabel: numericLabel,
      tithi: tithiNum,
      tithiName: tName,
      tithiLabel: tithiStr,
      paksha: Astro.pakshaOf(tithiNum),
      isEkadashi: Astro.isEkadashi(tithiNum),
      isPurnima: Astro.isPurnima(tithiNum),
      isAunsi: Astro.isAunsi(tithiNum),
      observances: Observances.summary(obsNamed, lang)
    };
  },

  getMonthData: function(year, month, lang, numStyle, weekStart) {
    lang = lang || "Nepali";
    numStyle = numStyle || "Devanagari";
    weekStart = (weekStart === 1) ? 1 : 0;
    var length = Bikram.monthLength(year, month);
    if (length === 0) return null;
    
    var grid = Bikram.monthGrid(year, month, weekStart);
    var marks = Observances.forMonth(grid, function(cell) {
      return Astro.tithiForDate(cell.gregorian.year, cell.gregorian.month, cell.gregorian.day);
    });
    
    var firstGreg = Bikram.toGregorian(year, month, 1);
    var lastGreg = Bikram.toGregorian(year, month, length);
    var span = Nepali.gregorianSpan(firstGreg, lastGreg);
    var title = Nepali.monthTitle(year, month, { language: lang, numerals: numStyle });
    var conf = Bikram.confidence(year);
    
    var formattedWeeks = [];
    for (var w = 0; w < grid.length; w++) {
      var row = [];
      for (var col = 0; col < grid[w].length; col++) {
        var cell = grid[w][col];
        if (!cell) {
          row.push(null);
        } else {
          var tithi = Astro.tithiForDate(cell.gregorian.year, cell.gregorian.month, cell.gregorian.day);
          var dayObs = marks[cell.day] || [];
          var isSat = Nepali.isWeeklyHoliday(cell.weekday);
          var isHol = isSat || Observances.isHoliday(dayObs);
          var namedObs = Observances.named(dayObs);
          var tName = Nepali.tithiName(tithi, lang);
          var tLabel = Nepali.tithiLabel(tithi, Astro.pakshaOf(tithi), lang);
          
          row.push({
            year: cell.year,
            month: cell.month,
            day: cell.day,
            dayText: Nepali.numerals(cell.day, numStyle),
            weekday: cell.weekday,
            weekdayName: Nepali.weekdayName(cell.weekday, lang),
            gregorian: cell.gregorian,
            gregorianDayText: String(cell.gregorian.day),
            tithi: tithi,
            tithiName: tName,
            tithiLabel: tLabel,
            paksha: Astro.pakshaOf(tithi),
            isEkadashi: Astro.isEkadashi(tithi),
            isPurnima: Astro.isPurnima(tithi),
            isAunsi: Astro.isAunsi(tithi),
            isHoliday: isHol,
            isSaturday: isSat,
            hasMark: dayObs.length > 0,
            observanceSummary: Observances.summary(namedObs, lang)
          });
        }
      }
      formattedWeeks.push(row);
    }
    
    var weekdays = Nepali.weekdayOrder(weekStart).map(function(w) {
      return {
        index: w,
        name: Nepali.weekdayShort(w, lang),
        isSaturday: Nepali.isWeeklyHoliday(w)
      };
    });
    
    return {
      year: year,
      month: month,
      title: title,
      gregorianSpan: span,
      confidence: conf,
      provisionalNotice: conf === "provisional" ? Nepali.provisionalNotice(year, { language: lang, numerals: numStyle }) : "",
      weekdays: weekdays,
      weeks: formattedWeeks
    };
  },

  convertDate: function(inputStr) {
    if (!inputStr) return { valid: false, error: "Empty date" };
    var bsResult = Bikram.readBikramDate(inputStr);
    if (bsResult.date) {
      var d = bsResult.date;
      var greg = Bikram.toGregorian(d.year, d.month, d.day);
      if (!greg) return { valid: false, error: "Out of calendar range" };
      var wd = Bikram.weekdayOf(d.year, d.month, d.day);
      var tithi = Astro.tithiForDate(greg.year, greg.month, greg.day);
      var obs = Observances.forDate(d, greg, tithi);
      return {
        valid: true,
        sourceType: "BS",
        year: d.year,
        month: d.month,
        day: d.day,
        bsFormatted: d.year + "-" + (d.month < 10 ? "0" : "") + d.month + "-" + (d.day < 10 ? "0" : "") + d.day,
        bsFormattedDev: Nepali.numerals(d.year, "Devanagari") + "-" + Nepali.padded(d.month, "Devanagari") + "-" + Nepali.padded(d.day, "Devanagari"),
        gregFormatted: greg.year + "-" + (greg.month < 10 ? "0" : "") + greg.month + "-" + (greg.day < 10 ? "0" : "") + greg.day,
        weekdayName: Nepali.weekdayName(wd, "Nepali"),
        tithiLabel: Nepali.tithiLabel(tithi, Astro.pakshaOf(tithi), "Nepali"),
        observance: Observances.summary(Observances.named(obs), "Nepali")
      };
    }
    var gregResult = Bikram.readGregorianDate(inputStr);
    if (gregResult.date) {
      var bs = gregResult.date;
      var parts = Bikram.toGregorian(bs.year, bs.month, bs.day);
      var wd = Bikram.weekdayOf(bs.year, bs.month, bs.day);
      var tithi = Astro.tithiForDate(parts.year, parts.month, parts.day);
      var obs = Observances.forDate(bs, parts, tithi);
      return {
        valid: true,
        sourceType: "AD",
        year: bs.year,
        month: bs.month,
        day: bs.day,
        bsFormatted: bs.year + "-" + (bs.month < 10 ? "0" : "") + bs.month + "-" + (bs.day < 10 ? "0" : "") + bs.day,
        bsFormattedDev: Nepali.numerals(bs.year, "Devanagari") + "-" + Nepali.padded(bs.month, "Devanagari") + "-" + Nepali.padded(bs.day, "Devanagari"),
        gregFormatted: parts.year + "-" + (parts.month < 10 ? "0" : "") + parts.month + "-" + (parts.day < 10 ? "0" : "") + parts.day,
        weekdayName: Nepali.weekdayName(wd, "Nepali"),
        tithiLabel: Nepali.tithiLabel(tithi, Astro.pakshaOf(tithi), "Nepali"),
        observance: Observances.summary(Observances.named(obs), "Nepali")
      };
    }
    return { valid: false, error: "Invalid date format. Example: 2083-07-17 or 2026-11-03" };
  }
};
"""

bundle_content = f"""
// Patro Consolidated Engine
var Data = {{}};
(function() {{
{calendar_data}
  Data = {{
    MONTH_LENGTHS: MONTH_LENGTHS, FIRST_YEAR: FIRST_YEAR, LAST_YEAR: LAST_YEAR,
    ANCHOR_AD: ANCHOR_AD, ATTESTED_THROUGH: ATTESTED_THROUGH, PUBLISHED_THROUGH: PUBLISHED_THROUGH
  }};
}})();

var Astro = {{}};
(function() {{
{astro}
  Astro = {{
    tithiForDate: tithiForDate, pakshaOf: pakshaOf, isEkadashi: isEkadashi,
    isPurnima: isPurnima, isAunsi: isAunsi, sunriseUtcMs: sunriseUtcMs,
    elongationAt: elongationAt, tithiAt: tithiAt
  }};
}})();

var Nepali = {{}};
(function() {{
{nepali}
  Nepali = {{
    numerals: numerals, padded: padded, monthName: monthName, weekdayName: weekdayName,
    weekdayShort: weekdayShort, tithiName: tithiName, tithiLabel: tithiLabel,
    formatDate: formatDate, monthTitle: monthTitle, gregorianSpan: gregorianSpan,
    PAKSHA: PAKSHA, isWeeklyHoliday: isWeeklyHoliday, weekdayOrder: weekdayOrder,
    normalizeLanguage: normalizeLanguage, normalizeNumerals: normalizeNumerals,
    normalizeFormat: normalizeFormat, normalizeWeekStart: normalizeWeekStart,
    provisionalNotice: provisionalNotice
  }};
}})();

var Observances = {{}};
(function() {{
{observances}
  Observances = {{
    forDate: forDate, isHoliday: isHoliday, named: named, summary: summary,
    forMonth: forMonth, nameOf: nameOf
  }};
}})();

var Bikram = {{}};
(function() {{
{bikram}
  Bikram = {{
    firstYear: firstYear, lastYear: lastYear, confidence: confidence,
    monthLength: monthLength, isValid: isValid, toGregorian: toGregorian,
    fromGregorian: fromGregorian, weekdayOf: weekdayOf, today: today,
    addMonths: addMonths, addDays: addDays, monthGrid: monthGrid, clampDay: clampDay,
    readBikramDate: readBikramDate, readGregorianDate: readGregorianDate
  }};
}})();

{patro_app_helpers}
"""

out_path = os.path.join("PatroMac", "Sources", "Resources", "patro_core.js")
with open(out_path, "w", encoding="utf-8") as f:
    f.write(bundle_content)

print(f"Generated {out_path} ({len(bundle_content)} bytes)")
