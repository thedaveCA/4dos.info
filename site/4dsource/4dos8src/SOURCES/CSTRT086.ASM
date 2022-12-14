;*****************************************************************************
;*
;*                            Open Watcom Project
;*
;*    Portions Copyright (c) 1983-2002 Sybase, Inc. All Rights Reserved.
;*
;*  ========================================================================
;*
;*    This file contains Original Code and/or Modifications of Original
;*    Code as defined in and that are subject to the Sybase Open Watcom
;*    Public License version 1.0 (the 'License'). You may not use this file
;*    except in compliance with the License. BY USING THIS FILE YOU AGREE TO
;*    ALL TERMS AND CONDITIONS OF THE LICENSE. A copy of the License is
;*    provided with the Original Code and Modifications, and is also
;*    available at www.sybase.com/developer/opensource.
;*
;*    The Original Code and all software distributed under the License are
;*    distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
;*    EXPRESS OR IMPLIED, AND SYBASE AND ALL CONTRIBUTORS HEREBY DISCLAIM
;*    ALL SUCH WARRANTIES, INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF
;*    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR
;*    NON-INFRINGEMENT. Please see the License for the specific language
;*    governing rights and limitations under the License.
;*
;*  ========================================================================
;*
;* Description:  DOS 16-bit startup code.
;*
;*****************************************************************************


;       This must be assembled using one of the following commands:
;               wasm cstrt086 -bt=DOS -ms -0
;               wasm cstrt086 -bt=DOS -mm -0
;               wasm cstrt086 -bt=DOS -mc -0
;               wasm cstrt086 -bt=DOS -ml -0
;               wasm cstrt086 -bt=DOS -mh -0
;

include mdef.inc
include xinit.inc

.286p

        name    cstart

        assume  nothing

if _MODEL and _BIG_CODE
        extrn   __CMain                 : far
        extrn   __InitRtns              : far
        extrn   __FiniRtns              : far
        extrn   __fatal_runtime_error_  : far
else
        extrn   __CMain                 : near
        extrn   __InitRtns              : near
        extrn   __FiniRtns              : near
        extrn   __fatal_runtime_error_  : near
endif
        extrn   _edata                  : byte  ; end of DATA (start of BSS)
        extrn   _end                    : byte  ; end of BSS (start of STACK)

        extrn   "C",_curbrk             : word
        extrn   "C",_psp                : word
        extrn   "C",_osmajor            : byte
        extrn   "C",_osminor            : byte
        extrn   __osmode                : byte
        extrn   __HShift                : byte
        extrn   "C",_STACKLOW           : word
        extrn   "C",_STACKTOP           : word
        extrn   "C",_cbyte              : word
        extrn   "C",_child              : word
        extrn   __no87                  : word
        extrn   "C",__FPE_handler       : dword
        extrn   "C",_LpCmdLine          : word
        extrn   "C",_LpPgmName          : word
        extrn   __get_ovl_stack         : word
        extrn   __restore_ovl_stack     : word
        extrn   __close_ovl_file        : word
        extrn   __DOSseg__              : byte

ifdef __TINY__
        extrn   __stacksize             : word
 DGROUP group _TEXT,CONST,STRINGS,_DATA,DATA,XIB,XI,XIE,YIB,YI,YIE,_BSS
else
 DGROUP group _NULL,_AFTERNULL,CONST,STRINGS,_DATA,DATA,XIB,XI,XIE,YIB,YI,YIE,_BSS,STACK
endif

ife _MODEL and _BIG_CODE

; this guarantees that no function pointer will equal NULL
; (WLINK will keep segment 'BEGTEXT' in front)
; This segment must be at least 4 bytes in size to avoid confusing the
; signal function.
; need a symbol defined here to prevent the dead code elimination from
; eliminating the segment.
; (the int 3h is useful for quickly revealing jumps to NULL code pointers)

BEGTEXT  segment word public 'CODE'
        assume  cs:BEGTEXT
forever label   near
        int     3h
        jmp     short forever
___begtext label byte
        nop
        nop
        nop
        nop
        public ___begtext
        assume  cs:nothing
BEGTEXT  ends

