;
; ������ main.asm.
;
; ������ �������� ����������
;
; ������ ���� ������������� 16.10.2013
;

;----------------------------------------

.686
.model flat, stdcall
option casemap:none

;----------------------------------------

include c:\masm32\include\kernel32.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\gdi32.inc
include c:\masm32\include\windows.inc
include c:\masm32\include\user32.inc
include c:\masm32\include\msvcrt.inc

include Strings.mac

;RGB macro r, g, b
    ;(r) or ((g) shr 8) or ((b) shr 16)
;RGB endm

;----------------------------------------

; ��������� ��������� � ������ ����
AppWindowName equ <"Application">

;----------------------------------------
;----------------------------------------
; _Ball STRUCTURE
_Ball struct
	block_element WCHAR 'B'
	color dword 0
	speed dword 0
	timer dword 0
	step_num dword 0
	position_x dword 1
	position_y dword 1
	course_x dword 1
	course_y dword 1
_Ball ends
; ---------------------------------------------
; _Level STRUCTURE
_Level struct
	game_lifes dword 0;���������� ������
	size_strings dword 0; ������ �� Y
	size_columns dword 0
	number dword 0; ����� ������
	name word 30 dup(' '); ��� 
	init byte 0; ��������� - ��������� �� �������������
	back word ' '; ���������
	map dword 0; ������� ������ - ����� ������

_Level ends
; ---------------------------------------------
; _Platform STRUCTURE
_Platform struct
	block_element WCHAR 'P'
	position_x dword 0
	position_y dword 0
_Platform ends
; ---------------------------------------------
; _Game STRUCTURE
_Game struct
	lifes dword 0;
	points dword 0;
	speed dword 30; ������� �������� ����
	fps dword 0 ; ������� ���������� ������
	
_Game ends
; ---------------------------------------------
.data

glChar dd 0

; ���������� ������ ���������
CurrentPlatform _Platform <>
; ���������� ������ ����, ������� ������������ � ���������� �����
CurrentBall _Ball <>
; ���������� ������ ����
CurrentGame _Game <>
; ������� ����������� �������
CurrentLevel _Level <>
.data?

hIns HINSTANCE ?

HwndMainWindow HWND ?

showMode byte ?



.const

.code

;----------------------------------------

RegisterClassMainWindow proto;

CreateMainWindow proto;

WndProcMain proto hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM


Ball_setPosition proc uses eax ebx ecx edx esi edi x: dword, y:dword
	mov eax, offset CurrentBall
	mov ebx, x
	mov [_Ball ptr [eax]].position_x, ebx
	mov ecx, y
	mov [_Ball ptr [eax]].position_y, ecx

	ret
Ball_setPosition endp
;
Ball_setStandard proc uses eax ebx ecx edx esi edi this_p: dword
	mov eax, offset CurrentBall
	mov [_Ball ptr [eax]].block_element, WCHAR ptr 'B'
	mov [_Ball ptr [eax]].speed, 30
	mov [_Ball ptr [eax]].timer, 0
	mov [_Ball ptr [eax]].step_num, 0

	ret
Ball_setStandard endp
;
Ball_setStandardPosition proc uses eax ebx ecx edx esi edi this_p: dword, current_level: dword, x: dword, y: dword
	mov ebx, [current_level]
	mov ecx, 2

	mov eax, [Level ptr [ebx]].size_columns
	div ecx
	mov edi, offset CurrentBall
	mov [_Ball ptr [edi]].position_x, eax


	mov eax, [_Level ptr [ebx]].size_strings
	div ecx
	mov edi, offset CurrentBall
	mov [_Ball ptr [edi]].position_y, eax

	ret
Ball_setStandardPosition endp
;
Ball_step proc uses eax ebx ecx edx esi edi this_p: dword
	mov eax, offset CurrentBall
	mov edi, [_Ball ptr [eax]].course_x
	.if edi > 0
		inc [_Ball ptr [eax]].position_x
	.else
		dec [_Ball ptr [eax]].position_x
	.endif
	mov edi, [_Ball ptr [eax]].course_y
	.if edi > 0
		inc [_Ball ptr [eax]].position_y
	.else
		dec [_Ball ptr [eax]].position_y
	.endif

	ret 
Ball_step endp
; it generates new course X and Y directions
Ball_genCourse proc uses eax ebx ecx edx esi edi this_p: dword
	invoke crt_clock
	invoke crt_srand

	invoke crt_rand
	mov ebx, offset CurrentBall
	.if eax == 1
		mov [_Ball ptr [ebx]].course_x, 1		
	.else
		mov [_Ball ptr [ebx]].course_x, -1		
	.endif

	invoke crt_rand
	mov ebx, offset CurrentBall
	.if eax == 1
		mov [_Ball ptr [ebx]].course_y, 1		
	.else
		mov [_Ball ptr [ebx]].course_y, -1		
	.endif
		
