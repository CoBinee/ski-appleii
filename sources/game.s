; game.s - ゲーム
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
.include    "penpen.inc"


; コードの定義
;
.segment    "APP"

; ゲームのエントリポイント
;
.global _GameEntry
.proc   _GameEntry

    ; アプリケーションの初期化

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; ゲームの初期化

    ; 道の初期化
    jsr     _RoadInitialize

    ; ペンペンの初期化
    jsr     _PenpenInitialize

    ; 処理の設定
    lda     #<GameIdle
    sta     APP_0_PROC_L
    lda     #>GameIdle
    sta     APP_0_PROC_H
    lda     #$00
    sta     APP_0_STATE

    ; 終了
    rts

.endproc

; ゲームを待機する
;
.proc   GameIdle

    ; 初期化
    lda     APP_0_STATE
    bne     @initialized

    ; ペンペンの設定
    jsr     _PenpenInactivate
    jsr     _PenpenUnmasked

    ; 名前の描画
    ldx     #<@name_string_arg
    lda     #>@name_string_arg
    jsr     _IocsDrawString

    ; 初期化の完了
    inc     APP_0_STATE
@initialized:

    ; ペンペンの更新
    jsr     _PenpenUpdate

    ; ペンペンの描画
    jsr     _PenpenDraw

    ; キー入力
    lda     IOCS_0_KEYCODE
    cmp     #' '
    bne     :+

    ; BEEP
    jsr     BELL

    ; 処理の設定
    lda     #<GameStart
    sta     APP_0_PROC_L
    lda     #>GameStart
    sta     APP_0_PROC_H
    lda     #$00
    sta     APP_0_STATE
:

    ; ウェイト
    ldy     #$40
    ldx     #$00
:
    dex
    bne     :-
    dey
    bne     :-

    ; 終了
    rts

; 名前
@name_string_arg:
    .byte   15, 12
    .word   @name_string
@name_string:
    .byte   _PE, __N, _PE, __N, _SP, _NO, _SP, _SU, _KI, _HF, $00

.endproc

; ゲームを開始する
;
.proc   GameStart

    ; 初期化
    lda     APP_0_STATE
    bne     @initialized

    ; ペンペンの設定
    jsr     _PenpenMasked

    ; 空白の描画
    ldx     #<@blank_string_arg
    lda     #>@blank_string_arg
    jsr     _IocsDrawString

    ; 初期化の完了
    inc     APP_0_STATE
@initialized:

    ; 道の更新
    jsr     _RoadUpdate

    ; ペンペンの更新
    jsr     _PenpenUpdate

    ; ペンペンの後ろの描画
    ldy     #PENPEN_Y - $01
    jsr     GameDrawPenpenBack

    ; 道の上部の描画
    jsr     _RoadDrawUpper

    ; ペンペンの描画
    jsr     _PenpenDraw

    ; 道の下部の描画
    jsr     _RoadDrawLower

    ; 新しい道の Y 位置の取得
    jsr     _RoadGetNextY
    cmp     #ROAD_SIZE_Y - $01
    bcc     :+

    ; 処理の設定
    lda     #<GamePlay
    sta     APP_0_PROC_L
    lda     #>GamePlay
    sta     APP_0_PROC_H
    lda     #$00
    sta     APP_0_STATE
:

    ; ウェイト
    jsr     GameWait

    ; 終了
    rts

; 空白
@blank_string_arg:
    .byte   15, 12
    .word   @blank_string
@blank_string:
    .asciiz "          "

.endproc

; ゲームをプレイする
;
.proc   GamePlay

    ; 初期化
    lda     APP_0_STATE
    bne     @initialized

    ; ペンペンの設定
    jsr     _PenpenActivate

    ; 初期化の完了
    inc     APP_0_STATE
@initialized:

    ; 道の更新
    jsr     _RoadUpdate

    ; ペンペンの更新
    jsr     _PenpenUpdate

    ; 道の上部の描画
    jsr     _RoadDrawUpper

    ; ペンペンの描画
    jsr     _PenpenDraw

    ; 道の下部の描画
    jsr     _RoadDrawLower

    ; 経路が道から外れているか
    ldy     #PENPEN_Y
    jsr     _RoadIsRouteOut
    cmp     #$00
    beq     :+

    ; BEEP
    jsr     BELL

    ; 処理の設定
    lda     #<GameOver
    sta     APP_0_PROC_L
    lda     #>GameOver
    sta     APP_0_PROC_H
    lda     #$00
    sta     APP_0_STATE
:

    ; ウェイト
    jsr     GameWait

    ; 終了
    rts

.endproc

; ゲームオーバーになる
;
.proc   GameOver

    ; 初期化
    lda     APP_0_STATE
    bne     @initialized

    ; 結果の描画
    jsr     _RoadDrawResultString

    ; 初期化の完了
    inc     APP_0_STATE
@initialized:

    ; キー入力待ち
    lda     IOCS_0_KEYCODE
    cmp     #' '
    bne     :+

    ; 処理の設定
    lda     #<_GameEntry
    sta     APP_0_PROC_L
    lda     #>_GameEntry
    sta     APP_0_PROC_H
    lda     #$00
    sta     APP_0_STATE
:
    ; 終了
    rts

.endproc

; ウェイトを入れる
;
.proc   GameWait

    ; 空ループ
    ldy     #$20
    ldx     #$00
:
    dex
    bne     :-
    dey
    bne     :-

    ; 終了
    rts

.endproc

; ペンペンの後ろを描画する
;
.proc   GameDrawPenpenBack

    ; IN
    ;   y = Y 位置

    sty     @tileset_arg + $0001
    ldx     #<@tileset_arg
    lda     #>@tileset_arg
    jsr     _IocsDraw7x8Tileset

    ; 終了
    rts

@tileset_arg:
    .byte   PENPEN_X - $01, $00
    .byte   $03, $01
    .word   @tileset
    .byte   $00
@tileset:
    .byte   $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00
    .byte   $00, $00, $00, $00, $00, $00, $00, $00

.endproc


; データの定義
;
.segment    "BSS"

; ゲームの情報
;
game:
    .tag    Game

