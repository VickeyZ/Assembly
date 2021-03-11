data segment
s db 100 dup(0),0Dh,0Ah,'$'
t db 100 dup(0),0Dh,0Ah,'$'
data ends

code segment
assume cs:code, ds:data
main:
   mov ax, data
   mov ds, ax
   mov si, 0;initial the array index
   mov di, 0
input:
   add si, 1
   mov ah, 1
   int 21h
   mov s[si], al; input chars and store in s
   cmp s[si], 0Dh
   jnz input
   mov si, 0
judge:
   add si, 1
   cmp s[si], 0Dh
   je endcase
   cmp s[si], 'a';compare with letter a
   jb if_space
   cmp s[si], 'z';judge whether lowercase
   jbe lowercase
   jmp othercase
if_space:
   cmp s[si], ' ';judge whether space
   je spacecase
othercase:
   mov cx, s[si]
   mov t[di], cx
   add di, 1
   jmp judge
spacecase:
   jmp judge
lowercase:
   sub s[si], 20h
   mov cx, s[si]
   mov t[di], cx
   add di, 1
   jmp judge
endcase:
   mov cx, di;save the number of elements
   mov di, 0
output:
   cmp di, cx
   je exit;break the loop and exit
   mov dl, t[di]
   add di, 1
   mov ah, 2
   int 21h 
   jmp output
exit:
   mov ah, 4Ch
   int 21h
code ends
end main




