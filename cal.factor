USING: accessors arrays calendar combinators
db.sqlite db.tuples db.types enter fonts.syntax fry grouping
io.pathnames io.styles kernel locals math math.functions
math.intervals math.order math.parser models models.combinators
models.merge monads peg peg.ebnf persistency quotations
sequences splitting ui ui.baseline-alignment ui.gadgets
ui.gadgets.biggies ui.gadgets.labels ui.gadgets.layout
ui.gadgets.magic-scrollers ui.gadgets.model-buttons
ui.gadgets.poppers ui.gadgets.sliders ui.gadgets.tracks
models.filter ui.pens ui.pens.solid colors.constants ;
IN: cal

STORED-TUPLE: event { text { VARCHAR 300 } } { day DATE } { minutes INTEGER } tags ;
STORED-TUPLE: repetitions { event INTEGER } { ending DATE } rule ;
home ".events" append-path <sqlite-db> event define-db

: multiple-of-7 ( a -- a' ) 7 / ceiling 7 * ;

: daylist ( viewedDate days -- timelist ) dup 0 = [ drop 1 ]
    [ dup 28 = [ drop [ beginning-of-month ] [ days-in-month ] bi ] when
        [ beginning-of-week ] [ multiple-of-7 ] bi*
    ] if [ 1 days time- dup ] dip days time+
    [ dupd before? ] curry [ 1 days time+ dup ] produce nip ;

: form-time ( list -- minutes )
    dup first [
        first2 {
           { "PM" [ 720 + ] }
           { "AM" [ ] }
           { f [ dup 60 360 [a,b] interval-contains? [ 720 + ] when ] }
        } case
    ] [ drop f ] if ;

EBNF: find-time
i = [0-9]
space = " " => [[ drop ignore ]]
time = i i? ":" i i space => [[ ":" 1array split1 [ sift ] dip [ string>number ] bi@ swap 60 * + ]]
am/pm = ("AM" | "PM") space
expr = time? am/pm? .* => [[ but-last form-time ]]
;EBNF ! 12:00 is weird- handle it

: insert-event ( popped -- )
    [ dup parent>> children>> remove ] keep
        [   control-value minutes>> swap
            [ control-value minutes>> before? ] sort-index
        ] keep [ parent>> ] keep rot add-gadget-at drop ;

: prev ( popper -- prev-popper )
    dup parent>> children>> [ index 1 - 0 max ] keep nth ;
    
:: handle-unfocus ( p -- )
    p control-value :> v
    v text>> find-time [
        [ v swap >>minutes drop ]
        [ p prev control-value minutes>> or p swap
        [ insert-event ] [ drop ] if ] bi
    ] when* v dup id>> [ modify-tuple ] [ store-tuple ] if ;

TUPLE: day < track other-month time ;

TUPLE: skin weekend weekday other-month gap ;
M: skin draw-interior over dup other-month>>
    [ drop other-month>> ] [ time>> day-of-week
        [ 0 = ] [ 6 = ] bi or [ weekend>> ] [ weekday>> ] if
    ] if draw-interior ;
M: skin draw-boundary gap>> draw-boundary ;

: <basic-theme> ( -- skin )
    COLOR: moccasin <solid>
    COLOR: white <solid>
    COLOR: DarkGray <solid>
    COLOR: DimGray <solid>
    skin boa ;

: <day> ( viewedDate timestamp -- gadget )
    swap over [ month>> ] bi@ = not
    vertical day new-track swap >>other-month
    over day>> number>string <label> add-gadget
    <basic-theme> [ >>interior ] keep >>boundary
    over >>time
    over event new swap >>day <query> swap >>tuple "minutes" >>order get-tuples
    <model> <popper> [ text>> ] >>quot [ swap >>text ] >>setter-quot rot
    '[ event new _ >>day 0 >>minutes "" >>text ] >>creator-quot [ handle-unfocus ] >>unfocus-hook
    [ remove-tuples ] >>delete-hook
    <magic-scroller> 1 add-gadget* <biggie> ;

: calendar ( viewedDate daynums -- gadget ) over [ daylist ] dip '[
    7 group [ [ [ _ over <day> ->% 1 swap 1quotation <$ ] map ] <hbox> ,% 1 ] map
    ] <vbox> swap concat merge >>model ;

: calWindow ( -- )
    [ [ $ MONTHS $ $ CAL $ [ $ TOOLBAR $ ] <hbox> , ] <vbox>
        [
            [ dup
                <spacer>
                [ [ 1 months time- month>> month-name ] fmap <label-control>
                    FONT: 18 ; <model-button> -1 >>value -> ]
                [ [ month>> month-name ] fmap <label-control> FONT: 24 bold ; , ]
                [ [ 1 months time+ month>> month-name ] fmap <label-control>
                    FONT: 18 ; <model-button> 1 >>value -> ]
                tri 2merge [ months time+ beginning-of-month ] smart fmap <spacer>
            ] with-self now >>value
        ] <hbox> { 25 0 } >>gap +baseline+ >>align MONTHS ,
        [ 28 0 28 7 <slider*> TOOLBAR ->
            [ updates discrete 2merge ] keep [ CAL calendar ->% 1 ] smart* bind
        ] with-self ,
    ] with-interface { 500 400 } >>pref-dim "Date Cowboy" open-window ;

! smart* is still not working

ENTER: [ calWindow ] with-ui ;