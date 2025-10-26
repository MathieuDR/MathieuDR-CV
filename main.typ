#let lang = sys.inputs.at("lang", default: "en")
#import "template/resume.typ": resume
#resume(..json("data/" + lang + ".json"))
