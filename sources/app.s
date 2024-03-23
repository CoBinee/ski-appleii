; app.s - アプリケーション
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


; コードの定義
;
.segment    "APP"

; アプリケーションのエントリポイント
;
.proc   AppEntry

    ; アプリケーションの初期化

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; 画面モードの設定
    sta     HIRES
    sta     LOWSCR
    sta     MIXCLR
    sta     TXTCLR

    ; ゼロページのクリア
    ldy     #APP_0
    lda     #$00
:
    sta     $00, y
    iny
    bne     :-

    ; 処理の設定
    lda     #<_GameEntry
    sta     APP_0_PROC_L
    lda     #>_GameEntry
    sta     APP_0_PROC_H
    lda     #$00
    sta     APP_0_STATE

.endproc

; アプリケーションを更新する
;
.proc   AppUpdate

    ; 処理の繰り返し
@loop:

    ; IOCS の更新
    jsr     _IocsUpdate

    ; 処理の実行
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    jmp     (APP_0_PROC)
:

    ; カウントの表示と更新
.if 0
    lda     APP_0_COUNT
    clc
    adc     #'0'
    sta     @count_string
    ldx     #<@count_string_arg
    lda     #>@count_string_arg
    jsr     _IocsDrawString
    inc     APP_0_COUNT
    lda     APP_0_COUNT
    cmp     #$0a
    bcc     :+
    lda     #$00
    sta     APP_0_COUNT
:
.endif

    ; ループ
    jmp     @loop

; カウント
@count_string_arg:
    .byte   39, 0
    .word   @count_string
@count_string:
    .asciiz "0"

.endproc


; データの定義
;
.segment    "BSS"

