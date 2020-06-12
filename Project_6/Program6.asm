TITLE Program #6     (Program6.asm)

; Author: Josh Sanford
; Last Modified: 6/7/2020
; OSU email address: sanfojos@oregonstate.edu
; Course number/section: CS271-400
; Project Number: 6               Due Date: 6/7/2020
; Description: This program takes 10 user input numbers, converts the strings
;			   into their numeric values, converts them back to strings and 
;			   displays them, calculates the sum and rounded average, and 
;			   again converts the results to strings and displays them.

INCLUDE Irvine32.inc

; (insert constant definitions here)
displayString	MACRO	buffer
	push	edx
	mov		edx, buffer
	call	WriteString
	pop		edx
ENDM

getString	MACRO	prompt, buffer, size_of_buffer
	push	ecx
	push	edx
	mov		edx, prompt
	call	WriteString
	mov		edx, buffer
	mov		ecx, size_of_buffer
	call	ReadString
	mov		sLength, eax
	pop		edx
	pop		ecx
ENDM

MAXSIZE = 1000

.data
read_buffer		BYTE	MAXSIZE	DUP(?)	;buffer for the getString macro
num_buffer		DWORD	MAXSIZE DUP(?)	;buffer to hold converted number
sum_buffer		DWORD	MAXSIZE	DUP(?)	;buffer to hold the sum
avg_buffer		DWORD	MAXSIZE DUP(?)	;buffer to hold the avg
write_buffer	BYTE	MAXSIZE	DUP(?)  ;buffer to hold number converted back to string

sLength			DWORD	?
num				DWORD	?
is_negative		DWORD	?	;set to 1 if user enters '-'
sum_val			DWORD	0	;to hold value of the sum
avg_val			DWORD	?	;to hold value of rounded average

intro_1		BYTE	"Programming Assignment #6: Designing low-level I/O procedures", 0
intro_2		BYTE	"Written by: Josh Sanford", 0

instructions_1		BYTE	"Please provide 10 signed decimal integers.", 0
instructions_2		BYTE	"Each number needs to be small enough to fit inside a 32 bit register.", 0
instructions_3		BYTE	"After you have finished inputting the raw numbers I will display a list", 0
instructions_4		BYTE	"of the integers, their sum, and their average value.", 0

prompt_num		BYTE	"Please enter a signed number: ", 0
prompt_error	BYTE	"ERROR: You did not enter a signed number or your number was too big.", 0
prompt_again	BYTE	"Please try again: ", 0

num_msg		BYTE	"You entered the following numbers: ", 0
sum_msg		BYTE	"The sum of these numbers is: ", 0
avg_msg		BYTE	"The rounded average is: ", 0

goodbye		BYTE	"Thanks for playing!", 0

;formatting
neg_sign	BYTE	"-", 0
comma		BYTE	",", 0
space		BYTE	" ", 0

.code
main PROC
	displayString	OFFSET intro_1
	call	Crlf
	displayString	OFFSET intro_2
	call	Crlf
	call	Crlf
	displayString	OFFSET instructions_1
	call	Crlf
	displayString	OFFSET instructions_2
	call	Crlf
	displayString	OFFSET instructions_3
	call	Crlf
	displayString	OFFSET instructions_4
	call	Crlf
	call	Crlf
	mov		ecx, 10
	mov		edi, OFFSET num_buffer
;loop to get 10 numbers from user
getInput:
	push	ecx
	push	OFFSET prompt_again
	push	OFFSET prompt_error
	push	SIZEOF read_buffer
	push	OFFSET prompt_num
	push	OFFSET read_buffer
	push	edi
	call	ReadVal	
	pop		ecx
	add		edi, 4
	loop	getInput
	call	Crlf
	displayString	OFFSET num_msg
	call	Crlf
;loop to display numbers
	mov		ecx, 10
	mov		esi, OFFSET num_buffer
	mov		edi, OFFSET write_buffer
writeOutput:
	push	esi
	push	edi 
	call	WriteVal
	cmp		ecx, 1
	je		noComma
	displayString OFFSET comma
noComma:
	displayString OFFSET space
	add		esi, 4
	inc		edi
	loop	WriteOutput
	call	Crlf
;loop to calculate sum of numbers
	mov		ecx, 10
	mov		esi, OFFSET num_buffer
sum:
	push	esi
	push	sum_val
	call	calcSum
	mov		sum_val, eax
	add		esi, 4
	loop	sum
;print out the sum
	displayString	OFFSET sum_msg
	mov		esi, OFFSET sum_buffer
	mov		eax, sum_val
	mov		[esi], eax
	push	esi
	push	edi
	call	WriteVal
	call	Crlf
;calculate and print the average
	mov		esi, OFFSET sum_buffer
	push	esi
	call	calcAvg
	mov		avg_val, eax
	mov		eax, avg_val
	mov		[esi], eax
	displayString	OFFSET avg_msg
	push	esi
	push	edi
	call	WriteVal
;say goodbye
	call	Crlf
	call	Crlf
	displayString OFFSET goodbye
	call	Crlf
	exit	; exit to operating system
main ENDP

