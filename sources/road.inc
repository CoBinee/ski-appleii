; road.inc - 道
; 


; 道
;
ROAD_SIZE_X                         =   10
ROAD_SIZE_Y                         =   24
ROAD_START_X                        =   15
ROAD_START_Y                        =   10
ROAD_LEFT                           =   3
ROAD_RIGHT                          =   23
ROAD_ROUTE_LEFT                     =   2
ROAD_ROUTE_RIGHT                    =   7
ROAD_DISTANCE_1000                  =   $00
ROAD_DISTANCE_0100                  =   $01
ROAD_DISTANCE_0010                  =   $02
ROAD_DISTANCE_0001                  =   $03
ROAD_DISTANCE_SIZE                  =   $04

; 道の情報
;
.struct Road

    ; X 位置
    xs              .byte   24

    ; 経路
    routes          .byte   24

    ; 次に登録する位置
    next_x          .byte
    next_y          .byte

    ; 距離
    distances       .byte   4

.endstruct