endif

_TEXT   segment word public 'CODE'

FAR_DATA segment byte public 'FAR_DATA'
FAR_DATA ends

        assume  ds:DGROUP

        INIT_VAL        equ 0101h
        NUM_VAL         equ 16

_NULL   segment para public 'BEGDATA'
__nullarea label word
        dw      NUM_VAL dup(INIT_VAL)
        public  __nullarea
_NULL   ends

_AFTERNULL segment word public 'BEGDATA'
        dw      0                       ; nullchar for string at address 0
_AFTERNULL ends


CONST   segment word public 'DATA'
CONST   ends

STRINGS segment word public 'DATA'
STRINGS ends

XIB     segment word public 'DATA'
XIB     ends
XI      segment word public 'DATA'
XI      ends
XIE     segment word public 'DATA'
XIE     ends

YIB     segment word public 'DATA'
YIB     ends
YI      segment word public 'DATA'
YI      ends
YIE     segment word public 'DATA'
YIE     ends

_DATA   segment word public 'DATA'

if _MODEL and _BIG_CODE
;       Variables filled in by Microsoft Overlay Manager
;       These are here for people who want to link with Microsoft Linker
;       and use CodeView for debugging overlayed programs.
__ovlflag  db 0                 ; non-zero => program is overlayed
__intno    db 0                 ; interrupt number used by MS Overlay Manager
__ovlvec   dd 0                 ; saved contents of interrupt vector used
        public  __ovlflag
        public  __intno
        public  __ovlvec
endif

_DATA   ends

DATA    segment word public 'DATA'
DATA    ends

_BSS    segment word public 'BSS'
_BSS    ends

STACK_SIZE      equ     800h

STACK   segment para stack 'STACK'
        db      (STACK_SIZE) dup(?)
STACK   ends

        assume  nothing
        public  __astart
        public  _Not_Enough_Memory_

        assume  cs:_TEXT

 __astart proc near
        jmp     around

;
; miscellaneous code-segment messages
;

NullAssign      db      0dh,0ah,'*** NULL assignment detected',0dh,0ah,0

NoMemory        db      'Not enough memory',0dh,0ah,0

ConsoleName     db      'con',00h

ife _MODEL and _BIG_CODE
                dw      ___begtext      ; make sure dead code elimination
endif                                   ; doesn't kill BEGTEXT segment

around: sti                             ; enable interrupts

; 
; On entry (called by 4DOS), we have:
;   DS = SS = DGROUP
;   ES = PSP segment
;   AX = DGROUP size
;   SP = adjusted stack pointer we should not modify
;
; DGROUP contains initialized data + BSS, ending at _end. That is also the
; bottom of the stack. The top of the stack can be calculated from sp.
; Between the top of stack and the size passed in ax is pre-allocated heap.
;

        mov     cx,ds                   ; get proper stack segment

        assume  ds:DGROUP

        mov     bx,offset DGROUP:_end   ; get bottom of stack
        add     bx,0Fh                  ; ...
        and     bl,0F0h                 ; ...
        mov     _STACKLOW,bx            ; ...
        mov     _psp,es                 ; save segment address of PSP

        mov     bx,sp                   ; calculate top address for stack
	add     bx,0Fh                  ; round up to paragraph boundary
	and     bl,0F0h                 ; ...
        mov     _STACKTOP,bx            ; set stack top

        mov     dx,bx                   ; make sure enough memory for stack
        shr     dx,1                    ; calc # of paragraphs needed
        shr     dx,1                    ; ... for data segment
        shr     dx,1                    ; ...
        shr     dx,1                    ; ...

        mov     cx,es:2h                ; get highest segment address
        mov     si,ds                   ; point to data segment
        sub     cx,si                   ; calc # of paragraphs available
        cmp     dx,cx                   ; compare with what we need
        jb      enuf_mem                ; if not enough memory
_Not_Enough_Memory_:
        mov     bx,1                    ; - set exit code
        mov     ax,offset NoMemory      ;
        mov     dx,cs                   ;
        call    __fatal_runtime_error_  ; - display msg and exit
