        .little

        .section .s_09862a,"ax"
join_open_8C09862A:
        mov     #8,r12

        .section .s_098946,"ax"
join_right_8C098946:
        cmp/eq  #-1,r0

        .section .s_098974,"ax"
join_left_8C098974:
        cmp/eq  #-1,r0

        .section .s_0989c2,"ax"
join_up_from_chibi_8C0989C2:
        cmp/eq  #-1,r0

        .section .s_0989cc,"ax"
join_up_wrap_8C0989CC:
        mov     #7,r9

        .section .s_0989ec,"ax"
join_up_to_chibi_8C0989EC:
        cmp/eq  #-1,r0

        .section .s_098a0c,"ax"
join_down_from_chibi_8C098A0C:
        cmp/eq  #-1,r0

        .section .s_098a16,"ax"
join_down_wrap_8C098A16:
        mov     #8,r9

        .section .s_098a36,"ax"
join_down_to_chibi_8C098A36:
        cmp/eq  #-1,r0

        .section .s_0b97e8,"ax"
row_table_8C0B97E8:
        .long   0, 1, 2, 3, 4, 5, 6, 7
        .long   0, 1, 2, 3, 4, 5, 6, 7
init_hook_8C0B9828:
        sts.l   pr,@-r15
        mov.l   L_screen_init,r0
        jsr     @r0
        nop
        mov.l   L_object_new,r0
        jsr     @r0
        nop
        mov.l   L_slot_21,r1
        mov.l   r0,@r1
        mov     r0,r4
        mov.w   L_icon_y,r1
        mov.l   r1,@-r15
        mov.w   L_icon_x,r1
        mov.l   r1,@-r15
        mov.l   L_icon_texture,r5
        mov     #15,r6
        mov     #81,r7
        mov.l   L_sprite_setup,r0
        jsr     @r0
        nop
        add     #8,r15
        lds.l   @r15+,pr
        rts
        nop
row_move_8C0B9858:
        mov.l   @(12,r6),r0
row_step_8C0B985A:
        add     r5,r0
        cmp/pz  r0
        bt      row_wrap_8C0B9862
        mov     #7,r0
row_wrap_8C0B9862:
        mov     #8,r1
        cmp/ge  r1,r0
        bf      row_set_8C0B986A
        mov     #0,r0
row_set_8C0B986A:
        mov.l   r0,@(12,r6)
        mov.l   @(4,r4),r1
        tst     r1,r1
        bt      row_done_8C0B988A
        mov.l   @(12,r4),r2
        mov     #7,r3
        cmp/eq  r3,r2
        bf      row_other_8C0B987C
        mov     #3,r2
row_other_8C0B987C:
        mov     r0,r1
        cmp/eq  r3,r1
        bf      row_compare_8C0B9884
        mov     #3,r1
row_compare_8C0B9884:
        cmp/eq  r2,r1
        bt      row_step_8C0B985A
        nop
row_done_8C0B988A:
        rts
        nop
        .align  2
L_screen_init:
        .long   0x8c06ff46
L_object_new:
        .long   0x8c0c6f36
L_slot_21:
        .long   0x8c2eb4b8
L_icon_texture:
        .long   0x800d000b
L_sprite_setup:
        .long   0x8c107d04
L_icon_y:
        .word   419
L_icon_x:
        .word   207

        .section .s_10a110,"ax"
init_stride_8C10A110:
        mov     #32,r3

        .section .s_10a12e,"ax"
init_stride_8C10A12E:
        mov     #32,r3

        .section .s_10a1ac,"ax"
init_table_8C10A1AC:
        .long   row_table_8C0B97E8

        .section .s_10a3e2,"ax"
input_stride_8C10A3E2:
        mov     #32,r10

        .section .s_10a3fc,"ax"
input_up_8C10A3FC:
        mov.l   L_row_move_up,r0
        mov     #-1,r5
        jsr     @r0
        mov     r14,r6
        bra     .+0x78
        nop
L_row_move_up:
        .long   row_move_8C0B9858
        .rept   14
        nop
        .endr

        .section .s_10a450,"ax"
input_down_8C10A450:
        mov.l   L_row_move_down,r0
        mov     #1,r5
        jsr     @r0
        mov     r14,r6
        bra     .+0x24
        nop
L_row_move_down:
        .long   row_move_8C0B9858
        .rept   14
        nop
        .endr

        .section .s_10a4f6,"ax"
input_no_toggle_8C10A4F6:
        sett

        .section .s_10a530,"ax"
input_table_8C10A530:
        .long   row_table_8C0B97E8

        .section .s_10a760,"ax"
input_table_8C10A760:
        .long   row_table_8C0B97E8

        .section .s_10a940,"ax"
screen_init_8C10A940:
        .long   init_hook_8C0B9828

        .section .s_10a9f0,"ax"
result_stride_8C10A9F0:
        add     #32,r7

        .section .s_10aa74,"ax"
result_table_8C10AA74:
        .long   row_table_8C0B97E8

        .section .s_10ab6c,"ax"
draw_table_8C10AB6C:
        .long   row_table_8C0B97E8

        .section .s_10ac98,"ax"
draw_portrait_2p_8C10AC98:
        mov.l   @(32,r5),r5

        .section .s_10ae00,"ax"
cursor_y_8C10AE00:
        mov     #58,r2
        mul.l   r2,r4
        mov     #1,r3
        and     r4,r3
        neg     r3,r3
        mov     #-18,r2
        and     r2,r3
        mov.l   r3,@(4,r15)
        mov.w   @(160,pc),r1
        add     r1,r3
        sts     macl,r4
        add     #-34,r4

        .section .s_10b0bc,"ax"
icon_slide_8C10B0BC:
        .word   0xDE00 + (0x8C10B1D0 - 0x8C10B0C0) / 4
        mov     r13,r8
        add     #48,r8
        mov     #13,r9
        mov     #0,r10
icon_loop_8C10B0C6:
        mov     r10,r0
        tst     #1,r0
        bf.s    icon_odd_8C10B0D6
        mov     #-49,r4
        mov     #-31,r4
        extu.b  r4,r4
        bra     icon_place_8C10B0DA
        add     r12,r4
icon_odd_8C10B0D6:
        extu.b  r4,r4
        sub     r12,r4
icon_place_8C10B0DA:
        mov.l   @r8+,r6
        mov     r9,r5
        jsr     @r14
        add     #58,r9
        add     #1,r10
        mov     r10,r0
        cmp/eq  #7,r0
        bf      icon_next_8C10B0EE
        mov     r13,r8
        add     #84,r8
icon_next_8C10B0EE:
        cmp/eq  #8,r0
        bf      icon_loop_8C10B0C6
        .rept   10
        nop
        .endr

        .section .s_10c05a,"ax"
demo_stride_8C10C05A:
        mov     #32,r3

        .section .s_10c084,"ax"
demo_table_8C10C084:
        .long   row_table_8C0B97E8

        .section .s_10c0ce,"ax"
ship_stride_8C10C0CE:
        mov     #32,r0

        .section .s_10c1b8,"ax"
ship_table_8C10C1B8:
        .long   row_table_8C0B97E8

        .section .s_10c21a,"ax"
scene_reset_8C10C21A:
        mov.l   r3,@(44,r4)

        .section .s_10c2f0,"ax"
scene_table_8C10C2F0:
        .long   row_table_8C0B97E8