Ball_genCourse endp
; �������� ������������ ������������ ��� ����
Ball_collision proc uses ebx ecx edx esi edi
	invoke Ball_platformCollision
	mov esi, eax
	invoke Ball_screenOut
	mov edi, eax
	.if esi != 0
		.if edi != 0
			ret 0; return false
		.endif
	.endif

	; ��������� ������ �� �����
	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_x
	mov edi, [_Ball ptr [ebx]].course_x
	.if esi <= 0
		.if edi < 0
			mov edi, -edi
			mov [_Ball ptr [ebx]].course_x, edi
		.endif
	.endif

	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_y
	mov edi, [_Ball ptr [ebx]].course_y
	.if esi <= 0
		.if edi < 0
			mov edi, -edi
			mov [_Ball ptr [ebx]].course_y, edi
		.endif
	.endif

	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_x
	mov ecx, offset CurrentLevel
	mov edi, [_Level ptr [ecx]].size_columns
	dec edi
	.if	esi >= edi
		mov esi, [_Ball ptr [ebx]].course_x
		.if	esi > 0
			mov [_Ball ptr [ebx]].course_x, -edi
		.endif
	.endif

	mov ebx, offset CurrentBall
	mov ecx, offset CurrentLevel
	mov esi, [_Ball ptr [ebx]].position_y
	mov edi, [_Level ptr [ecx]].size_strings
	dec edi
	.if esi == edi
		mov edx, offset CurrentGame
		dec [_Game ptr [edx]].lifes
		invoke Ball_setStandard
		invoke Platform_setStandard
		mov ebx, offset CurrentGame
		mov esi, [_Game ptr [ebx]].lifes
		.if esi == 0
			invoke Level_End, 0
		.endif
	.endif

	
	; ����� ��������� ������ �� �����
	; ��������� ����� ����!
Ball_collision endp
;
Ball_screenOut proc uses ebx ecx edx esi edi
	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_y
	.if esi <= 0
		ret 1
	.endif

	ret 0
Ball_screenOut endp
;
Ball_platformCollision proc uses ebx ecx edx esi edi
	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_x
	mov ebx, offset CurrentPlatform
	mov edi, [_Platform ptr  [ebx]].position_x
	;������������ � ����������
	.if esi >= edi
		add edi, [_Platform ptr [ebx]].length
		.if esi < edi
			mov ebx, offset CurrentBall
			mov esi, [_Ball ptr [ebx]].position_y
			mov ebx, offset CurrentPlatform
			mov edi, [_Platform ptr [ebx]].position_y
			dec edi
			.if esi == edi
				ret 1; return true
			.endif	
		.endif
	.endif
	; ������������ � ���������� �� ���������
	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_x
	mov ebx, offset CurrentPlatform
	mov edi, [_Platform ptr [ebx]].position_x
	dec edi
	.if	esi == edi
		mov edi, [_Platform ptr [ebx]].position_y
		dec edi
		mov ebx, CurrentBall
		mov esi, [_Ball ptr [ebx]].position_y
		.if esi == edi
			ret 1 ; return true
		.endif
	.endif

	mov ebx, offset CurrentBall
	mov esi, [_Ball ptr [ebx]].position_x
	mov ebx, offset CurrentPlatform
	mov edi, [_Platform ptr [ebx]].position_x
	add edi, [_Platform ptr [ebx]].length
	.if	esi == edi
		mov edi, [_Platform ptr [ebx]].position_y
		dec edi
		mov ebx, CurrentBall
		mov esi, [_Ball ptr [ebx]].position_y
		.if esi == edi
			ret 1 ; return true
		.endif
	.endif
	
	ret 0
Ball_platformCollision endp
;
Ball_speedControl proc uses eax ebx ecx edx esi edi

Ball_speedControl endp

; END OF BALL STRUCTURE AND FUNCTIONS



WinMain proc stdcall hInstance:HINSTANCE, hPrevInstance:HINSTANCE, szCmdLine:PSTR, iCmdShow:DWORD

    local msg: MSG

    mov eax, [hInstance]
    mov [hIns], eax

    invoke CreateMainWindow
    mov [HwndMainWindow], eax
    .if [HwndMainWindow] == 0
        xor eax, eax
        ret
    .endif
	
    .while TRUE
        invoke GetMessage, addr msg, NULL, 0, 0
            .break .if eax == 0

        invoke TranslateMessage, addr msg
        invoke DispatchMessage, addr msg

    .endw

    mov eax, [msg].wParam
    ret

WinMain endp

;--------------------

;
; ����������� ������ ��������� ���� ����������
;
RegisterClassMainWindow proc

    local WndClass:WNDCLASSEX	; ��������� ������

    ; ��������� ���� ���������
    mov WndClass.cbSize, sizeof (WNDCLASSEX)	; ������ ��������� ������
    mov WndClass.style, 0
    mov WndClass.lpfnWndProc, WndProcMain		; ����� ������� ��������� ������
    mov WndClass.cbClsExtra, 0
    mov WndClass.cbWndExtra, 0
    mov eax, [hIns]
    mov WndClass.hInstance, eax					; ��������� ����������
    invoke LoadIcon, hIns, $CTA0("MainIcon")	; ������ ����������
    mov WndClass.hIcon, eax
    invoke LoadCursor, NULL, IDC_ARROW
    mov WndClass.hCursor, eax
    invoke GetStockObject, BLACK_BRUSH			; ����� ��� ����
    mov WndClass.hbrBackground, eax
    mov WndClass.lpszMenuName, NULL
    mov WndClass.lpszClassName, $CTA0(AppWindowName)	; ��� ������
    invoke LoadIcon, hIns, $CTA0("MainIcon")
    mov WndClass.hIconSm, eax

    invoke RegisterClassEx, addr WndClass
    ret

