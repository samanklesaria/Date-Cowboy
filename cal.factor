USING: accessors cal.skins calendar enter fonts.syntax fry
grouping io.styles kernel math math.functions math.order
math.parser models.combinators monads sequences ui
ui.baseline-alignment ui.gadgets ui.gadgets.buttons
ui.gadgets.labels ui.gadgets.layout ui.gadgets.sliders
ui.gadgets.tracks ;
IN: cal

: multiple-of-7 ( a -- a' ) 7 / ceiling 7 * ;
: daylist ( viewedDate days -- timelist ) dup 0 = [ drop 1 ]
    [ dup 28 = [ drop [ beginning-of-month ] [ days-in-month ] bi ] when
        [ beginning-of-week ] [ multiple-of-7 ] bi*
    ] if [ 1 days time- dup ] dip days time+
    [ dupd before? ] curry [ 1 days time+ dup ] produce nip ;

TUPLE: day < track other-month time ;
USE: cal.skins
: <day> ( viewedDate timestamp -- gadget )
    tuck [ month>> ] bi@ = not
    vertical day new-track swap >>other-month
    over day>> number>string <label> f track-add
    swap >>time <mozilla-theme> [ >>interior ] keep >>boundary ;

: calendar ( viewedDate daynums -- gadget ) over [ daylist ] dip '[
    7 group [ [ [ _ swap <day> ,% 1 ] each ] <hbox> ,% 1 ] each
    ] <vbox> ;

: calWindow ( -- ) [ [ $ MONTHS $ $ CAL $ [ $ TOOLBAR $ ] <hbox> , ] <vbox>
    [
        [ dup
            <spacer>
            [ [ 1 months time- month>> month-name ] fmap <label-control> FONT: 18 ; <button*> -1 >>value -> ]
            [ [ month>> month-name ] fmap <label-control> FONT: 24 bold ; , ]
            [ [ 1 months time+ month>> month-name ] fmap <label-control> FONT: 18 ; <button*> 1 >>value -> ]
            tri 2merge [ months time+ 1 >>day ] 2fmap <spacer>
        ] with-self now >>value
    ] <hbox> { 25 0 } >>gap +baseline+ >>align MONTHS ,
    28 0 28 7 <slider*> TOOLBAR -> [ CAL calendar ,% 1 ] 2$> ,
    ] with-interface { 500 400 } >>pref-dim "Date Cowboy" open-window ;
ENTER: [ calWindow ] with-ui ;