enuf_mem:                               ; endif

        mov     _curbrk,ax              ; set top of memory owned by process
        mov     ax,_psp                 ; get segment addr of PSP
        mov     es,ax                   ; place in ES
;
;       copy command line into bottom of stack
;
        mov     di,es                   ; point ds to PSP
	mov     ds,di                   ; ...
        mov     di,81H                  ; DOS command buffer _psp:80
        mov     cl,-1[di]               ; get length of command
        mov     ch,0
        cld                             ; set direction forward
        mov     al,' '
        repe    scasb
        lea     si,-1[di]

        mov     dx,DGROUP
        mov     es,dx                   ; es:di is destination
        mov     di,es:_STACKLOW
        mov     es:_LpCmdLine+0,di      ; stash lpCmdLine pointer
        mov     es:_LpCmdLine+2,es      ; ...
        je      noparm
        inc     cx
        rep     movsb
noparm: sub     al,al
        stosb                           ; store NULLCHAR
        mov     al,0                    ; assume no pgm name
        stosb                           ; . . .
        dec     di                      ; back up pointer 1
;
;       get DOS version number
;
        mov     ah,30h
        int     21h
        mov     es:_osmajor,al
        mov     es:_osminor,ah
        mov     cx,di                   ; remember address of pgm name
        cmp     al,3                    ; if DOS version 3 or higher
        jb      nopgmname               ; then
;
;       copy the program name into bottom of stack
;
        mov     ds,ds:2ch               ; get segment addr of environment area
        sub     si,si                   ; offset 0
        xor     bp,bp                   ; no87 not present!
L0:     mov     ax,[si]                 ; get first part of environment var
        or      ax,2020H                ; lower case
        cmp     ax,"on"                 ; if first part is 'NO'
        jne     L1                      ; - then
        mov     ax,2[si]                ; - get second part
        cmp     ax,"78"                 ; - if second part is '87'
        jne     L1                      ; - then
        inc     bp                      ; - - set bp to indicate NO87
L1:     cmp     byte ptr [si],0         ; end of string ?
        lodsb
        jne     L1                      ; until end of string
        cmp     byte ptr [si],0         ; end of all strings ?
        jne     L0                      ; if not, then skip next string
        lodsb
        inc     si                      ; - point to program name
        inc     si                      ; - . . .
L2:     cmp     byte ptr [si],0         ; - end of pgm name ?
        movsb                           ; - copy a byte
        jne     L2                      ; - until end of pgm name
nopgmname:                              ; endif
        mov     si,cx                   ; save address of pgm name
        mov     es:_LpPgmName+0,si      ; stash LpPgmName pointer
        mov     es:_LpPgmName+2,es      ; ...

        mov     ax,es:_psp              ; get segment addr of PSP
        mov     es,ax                   ; place in ES
        mov     bx,sp                   ; end of stack in data segment

        assume  ds:DGROUP
        mov     dx,DGROUP
        mov     ds,dx
        mov     es,dx
        mov     __no87,bp               ; set state of "NO87" environment var
        mov     _STACKLOW,di            ; save low address of stack

        mov     cx,offset DGROUP:_end   ; end of _BSS segment (start of STACK)
        mov     di,offset DGROUP:_edata ; start of _BSS segment
        sub     cx,di                   ; calc # of bytes in _BSS segment
        mov     al,0                    ; zero the _BSS segment
        rep     stosb                   ; . . .

        cmp     word ptr __get_ovl_stack,0 ; if program not overlayed
        jne     _is_ovl                 ; then
        mov     ax,offset __null_ovl_rtn; - set vectors to null rtn
        mov     __get_ovl_stack,ax      ; - ...
        mov     __get_ovl_stack+2,cs    ; - ...
        mov     __restore_ovl_stack,ax  ; - ...
        mov     __restore_ovl_stack+2,cs; - ...
        mov     __close_ovl_file,ax     ; - ...
        mov     __close_ovl_file+2,cs   ; - ...
_is_ovl:                                ; endif
        xor     bp,bp                   ; set up stack frame
if _MODEL and _BIG_CODE
        push    bp                      ; ... for new overlay manager
        mov     bp,sp                   ; ...
