
        includelib      crash    ;tasm

min_meteor      equ     9       ; Init Meteor Number
max_meteor      equ     10      ; Max Meteor Number
drive_count_ofs equ     40h
max_level       equ     max_meteor-min_meteor+1
tab     equ     9
init_ship_turn  equ     5
min_bullet      equ     5
max_bullet      equ     7
bullet_range    equ     100
normal_sound_flag1      equ 50
normal_sound_flag2      equ 5
normal_freq     equ     8000
bullet_sound_flag1      equ 2
bullet_sound_flag2      equ 1
bullet_sound_duration   equ 7
bullet_freq     equ     500
break_sound_flag1       equ 2
break_sound_flag2       equ 1
break_sound_duration    equ 30
break_freq      equ     10000
crash_sound_flag1       equ 3
crash_sound_flag2       equ 2
crash_sound_duration    equ 200
crash_freq      equ     12000
bullet_rec_len  equ     8
meteor_rec_len  equ     9
_x      equ     word    ptr 0
_y      equ     word    ptr 2
_flag   equ     byte    ptr 4
_direct equ     word    ptr 5
_counter        equ     byte ptr 7
_kind   equ     byte    ptr 7
_turn   equ     byte    ptr 8

extrn   gmode:near,     tmode:near
extrn   clearg:near,    cleart:near
extrn   x:word,         y:word
extrn   odraw:near,     cdraw:near
extrn   prints:near,    printn:near
extrn   soundon:near,   soundoff:near
extrn   yverth:word,    freq:word
extrn   crash:byte,     ship:byte

code    segment byte public
        assume  cs:code,ds:data

main    proc    far
        mov     ax,seg zstack
        cli
        mov     ss,ax
        mov     sp,offset heap
        sti

        mov     ax,data
        mov     ds,ax

        call    show_info

        mov     ah,0fh
        int     10h
        mov     mode,al
        cmp     mode,7
        je      herc1

        xor     bx,bx
        xor     bp,bp
        mov     cx,350-2        ;348
make_yverth:
        mov     ax,80
        mul     bp
        mov     ds:yverth[bx],ax
        inc     bx
        inc     bx

        inc     bp
        loop    make_yverth

        mov     ax,0fh
        int     10h

        jmp     short both1

herc1:
        call    gmode
        mov     ax,0
        call    clearg
both1:
        call    stop_motor
        call    setup_timer

start:
        cmp     mode,7
        je      herc2

        mov     ax,0a000h
        mov     es,ax

        jmp     short both2
herc2:
        mov     ax,0b000h
        mov     es,ax
both2:
        mov     x,20
        mov     y,339
        lea     bx,pro_spc
        call    prints

        mov     x,55-1
        mov     y,339
        lea     bx,snd_spc
        call    prints

        call    pause

        cmp     mode,7
        je      herc3

        mov     ax,0fh
        int     10h

        jmp     short both3     ;typo;lost!
herc3:
        mov     ax,0
        call    clearg
both3:
        cmp     level,max_level
        jne     init_start
        jmp     the_end
init_start:
        call    initialize
        call    show_protect
        call    show_level
        call    show_sound
head:
        call    management
        cmp     crash_flag,0
        je      h2
        cmp     crash_counter,0
        jne     h1
        call    init_crash
h1:
        inc     crash_counter
        cmp     crash_counter,200
        jle     h2
        call    crash_manage
        jmp     start
h2:
        cmp     meteor_num,0
        jne     h5
        add     score,500
        inc     level
        cmp     init_meteor,max_meteor
        jge     h3
        inc     init_meteor
h3:
        cmp     bullet_num,max_bullet
        jge     h4
        inc     bullet_num
h4:
        call    soundoff
        jmp     start
h5:
        cmp     snd_switch_flag,1
        jne     go_sound
        call    soundoff
        jmp     short go_delay
go_sound:
        call    sound
go_delay:
        call    delay
        mov     ah,1
        int     16h
        jz      h6
        mov     ah,0
        int     16h
        cmp     al,'/'
        je      sound_switch
        cmp     al,tab
        je      protect
        cmp     al,27
        je      game_over
        cmp     ship_flag,0
        jne     h6
        call    ship_control
h6:
        jmp     head
game_over:
        cmp     mode,7
        je      herc4

        mov     ax,3
        int     10h

        jmp     short both4     ;typo;lost!
herc4:
        call    tmode
        call    cleart
both4:
        call    soundoff
        call    recover_timer
        mov     al,0
        out     21h,al
        call    show_thanks
        mov     ax,4c00h
        int     21h
protect:
        call    sub_hidden
        jmp     head
sound_switch:
        call    sub_snd_switch
        jmp     head
the_end:
        mov     x,41-5    ;(80-8)/2=72/2=36=41-5
        mov     y,170
        lea     bx,the_end$
        call    prints

        xor     ah,ah
        int     16h
        jmp     short game_over
