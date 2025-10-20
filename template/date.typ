/// Creates a formatted date with a short month and a year (e.g. "Jan 2025").
///
/// -> content
#let date(
  /// -> int
  year: 0,
  /// -> int | none
  month: none
) = {
  if month == none {
    str(year)
  } else {
    datetime(year: year, month: month, day: 1).display("[month repr:short] [year repr:full]")
  }
}

/// Creates a formatted date range, using "Present" in place of a missing end date.
/// 
/// Panics when the start date is `none`.
/// 
/// -> content
#let range(
  /// -> date | none
  from: none, 
  /// -> date | none | str
  to: none
) = {
  let d_from = date(..from)
  if d_from == none {
    panic("range.from must not be none - please pass a valid date")
  }

  ( 
    d_from
    + " " 
    + $dash.em$ 
    + " " 
    + { if(type(to) == str) { [#to] } else { date(..to) } }
  )
}