RegisterClassMainWindow endp

;--------------------

;
; �������� ��������� ���� ����������
;
CreateMainWindow proc

    local hwnd:HWND

    ; ����������� ������ ��������� ����
    invoke RegisterClassMainWindow

    ; �������� ���� ������������������� ������
    invoke CreateWindowEx, 
        WS_EX_CONTROLPARENT or WS_EX_APPWINDOW, ; ����������� ����� ����
        $CTA0(AppWindowName),	; ��� ������������������� ������ ����
        $CTA0("Application"),	; ��������� ����
        WS_OVERLAPPEDWINDOW,	; ����� ����
        10,	    ; X-���������� ������ �������� ����
        10,	    ; Y-���������� ������ �������� ����
        650,    ; ������ ����
        650,    ; ������ ����
        NULL,   ; ��������� ������������� ����
        NULL,   ; ��������� �������� ���� (��� �������� ����)
        [hIns], ; ������������� ����������
        NULL
    mov [hwnd], eax
    
    .if [hwnd] == 0
        invoke MessageBox, NULL, $CTA0("������ �������� ��������� ���� ����������"), NULL, MB_OK
        xor eax, eax
        ret
    .endif
        
    invoke ShowWindow, hwnd, SW_SHOWNORMAL
    invoke UpdateWindow, hwnd
    
    mov eax, [hwnd]
    ret

CreateMainWindow endp

;--------------------

;
; ������� ��������� ��������� �������� ���� ����������.
; ���������� �������� ��� ����������� ��������� ��� �������� ����
; � ���������������� �����������.
;
; ���������:
;
; hwnd      ��������� ����, ����������� ���������
; iMsg      ������������� (�����) ���������
; wParam    �������� ���������
; lParam    �������� ���������
;
WndProcMain proc hwnd:HWND, iMsg:UINT, wParam:WPARAM, lParam:LPARAM

    local hdc:HDC
    local pen:HPEN
    local ps:PAINTSTRUCT

    .if [iMsg] == WM_CREATE
        ; �������� ����
        
        xor eax, eax
        ret
    .elseif [iMsg] == WM_DESTROY
        ; �������� ����
        
        invoke PostQuitMessage, 0
        xor eax, eax
        ret
    .elseif [iMsg] == WM_CHAR
        ; ���� � ����������
        
        mov eax, [wParam]
        mov [glChar], eax
        xor eax, eax
        invoke InvalidateRect, hwnd, NULL, TRUE
        ret
    .elseif [iMsg] == WM_PAINT
        ; ����������� ����
        
        ; �������� �������� ����������
        invoke BeginPaint, HwndMainWindow, addr ps
        mov [hdc], eax
        
        ; ���������� ���� ������
        invoke SetTextColor, [hdc], 255
        
        ; ���������� ���� ���� ������
        invoke SetBkColor, [hdc], 100 + (100 shl 8) + (100 shl 16)
        
        ; ����� ������ �� �������� ����������
        invoke TextOut, [hdc], 10, 10, $CTA0("Hello, World"), 12
        
        ; ����� ���������� ���������� �������
        invoke TextOut, [hdc], 10, 50, addr glChar, 1
        invoke TextOut, [hdc], 20, 50, addr glChar, 1
        
        ; ������ ������ "����" ��� ��������� �����
        invoke CreatePen, 
            PS_SOLID,       ; ����� ��� ����� (��������)
            3,              ; ������� �����
            (30 shl 16) + (150 shl 8) + 255 ; ���� �����
        mov [pen],eax
        
        ; ����������� ��������� ����� � ���������� ����������
        invoke SelectObject, [hdc], [pen]
        
        ; ���������� ������� �������, � ������� ���������� ���������
        invoke MoveToEx,
            [hdc],          ; ��������� ��������� ����������
            0,              ; X-����������
            75,             ; Y-����������
            NULL
            
        ; ������ ����� ��������� ������ �� ������� ������� �� ��������� �����
        invoke LineTo,
            [hdc],          ; ��������� ��������� ����������
            1500,           ; X-���������� �������� �����
            75              ; Y-���������� �������� �����

        ; ������� ��������� "����"
        invoke DeleteObject, pen
        
        ; ���������� �����������
        invoke EndPaint, [hwnd], addr ps
        
        xor eax, eax
        ret
    .endif
    
    ; �������������� ��������� ������������ � �������
    ; ��������� �� ���������.
    invoke DefWindowProc, hwnd, iMsg, wParam, lParam
    ret

WndProcMain endp

;--------------------

;--------------------


end
