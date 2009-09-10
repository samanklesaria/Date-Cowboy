USING: accessors arrays cal.skins calendar combinators db.sqlite
db.tuples db.types enter fonts.syntax fry grouping io.pathnames
io.styles kernel locals math math.functions math.intervals
math.order math.parser models models.combinators monads peg
peg.ebnf persistency sequences sequences.extras ui
ui.baseline-alignment ui.gadgets ui.gadgets.biggies
ui.gadgets.labels ui.gadgets.layout ui.gadgets.magic-scrollers
ui.gadgets.model-buttons ui.gadgets.poppers ui.gadgets.sliders
ui.gadgets.tracks splitting ui.tools.inspector ;
IN: cal

STORED-TUPLE: event { text { VARCHAR 300 } } { day BIG-INTEGER } { pos INTEGER } ;
home ".events" append-path <sqlite-db> event define-db

: multiple-of-7 ( a -- a' ) 7 / ceiling 7 * ;

: >minutes ( timestamp -- seconds ) unix-1970 (time-) 60 / >integer ;

: whole-day ( timestamp -- interval ) dup 1 days time+ [ >minutes ] bi@ [a,b) ;

: control-text ( control -- text ) control-value text>> ;

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
;EBNF

: insert-event ( popped -- pos )
    dup parent>> children>>
    [
        dupd over control-text find-time
        [ [ delete ] [ [ [ control-value day>> ] bi@ before? ] insert-sorted ] 2bi ]
        [
            2dup tuck index 1 - swap ?nth
            dup [ control-text find-time ] when
            [ [ delete ] [ swap prefix ] 2bi ] [ nip ] if
        ] if
        swap parent>> (>>children)
    ]
    [ drop relayout ]
    [ index ] 2tri ;

:: handle-unfocus ( p d -- )
    [let* | v [ p control-value ] tm [ v text>> find-time ] |
        tm [
            v d tm minutes time+ >minutes swap (>>day)
        ] when
        p insert-event
        v swap >>pos f >>id store-tuple
    ] ;

TUPLE: day < track other-month time ;
: <day> ( viewedDate timestamp -- gadget )
    tuck [ month>> ] bi@ = not
    vertical day new-track swap >>other-month
    over day>> number>string <label> f add-gadget*
    over >>time <mozilla-theme> [ >>interior ] keep >>boundary
    event new rot [ 
        whole-day >>day <query> swap >>tuple "pos" >>order get-tuples <model> <popper>
        [ text>> ] >>quot [ control-value remove-tuples ] >>focus-hook
    ] keep
    [ >minutes '[ event new _ >>day swap >>text ] >>setter-quot ]
    [ '[ _ handle-unfocus ] >>unfocus-hook ] bi
    <magic-scroller> 1 add-gadget* <biggie> ;

: calendar ( viewedDate daynums -- gadget ) over [ daylist ] dip '[
    7 group [ [ [ _ swap <day> ,% 1 ] each ] <hbox> ,% 1 ] each
    ] <vbox> ;

: calWindow ( -- ) [ [ $ MONTHS $ $ CAL $ [ $ TOOLBAR $ ] <hbox> , ] <vbox>
    [
        [ dup
            <spacer>
            [ [ 1 months time- month>> month-name ] fmap <label-control> FONT: 18 ; <model-button> -1 >>value -> ]
            [ [ month>> month-name ] fmap <label-control> FONT: 24 bold ; , ]
            [ [ 1 months time+ month>> month-name ] fmap <label-control> FONT: 18 ; <model-button> 1 >>value -> ]
            tri 2merge [ months time+ 1 >>day ] 2fmap <spacer>
        ] with-self now >>value
    ] <hbox> { 25 0 } >>gap +baseline+ >>align MONTHS ,
    28 0 28 7 <slider*> TOOLBAR -> [ CAL calendar ,% 1 ] 2$> ,
    ] with-interface { 500 400 } >>pref-dim "Date Cowboy" open-window ;

ENTER: [ calWindow ] with-ui ;