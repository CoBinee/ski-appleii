; pen.inc - ペンペン
; 


; ペンペン
;
PENPEN_X                            =   19
PENPEN_Y                            =   10

; ペンペンの情報
;
.struct Penpen

    ; 操作可能
    active          .byte

    ; 位置
    position_x      .byte
    position_y      .byte

    ; 移動
    move            .byte

    ; マスク
    mask            .byte

    ; アニメーション
    animation       .byte

.endstruct
