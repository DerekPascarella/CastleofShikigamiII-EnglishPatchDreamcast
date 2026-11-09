        .little

        .section .s_06efe2,"ax"
hit_check_8C06EFE2:
        jsr     @r1
        nop

        .section .s_06f078,"ax"
hit_check_target_8C06F078:
        .long   hit_test_8C117B82

        .section .s_117984,"ax"
draw_val_8C117984:
        .long   val_8C0B9008

        .section .s_117af4,"ax"
help_val_8C117AF4:
        .long   val_8C0B9008

        .section .s_117b54,"ax"
build_stub_8C117B54:
        mov.l   L_build,r0
        jmp     @r0
        nop
init_hook_8C117B5A:
        mov.l   L_inv_flag,r1
        mov.l   @r1,r0
        mov.l   r0,@(4,r1)
        mov.l   r0,@(60,r1)
        add     #124,r1
        mov.l   L_options_init,r2
        jmp     @r2
        mov.l   r0,@r1
commit_hook_8C117B6A:
        mov.l   L_inv_flag,r1
        mov.l   @(60,r1),r0
        mov.l   r0,@r1
        add     #124,r1
        mov.l   L_redraw,r2
        jmp     @r2
        mov.l   r0,@r1
revert_hook_8C117B78:
        mov.l   L_inv_flag,r1
        mov.l   @(4,r1),r0
        mov.l   L_revert,r2
        jmp     @r2
        mov.l   r0,@r1
hit_test_8C117B82:
        mov.l   L_debug_flags,r1
        mov.l   @r1,r0
        and     #64,r0
        mov.l   L_inv_flag,r1
        mov.l   @r1,r1
        or      r1,r0
        rts
        tst     r0,r0
        .align  2
L_build:
        .long   build_8C0B90AC
L_inv_flag:
        .long   inv_flag_8C0B9000
L_options_init:
        .long   0x8C116F08
L_redraw:
        .long   0x8C1179A8
L_revert:
        .long   0x8C1180DE
L_debug_flags:
        .long   0x8C150B00
        .rept   2
        nop
        .endr

        .section .s_117c78,"ax"
reinit_val_8C117C78:
        .long   val_8C0B9008

        .section .s_11804c,"ax"
enter_val_8C11804C:
        .long   val_8C0B9008

        .section .s_118078,"ax"
enter_bak_8C118078:
        .long   bak_8C0B9048

        .section .s_11809c,"ax"
enter_init_8C11809C:
        .long   init_hook_8C117B5A

        .section .s_1182e8,"ax"
revert_bak_8C1182E8:
        .long   bak_8C0B9048

        .section .s_119610,"ax"
loop_val_8C119610:
        .long   val_8C0B9008

        .section .s_11994c,"ax"
extra_index_8C11994C:
        cmp/eq  #14,r0

        .section .s_119996,"ax"
exit_index_8C119996:
        cmp/eq  #15,r0

        .section .s_1199a8,"ax"
exit_index_8C1199A8:
        cmp/eq  #14,r0

        .section .s_1199f4,"ax"
redraw_8C1199F4:
        .long   commit_hook_8C117B6A

        .section .s_119cd0,"ax"
cancel_8C119CD0:
        .long   revert_hook_8C117B78

        .section .s_119ce0,"ax"
exit_bak_8C119CE0:
        .long   bak_8C0B9048

        .section .s_0b9000,"ax"
inv_flag_8C0B9000:
        .long   0
inv_entry_8C0B9004:
        .long   0
val_8C0B9008:
        .fill   16,4,0
bak_8C0B9048:
        .fill   16,4,0
extra_save_8C0B9088:
        .fill   3,4,0
inv_values_8C0B9094:
        .long   0, help_off_8C0B914C, 3
        .long   0, help_on_8C0B9158, 3
build_8C0B90AC:
        mov.l   L_table,r5
        mov     #104,r6
        shll    r6
        add     r5,r6
        mov.l   L_extra_save,r4
        mov.l   @r4,r0
        tst     r0,r0
        bf      1f
        mov.l   @(32,r6),r0
        mov.l   r0,@r4
        mov.l   @(36,r6),r0
        mov.l   r0,@(4,r4)
        mov.l   @(40,r6),r0
        mov.l   r0,@(8,r4)
1:      mov.l   L_inv_values,r1
        mov.l   @(56,r5),r2
        mov.l   @(12,r2),r0
        mov.l   r0,@r1
        mov.l   @r2,r0
        mov.l   r0,@(12,r1)
        mov.l   L_label,r0
        mov.l   @r0,r0
        mov.l   r0,@r6
        mov.l   @(52,r5),r0
        mov.l   r0,@(4,r6)
        mov.l   r1,@(8,r6)
        mov.l   L_row_13,r0
        mov.l   r0,@(12,r6)
        mov.l   L_unlock,r0
        mov.l   @r0,r0
        mov.l   L_count,r7
        mov.l   L_row_14,r1
        tst     r0,r0
        bt/s    2f
        add     #16,r6
        mov     #16,r0
        mov.l   r0,@r7
        mov.l   r1,@(12,r6)
        mov.l   @r4,r0
        mov.l   r0,@r6
        mov.l   @(4,r4),r0
        mov.l   r0,@(4,r6)
        mov.l   @(8,r4),r0
        mov.l   r0,@(8,r6)
        mov.l   L_row_15,r1
        bra     3f
        add     #16,r6
2:      mov     #15,r0
        mov.l   r0,@r7
3:      mov.l   r1,@(12,r6)
        mov     #1,r2
        shll8   r2
        add     r5,r2
        mov.l   @r2,r0
        mov.l   r0,@r6
        mov.l   @(4,r2),r0
        mov.l   r0,@(4,r6)
        mov.l   @(8,r2),r0
        rts
        mov.l   r0,@(8,r6)
        .align  2
L_table:
        .long   0x8C1A5FFC
L_extra_save:
        .long   extra_save_8C0B9088
L_inv_values:
        .long   inv_values_8C0B9094
L_label:
        .long   label_slot_8C0B9148
L_row_13:
        .long   0x00250002
L_unlock:
        .long   0x8C1F0420
L_count:
        .long   0x8C2F83E8
L_row_14:
        .long   0x00280001
L_row_15:
        .long   0x002A0001