main    endp

sub_snd_switch  proc near
        inc     snd_switch_flag
        cmp     snd_switch_flag,2
        jne     end_sound_switch
        mov     snd_switch_flag,0
end_sound_switch:
        call    show_sound
        ret
sub_snd_switch  endp

sub_hidden      proc near
        inc     protect_flag
        cmp     protect_flag,2
        jne     end_sub_hidden
        mov     protect_flag,0
end_sub_hidden:
        call    show_protect
        ret
sub_hidden      endp

setup_timer     proc near
        push    ds
        push    es
        mov     ax,3508h
        int     21h
        mov     time_ip,bx
        mov     time_cs,es
        push    cs
        pop     ds
        mov     dx,offset timer
        mov     ax,2508h
        cli
        int     21h
        mov     al,36h
        out     43h,al
        mov     bx,11932
        mov     al,bl
        out     40h,al
        mov     al,bh
        out     40h,al
        mov     al,0fch
        out     21h,al
        sti
        pop     es
        pop     ds
        ret
setup_timer     endp

pause   proc    near
        mov     x,32-4
        mov     y,339
        lea     bx,pause_str
        call    prints
pause1:
        mov     ah,1
        int     16h
        jz      pause1
        mov     ah,0
        int     16h
        cmp     al,13
        jne     pause1
        ret
pause   endp

initialize      proc near
        mov     sound_flag1,normal_sound_flag1
        mov     sound_flag2,normal_sound_flag2
        mov     sound_counter,normal_sound_flag1
        mov     reset_soundflag,0
        mov     freq,normal_freq
        mov     ship_direct,0
        mov     ship_now_direct,0
        mov     ship_x,350
        mov     ship_y,150
        mov     ship_vx,0
        mov     ship_vy,0
        mov     ship_turn,init_ship_turn
        mov     ship_flag,0
        mov     crash_counter,0
        mov     crash_flag,0
        mov     ax,init_meteor
        mov     meteor_num,ax
        lea     si,meteor_data
        mov     cx,meteor_num
        mov     di,0
init1:
        push    cx
        mov     ax,counter
        sub     ax,100
        jge     init2
        add     ax,640-40     ;680=720-40
init2:
        mov     [si+_x],ax
        mov     ax,counter
        mov     [si+_y],ax
        mov     [si+_flag],0
        mov     [si+_kind],2
        mov     [si+_turn],1
        mov     ax,random[di]
        mov     [si+_direct],ax
        add     si,meteor_rec_len
        add     di,2
        pop     cx
        loop    init1
        lea     si,bullet_data
        mov     cx,bullet_num
init3:
        mov     [si+_flag],0
        add     si,bullet_rec_len
        loop    init3
        call    show_high_score
        call    show_score
        mov     flag,1
        call    draw_ship
        ret
initialize      endp

management      proc near
        mov     flag,0
        call    draw_bullet
        lea     si,meteor_data
        mov     cx,meteor_num
        jcxz    ma3
ma1:
        push    cx
        dec     [si+_turn]
        jnz     ma2
        mov     bl,[si+_kind]
        mov     bh,0
        mov     al,meteor_turn[bx]
        mov     [si+_turn],al
        mov     flag,0
        call    draw_meteor
        cmp     [si+_flag],0
        je      ma2
        call    break_meteor
ma2:
        add     si,meteor_rec_len
        pop     cx
        loop    ma1
ma3:
        dec     ship_turn
        jnz     ma4
        mov     ship_turn,init_ship_turn
        mov     flag,0
        call    draw_ship
        mov     al,ship_flag
        or      crash_flag,al
ma4:
        lea     si,meteor_data
        mov     cx,meteor_num
        jcxz    ma7
ma5:
        push    cx
        push    si
        mov     bl,[si+_kind]
        mov     bh,0
        mov     al,meteor_turn[bx]
        cmp     [si+_turn],al
        jne     ma6
        mov     bx,[si+_direct]
        call    get_direct
        add     [si+_x],ax
        add     [si+_y],bx
        call    adjust_meteor_pos
        mov     flag,1
        call    draw_meteor
ma6:
        pop     si
        add     si,meteor_rec_len
        pop     cx
        loop    ma5
ma7:
        cmp     ship_turn,init_ship_turn
        jne     ma8
        mov     ax,ship_vx
        add     ship_x,ax
        mov     ax,ship_vy
        add     ship_y,ax
        call    adjust_ship_pos
        mov     flag,1
        mov     ax,ship_direct
        mov     ship_now_direct,ax
        call    draw_ship
ma8:
        mov     flag,1
        call    draw_bullet
        ret
management      endp

init_crash      proc near
        mov     freq,crash_freq
        mov     sound_flag1,crash_sound_flag1
        mov     sound_flag2,crash_sound_flag2
        mov     reset_soundflag,crash_sound_duration
        mov     sound_counter,crash_sound_flag1
        ret
