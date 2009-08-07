USING: accessors calendar kernel ui.pens ui.pens.solid colors.constants ;
IN: cal.skins

TUPLE: skin weekend weekday other-month gap ;
M: skin draw-interior over dup other-month>> ! this one's from the day
    [ drop other-month>> ] [ time>> day-of-week
        [ 0 = ] [ 6 = ] bi or [ weekend>> ] [ weekday>> ] if
    ] if draw-interior ;
M: skin draw-boundary gap>> draw-boundary ;

: <mozilla-theme> ( -- skin )
    COLOR: moccasin <solid>
    COLOR: white <solid>
    COLOR: DarkGray <solid>
    COLOR: DimGray <solid>
    skin boa ;