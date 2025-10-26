#import "subsection.typ": subsection

/// Creates a generic section with a title, some text content, and some subsections.
/// 
/// -> content
#let section(
  /// -> str | none
  title: none,
  /// -> array
  subsections: (),
  /// -> str | none
  text: none,

) = {
  if title != none {
    [== #title]
  }

  line()
  if (type(text) == str) {
   [#text]
  }

  if( subsections.len() > 0){
    subsections.map(x => subsection(..x)).join()
  }
}