init_crash      endp

crash_manage    proc near
        mov     init_meteor,min_meteor
        mov     bullet_num,min_bullet
        mov     ax,score
        cmp     high_score,ax
        jae     cm2
        mov     high_score,ax
cm2:
        mov     score,0
        call    soundoff
        ret
crash_manage    endp

sound   proc    near
        cmp     reset_soundflag,0
        je      so0
        dec     reset_soundflag
        jnz     so0
        mov     sound_flag1,normal_sound_flag1
        mov     sound_flag2,normal_sound_flag2
        mov     freq,normal_freq
so0:    mov     ax,sound_flag1
        mov     bx,sound_flag2
        dec     sound_counter
        cmp     sound_counter,bx
        je      so1
        jg      soe
        cmp     sound_counter,0
        jne     soe
        mov     sound_counter,ax
        call    soundoff
        jmp     short soe
so1:
        cmp     freq,1000
        jg      so2
        add     freq,100
so2:
        cmp     freq,10000
        jl      so3
        add     freq,50
so3:
        call    soundon
soe:
        ret
sound endp

delay   proc    near
        mov     ax,delay_counter
d1:
        cmp     counter,ax
        je      d1
        mov     ax,counter
        mov     delay_counter,ax
        ret
delay   endp

ship_control    proc near
        cmp     al,' '
        jne     sc0
        call    shoot
        jmp     short sc6
sc0:    cmp     ah,75
        jne     sc2
        dec     ship_direct
        cmp     ship_direct,0
        jge     sc1
        mov     ship_direct,23
sc1:
        jmp     short sc6
sc2:
        cmp     ah,77
        jne     sc4
        inc     ship_direct
        cmp     ship_direct,23
        jle     sc3
        mov     ship_direct,0
sc3:
        jmp     short sc6
sc4:
        cmp     ah,72
        jne     sc5
        mov     bx,ship_direct
        call    get_direct
        call    change_shipv
        jmp     short sc6
sc5:
        cmp     ah,80
        jne     sc6
        mov     bx,ship_direct
        call    get_direct
        neg     ax
        neg     bx
        call    change_shipv
sc6:
        ret
ship_control    endp

recover_timer   proc near
        cli
        push    es
        mov     ax,0
        mov     es,ax
        mov     ax,time_ip
        mov     es:[20h],ax
        mov     ax,time_cs
        mov     es:[22h],ax
        pop     es
        mov     al,36h
        out     43h,al
        mov     bx,0
        mov     al,bl
        out     40h,al
        mov     al,bh
        out     40h,al
        sti
        ret
recover_timer   endp

draw_bullet     proc near
        lea     si,bullet_data
        mov     cx,bullet_num
db1:
        call    draw_bullet2
        loop    db1
        ret
draw_bullet     endp

draw_bullet2    proc near
        push    cx
        push    si
        cmp     [si+_flag],1
        jne     db8
        cmp     flag,1
        jne     db3
        dec     [si+_counter]
        jnz     db2
        mov     [si+_flag],0
        jmp     short db8
db2:
        mov     bx,[si+_direct]
        call    get_direct
        add     [si+_x],ax
        add     [si+_y],bx
        call    adjust_bullet_pos
        cmp     [si+_flag],1
        jne     db8
db3:
        push    [si+_x]
        pop     x
        push    [si+_y]
        pop     y
        push    si
        lea     si,bullet_shape
        mov     ax,x
        and     ax,111b
        shl     ax,1
        add     si,ax
        shl     ax,1
        add     si,ax
        shr     x,1
        shr     x,1
        shr     x,1
        cmp     flag,1
        jne     db5
        call    cdraw
        cmp     crash,0
        je      db7
        call    ndraw
        pop     si
        push    [si+_x]
        pop     x
        mov     [si+_flag],0
        call    set_meteor_flag
        jmp     short db8
db5:
        call    ndraw
db7:
        pop     si
db8:
        pop     si
        add     si,bullet_rec_len
        pop     cx
        ret
draw_bullet2    endp

draw_meteor proc near
        push    si
        push    [si+_x]
        pop     x
        push    [si+_y]
        pop     y
        mov     al,[si+_kind]
        mov     bx,x
        and     bx,111b
        cmp     al,0
        jne     dm1
        lea     si,meteor1
        mov     ax,2+2*9
        mul     bx
        add     si,ax
        jmp     short dm3
dm1:
        cmp     al,1
        jne     dm2
        lea     si,meteor2
        mov     ax,2+3*11
        mul     bx
        add     si,ax
        jmp     short dm3
dm2:
        lea     si,meteor3
        mov     ax,2+4*22
        mul     bx
        add     si,ax
