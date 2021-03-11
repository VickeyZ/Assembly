comment #
第3次汇编作业
键盘输入两个十进制非符号数(≤65535)，计算两数之乘积，
分别以十进制、十六进制、二进制输出结果。例如：
输入：
12345
65535
输出：
12345*65535=
809029575
3038CFC7h
0011 0000 0011 1000 1100 1111 1100 0111B
其中输入一行字符串可以通过调用int 21h的0Ah子功能实现，具体可参考教材P.216。
十六进制的输出结果若不足8位，前面需要补0凑成8位。
二进制的输出结果要分成8组，每组4位，各组之间空一格。
另外，程序中允许使用32位寄存器。
作业上传到ftp://10.71.45.100/第3次汇编作业
登录用户名及密码均为: bhhasm
作业文件命名格式：学号姓名.asm
#

.386
data segment use16
input1 db 6;内存缓冲区，input1[1]存放实际输入字符数，offset input1+2 访问首字符
       db ?
       db 6 dup(?)
input2 db 6
       db ?
       db 6 dup(?)
a      dd 0
ans    dd 0
dcm    db 10 dup(' '), 0Dh, 0Ah, '$'
hex    db 8  dup(0), 'h', 0Dh, 0Ah, '$'
bin    db "0000 0000 0000 0000 0000 0000 0000 0000B", 0Dh, 0Ah, '$' 
error  db 'Input Error', 0Dh, 0Ah, '$'
data ends

stack1 segment stack
	dw 100h dup(?)
stack1 ends

code segment use16
assume cs:code, ds:data, ss:stack1
inputerror:
   mov dx, offset error
   mov ah, 09h
   int 21h
   jmp done
main:
   mov ax, data
   mov ds, ax
   mov ah, 0Ah
   mov dx, offset input1
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov dl, 0Ah
   int 21h;传入第一串十进制数
   mov ah, 0Ah
   mov dx, offset input2
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov ah, 2
   mov dl, 0Ah
   int 21h;传入第二串十进制数
pro1:
   xor cx, cx;置0
   mov cl, input1[1];字符个数即为循环次数
   cmp cl, 5
   ja  inputerror
   mov bx, offset input1+2
print1:
   mov ah, 2
   mov dl, [bx]
   cmp dl, '0'
   jb  inputerror
   cmp dl, '9'
   ja  inputerror
   int 21h;字符逐个输出
   inc bx
   dec cx
   jnz print1
pro2:
   mov ah, 2
   mov dl, '*'
   int 21h
   xor cx, cx
   mov cl, input2[1]
   cmp cl, 5
   ja inputerror
   mov bx, offset input2+2
print2:
   mov ah, 2
   mov dl, [bx]
   cmp dl, '0'
   jb  inputerror
   cmp dl, '9'
   ja  inputerror
   int 21h
   inc bx
   dec cx
   jnz print2
pro3:
   mov ah, 2
   mov dl, '='
   int 21h
   mov ah, 2
   mov dl, 0Dh
   int 21h
   mov ah, 2
   mov dl, 0Ah
   int 21h;第一行输出
tran1:			;将第一串字符转化为十进制数
   xor eax, eax
   xor edx, edx
   mov si, offset input1+2
tran10_1:
   mov cl, [si]
   cmp cl, 0Dh;判断字符是否读取完
   je  tran2
   mov ebx, 10
   mul ebx;位数存入eax
   xor edx, edx
   mov dl, [si]
   sub dl, '0';个位数存入edx
   add eax, edx
   inc si
   jmp tran10_1
tran2:			;第二串字符
   mov a, eax;存入第一串字符的十进制值
   cmp a, 65535
   ja  inputerror
   xor eax, eax
   xor edx, edx
   mov si, offset input2+2
tran10_2:
   mov cl, [si]
   cmp cl, 0Dh
   je  tran3
   mov ebx, 10
   mul ebx
   xor edx, edx
   mov dl, [si]
   sub dl, '0'
   add eax, edx
   inc si
   jmp tran10_2
tran3:
   mov ebx, a
   mov a, eax
   cmp a, 65535
   ja inputerror
   mul ebx
   mov ans, eax;将乘法结果存入ans
   xor di, di
   xor cx, cx
decimal:
   xor edx, edx
   mov ebx, 10
   div ebx;eax=商， edx=余数
   add dl, '0'
   push dx
   inc cx
   cmp eax, 0
   jne decimal
pop_d:
   pop dx
   mov dcm[di], dl;弹出存入数组，输出
   inc di
   dec cx
   jnz pop_d
   mov ah, 9
   mov dx, offset dcm
   int 21h
   mov eax, ans
   xor di, di
   mov cx, 8
hexadecimal:
   rol eax, 4
   push eax
   and eax, 0Fh
   cmp al, 10
   jb digit
   sub al, 10
   add al, 'A'
   jmp ctn
digit:
   add al, '0'
ctn:
   mov hex[di], al
   pop eax
   inc di
   dec cx
   jnz hexadecimal
   mov ah, 9
   mov dx, offset hex
   int 21h
   mov eax, ans
   xor di, di
binary:
   cmp bin[di], 'B'
   je bin_print
   cmp bin[di], ' '
   je next
   shl eax, 1
   jnc next
   mov bin[di], '1'
   inc di
   jmp binary
next:
   inc di
   jmp binary
bin_print:
   mov ah, 9
   mov dx, offset bin
   int 21h
done:
   mov ah, 4Ch
   int 21h
code ends
end main