endif
        ; DON'T MODIFY BP FROM THIS POINT ON!
        mov     ax,offset __null_FPE_rtn; initialize floating-point exception
        mov     word ptr __FPE_handler,ax       ; ... handler address
        mov     word ptr __FPE_handler+2,cs     ; ...

        mov     ax,0FFh                 ; run all initalizers
        call    __InitRtns              ; call initializer routines
        call    __CMain
__astart endp

;       don't touch AL in __exit, it has the return code

__exit  proc near
        public  "C",__exit
        push    ax
        mov     dx,DGROUP
        mov     ds,dx
        cld                             ; check lower region for altered values
        lea     di,__nullarea           ; set es:di for scan
        mov     es,dx
        mov     cx,NUM_VAL
        mov     ax,INIT_VAL
        repe    scasw
        pop     ax                      ; restore return code
        je      ok
;
; low memory has been altered
;
        mov     bx,ax                   ; get exit code
        mov     ax,offset NullAssign    ; point to msg
        mov     dx,cs                   ; . . .

        public  __do_exit_with_msg__

; input: DX:AX - far pointer to message to print
;        BX    - exit code

__do_exit_with_msg__:
        mov     sp,offset DGROUP:_end+80h; set a good stack pointer
        push    bx                      ; save return code
        push    ax                      ; save address of msg
        push    dx                      ; . . .
        mov     dx,_TEXT
        mov     ds,dx
        mov     dx,offset ConsoleName
        mov     ax,03d01h               ; write-only access to screen
        int     021h
        mov     bx,ax                   ; get file handle
        pop     ds                      ; restore address of msg
        pop     dx                      ; . . .
        mov     si,dx                   ; get address of msg
        cld                             ; make sure direction forward
L3:     lodsb                           ; get char
        cmp     al,0                    ; end of string?
        jne     L3                      ; no
        mov     cx,si                   ; calc length of string
        sub     cx,dx                   ; . . .
        dec     cx                      ; . . .
        mov     ah,040h                 ; write out the string
        int     021h                    ; . . .
        pop     ax                      ; restore return code
ok:
if _MODEL and _BIG_CODE
        mov     dx,DGROUP               ; get access to DGROUP
        mov     ds,dx                   ; . . .
        cmp     byte ptr __ovlflag,0    ; if MS Overlay Manager present
        je      no_ovl                  ; then
        push    ax                      ; - save return code
        mov     al,__intno              ; - get interrupt number used
        mov     ah,25h                  ; - DOS func to set interrupt vector
        lds     dx,__ovlvec             ; - get previous contents of vector
        int     21h                     ; - restore interrupt vector
        pop     ax                      ; - restore return code
no_ovl:                                 ; endif
endif
        push    ax                      ; save return code
        mov     ax,00h                  ; run finalizers
        mov     dx,FINI_PRIORITY_EXIT-1 ; less than exit
        call    __FiniRtns              ; do finalization
        pop     ax                      ; restore return code
        mov     ah,04cH                 ; DOS call to exit with return code
        int     021h                    ; back to DOS
__exit  endp


;
;       set up addressability without segment relocations for emulator
;
public  __GETDS
__GETDS proc    near
        push    ax                      ; save ax
ifdef __TINY__
;       can't have segment fixups in the TINY memory model
        mov     ax,cs                   ; DS=CS
else
        mov     ax,DGROUP               ; get DGROUP
endif
        mov     ds,ax                   ; load DS with appropriate value
        pop     ax                      ; restore ax
        ret                             ; return
__GETDS endp


__null_FPE_rtn proc far
        ret                             ; return
__null_FPE_rtn endp

__null_ovl_rtn proc far
        ret                             ; return
__null_ovl_rtn endp

        xref    __HeapInit_

InitHeap proc   far
        push    dx                      ; save dx
        mov     dx,_curbrk              ; get size of segment
        mov     ax,_STACKTOP            ; get start address of heap
        sub     dx,ax                   ; subtract start of heap
        call    __HeapInit_             ; initialize the heap
        pop     dx                      ; restore dx
        ret                             ; return
											InitHeap endp
_TEXT   ends

        xinit   InitHeap,0

        end