dm3:
        shr     x,1
        shr     x,1
        shr     x,1
        cmp     flag,1
        jne     dm4
        call    odraw
        jmp     short dm5
dm4:
        call    ndraw
dm5:
        pop     si
        ret
draw_meteor     endp

draw_ship       proc near
        mov     ax,ship_now_direct
        shl     ax,1
        shl     ax,1
        shl     ax,1
        mov     bx,ax
        mov     cl,5
        shl     bx,cl
        neg     ax
        add     ax,bx
        shr     bx,1
        add     ax,bx
        mov     si,ax
        lea     ax,ship
        add     si,ax
        mov     ax,ship_x
        and     ax,111b
        mov     bx,ax
        mov     cl,5
        shl     bx,cl
        neg     ax
        add     ax,bx
        shr     bx,1
        add     ax,bx
        add     si,ax
        push    ship_x
        pop     x
        push    ship_y
        pop     y
        shr     x,1
        shr     x,1
        shr     x,1
        cmp     crash_flag,0
        je      ds0
        mov     ax,ship_x
        and     ax,7
        mov     bx,3*15+2
        mul     bx
        lea     si,crash_shape
        add     si,ax
ds0:
        cmp     flag,1
        jne     ds1
        call    cdraw
        jmp     short ds2
ds1:
        call    cndraw
ds2:
        cmp     protect_flag,1
        je      auto_fire
        mov     al,crash
        or      ship_flag,al
end_draw_ship:
        ret
auto_fire:
        call    shoot
        ret
draw_ship       endp

break_meteor    proc near
        mov     al,[si+_kind]
        mov     ah,0
        neg     ax
        add     ax,3
        shl     ax,1
        shl     ax,1
        shl     ax,1
        shl     ax,1
        add     score,ax
        mov     bx,meteor_num
        mov     ax,meteor_rec_len
        mul     bx
        lea     bx,meteor_data
        add     bx,ax
        cmp     [si+_kind],0
        jz      bm9
        dec     [si+_kind]
        inc     meteor_num
        mov     [si+_flag],0
        mov     [bx+_flag],0
        mov     ax,[si+_direct]
        mov     cx,ax
        inc     cx
        inc     cx
        mov     dx,ax
        dec     dx
        dec     dx
        dec     dx
        cmp     dx,0
        jge     bm1
        add     dx,24
bm1:
        cmp     cx,23
        jle     bm2
        sub     cx,24
bm2:
        mov     [si+_direct],cx
        mov     [bx+_direct],dx
        mov     al,[si+_kind]
        mov     [bx+_kind],al
        push    [si+_x]
        pop     [bx+_x]
        push    [si+_y]
        pop     [bx+_y]
        mov     [si+_turn],1
        mov     [bx+_turn],1
        jmp     short bm10
bm9:
        push    si
        mov     di,si
        add     si,meteor_rec_len
        push    es
        push    ds
        pop     es
        sub     bx,si
        mov     cx,bx
        cld
        rep     movsb
        pop     es
        pop     si
        sub     si,meteor_rec_len
        dec     meteor_num
bm10:
        call    show_score
        mov     freq,break_freq
        mov     sound_flag1,break_sound_flag1
        mov     sound_flag2,break_sound_flag2
        mov     reset_soundflag,break_sound_duration
        mov     sound_counter,break_sound_flag1
        ret
break_meteor endp

adjust_meteor_pos proc near ;>
        cmp     [si+_x],640-40        ;68o=720-40
        jle     ast1
        mov     [si+_x],0
ast1:
        cmp     [si+_y],300 ;>
        jle     ast2
        mov     [si+_y],0
ast2:
        cmp     [si+_x],0
        jge     ast3
        mov     [si+_x],640-40        ;68o=720-40
ast3:
        cmp     [si+_y],0
        jge     ast4
        mov     [si+_y],300 ;>
ast4:
        ret
adjust_meteor_pos endp

adjust_ship_pos proc near
        cmp     ship_x,640-40 ;68o=720-40
        jle     asp1
        mov     ship_x,0
asp1:
        cmp     ship_y,300 ;>
        jle     asp2
        mov     ship_y,0
asp2:
        cmp     ship_x,0
        jge     asp3
        mov     ship_x,640-40 ;68o=720-40
asp3:
        cmp     ship_y,0
        jge     asp4
        mov     ship_y,300 ;>
asp4:
        ret
adjust_ship_pos endp

shoot   proc    near
        mov     cx,bullet_num
        lea     si,bullet_data
sh1:
        cmp     [si+_flag],0
        je      sh2
        add     si,bullet_rec_len
        loop    sh1
        jmp     short sh9
sh2:
        dec     score
        cmp     score,0
        jge     sh3
        mov     score,0
