        .little

        .section .s_11d910,"ax"
boot_comment_copy_8C11D910:
        mov     r15,r4
        .word   0xD500 + (0x8C11D9F0 - 0x8C11D914) / 4
        add     #50,r4
        .word   0xD100 + (0x8C11D9F8 - 0x8C11D918) / 4
        jsr     @r1
        mov     #32,r6
        mov     #16,r6
        .word   0xD500 + (0x8C11D9F4 - 0x8C11D920) / 4
        bra     game_name_copy_8C11D95C
        mov     r15,r4
        .rept   28
        nop
        .endr
game_name_copy_8C11D95C:
