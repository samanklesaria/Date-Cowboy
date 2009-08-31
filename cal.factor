USING: accessors cal.skins calendar db.sqlite db.types enter
fonts.syntax fry grouping io.pathnames io.styles kernel math
math.functions math.order math.parser models.combinators monads
persistency sequences ui ui.baseline-alignment ui.gadgets
ui.gadgets.model-buttons ui.gadgets.labels ui.gadgets.layout
ui.gadgets.poppers ui.gadgets.sliders ui.gadgets.tracks
ui.gadgets.biggies ui.gadgets.magic-scrollers models ;
IN: cal

STORED-TUPLE: event { text { VARCHAR 300 } } { day DATE } ;
home ".events" append-path <sqlite-db> event define-db

: multiple-of-7 ( a -- a' ) 7 / ceiling 7 * ;
: daylist ( viewedDate days -- timelist ) dup 0 = [ drop 1 ]
    [ dup 28 = [ drop [ beginning-of-month ] [ days-in-month ] bi ] when
        [ beginning-of-week ] [ multiple-of-7 ] bi*
    ] if [ 1 days time- dup ] dip days time+
    [ dupd before? ] curry [ 1 days time+ dup ] produce nip ;

TUPLE: day < track other-month time ;
: <day> ( viewedDate timestamp -- gadget )
    tuck [ month>> ] bi@ = not
    vertical day new-track swap >>other-month
    over day>> number>string <label> f add-gadget*
    over >>time <mozilla-theme> [ >>interior ] keep >>boundary
    event new rot [ 
        >>day get-tuples [ text>> ] map <model> <popper>
    ] keep
    [ '[ event new _ >>day swap >>text store-tuple ] >>unfocus-hook ]
    [ '[ event new _ >>day swap >>text remove-tuples ] >>focus-hook ] bi
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