sh3:
        mov     freq,bullet_freq
        mov     sound_flag1,bullet_sound_flag1
        mov     sound_flag2,bullet_sound_flag2
        mov     reset_soundflag,bullet_sound_duration
        mov     sound_counter,bullet_sound_flag1
        mov     [si+_flag],1
        mov     bx,ship_direct
        mov     [si+_direct],bx
        call    get_direct
        mov     [si+_x],ax
        mov     [si+_y],bx
        shl     ax,1
        shl     bx,1
        shl     ax,1
        shl     bx,1
        add     ax,ship_x
        add     [si+_x],ax
        add     bx,ship_y
        add     bx,7
        add     [si+_y],bx
        mov     [si+_counter],bullet_range
        call    show_score
sh9:
        ret
shoot   endp

change_shipv    proc near
        mov     cx,ship_vx
        mov     dx,ship_vy
        add     cx,ax
        add     dx,bx
        cmp     cx,10
        jle     csv1
        mov     cx,10
csv1:
        cmp     dx,7
        jle     csv2
        mov     dx,7
csv2:
        cmp     cx,-10
        jge     csv3
        mov     cx,-10
csv3:
        cmp     dx,-7
        jge     csv4
        mov     dx,-7
csv4:
        mov     ship_vx,cx
        mov     ship_vy,dx
        ret
change_shipv    endp

adjust_bullet_pos proc near
        cmp     [si+_x],640-3        ;7l7=720-3
        jle     adp1
        mov     [si+_x],0
adp1:
        cmp     [si+_y],332 ;>
        jle     adp2
        mov     [si+_y],0
adp2:
        cmp     [si+_x],0
        jge     adp3
        mov     [si+_x],640-3        ;7l7=720-3
adp3:
        cmp     [si+_y],0
        jge     adp4
        mov     [si+_y],332 ;>
adp4:
        mov     ax,[si+_x]
        add     ax,7
        sub     ax,ship_x
        cmp     ax,-2
        jl      adp5
        cmp     ax,23
        jg      adp5
        mov     ax,[si+_y]
        sub     ax,ship_y
        cmp     ax,-1
        jl      adp5
        cmp     ax,14
        jg      adp5
        mov     [si+_flag],0
adp5:
        ret
adjust_bullet_pos endp

set_meteor_flag proc near
        lea     si,meteor_data
        mov     cx,meteor_num
        mov     ax,x ;>
        add     ax,7
        mov     bx,y
ssf1:
        push    cx
        push    si
        mov     cl,[si+_kind]
        mov     ch,0
        shl     cx,1
        mov     di,cx
        mov     cx,[si+_x]
        mov     dx,[si+_y]
        sub     cx,ax
        sub     dx,bx
        cmp     cx,3
        jge     ssf9
        cmp     cx,meteor_wide[di]
        jl      ssf9
        cmp     dx,2
        jge     ssf9
        cmp     dx,meteor_depth[di]
        jl      ssf9
        mov     [si+_flag],1
ssf9:
        pop     si
        add     si,meteor_rec_len
        pop     cx
        loop    ssf1
        ret
set_meteor_flag endp

timer   proc    far
        cli
        push    ax
        inc     counter
        cmp     counter,200
        jl      timer1
        mov     counter,0
timer1:
        mov     al,20h
        out     20h,al
        pop     ax
        iret
timer   endp

show_score      proc near
        push    bx

        mov     x,72-7 ;>
        mov     y,339 ;>
        lea     bx,score_str
        call    prints

        mov     x,0 ;>
        mov     y,339-8 ;>
        lea     bx,ruler
        call    prints

        mov     x,80-7  ;0~79 in 640x350
        mov     y,339 ;>
        mov     ax,score
        call    printn

        mov     ax,score
        cmp     high_score,ax
        jae     end_show_score
        mov     high_score,ax
        call    show_high_score
end_show_score:
        pop     bx
        ret
show_score endp

show_high_score proc near
        push    bx
        mov     x,0
        mov     y,339 ;>
        lea     bx,highscore_str
        call    prints
        mov     x,13
        mov     y,339 ;>
        mov     ax,high_score
        call    printn
        pop     bx
        ret
show_high_score endp

get_direct      proc near
        shl     bx,1
        shl     bx,1
        mov     ax,direct[bx]
        mov     bx,direct[bx+2]
        ret
get_direct      endp

cndraw  proc    near
        mov     crash,0
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        mov     dl,[si]
        mov     dh,0
        mov     cl,[si+1]
        mov     ch,0
        inc     si
        inc     si
        mov     bx,y
        shl     bx,1
cnd1:
        push    cx
        mov     di,yverth[bx]
        add     di,x
        add     bx,2
        mov     cx,dx
cnd2:
        mov     al,[si]
        mov     ah,es:[di]
        and     ah,al
        xor     ah,al
        or      crash,ah
        not     al
        and     es:[di],al
        inc     si
        inc     di
        loop    cnd2
        pop     cx
        loop    cnd1
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret
cndraw  endp

