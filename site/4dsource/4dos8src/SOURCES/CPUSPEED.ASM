; -----------------------------------------------------------------------------
; CPUSPEED.ASM  CPU speed measurement routine for TMi0SDGL 2      Version 2.15
;
; Too-Much-In-One-So-Don't-Get-Lost(tm) Revision 2 CPU/FPU Detection Library
; Copyright(c) 1996-2000 by B-coolWare.  Written by Bobby Z.
; -----------------------------------------------------------------------------
; This file contains Speed routine that plays part in CPU clock frequency
; calculation. Algorithm was taken from Norton SysInfo as well as several
; constants.

        INCLUDE HEADER.ASH

        PUBLIC  Speed

; --- Windows detection and critical section handling

IFNDEF  __32bit__

isUnderWin      proc near
        mov     ax,1600h
        int     2Fh
        or      al,al
        jz      @@nowin
        cmp     al,80h
        jz      @@nowin
        stc
        ret
@@nowin:
        clc
        ret
isUnderWin      endp

winStartCritical        proc near
        push    ax
        call    IsUnderWin
        jnc     @@Q
        mov     ax,1681h
        int     2Fh
@@Q:
        pop     ax
        ret
winStartCritical        endp

winEndCritical          proc near
        push    ax
        call    IsUnderWin
        jnc     @@Q
        mov     ax,1682h
        int     2Fh
@@Q:
        pop     ax
        ret
winEndCritical          endp

ENDIF

; ------ Speed routine implementation

IFDEF  __32bit__
 Speed   PROC  DIST USES ebx ecx edx esi edi
ELSE
 Speed   PROC  DIST USES si di
 LOCAL   Stage : Word           ; local variable to differ test stages
ENDIF
        mov     cx,2
IFNDEF  __32bit__
        mov     Stage,0
        call    winStartCritical; enter Windows critical section
                                ; IBM OS/2 doesn't provide a critical section
                                ; mechanism, so you should set HW_TIMER = ON
                                ; in DOS Box settings to get correct result.
ENDIF
@@1:
        mov     speedShift,cx   ; initialize speedShift
IFNDEF  __32bit__
        push    Stage
ELSE
        push    0
ENDIF
        call    speedTest       ; do a code section 101 times
        cmp     ax,1000h
        jnb     @@2
        mov     cx,speedShift
IFDEF   __32bit__
        shl     cx,3
ELSE
        shl     cx,1            ; repeat test with increasing values until
        shl     cx,1            ; we get reasonable time value worth working
        shl     cx,1            ; with
ENDIF
        jmp     @@1
@@2:
        push    ax
        mov     cx,speedShift   ; now do the same code section 100 times less
IFNDEF  __32bit__
        mov     Stage,1
        push    Stage
ELSE
        push    1
ENDIF
        call    speedTest
IFNDEF  __32bit__
        call    winEndCritical  ; exit Windows critical section
ENDIF
        pop     dx
        sub     dx,ax           ; now we got time how long 100*shift instructions
        xchg    ax,dx           ; were performed - knowing number of ticks it
        ret                     ; takes for each CPU type we can compute the
Speed   ENDP                    ; CPU clock frequency.

speedTest       PROC    NEAR, Stage : Word

        clr     dx
        mov     si,0AAAAh
        mov     bx,05555h
        in      al,61h          ; initialize hardware timer
        jmp     $+2
        and     al,0FCh
        out     61h,al
        jmp     $+2
        mov     al,0B4h
        out     43h,al
        jmp     $+2
        clr     al
        out     42h,al
        jmp     $+2
        out     42h,al
        jmp     $+2
        in      al,61h
        mov     di,ax
        or      al,01
        cmp     Stage,0
        jnz     @@2
@@1:
        cli
        out     61h,al
@@3:
        REPT    101
        mov     ax,si
        div     bx
        ENDM
        dec     cx
        jz      @@4
        jmp     @@3
@@2:
        cli
        out     61h,al
@@5:
        mov     ax,si
        div     bx
        dec     cx
        jz      @@4
        jmp     @@5

@@4:
        mov     ax,di           ; shut down timer and get results
        out     61h,al
        jmp     $+2
        sti
        in      al,42h
        jmp     $+2
        xchg    ah,al
        in      al,42h
        jmp     $+2
        xchg    ah,al
        neg     ax
        push    ax
        in      al,61h
        jmp     $+2
        and     al,0FDh
        out     61h,al
; fix the waveform back to default (suggested by Pascal Moulart)
        mov     al,0B6h
        out     43h,al
        jmp     $+2
        clr     al
        out     42h,al
        jmp     $+2
        out     42h,al
        pop     ax
        ret
speedTest       ENDP

        END
