#let lang = sys.inputs.at("lang", default: "en")
// #import "@preview/kiresume:0.1.17": resume
#import "template/resume.typ": resume
#resume(..json("data/" + lang + ".json"))