ndraw   proc    near
        push    bx
        push    cx
        push    dx
        push    si
        push    di
        mov     dl,[si]
        mov     dh,0
        mov     cl,[si+1]
        mov     ch,0
        inc     si
        inc     si
        mov     bx,y
        shl     bx,1
nd1:
        push    cx
        mov     di,yverth[bx]
        add     di,x
        add     bx,2
        mov     cx,dx
nd2:
        mov     al,[si]
        not     al
        and     es:[di],al
        inc     si
        inc     di
        loop    nd2
        pop     cx
        loop    nd1
        pop     di
        pop     si
        pop     dx
        pop     cx
        pop     bx
        ret
ndraw endp

stop_motor    proc near
        push    ds
        push    ax
        push    dx
        mov     ax,40h
        mov     ds,ax
        and     byte ptr ds:[3fh],0f0h
        mov     dx,3f2h
        mov     al,0ch
        out     dx,al
        pop     dx
        pop     ax
        pop     ds
        ret
stop_motor endp

show_protect    proc near
        push    bx
        mov     x,20
        mov     y,339
        cmp     protect_flag,1
        je      print_pro_on
        lea     bx,pro_off
        jmp     short go_print_pro
print_pro_on:
        lea     bx,pro_on
go_print_pro:
        call    prints
        pop     bx
        ret
show_protect    endp

show_sound      proc near
        push    bx

        mov     x,55-1
        mov     y,339
        cmp     snd_switch_flag,1
        je      print_snd_off
        lea     bx,snd_on
        jmp     short go_print_snd
print_snd_off:
        lea     bx,snd_off
go_print_snd:
        call    prints
        pop     bx
        ret
show_sound      endp

show_level      proc near
        push    bx

        mov     x,39
        mov     y,339
        lea     bx,level$
        call    prints

        mov     x,45
        mov     y,339
        mov     ax,level
        inc     ax
        call    printn

        pop     bx
        ret
show_level      endp

show_info       proc near
        mov     dx,offset info
        mov     ah,9
        int     21h
        mov     ah,0
        int     16h
        ret
show_info       endp

show_thanks     proc near
        mov     dx,offset thanks
        mov     ah,9
        int     21h
        ret
show_thanks     endp

code    ends

data    segment byte public

bullet_data     db bullet_rec_len*max_bullet dup(0)
meteor_data     db meteor_rec_len*max_meteor*4 dup(0)

direct  equ     this word
        dw      0,-3
        dw      1,-3
        dw      2,-3
        dw      3,-3
        dw      3,-2
        dw      3,-1

        dw      3,0
        dw      3,1
        dw      3,2
        dw      3,3
        dw      2,3
        dw      1,3

        dw       0,3
        dw      -1,3
        dw      -2,3
        dw      -3,3
        dw      -3,2
        dw      -3,1

        dw      -3, 0
        dw      -3,-1
        dw      -3,-2
        dw      -3,-3
        dw      -2,-3
        dw      -1,-3

meteor1 equ     this byte
        db 2,9
        db       28,0
        db       54,0
        db      106,0
        db       85,0
        db      171,0
        db      213,0
        db      171,0
        db      118,0
        db       28,0
        db 2,9
        db       14,  0
        db       27,  0
        db       53,  0
        db       42,128
        db       85,128
        db      106,128
        db       85,128
        db       59,  0
        db       14,  0
        db 2,9
        db       7,  0
        db      13,128
        db      26,128
        db      21, 64
        db      42,192
        db      53, 64
        db      42,192
        db      29,128
        db       7,  0
        db 2,9
        db       3,128
        db       6,192
        db      13, 64
        db      10,160
        db      21, 96
        db      26,160
        db      21, 96
        db      14,192
        db       3,128
        db 2,9
        db       1,192
        db       3, 96
        db       6,160
        db       5, 80
        db      10,176
        db      13, 80
        db      10,176
        db       7, 96
        db       1,192
        db 2,9
        db      0,224
        db      1,176
        db      3, 80
        db      2,168
        db      5, 88
        db      6,168
        db      5, 88
        db      3,176
        db      0,224
        db 2,9
        db      0,112
        db      0,216
        db      1,168
        db      1, 84
        db      2,172
        db      3, 84
        db      2,172
        db      1,216
        db      0,112
        db 2,9
        db      0, 56
        db      0,108
        db      0,212
        db      0,170
        db      1, 86
        db      1,170
        db      1, 86
        db      0,236
        db      0, 56

