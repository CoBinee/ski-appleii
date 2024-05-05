; road.s - 道
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
.include    "road.inc"


; コードの定義
;
.segment    "APP"

; 道を初期化する
;
.global _RoadInitialize
.proc   _RoadInitialize

    ; 0 クリア
    ldx     #.sizeof(Road) - $01
    lda     #$00
:
    sta     road, x
    dex
    bpl     :-

    ; 次の位置の設定
    lda     #ROAD_START_X
    sta     road + Road::next_x
    lda     #ROAD_START_Y
    sta     road + Road::next_y

    ; 終了
    rts

.endproc

; 道を更新する
;
.global _RoadUpdate
.proc   _RoadUpdate

    ; スクロールの判定
    lda     road + Road::next_y
    cmp     #ROAD_SIZE_Y
    bne     @scrolled

    ; 距離の更新
    ldx     #ROAD_DISTANCE_SIZE - $01
:
    inc     road + Road::distances, x
    lda     road + Road::distances, x
    sec
    sbc     #$0a
    bne     @distanced
    sta     road + Road::distances, x
    dex
    bpl     :-
    lda     #$09
    sta     road + Road::distances + ROAD_DISTANCE_1000
    sta     road + Road::distances + ROAD_DISTANCE_0100
    sta     road + Road::distances + ROAD_DISTANCE_0010
    sta     road + Road::distances + ROAD_DISTANCE_0001
@distanced:

    ; スクロール
    ldx     #$00
    ldy     #$01
:
    lda     road + Road::xs, y
    sta     road + Road::xs, x
    lda     road + Road::routes, y
    sta     road + Road::routes, x
    inx
    iny
    tya
    cmp     #ROAD_SIZE_Y
    bne     :-
    dec     road + Road::next_y
@scrolled:

    ; 新しい道の作成
    ldy     road + Road::next_y
    lda     road + Road::next_x
    sta     road + Road::xs, y

    ; 次の作成
    jsr     _IocsGetRandomNumber
    and     #$0f
    tax
    lda     @next_dx, x
    ldy     road + Road::next_y
    clc
    adc     road + Road::xs, y
    cmp     #ROAD_LEFT
    bcs     :+
    lda     #ROAD_LEFT
    jmp     :++
:
    cmp     #ROAD_RIGHT
    bcc     :+
    lda     #ROAD_RIGHT
:
    sta     road + Road::next_x
    inc     road + Road::next_y

    ; 終了
    rts

; 道のずれ
@next_dx:
    .byte   $00, $01, $ff
    .byte   $00, $01, $ff
    .byte   $01, $01, $ff
    .byte   $00, $01, $ff
    .byte   $00, $01, $ff
    .byte   $ff

.endproc

; 道の上部を描画する
;
.global _RoadDrawUpper
.proc   _RoadDrawUpper

    ; 道の描画
    ldy     #$00
    lda     #ROAD_START_Y
    jsr     RoadDraw

    ; 終了
    rts

.endproc

; 道の下部を描画する
;
.global _RoadDrawLower
.proc   _RoadDrawLower

    ; 道の描画
    ldy     #ROAD_START_Y + $01
    lda     #ROAD_SIZE_Y - $01
    jsr     RoadDraw

    ; 終了
    rts

.endproc

; 道を描画する
;
.proc   RoadDraw

    ; IN
    ;   y = 開始 Y 位置
    ;   a = 終了 Y 位置

    ; 終了 Y 位置の取得
    sta     @y_end

    ; 道の描画
@draw_start:
    tya
    pha
    lda     road + Road::xs, y
    beq     @draw_next
    sta     @tileset_arg + $0000
    sty     @tileset_arg + $0001
    ror     a
    bcs     :+
    ldx     #<road_tileset_even
    lda     #>road_tileset_even
    jmp     :++
:
    ldx     #<road_tileset_odd
    lda     #>road_tileset_odd
:
    stx     @tileset_arg + $0004
    sta     @tileset_arg + $0005
    lda     road + Road::routes, y
    asl     a
    sta     APP_0_WORK_0
    asl     a
    asl     a
    clc
    adc     APP_0_WORK_0
    sta     @tileset_arg + $0006
    ldx     #<@tileset_arg
    lda     #>@tileset_arg
    jsr     _IocsDraw7x8Tileset
@draw_next:
    pla
    cmp     @y_end
    bcs     @draw_end
    tay
    iny
    jmp     @draw_start
@draw_end:

    ; 終了
    rts

; 終了 Y 位置
@y_end:
    .byte   $00

; タイルセット
@tileset_arg:
    .byte   $00, $00
    .byte   $0a, $01
    .word   road_tileset_even
    .byte   $00

.endproc

; 新しい道の Y 位置を取得する
;
.global _RoadGetNextY
.proc   _RoadGetNextY

    ; OUT
    ;   a = 新しい道の Y 位置

    ; 位置の取得
    lda     road + Road::next_y

    ; 終了
    rts

