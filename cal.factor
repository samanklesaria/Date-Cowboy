USING: accessors arrays calendar combinators grouping kernel
math math.functions math.order models.range monads
sequences ui.frp.gadgets ui.frp.layout ui.frp.signals
ui.gadgets ui.gadgets.labels ui.gadgets.sliders
ui.gadgets.tracks enter ui ui.baseline-alignment
math.parser locals ui.tools.inspector ;
IN: cal

: multiple-of-7 ( a -- a' ) 7 / ceiling 7 * ;
: daylist ( viewedDate days -- timelist ) dup 0 = [ drop 1 ]
    [ dup 28 = [ drop [ beginning-of-month ] [ days-in-month ] bi ] when
        [ beginning-of-week ] [ multiple-of-7 ] bi*
    ] if [ 1 days time- dup ] dip days time+
    [ dupd before? ] curry [ 1 days time+ dup ] produce nip ;

TUPLE: day < track other-month? time ;
USE: cal.skins
: <day> ( viewedDate timestamp -- gadget )
    tuck [ month>> ] bi@ = not
    vertical day new-track swap >>other-month?
    over day>> number>string <label> 1 track-add
    swap >>time <mozilla-theme> [ >>interior ] keep >>boundary ;

:: calendar ( viewedDate daynums -- gadget ) viewedDate daynums daylist [
    7 group [ [ [ viewedDate swap <day> ,% 1 ] each ] <hbox> ,% 1 ] each
    ] <vbox> ;

: <label+font> ( model size -- gadget font ) [ <label-control> dup font>> ] dip >>size ;

: calWindow ( -- ) [ [ $ MONTHS $ $ CAL $ [ $ TOOLBAR $ ] <hbox> , ] <vbox>
    [
        [ dup
            <spacer>
            [ [ 1 months time- month>> month-name ] fmap 18 <label+font> drop <frp-button> -1 >>value -> ]
            [ [ month>> month-name ] fmap 24 <label+font> t >>bold? drop , ]
            [ [ 1 months time+ month>> month-name ] fmap 18 <label+font> drop <frp-button> 1 >>value -> ]
            tri <2merge> [ months time+ 1 >>day ] 2fmap <spacer>
        ] with-self now >>value
    ] <hbox> { 25 0 } >>gap +baseline+ >>align MONTHS ,
    0 0 0 28 7 <frp-slider> TOOLBAR -> [ CAL calendar ,% 1 ] 2$> ,
    ] with-interface { 500 400 } >>pref-dim "Date Cowboy" open-window ;
ENTER: [ calWindow ] with-ui ;