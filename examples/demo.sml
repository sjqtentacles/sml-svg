(* demo.sml

   A tour of the `Svg` builder: compose a small landscape "card" out of every
   element kind -- a background `Rect`, a sun `Circle`, a mountain `Path`, a
   horizon `Line`, a `Group` of accent dots, and `Text` labels -- then render
   it with `Svg.toString` and write it to `example.svg`. The output is
   deterministic and byte-identical under MLton and Poly/ML. Build and run with
   `make example`. *)

structure S = Svg

fun line s = print (s ^ "\n")

(* A palette for the accent dots. *)
val palette = ["#38bdf8", "#34d399", "#fbbf24", "#f472b6", "#a78bfa"]

(* Five accent dots in a row near the bottom-left, one per palette color. *)
val dots =
  let
    val n = length palette
    val idx = List.tabulate (n, fn i => i)
  in
    ListPair.map
      (fn (i, color) =>
         S.Circle { cx = 30.0 + real i * 22.0, cy = 214.0, r = 6.0
                  , attrs = [("fill", color)] })
      (idx, palette)
  end

(* The drawing: ordered back-to-front. *)
val scene =
  { width = 360, height = 240
  , els =
      [ (* card background + rounded border *)
        S.Rect { x = 0.0, y = 0.0, width = 360.0, height = 240.0
               , attrs = [("fill", "#f8fafc")] }
      , S.Rect { x = 8.0, y = 8.0, width = 344.0, height = 224.0
               , attrs = [ ("fill", "none"), ("stroke", "#cbd5e1")
                         , ("stroke-width", "2"), ("rx", "12") ] }
      , (* sun behind the mountains *)
        S.Circle { cx = 272.0, cy = 92.0, r = 30.0
                 , attrs = [("fill", "#fbbf24")] }
      , (* mountain silhouette: a raw Path, default (dark) fill *)
        S.Path "M 20 184 L 80 96 L 130 150 L 190 70 L 246 150 L 300 110 L 340 184 Z"
      , (* horizon line *)
        S.Line { x1 = 20.0, y1 = 184.0, x2 = 340.0, y2 = 184.0
               , attrs = [("stroke", "#0f172a"), ("stroke-width", "2")] }
      , (* accent dots, grouped *)
        S.Group dots
      , (* labels *)
        S.Text { x = 24.0, y = 40.0, text = "sml-svg"
               , attrs = [ ("fill", "#0f172a"), ("font-size", "24")
                         , ("font-family", "monospace"), ("font-weight", "bold") ] }
      , S.Text { x = 24.0, y = 58.0
               , text = "pure Standard ML <svg> builder & pretty-printer"
               , attrs = [ ("fill", "#475569"), ("font-size", "11")
                         , ("font-family", "monospace") ] } ] }

val svg = S.toString scene

(* Write the asset (committed; embedded in the README). *)
val () =
  let
    val out = TextIO.openOut "example.svg"
  in
    TextIO.output (out, svg ^ "\n");
    TextIO.closeOut out
  end

val () = line "Wrote example.svg:"
val () = line ""
val () = line svg
