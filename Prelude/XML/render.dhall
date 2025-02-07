{-|
Render an `XML` value as `Text`

For indentation and schema validation, see the `xmllint` utility
bundled with libxml2.

```
let XML = ./package.dhall

in  XML.render
    ( XML.element
      { name = "foo"
      , attributes = [ XML.attribute "a" "x", XML.attribute "b" (Natural/show 2) ]
      , content = [ XML.leaf { name = "bar", attributes = XML.emptyAttributes } ]
      }
    )
= "<foo a=\"x\" b=\"2\"><bar/></foo>"
```

-}
let XML =
        ./Type.dhall
          sha256:ab91a0edaf0513e0083b1dfae5efa160adc99b0e589775a4a699ab77cce528a9
      ? ./Type.dhall

let Text/concatMap =
        ../Text/concatMap.dhall
          sha256:7a0b0b99643de69d6f94ba49441cd0fa0507cbdfa8ace0295f16097af37e226f
      ? ../Text/concatMap.dhall

let Text/concat =
        ../Text/concat.dhall
          sha256:731265b0288e8a905ecff95c97333ee2db614c39d69f1514cb8eed9259745fc0
      ? ../Text/concat.dhall

let element =
        ./element.dhall
          sha256:79266d604e147caf37e985581523b684f7bac66de0c93dd828841df3dfc445f9
      ? ./element.dhall

let text =
        ./text.dhall
          sha256:a59670560a08bfc815893dee1f3eae21a5252400f8a619d1cd7bdd9f48eea2ab
      ? ./text.dhall

let emptyAttributes =
        ./emptyAttributes.dhall
          sha256:11b86e2d3f3c75d47a1d580213d2a03fd2c36d64f3e9b6381de0ba23472f64d5
      ? ./emptyAttributes.dhall

let Attr = { mapKey : Text, mapValue : Text }

let esc = λ(x : Text) → λ(y : Text) → Text/replace x "&${y};"

let `escape&` = esc "&" "amp"

let `escape<` = esc "<" "lt"

let `escape>` = esc ">" "gt"

let `escape'` = esc "'" "apos"

let `escape"` = esc "\"" "quot"

let escapeCommon = λ(text : Text) → `escape<` (`escape&` text)

let escapeAttr = λ(text : Text) → `escape"` (`escape'` (escapeCommon text))

let escapeText = λ(text : Text) → `escape>` (escapeCommon text)

let renderAttr = λ(x : Attr) → " ${x.mapKey}=\"${escapeAttr x.mapValue}\""

let render
    : XML → Text
    = λ(x : XML) →
        x
          Text
          { text = escapeText
          , rawText = λ(t : Text) → t
          , element =
              λ ( elem
                : { attributes : List { mapKey : Text, mapValue : Text }
                  , content : List Text
                  , name : Text
                  }
                ) →
                let attribs = Text/concatMap Attr renderAttr elem.attributes

                in      "<${elem.name}${attribs}"
                    ++  ( if    Natural/isZero (List/length Text elem.content)
                          then  "/>"
                          else  ">${Text/concat elem.content}</${elem.name}>"
                        )
          }

let simple =
      λ(name : Text) →
      λ(content : List XML) →
        element { name, attributes = emptyAttributes, content }

let example0 =
        assert
      :   render
            ( simple
                "note"
                [ simple "to" [ text "Tove" ]
                , simple "from" [ text "Jani" ]
                , simple "heading" [ text "Reminder" ]
                , simple "body" [ text "Don't forget me this weekend!" ]
                ]
            )
        ≡ Text/replace
            "\n"
            ""
            ''
            <note>
            <to>Tove</to>
            <from>Jani</from>
            <heading>Reminder</heading>
            <body>Don't forget me this weekend!</body>
            </note>
            ''

let example1 =
        assert
      :   render
            ( element
                { name = "escape"
                , attributes = toMap { attribute = "<>'\"&" }
                , content = [ text "<>'\"&" ]
                }
            )
        ≡ Text/replace
            "\n"
            ""
            ''
            <escape attribute="&lt;>&apos;&quot;&amp;">&lt;&gt;'"&amp;</escape>
            ''

in  render
