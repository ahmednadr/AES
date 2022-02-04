org 100h
equate MACRO array,temp                 ;array = temp
   mov si,temp                          ;set temp offset to si
   mov di,array                         ;set array offset to di
   mov cx,18                            ;count 18 ->16 data and 2
equal:mov bl,[si]                       ;switch and increment
      mov [di],bl
      inc si
      inc di 
      loop equal
endm
ffmul MACRO mixbyte,arraybyte,polyirreducable ;finite field multiplication
   local two
   local three 
   local nd
   local modulo
   local thm
    mov bh,mixbyte                ;load the byte from the mix matrix to bh
    mov bl,arraybyte              ;load the byte from array to bl
    cmp bh,03h                    ;check if mix mat byte is 3 or 2
    jz three
    cmp bh,02h
    jz two   
    jmp nd
   two:shl bl,1                   ;if two then shift 1 to left and if carry ->modulo
       jc modulo 
       jmp nd
   modulo:xor bl,polyirreducable  ;xor with irreducable polynomial of the finite field
          jmp nd  
   three:mov ah,arraybyte         ;if three then xor with if two
         shl bl,1
         jc thm 
         xor bl,ah 
         jmp nd  
   thm: xor bl,polyirreducable
        xor bl,ah 
        jmp nd 
   nd:mov arraybyte,bl             ;return byte to array
        endm  
mixcolumns macro                   ;mix matrix and array
    local hi
    mov cx,4                       ;loop for 4 columns
    mov ax,0                       ;counter for the columns
 hi:push cx                        ;push the cx and ax to stack to keep track of current values 
    push ax
    helpcolumn ax                  ;call helper macro
    inc ax                         ;inc the counter to move to next column
    loop hi     
endm
helpcolumn macro c 
    add array,2                          ;first two bytes 16,?
    add temp,2
    mov cx,4                             ;set loop to 4 as 4 bytes in each column
    mov di,0                             ;indexing the mix matrix
    mov dx,0                             ;helps in setting the right indexing values for the 4 bytes in each column
    mov si,c                             ;si=4c for the first element in every column
    add si,c  
    add si,c
    add si,c
    jmp h
       h:mov ah,array[si]                 
        ffmul mixmat[di],ah,polyirreducable ;calling the ffmul macro to multiply according to the arithmitics of the finite field
        push di                             ;save the mix matrix indexing as we will use di to index something else
        mov di,dx
        add di,2
        add di,si
        add di,cx                        ;calculate the location of the byte that's been calculated
        mov al,temp[di-4]                ;we get the total value for the xor opperations so far 
        xor al,ah                        ;we xor the new value from the multiplication with the old total 
        mov temp[di-4],al                ;we put the new total value back to our temp array
        pop di                           ;pop back the di as the value for the mix matrix indexing 
        add di,4                         ;add 4 to move to the next element in the row (mix matrix)
        inc si                           ;inc si as to get the next element in the column of the array
        loop h                           ;loop for 4 time to pass by all 4 elements in a column
        jmp nexti
nexti:inc dx                             ;inc dx to move to the next row in the mix matrix
      mov di,dx
      mov cx,4                           ;set loop to 4 as 4 bytes in each column
      cmp di,4                           ;only 4 rows in the matrix
      jnz h                              ;jmp back to the loop
      pop ax                             ;pop back the value used by the other macro
      pop cx
endm      
shiftrows MACRO array  
    local shift
    local nd
       mov di,array                      ;move array ofset to di for indexing
       add di,3                          ;add 3 to start from row 2
       mov ax,1                          ;ax is the number of shift loop to do ex: 1 for row 2 and 2 for row 3
       mov cx,ax                         ;mov ax to cx for loop counter
       jmp shift
  setdi:mov di,ax                        ;the index is equal to the number of shifts plus one and plus another two for the 16,?
        add di,3 
        jmp shift
  shift:mov dl,[di]                      ;save the first byte to be put later in last 
        helpshift di                     ;all shift to left and first put in last
        add di,4                         ;add 4 to get next element in the row
        helpshift di
        add di,4
        helpshift di
        add di,4
        mov [di],dl                      ;put the first byte in the last position
        mov di,ax                        ;the index is equal to the number of shifts plus one and plus another two for the 16,?
        add di,3 
        loop shift
        inc ax                           ;max ax is 3 shifts
        mov cx ,ax
        cmp cx,4
        jz nd 
        jmp setdi
        jmp shift
nd:         
endm   
helpshift macro array
        mov si,array
        add si,4                         ;overwrite a byte with the next one in the row
        mov bl,[si]
        mov [array],bl 
endm  
addkey MACRO                
   mov si,0                          
   mov cx,16                            ;xo the array byte with the corresponding key byte
equal1:MOV AL,array[SI+2]               ;+2 for the 16,?
      MOV AH,key[SI]
      XOR AL,AH
      MOV array[SI+2],AL 
      inc si
      loop equal1
