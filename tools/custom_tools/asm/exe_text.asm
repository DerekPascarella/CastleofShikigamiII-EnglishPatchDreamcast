.little
        .global mb_code_8C114290, mb_adv_8C1142AE, text_add_row_8C0B9C58, text_fetch_8C0B9CA8, help_x_8C0B9CDC

        .section .mb,"ax"
mb_code_8C114290:
        mov.b   @r12,r0
        cmp/pz  r0
        bf/s    1f
        extu.b  r0,r3
        add     #0x20,r0
        shll8   r0
        or      #0x86,r0
        mov     r0,r3
        rts
        add     #-1,r12
1:      mov.b   @(1,r12),r0
        extu.b  r0,r0
        shll8   r0
        rts
        or      r0,r3

mb_adv_8C1142AE:
        mov.l   @(4,r13),r7
        mov     #20,r0
        extu.b  r7,r2
        mov     #-122,r4
        extu.b  r4,r4
        cmp/eq  r4,r2
        bf      1f
        shlr8   r7
        extu.b  r7,r7
        mov.l   L_wtab_mb,r2
        add     r7,r2
        mov.b   @r2,r0
        extu.b  r0,r0
1:      add     r0,r3
        rts
        mov.l   r3,@(8,r1)
        .align 2
L_wtab_mb:
        .long   0x8c0b9bf8 - 0x40

        .section .tw,"ax"
text_add_row_8C0B9C58:
        mov.l   r14,@-r15
        mov.l   r13,@-r15
        sts.l   pr,@-r15
        tst     r4,r4
        bt      9f
        mov     r4,r13
1:      mov     r5,r14
        mov     #0,r6
2:      mov.b   @r14+,r0
        tst     r0,r0
        bt      3f
        cmp/eq  #10,r0
        bt      3f
        cmp/pz  r0
        bt/s    2b
        add     #2,r6
        bra     2b
        add     #1,r14
3:      bsr     help_x_8C0B9CDC
        mov.l   @(0x10,r13),r4
        nop
        mov     r14,r5
        mov     #-1,r0
        mov.b   @(r0,r14),r0
        cmp/eq  #10,r0
        bt      1b
        mov.l   L_flag,r4
        mov.l   @r4,r2
        tst     r2,r2
        bf      9f
        mov.l   L_src,r2
        mov     #1,r0
        mov.l   L_dst,r1
        mov.l   @r2,r3
        mov.l   r3,@r1
        mov.l   r0,@r4
9:      lds.l   @r15+,pr
        mov.l   @r15+,r13
        rts
        mov.l   @r15+,r14

text_fetch_8C0B9CA8:
        mov.b   @r9+,r0
        cmp/pz  r0
        bf/s    1f
        extu.b  r0,r0
        add     #0x20,r0
        shll8   r0
        bra     2f
        or      #0x86,r0
1:      mov.b   @r9+,r1
        extu.b  r1,r1
        shll8   r1
        or      r1,r0
2:      mov.l   r9,@(8,r15)
        mov     r0,r9
        mov.l   L_lookup,r1
        jmp     @r1
        mov     r0,r4

        .align 2
L_flag:   .long 0x8c3084ec
L_src:    .long 0x8c3084f4
L_dst:    .long 0x8c3084f0
L_lookup: .long 0x8c120506

help_x_8C0B9CDC:
        mov.l   @(4,r13),r0
        mov.w   L_help_y,r1
        cmp/eq  r1,r0
        bf      8f
        mov.l   @r13,r0
        mov.w   L_options_x,r1
        cmp/eq  r1,r0
        mov.w   L_options_new_x,r0
        bt      7f
        mov.w   L_extra_new_x,r0
7:      mov.l   r0,@r4
8:      mov.l   L_draw_hx,r3
        jmp     @r3
        nop
        .align 2
L_draw_hx:       .long 0x8c12085c
L_help_y:        .word 350
L_options_x:     .word 184
L_options_new_x: .word 172
L_extra_new_x:   .word 136

.section .s_120744,"ax"
cols_8C120744:
        mov     #64,r11

        .section .s_1208d2,"ax"
fetch_site_8C1208D2:
        nop
        nop
        nop
        nop
        .section .s_1208dc,"ax"
fetch_slot_8C1208DC:
        nop
        .section .s_120984,"ax"
fetch_literal_8C120984:
        .long   0x8c0b9ca8

        .section .s_122a8e,"ax"
add_row_8C122A8E:
        .word   0xd001
        jmp     @r0
        nop
        .word   0x9c58, 0x8c0b

        .section .s_11416a,"ax"
mb_code_site_8C11416A:
        .word   0xb091
        nop
        nop
        mov     #3,r0
        mov.l   r0,@(12,r13)
        nop
        .section .s_114268,"ax"
mb_adv_site_8C114268:
        .word   0xb021
        nop