;*********************************************
; Procedure reads a string from user input and converts it to the numeric value
; preconditions: arrays are initialized
; postconditions: registers al, eax, ebx, ecx, edx are changed
; receives: addresses of read_buffer num_buffer, prompt_num, prompt_error 
;           and prompt_again, and value of the size of read_buffer
; returns: converted number in element pointed to in num_buffer
;*********************************************
ReadVal PROC
	push	ebp
	mov		ebp, esp
	getString	[ebp + 16], [ebp + 12], [ebp + 20]
	mov		ecx, sLength
	mov		esi, [ebp + 12]
	mov		edi, [ebp + 8]
	mov		ebx, 10
	mov		edx, 0
	mov		is_negative, 0
	cld		;set direction flag for backwards direction
load:
	lodsb	;load contents at esi into al
	movsx	eax, al
	cmp		eax, 48
	jl		checkIfSign
	cmp		eax, 57
	jg		invalidInput
	cbw
	sub		eax, 48
	mov		num, eax
	mov		eax, edx
	imul	ebx		;result is in EDX:EAX
	add		eax, num
	jo		invalidInput
	adc		edx, 0
	jnz		invalidInput
	mov		edx, eax
	loop	load
	cmp		is_negative, 1
	je		makeNegative
	jmp		store
checkIfSign:
	cmp		al, 43	;check if plus sign
	je		setPositive
	cmp		al, 45	;check if minus sign
	je		setNegative
invalidInput:
	displayString	[ebp + 24]
	call			Crlf
	mov				esi, [ebp + 12]		;move esi back to beginning of buffer
	getString		[ebp + 28], [ebp + 12], [ebp + 20]
	mov				ecx, sLength	;reset loop counter
	mov				edx, 0
	mov				is_negative, 0
	jmp				load
setNegative:
	mov		is_negative, 1		;set my Sign flag
	cmp		ecx, sLength
	jne		invalidInput
	dec		ecx
	jmp		load
setPositive:
	mov		is_negative, 0		;clear my Sign flag
	cmp		ecx, sLength
	jne		invalidInput
	dec		ecx
	jmp		load
makeNegative:
	;convert to negative
	mov		eax, 2	
	mov		ebx, edx
	cdq
	mul		ebx		
	sub		ebx, eax
	mov		edx, ebx
store:
	mov		eax, edx
	cld
	stosd	;store contents of al at edi
	jmp		quit
quit:
	;displayString	OFFSET num_buffer
	pop		ebp
	ret		24
ReadVal ENDP

;*********************************************
; Procedure converts a numeric value into a string and displays it
; to the screen
; preconditions: arrays are initialized
; postconditions: register eax is changed
; receives: address of num_buffer and write_buffer
; returns: converted string in write_buffer
;*********************************************
WriteVal PROC
	push	ebp
	mov		ebp, esp
	mov		esi, [ebp + 12]
	mov		edi, [ebp + 8]
	cld
	lodsd
	;check if negative
	test	eax, eax
	js		negative_sign
	jmp		convert
negative_sign:
	mov		num, eax
	mov		eax, 45
	stosb	
	displayString [ebp + 8]
	dec		edi
	mov		eax, num
	neg		eax
convert:
	call    NumToString
	displayString [ebp + 8]
	pop		ebp
	ret		8
WriteVal ENDP

;*********************************************
; Procedure uses recursion to break a numeric value down into
; a string
; preconditions: esi and edi hold the offsets of arrays, and
;				 numeric value is loaded into eax
; postconditions: registers eax, ebx, edx are changed
; receives: eax
; returns: converted string is stored in write_buffer
;*********************************************
NumToString PROC
	push	ebp
	mov		ebp, esp
	mov		ebx, 10
	cmp		eax, 0
	jl		recurse
	cmp		eax, 9
	jg		recurse
	jmp		base_case
recurse:	
	cdq
	idiv	ebx	;al = 76, dl = 9
				;al = 7, dl = 6
				;al = 0, dl = 7
	push	edx
	call	NumToString
	pop		edx
	add		edx, 48
	mov		eax, edx
	stosb
	jmp		quit
base_case:
	add		eax, 48
	stosb
quit:	
	pop		ebp
	ret		
NumToString	ENDP

;*********************************************
; Procedure calculates the sum of all the numbers stored in num_buffer
; preconditions: array is initialized
; postconditions: register eax is changed
; receives: address of sum_buffer and value of sum_val
; returns: the sum in eax
;*********************************************
calcSum PROC
	push	ebp
	mov		ebp, esp
	mov		esi, [ebp + 12]
	mov		ebx, [ebp + 8]
	lodsd
	add		eax, ebx
	pop		ebp
	ret		8
CalcSum ENDP

;*********************************************
; Procedure calculates the average of the numbers and
; rounds it to the nearest whole number
; preconditions: array is initialized and sum_buffer holds
;	             the calculated sum
; postconditions: registers eax, ebx, edx are changed
; receives: address of sum_buffer and value of avg_val
; returns: the rounded average in eax
;*********************************************

calcAvg PROC
	push	ebp
	mov		ebp, esp
	mov		esi, [ebp + 8]
	mov		ebx, 10
	cld
	lodsd
	cdq
	idiv	ebx
	push	eax
	push	edx
	mov		eax, ebx
	mov		ebx, 2
	cdq
	idiv	ebx
	pop		edx
	cmp		edx, eax
	jge		roundUp
	pop		eax
	jmp		quit
roundUp:
	pop		eax
	inc		eax
quit:
	pop		ebp
	ret		4
calcAvg ENDP
END main
