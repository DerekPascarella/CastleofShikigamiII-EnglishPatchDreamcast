        .little

        .section .s_0b7a58,"ax"
prev_delay_slot_8C0B7A58:
        .short  0x6ef6
analog_entry_8C0B7A5A:
        bra     analog_synth_8C0B7A98
        nop
        .short  0x2fd6,0x2fc6,0x2fb6,0x2fa6,0x2f96,0x2f86,0xfffb,0x4f22,0xa069,0x69e3

shared_pool_8C0B7A72:
        .short  0x0178
        .short  0x00ff
        .short  0x0000
        .short  0xbf30
        .short  0x8c2b
        .short  0x27fa
        .short  0x8c01
        .short  0xbc40
        .short  0x8c2b
        .short  0xbc38
        .short  0x8c2b
        .short  0x5764
        .short  0x8c12
        .short  0xbf38
        .short  0x8c2b
        .short  0xbf40
        .short  0x8c2b
        .short  0x4fc4
        .short  0x8c12
analog_synth_8C0B7A98:
        mov.l   r8,@-r15
        mov.l   r9,@-r15
        mov.l   L_records,r6
        mov.l   L_states,r8
        mov     #2,r7
analog_player_8C0B7AA2:
        mov.l   L_heartbeat,r1
        mov.b   @r1,r0
        tst     r0,r0
        mov.w   L_dz_menu,r4
        bt      analog_dz_8C0B7AB4
        mov.l   @r8,r0
        cmp/eq  #1,r0
        bt      analog_dz_8C0B7AB4
        mov.w   L_dz_game,r4
analog_dz_8C0B7AB4:
        mov     #0x5c,r0
        mov.l   @(r0,r6),r1
        mov     #0x58,r0
        mov.l   @(r0,r6),r3
        mov     r1,r5
        cmp/pz  r5
        bt      analog_ay_8C0B7AC4
        neg     r5,r5
analog_ay_8C0B7AC4:
        mov     r3,r9
        cmp/pz  r9
        bt      analog_ax_8C0B7ACC
        neg     r9,r9
analog_ax_8C0B7ACC:
        mov     #0,r2
        cmp/gt  r4,r5
        bt      analog_live_8C0B7AD6
        cmp/gt  r4,r9
        bf      analog_merge_8C0B7B08
analog_live_8C0B7AD6:
        mov.w   L_slope,r0
        mul.l   r0,r9
        sts     macl,r4
        mov     r5,r0
        shll8   r0
        cmp/gt  r4,r0
        bf      analog_horiz_8C0B7AF0
        cmp/pz  r1
        mov     #0x10,r2
        bt      analog_down_8C0B7AEE
        bra     analog_horiz_8C0B7AF0
        nop
analog_down_8C0B7AEE:
        mov     #0x20,r2
analog_horiz_8C0B7AF0:
        mov.w   L_slope,r0
        mul.l   r0,r5
        sts     macl,r4
        mov     r9,r0
        shll8   r0
        cmp/gt  r4,r0
        bf      analog_merge_8C0B7B08
        mov     #0x40,r0
        cmp/pz  r3
        bf      analog_left_8C0B7B06
        shll    r0
analog_left_8C0B7B06:
        or      r0,r2
analog_merge_8C0B7B08:
        mov     #0x54,r0
        mov.l   @(r0,r6),r1
        or      r2,r1
        mov.l   r1,@(r0,r6)
        mov     #0x40,r0
        add     r0,r8
        mov.w   L_stride,r0
        dt      r7
        bf/s    analog_player_8C0B7AA2
        add     r0,r6
        mov.l   L_heartbeat,r1
        mov     #0,r2
        mov.b   r2,@r1
        mov.l   @r15+,r9
        rts
        mov.l   @r15+,r8
heartbeat_hook_8C0B7B28:
        mov.l   L_heartbeat,r1
        mov     #1,r0
        mov.l   L_gamepad,r2
        jmp     @r2
        mov.b   r0,@r1
L_dz_game:
        .short  512
L_dz_menu:
        .short  2048
L_stride:
        .short  0x178
L_slope:
        .short  106
        .align  2
L_heartbeat:
        .long   heartbeat_8C0B7B4C
L_records:
        .long   0x8c2bbc40
L_states:
        .long   0x8c24693c
L_gamepad:
        .long   0x8c06eacc
heartbeat_8C0B7B4C:
        .long   0

        .section .s_08f308,"ax"
gamepad_call_8C08F308:
        .long   heartbeat_hook_8C0B7B28