meteor2 equ this byte
db 3,11,15,248,0,26,188,0,53,86,0,106,171,0,85,85,0
db 106,171,0,213,85,0,234,171,0,125,87,0,15,238,0,0,124,0
db 3,11,7,252,0,13,94,0,26,171,0,53,85,128,42,170,128
db 53,85,128,106,170,128,117,85,128,62,171,128,7,247,0,0,62,0
db 3,11,3,254,0,6,175,0,13,85,128,26,170,192,21,85,64
db 26,170,192,53,85,64,58,170,192,31,85,192,3,251,128,0,31,0
db 3,11,1,255,0,3,87,128,6,170,192,13,85,96,10,170,160
db 13,85,96,26,170,160,29,85,96,15,170,224,1,253,192,0,15,128
db 3,11,0,255,128,1,171,192,3,85,96,6,170,176,5,85,80
db 6,170,176,13,85,80,14,170,176,7,213,112,0,254,224,0,7,192
db 3,11,0,127,192,0,213,224,1,170,176,3,85,88,2,170,168
db 3,85,88,6,170,168,7,85,88,3,234,184,0,127,112,0,3,224
db 3,11,0,63,224,0,106,240,0,213,88,1,170,172,1,85,84
db 1,170,172,3,85,84,3,170,172,1,245,92,0,63,184,0,1,240
db 3,11,0,31,240,0,53,120,0,106,172,0,213,86,0,170,170
db 0,213,86,1,170,170,1,213,86,0,250,174,0,31,220,0,0,248
meteor3 equ this byte
db 4,22,0,15,240,0,1,255,252,0,7,250,190,0,31,87,87,0,58,170,171,0,53,85,87,0
db 106,170,171,0,117,85,87,0,234,170,171,0,213,85,87,0,234,170,171,0,213,85
db 87,0,234,170,171,0,213,85,87,0,234,170,171,0,213,85,87,0,234,170,171,0,213
db 85,87,0,234,170,175,0,245,85,252,0,127,255,240,0,31,255,0,0,4,22,0,7,248
db 0,0,255,254,0,3,253,95,0,15,171,171,128,29,85,85,128,26,170,171,128,53,85
db 85,128,58,170,171,128,117,85,85,128,106,170,171,128,117,85,85,128,106,170
db 171,128,117,85,85,128,106,170,171,128,117,85,85,128,106,170,171,128,117,85
db 85,128,106,170,171,128,117,85,87,128,122,170,254,0,63,255,248,0,15,255,128
db 0,4,22,0,3,252,0,0,127,255,0,1,254,175,128,7,213,213,192,14,170,170,192,13
db 85,85,192,26,170,170,192,29,85,85,192,58,170,170,192,53,85,85,192,58,170
db 170,192,53,85,85,192,58,170,170,192,53,85,85,192,58,170,170,192,53,85,85
db 192,58,170,170,192,53,85,85,192,58,170,171,192,61,85,127,0,31,255,252,0,7
db 255,192,0,4,22,0,1,254,0,0,63,255,128,0,255,87,192,3,234,234,224,7,85,85
db 96,6,170,170,224,13,85,85,96,14,170,170,224,29,85,85,96,26,170,170,224,29
db 85,85,96,26,170,170,224,29,85,85,96,26,170,170,224,29,85,85,96,26,170,170
db 224,29,85,85,96,26,170,170,224,29,85,85,224,30,170,191,128,15,255,254,0,3
db 255,224,0,4,22,0,0,255,0,0,31,255,192,0,127,171,224,1,245,117,112,3,170,170
db 176,3,85,85,112,6,170,170,176,7,85,85,112,14,170,170,176,13,85,85,112,14
db 170,170,176,13,85,85,112,14,170,170,176,13,85,85,112,14,170,170,176,13,85
db 85,112,14,170,170,176,13,85,85,112,14,170,170,240,15,85,95,192,7,255,255,0,1
db 255,240,0,4,22,0,0,127,128,0,15,255,224,0,63,213,240,0,250,186,184,1,213,85
db 88,1,170,170,184,3,85,85,88,3,170,170,184,7,85,85,88,6,170,170,184,7,85,85
db 88,6,170,170,184,7,85,85,88,6,170,170,184,7,85,85,88,6,170,170,184,7,85,85
db 88,6,170,170,184,7,85,85,120,7,170,175,224,3,255,255,128,0,255,248,0,4,22,0
db 0,63,192,0,7,255,240,0,31,234,248,0,125,93,93,0,234,170,172,0,213,85,92,1
db 170,170,172,1,213,85,92,3,170,170,172,3,85,85,92,3,170,170,172,3,85,85,92,3
db 170,170,172,3,85,85,92,3,170,170,172,3,85,85,92,3,170,170,172,3,85,85,92,3
db 170,170,188,3,213,87,240,1,255,255,192,0,127,252,0,4,22,0,0,31,224,0,3,255
db 248,0,15,245,124,0,62,174,174,0,117,85,86,0,106,170,174,0,213,85,86,0,234
db 170,174,1,213,85,86,1,170,170,174,1,213,85,86,1,170,170,174,1,213,85,86,1
db 170,170,174,1,213,85,86,1,170,170,174,1,213,85,86,1,170,170,174
db 1,213,85,94,1,234,171,248,0,255,255,224,0,63,254,0
bullet_shape equ this byte
db 2,2,11b,10000000b,11b,10000000b
db 2,2, 1b,11000000b, 1b,11000000b
db 2,2, 0b,11100000b, 0b,11100000b
db 2,2, 0b,01110000b, 0b,01110000b
db 2,2, 0b,00111000b, 0b,00111000b
db 2,2, 0b,00011100b, 0b,00011100b
db 2,2, 0b,00001110b, 0b,00001110b
db 2,2, 0b,00000111b, 0b,00000111b
crash_shape equ this byte
db 3,15,0,128,0,36,84,0,8,0,0,34,81,0,82,164,0,5,80,0,90,164,0
db 133,82,0,26,164,0,37,81,0,138,168,0,18,66,0,72,20,0,18,80,0,4,4,0
db 3,15,0,64,0,18,42,0,4,0,0,17,40,128,41,82,0,2,168,0,45,82,0
db 66,169,0,13,82,0,18,168,128,69,84,0,9,33,0,36,10,0,9,40,0,2,2,0
db 3,15,0,32,0,9,21,0,2,0,0,8,148,64,20,169,0,1,84,0,22,169,0
db 33,84,128,6,169,0,9,84,64,34,170,0,4,144,128,18,5,0,4,148,0,1,1,0
db 3,15,0,16,0,4,138,128,1,0,0,4,74,32,10,84,128,0,170,0,11,84,128
db 16,170,64,3,84,128,4,170,32,17,85,0,2,72,64,9,2,128,2,74,0,0,128,128
db 3,15,0,8,0,2,69,64,0,128,0,2,37,16,5,42,64,0,85,0,5,170,64
db 8,85,32,1,170,64,2,85,16,8,170,128,1,36,32,4,129,64,1,37,0,0,64,64
db 3,15,0,4,0,1,34,160,0,64,0,1,18,136,2,149,32,0,42,128,2,213,32
db 4,42,144,0,213,32,1,42,136,4,85,64,0,146,16,2,64,160,0,146,128,0,32,32
db 3,15,0,2,0,0,145,80,0,32,0,0,137,68,1,74,144,0,21,64,1,106,144
db 2,21,72,0,106,144,0,149,68,2,42,160,0,73,8,1,32,80,0,73,64,0,16,16
db 3,15,0,1,0,0,72,168,0,16,0,0,68,162,0,165,72,0,10,160,0,181,72
db 1,10,164,0,53,72,0,74,162,1,21,80,0,36,132,0,144,40,0,36,160,0,8,8
ship_x          dw 0
ship_y          dw 0
ship_vx         dw 0
ship_vy         dw 0
ship_direct     dw 0
ship_now_direct dw 0
ship_turn       db 0
ship_flag       db 0
crash_flag      db 0
crash_counter   dw 0
bullet_num      dw min_bullet
init_meteor     dw min_meteor
meteor_num      dw min_meteor
meteor_turn     db 3,5,7
meteor_wide     dw -2*8,-3*8,-4*8
meteor_depth    dw -9,-11,-22
sound_flag1     dw normal_sound_flag1
sound_flag2     dw normal_sound_flag2
sound_counter   dw normal_sound_flag1
reset_soundflag dw 0
time_ip         dw ?
time_cs         dw ?
counter         dw 0
score           dw 0
high_score      dw 0
delay_counter   dw 0
flag            db 0
random          dw 14,23,1,8,17,20,22,2,4,7,9,11,13,15,16,19,21,5,3,10

level dw 0
snd_switch_flag db 0
protect_flag db 0

score_str db 'SCORE :        $'
highscore_str db 'HIGH SCORE :        $'
pause_str db 'Press [ENTER] TO START!$'

the_end$ db "THE END!$"
level$  db "LEVEL $"
snd_on  db "SOUND ON!$"
snd_off db "SOUND OFF$"
snd_spc db "         $"
pro_spc db "           $"
pro_on  db "PROTECT ON!$"
pro_off db "PROTECT OFF$"
info    db 13,10
        db "           Crash Meteor  Version 1.0           ",13,10
        db "                Key & Function:                ",13,10,10
        db "                 Arrows = Move                 ",13,10
        db "                 Space  = Shot                 ",13,10
        db "                 Esc    = Exit                 ",13,10
        db "                 ?/     = Sound                ",13,10
        db "                 Tab    = Super                ",13,10,10
        db "           Press a key when ready...$"

thanks  db 13,10,"Thanks for Playing Crash Meteor",13,10,"$"

mode    db      ?

ruler   db  '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!$'

data    ends

zstack  segment stack   'stack'
        db      1024    dup (?)
heap    equ     $
zstack  ends

        end     main

