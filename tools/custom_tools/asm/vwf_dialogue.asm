        .little
        .text

put_adv_8C0B9BA4:
        sts.l   pr,@-r15
        mov.l   @(0x18,r14),r2
        bsr     width_8C0B9BCE
        mov     r9,r7
        add     r0,r2
        lds.l   @r15+,pr
        rts
        add     r2,r10

wrap_relayout_8C0B9BB4:
        sts.l   pr,@-r15
        mov.l   L_pos,r1
        jsr     @r1
        nop
        mov.l   r0,@-r15
        bsr     width_8C0B9BCE
        mov.w   @r12,r7
        add     #-20,r0
        add     r0,r10
        mov.l   @r15+,r0
        lds.l   @r15+,pr
        rts
        nop

width_8C0B9BCE:
        extu.b  r7,r1
        mov.w   L_lead,r0
        cmp/eq  r0,r1
        bf/s    1f
        mov     #20,r0
        shlr8   r7
        extu.b  r7,r7
        add     #-0x40,r7
        mov.l   L_wtab,r1
        add     r7,r1
        mov.b   @r1,r0
        extu.b  r0,r0
1:      rts
        nop

        .align 2
L_lead: .word   0x0086
        .align 2
L_pos:  .long   0x8c09e6b4
L_wtab: .long   0x8c0b9bf8

width_table_8C0B9BF8:
        .fill   96,1,20

tramp_8C120838:
        mov.l   1f,r0
        jmp     @r0
        nop
        nop
1:      .long   0x8c0b9ba4

advance_site_8C120912:
        bsr     tramp_8C120838
        mov.l   @(0x10,r14),r3
        nop
        nop

relayout_literal_8C120A70:
        .long   0x8c0b9bb4

column_limit_8C12174E:
        mov     #48,r6
column_limit_8C1217CE:
        mov     #48,r6
column_limit_8C1218DC:
        mov     #48,r6

caption_columns_8C120E94:
        mov     #48,r3
caption_buffer_8C120F7A:
        .word   0x0900
