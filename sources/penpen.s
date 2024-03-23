; penpen.s - ペンペン
;


; 6502 - CPU の選択
.setcpu     "6502"

; 自動インポート
.autoimport +

; エスケープシーケンスのサポート
.feature    string_escapes


; ファイルの参照
;
.include    "apple2.inc"
.include    "iocs.inc"
.include    "app.inc"
.include    "game.inc"
.include    "penpen.inc"


; コードの定義
;
.segment    "APP"

; ペンペンを初期化する
;
.global _PenpenInitialize
.proc   _PenpenInitialize

    ; ペンペンの初期化

    ; 0 クリア
    ldx     #.sizeof(Penpen)
    lda     #$00
:
    dex
    bmi     :+
    sta     penpen, x
    jmp     :-
:

    ; 位置の設定
    lda     #PENPEN_X
    sta     penpen + Penpen::position_x
    lda     #PENPEN_Y
    sta     penpen + Penpen::position_y

    ; 終了
    rts

.endproc

; ペンペンを更新する
;
.global _PenpenUpdate
.proc   _PenpenUpdate

    ; 操作の可否
    lda     penpen + Penpen::active
    beq     @played

;   ; 移動のクリア
;   lda     #$00
;   sta     penpen + Penpen::move

    ; キー入力
    lda     IOCS_0_KEYCODE
    cmp     #$08
    beq     @input_left
    cmp     #'J'
    beq     @input_left
    cmp     #$15
    beq     @input_right
    cmp     #'L'
    beq     @input_right
;   cmp     #' '
;   beq     @input_stop
;   cmp     #'K'
;   beq     @input_stop
    jmp     @inputed
@input_left:
    lda     #$ff
    sta     penpen + Penpen::move
    jmp     @inputed
@input_right:
    lda     #$01
    sta     penpen + Penpen::move
;   jmp     @inputed
;@input_stop:
;   lda     #$00
;   sta     penpen + Penpen::move
;   jmp     @inputed
@inputed:

    ; 移動
    lda     penpen + Penpen::move
    clc     
    adc     penpen + Penpen::position_x
    sta     penpen + Penpen::position_x

    ; 経路の設定
    ldx     penpen + Penpen::position_x
    ldy     penpen + Penpen::position_y
    jsr     _RoadSetRoute

    ; 操作の完了
@played:

    ; アニメーションの更新
    lda     #$06
    eor     penpen + Penpen::animation
    sta     penpen + Penpen::animation

    ; 終了
    rts

.endproc

; ペンペンを描画する
;
.global _PenpenDraw
.proc   _PenpenDraw

    ; 共通の設定
    lda     penpen + Penpen::position_x
    sec
    sbc     #$01
    sta     @tileset_arg + $0000
    lda     penpen + Penpen::position_y
    sec
    sbc     #$01
    sta     @tileset_arg + $0001
    lda     @tileset_arg + $0000
    ror     a
    bcs     :+
    ldx     #<penpen_sprite_even
    lda     #>penpen_sprite_even
    jmp     :++
:
    ldx     #<penpen_sprite_odd
    lda     #>penpen_sprite_odd
:
    stx     @tileset_arg + $0004
    sta     @tileset_arg + $0005

    ; マスクありの描画
    lda     penpen + Penpen::mask
    beq     :+
    lda     #<penpen_sprite_mask
    sta     @tileset_arg + $0006
    lda     #>penpen_sprite_mask
    sta     @tileset_arg + $0007
    lda     penpen + Penpen::animation
    sta     @tileset_arg + $0008
    ldx     #<@tileset_arg
    lda     #>@tileset_arg
    jsr     _IocsDraw7x8MaskedTileset
    jmp     @drawed

    ; マスクなしの描画
:
    lda     penpen + Penpen::animation
    sta     @tileset_arg + $0006
    ldx     #<@tileset_arg
    lda     #>@tileset_arg
    jsr     _IocsDraw7x8Tileset
;   jmp     @drawed

    ; 終了
@drawed:
    rts

; タイルセット
@tileset_arg:
    .byte   $00, $00
    .byte   $03, $02
    .word   penpen_sprite_even
    .word   penpen_sprite_mask
    .byte   $00

.endproc

; ペンペンを操作できるようにする
;
.global _PenpenActivate
.proc   _PenpenActivate

    ; 操作可能
    lda     #$01
    sta     penpen + Penpen::active

    ; 終了
    rts

.endproc

; ペンペンの操作をできなくする
;
.global _PenpenInactivate
.proc   _PenpenInactivate

    ; 操作不可
    lda     #$00
    sta     penpen + Penpen::active

    ; 終了
    rts

.endproc

; ペンペンをマスクありで描画する
;
.global _PenpenMasked
.proc   _PenpenMasked

    ; マスクあり
    lda     #$01
    sta     penpen + Penpen::mask

    ; 終了
    rts

.endproc

; ペンペンをマスクなしで描画する
;
.global _PenpenUnmasked
.proc   _PenpenUnmasked

    ; マスクあり
    lda     #$00
    sta     penpen + Penpen::mask

    ; 終了
    rts

.endproc

; ピクセルパターン
;
penpen_sprite_even:
.incbin     "resources/sprites/penpen-e.ts"
penpen_sprite_odd:
.incbin     "resources/sprites/penpen-o.ts"
penpen_sprite_mask:
.incbin     "resources/sprites/penpen-m.ts"


; データの定義
;
.segment    "BSS"

; ペンペンの情報
;
penpen:
    .tag    Penpen
