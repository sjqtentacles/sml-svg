(* test.sml

   Strict-TDD suite for `Svg`. SVG serialization is exact text, so unlike the
   numeric libraries every assertion is a byte-for-byte `checkString` against a
   golden document. The same goldens must come out of MLton and Poly/ML, which
   is the whole point of `fmtReal` (fixed precision, trimmed, decimal-point
   normalized, leading "-" not "~").

   Goldens are assembled with `lines` (join with "\n") so the expected tree is
   readable in source and the indentation is explicit. The document header is
   factored into `svgOpen` to keep each case focused on its body. *)

structure Tests =
struct

  structure S = Svg

  (* Join lines with newlines (no trailing newline -- matches toString). *)
  fun lines xs = String.concatWith "\n" xs

  fun svgOpen (w, h) =
    "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" ^ Int.toString w
    ^ "\" height=\"" ^ Int.toString h ^ "\" viewBox=\"0 0 "
    ^ Int.toString w ^ " " ^ Int.toString h ^ "\">"

  fun runAll () =
    let
      (* ---- fmtReal: deterministic, decimal-point-normalized ---- *)
      val () = Harness.section "fmtReal numeric formatting"
      val () = Harness.checkString "10.0"   ("10.0",   S.fmtReal 10.0)
      val () = Harness.checkString "3.14"   ("3.14",   S.fmtReal 3.14)
      val () = Harness.checkString "neg"    ("-2.5",   S.fmtReal ~2.5)
      val () = Harness.checkString "zero"   ("0.0",    S.fmtReal 0.0)
      val () = Harness.checkString "negzero"("0.0",    S.fmtReal ~0.0)
      val () = Harness.checkString "half"   ("0.5",    S.fmtReal 0.5)
      val () = Harness.checkString "hundred"("100.0",  S.fmtReal 100.0)
      val () = Harness.checkString "frac3"  ("1.125",  S.fmtReal 1.125)
      val () = Harness.checkString "trim"   ("12.34",  S.fmtReal 12.34)
      val () = Harness.checkString "tenth"  ("0.1",    S.fmtReal 0.1)
      val () = Harness.checkString "negfrac"("-0.25",  S.fmtReal ~0.25)
      val () = Harness.checkString "big"    ("1024.0", S.fmtReal 1024.0)

      (* ---- empty document ---- *)
      val () = Harness.section "Empty document"
      val () =
        Harness.checkString "no elements"
          (lines [svgOpen (100, 50), "</svg>"],
           S.toString { width = 100, height = 50, els = [] })

      (* ---- single rect ---- *)
      val () = Harness.section "Single shapes"
      val () =
        Harness.checkString "rect with fill"
          (lines
             [ svgOpen (200, 100)
             , "  <rect x=\"10.0\" y=\"20.0\" width=\"50.0\" height=\"30.0\" fill=\"red\"/>"
             , "</svg>" ],
           S.toString
             { width = 200, height = 100
             , els = [ S.Rect { x = 10.0, y = 20.0, width = 50.0, height = 30.0
                              , attrs = [("fill", "red")] } ] })

      val () =
        Harness.checkString "circle"
          (lines
             [ svgOpen (60, 60)
             , "  <circle cx=\"30.0\" cy=\"30.0\" r=\"15.0\" fill=\"blue\"/>"
             , "</svg>" ],
           S.toString
             { width = 60, height = 60
             , els = [ S.Circle { cx = 30.0, cy = 30.0, r = 15.0
                                , attrs = [("fill", "blue")] } ] })

      val () =
        Harness.checkString "line with two attrs"
          (lines
             [ svgOpen (100, 100)
             , "  <line x1=\"0.0\" y1=\"0.0\" x2=\"100.0\" y2=\"100.0\" stroke=\"black\" stroke-width=\"2\"/>"
             , "</svg>" ],
           S.toString
             { width = 100, height = 100
             , els = [ S.Line { x1 = 0.0, y1 = 0.0, x2 = 100.0, y2 = 100.0
                              , attrs = [("stroke", "black"), ("stroke-width", "2")] } ] })

      val () =
        Harness.checkString "path"
          (lines
             [ svgOpen (40, 40)
             , "  <path d=\"M0 0 L10 10 Z\"/>"
             , "</svg>" ],
           S.toString
             { width = 40, height = 40, els = [ S.Path "M0 0 L10 10 Z" ] })

      (* ---- text + escaping ---- *)
      val () = Harness.section "Text and escaping"
      val () =
        Harness.checkString "text content escaped"
          (lines
             [ svgOpen (120, 30)
             , "  <text x=\"5.0\" y=\"15.0\" font-size=\"12\">a &lt; b &amp; c &gt; d</text>"
             , "</svg>" ],
           S.toString
             { width = 120, height = 30
             , els = [ S.Text { x = 5.0, y = 15.0, text = "a < b & c > d"
                              , attrs = [("font-size", "12")] } ] })

      val () =
        Harness.checkString "attribute value escaped"
          (lines
             [ svgOpen (10, 10)
             , "  <rect x=\"0.0\" y=\"0.0\" width=\"10.0\" height=\"10.0\" data-x=\"a&quot;&amp;&lt;&gt;b\"/>"
             , "</svg>" ],
           S.toString
             { width = 10, height = 10
             , els = [ S.Rect { x = 0.0, y = 0.0, width = 10.0, height = 10.0
                              , attrs = [("data-x", "a\"&<>b")] } ] })

      (* ---- groups + nesting ---- *)
      val () = Harness.section "Groups and nesting"
      val () =
        Harness.checkString "group with two children"
          (lines
             [ svgOpen (100, 100)
             , "  <g>"
             , "    <circle cx=\"30.0\" cy=\"30.0\" r=\"15.0\" fill=\"blue\"/>"
             , "    <line x1=\"0.0\" y1=\"0.0\" x2=\"100.0\" y2=\"100.0\" stroke=\"black\"/>"
             , "  </g>"
             , "</svg>" ],
           S.toString
             { width = 100, height = 100
             , els =
                 [ S.Group
                     [ S.Circle { cx = 30.0, cy = 30.0, r = 15.0
                                , attrs = [("fill", "blue")] }
                     , S.Line { x1 = 0.0, y1 = 0.0, x2 = 100.0, y2 = 100.0
                              , attrs = [("stroke", "black")] } ] ] })

      val () =
        Harness.checkString "nested groups indent two columns each"
          (lines
             [ svgOpen (50, 50)
             , "  <g>"
             , "    <g>"
             , "      <rect x=\"1.0\" y=\"2.0\" width=\"3.0\" height=\"4.0\"/>"
             , "    </g>"
             , "  </g>"
             , "</svg>" ],
           S.toString
             { width = 50, height = 50
             , els =
                 [ S.Group
                     [ S.Group
                         [ S.Rect { x = 1.0, y = 2.0, width = 3.0, height = 4.0
                                  , attrs = [] } ] ] ] })

      val () =
        Harness.checkString "empty group"
          (lines [ svgOpen (10, 10), "  <g></g>", "</svg>" ],
           S.toString
             { width = 10, height = 10, els = [ S.Group [] ] })

      (* ---- multiple top-level elements, one per line ---- *)
      val () = Harness.section "Document composition"
      val () =
        Harness.checkString "siblings each on their own line"
          (lines
             [ svgOpen (30, 30)
             , "  <rect x=\"0.0\" y=\"0.0\" width=\"30.0\" height=\"30.0\" fill=\"#eee\"/>"
             , "  <circle cx=\"15.0\" cy=\"15.0\" r=\"5.0\"/>"
             , "  <text x=\"2.0\" y=\"28.0\">hi</text>"
             , "</svg>" ],
           S.toString
             { width = 30, height = 30
             , els =
                 [ S.Rect { x = 0.0, y = 0.0, width = 30.0, height = 30.0
                          , attrs = [("fill", "#eee")] }
                 , S.Circle { cx = 15.0, cy = 15.0, r = 5.0, attrs = [] }
                 , S.Text { x = 2.0, y = 28.0, text = "hi", attrs = [] } ] })

      (* ---- no attrs -> bare geometry ---- *)
      val () =
        Harness.checkString "rect without attrs"
          (lines
             [ svgOpen (10, 10)
             , "  <rect x=\"0.0\" y=\"0.0\" width=\"10.0\" height=\"10.0\"/>"
             , "</svg>" ],
           S.toString
             { width = 10, height = 10
             , els = [ S.Rect { x = 0.0, y = 0.0, width = 10.0, height = 10.0
                              , attrs = [] } ] })

      (* ---- fractional + negative coordinates render via fmtReal ---- *)
      val () =
        Harness.checkString "fractional and negative coords"
          (lines
             [ svgOpen (20, 20)
             , "  <line x1=\"-1.5\" y1=\"0.25\" x2=\"10.75\" y2=\"-3.0\"/>"
             , "</svg>" ],
           S.toString
             { width = 20, height = 20
             , els = [ S.Line { x1 = ~1.5, y1 = 0.25, x2 = 10.75, y2 = ~3.0
                              , attrs = [] } ] })
    in
      ()
    end

  fun run () = (Harness.reset (); runAll (); Harness.run ())
end