.endproc

; 経路を設定する
;
.global _RoadSetRoute
.proc   _RoadSetRoute

    ; IN
    ;   x = X 位置
    ;   y = Y 位置

    ; 経路の設定
    txa
    sec
    sbc     road + Road::xs, y
    bpl     :+
    lda     #$00
    jmp     :++
:
    cmp     #ROAD_SIZE_X
    bcc     :+
    lda     #ROAD_SIZE_X - $01
:
    sta     road + Road::routes, y

    ; 終了
    rts

.endproc

; 経路を取得する
;
.global _RoadGetRoute
.proc   _RoadGetRoute

    ; IN
    ;   y = Y 位置
    ; OUT
    ;   a = X 位置

    ; 経路の取得
    lda     road + Road::routes, y

    ; 終了
    rts

.endproc

; 経路が道から外れているかどうかを判定する
;
.global _RoadIsRouteOut
.proc   _RoadIsRouteOut

    ; IN
    ;   y = Y 位置
    ; OUT
    ;   a = 0..道の上, 1..道から外れている

    ; 経路の取得
    lda     road + Road::routes, y
    cmp     #ROAD_ROUTE_LEFT
    bcc     :+
    cmp     #ROAD_ROUTE_RIGHT + $01
    bcs     :+
    lda     #$00
    jmp     :++
:
    lda     #$01
:

    ; 終了
    rts

.endproc

; 結果の文字列を描画する
;
.global _RoadDrawResultString
.proc   _RoadDrawResultString

    ; 距離の文字列化
    ldy     #ROAD_DISTANCE_SIZE - $01
:
    lda     road + Road::distances, y
    clc
    adc     #'0'
    sta     @distance_string, y
    dey
    bpl     :-

    ; 距離の表示
    ldx     #ROAD_DISTANCE_SIZE - $01
    ldy     #$00
:
    lda     road + Road::distances, y
    bne     :+
    iny
    dex
    bne     :-
:
    tya
    clc
    adc     #<@distance_string
    sta     @distance_string_arg + $0002
    lda     #$00
    adc     #>@distance_string
    sta     @distance_string_arg + $0003
    ldx     #<@distance_string_arg
    lda     #>@distance_string_arg
    jsr     _IocsDrawString

    ; 評価の描画
    lda     road + Road::distances + ROAD_DISTANCE_1000
    beq     :+
    ldx     #<@eval_string_0
    lda     #>@eval_string_0
    jmp     @draw_eval
:
    lda     road + Road::distances + ROAD_DISTANCE_0100
    cmp     #$05
    bcc     :+
    ldx     #<@eval_string_1
    lda     #>@eval_string_1
    jmp     @draw_eval
:
    cmp     #$01
    bcc     :+
    ldx     #<@eval_string_2
    lda     #>@eval_string_2
    jmp     @draw_eval
:
    ldx     #<@eval_string_3
    lda     #>@eval_string_3
;   jmp     @draw_eval
@draw_eval:
    stx     @eval_string_arg + $0002
    sta     @eval_string_arg + $0003
    ldx     #<@eval_string_arg
    lda     #>@eval_string_arg
    jsr     _IocsDrawString

    ; 終了
    rts

; 距離
@distance_string_arg:
    .byte   13, 12
    .word   @distance_string
@distance_string:
    .byte   '0', '0', '0', '0'
    .byte   _ME, _HF, _TO, _RU, _DA, _YO, '!', $00

; 評価
@eval_string_arg:
    .byte   13, 13
    .word   @eval_string_0
@eval_string_0:
    .byte   'C', 'O', 'N', 'G', 'R', 'A', 'T', 'U', 'L', 'A', 'T', 'I', 'O', 'N', '!', $00
@eval_string_1:
    .byte   _SA, __I, _KO, _HF, '!', $00
@eval_string_2:
    .byte   'G', 'O', 'O', 'D', '!', $00
@eval_string_3:
    .byte   _SA, __I, _TE, _HF, '!', $00

.endproc

; 高記録時に BEEP を再生する
;
.global _RoadBeepResult
.proc   _RoadBeepResult

    ; BEEP の再生
    lda     road + Road::distances + ROAD_DISTANCE_1000
    beq     :+
    ldx     #<@beep
    lda     #>@beep
    jsr     _IocsBeepScore
:

    ; 終了
    rts

; BEEP
@beep:
    .byte   _R,   _L4
    .byte   _O5A, _L16
    .byte   _O5D, _L16
    .byte   _O5A, _L16
    .byte   _O5D, _L16
    .byte   _O5A, _L8
    .byte   IOCS_BEEP_END

.endproc


; ピクセルパターン
;
road_tileset_even:
.incbin     "resources/tiles/road-e.ts"
road_tileset_odd:
.incbin     "resources/tiles/road-o.ts"


; データの定義
;
.segment    "BSS"

; 道の情報
;
road:
    .tag    Road
