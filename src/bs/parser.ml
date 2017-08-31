(* The nodeType property returns the node type, as a number, of the specified node.

   If the node is an element node, the nodeType property will return 1.

   If the node is an attribute node, the nodeType property will return 2.

   If the node is a text node, the nodeType property will return 3.

   If the node is a comment node, the nodeType property will return 8.

   This property is read-only. *)
let elements = ["br"; "br'"; "div"; "span"; "p"; "pre"; "a";
                "section"; "header"; "footer"; "h1"; "h2"; "h3"; "h4"; "h5"; "h6"; "i";
                "strong"; "button"; "input"; "textarea"; "label"; "ul"; "ol"; "li"; "table";
                "thead"; "tfoot"; "tbody"; "th"; "tr"; "td"; "progress"; "img"; "select";
                "option'"; "form"; "nav"]
let properties = ["id"; "href"; "src"; "style"; "styles"; "placeholder"; "autofocus"; "value"; "name";
                  "checked"; "hidden"; "target"; "action"; "onCB"; "onMsg";
                  "onInputOpt"; "onInput"; "onChangeOpt"; "onChange"; "onClick"; "onDoubleClick";
                  "onBlur"; "onFocus"; "onCheckOpt"; "onCheck"; "onMouseDown"; "onMouseUp";
                  "onMouseEnter"; "onMouseLeave"; "onMouseOver"; "onMouseOut"]
type attr = <
  value : string;
  name : string
> Js.t
type node = <
  attribs : string Js.Dict.t;
  children : node Js.Dict.t;
  _type : string;
  name : string;
  data : string
> Js.t

external parseHtml : string -> node Js.Array.t = "parseHTML" [@@bs.module "cheerio"]
let wrapString str =
  (* let str = Js.String.replace "\n" "" str in *)
  (* let str = Js.String.replace "\t" "" str in *)
  if str == "" then "\"\""
  else
    let noneAscii = try str |> Js.String.match_ [%re "/[\u{0080}-\u{FFFF}\"]/gu"] with _ -> None in
    match noneAscii with
    | Some _matched -> "{js|" ^ str ^ "|js}"
    | None -> "\"" ^ str ^ "\""

let wrapList str =
  if str == "" then "[]" else
    "[ " ^ str ^ " ]"
let listFromArray arr =
  arr |> Js.Array.joinWith "\n; " |> wrapList
let wrapTuple str = "(" ^ str ^ ")"
let tupleFromArray arr =
  arr |> Js.Array.joinWith ", " |> wrapTuple
let tupleFromList list = list |> String.concat ", " |> wrapTuple

let constructAttribute attribute =
  let name, value = attribute in
  match attribute with
  | "checked", "checked" -> "checked true"
  | "checked", _ -> "checked false"
  | "class", value ->
    let classArray = Js.String.split " " value in
    let length = Js.Array.length classArray in
    if length < 2 then
      ["class'"; wrapString value] |> String.concat " "
    else
      let translateClass clazz = [wrapString clazz; (string_of_bool true)] |> tupleFromList in
      let list = Js.Array.map translateClass classArray |> listFromArray in
      ["classList"; list] |> String.concat " "
  | "style", value ->
    let translatePair (pairStr:string) =
      let tempList = Js.String.split ":" pairStr |> Js.Array.reduce (fun list (item:string) -> List.append list [(item |> Js.String.trim)]) []
      in
      (
        match tempList with
        | k::v::_tail -> Some (wrapString k, wrapString v)
        | _ -> None
      )
    in
    let pairArray = Js.String.split ";" value |> Js.Array.map translatePair in
    let pairList = pairArray |> Js.Array.reduce (fun list (item:((string * string) option)) -> match item with | Some item -> item::list | None -> list) [] in
    let tupleToTuple (k, v) = [k; v] |> String.concat ", " |> wrapTuple in
    ( match pairList with
      | [(k, v)] -> "style"::[k; v] |> String.concat " "
      | _ -> ["styles"; pairList |> List.map tupleToTuple |> String.concat "; " |> wrapList] |> String.concat " "
    )
  | name, value when List.mem name properties -> [name; (wrapString value)] |> String.concat " "
  | _ -> ["Vdom.prop"; (wrapString name); (wrapString value)] |> String.concat " "

let constructAttributeArray attributes =
  Js.Array.map constructAttribute attributes |> listFromArray

let rec convertElement element =
  let name = try element##name with _ -> "" in
  let attributes = try Js.Dict.entries element##attribs with _ -> [%bs.obj [||]] in
  let childNodes = try Js.Dict.values element##children with _ -> [%bs.obj [||]] in
  let nodeType = try element##_type with _ -> (*any number other than 1, 2, 3*) "text" in
  match nodeType with
  (* element node *)
  | "tag" ->
    (match name with
     | "br" -> ["br"; constructAttributeArray attributes] |> String.concat " "
     | _ ->
       let name = (
         match name with
         | "input" -> "input'"
         | name when List.mem name elements -> name
         | _ -> ["Vdom.fullnode"; wrapString ""; wrapString name ; wrapString "" ; wrapString ""] |> String.concat " "
       )
       in
       [name; constructAttributeArray attributes ; (Js.Array.map convertElement childNodes |> Js.Array.filter (fun x -> x != "")  |> listFromArray)] |> String.concat "\n"
    )
  (* text node *)
  | "text" ->
    let text = element##data in
    let trimmed = Js.String.trim text in
    if trimmed == "" then "" else ["text"; (trimmed |> wrapString )] |> String.concat " "
  (* attribute node *)
  | _ -> ""

let convertElementArray elementArray =
  let convertedArray = Js.Array.map convertElement elementArray in
  let length = Js.Array.length convertedArray in
  if length == 1
  then
    convertedArray |> Js.Array.filter (fun x -> x != "") |> Js.Array.join
  else
    ["div"; "" |> wrapList ; convertedArray |> Js.Array.filter (fun x -> x != "") |> listFromArray]  |> String.concat " "

let convert str =
  (* let _ = Js.log str in *)
  let elementArray = parseHtml str in
  let _ = Js.log elementArray in
  elementArray |> convertElementArray