endm
.data segment 
    sbox DB 063H,07cH,077H,07bH,0f2H,06bH,06fH,0c5H,030H,001H,067H,02bH,0feH,0d7H,0abH,076H ;s-box
         DB 0caH,082H,0c9H,07dH,0faH,059H,047H,0f0H,0adH,0d4H,0a2H,0afH,09cH,0a4H,072H,0c0H
         DB 0b7H,0fdH,093H,026H,036H,03fH,0f7H,0ccH,034H,0a5H,0e5H,0f1H,071H,0d8H,031H,015H
         DB 004H,0c7H,023H,0c3H,018H,096H,005H,09aH,007H,012H,080H,0e2H,0ebH,027H,0b2H,075H
         DB 009H,083H,02cH,01aH,01bH,06eH,05aH,0a0H,052H,03bH,0d6H,0b3H,029H,0e3H,02fH,084H
         DB 053H,0d1H,000H,0edH,020H,0fcH,0b1H,05bH,06aH,0cbH,0beH,039H,04aH,04cH,058H,0cfH
         DB 0d0H,0efH,0aaH,0fbH,043H,04dH,033H,085H,045H,0f9H,002H,07fH,050H,03cH,09fH,0a8H
         DB 051H,0a3H,040H,08fH,092H,09dH,038H,0f5H,0bcH,0b6H,0daH,021H,010H,0ffH,0f3H,0d2H
         DB 0cdH,00cH,013H,0ecH,05fH,097H,044H,017H,0c4H,0a7H,07eH,03dH,064H,05dH,019H,073H
         DB 060H,081H,04fH,0dcH,022H,02aH,090H,088H,046H,0eeH,0b8H,014H,0deH,05eH,00bH,0dbH
         DB 0e0H,032H,03aH,00aH,049H,006H,024H,05cH,0c2H,0d3H,0acH,062H,091H,095H,0e4H,079H
         DB 0e7H,0c8H,037H,06dH,08dH,0d5H,04eH,0a9H,06cH,056H,0f4H,0eaH,065H,07aH,0aeH,008H
         DB 0baH,078H,025H,02eH,01cH,0a6H,0b4H,0c6H,0e8H,0ddH,074H,01fH,04bH,0bdH,08bH,08aH
         DB 070H,03eH,0b5H,066H,048H,003H,0f6H,00eH,061H,035H,057H,0b9H,086H,0c1H,01dH,09eH
         DB 0e1H,0f8H,098H,011H,069H,0d9H,08eH,094H,09bH,01eH,087H,0e9H,0ceH,055H,028H,0dfH
         DB 08cH,0a1H,089H,00dH,0bfH,0e6H,042H,068H,041H,099H,02dH,00fH,0b0H,054H,0bbH,016H 
    array db 16,?,16 DUP (?)                                                               ;user input
    temp db 16,?,16 DUP (0)                                                                 ;temporary array 
    mixmat db 02h,01h,01h,03h,03h,02h,01h,01h,01h,03h,02h,01h,01h,01h,03h,02h               ;mix matrix                
    polyirreducable db 01Bh                                                               ;inreducable polynomial for moudlo 
    key DB 02bH,028H,0abH,09H
        DB 07eH,0aeH,0F7H,0cfH
        DB 015H,0d2H,015H,04fH
        DB 016H,0a6H,088H,03cH   
.code segment 
     call input
     call subbyte 
     mov ax,offset array
     shiftrows ax
     mixcolumns
     mov ax,offset temp
     mov bx,offset temp
     equate ax,bx
     addkey
     mov array[17],"$" 
     call output 
     mov ax,offset array  
ret   
input  proc                 ;input function
     mov ah,0Ah
    mov dx,offset array
    int 21h
    ret
endp  
asciiconvert proc
    mov cx ,16
  p:mov ah,array[di]
    and ah,0fh             
    mov array[di],ah 
    inc di
    loop p
    ret
endp
SubByte PROC  
    mov si,2 
    mov cx,16               ;loop 16 times for 16 bytes
  r:mov ah,array[si]
    and al,00FH             ;seperate lower half and upper half of byte
    and ah,0F0H
    ror ah,04               ;rotate 4 times toso we can add the lower adn upper halves together
    sal ah,4                ;ex: 10100011 rotate 4 times to get 00111010 then     
    add al,ah               ;shift left 4 times to get 10100000 than can directly be added to the other half (to be fair i copied these two lines of code but i understand them)    
    mov ah,0                    
    mov di,ax               ;add then move to di to get the corresponding s box value    
    mov ah,sbox[di]             
    mov array[si],ah
    inc si
    loop r 
    ret
ENDP 
output  proc                 ;output function
     mov ah,09h
    mov dx,offset array+2
    int 21h
    ret
endp 