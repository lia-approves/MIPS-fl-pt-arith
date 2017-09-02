.data			#Assembler directive signaling start of data section
A: .float 12.0		#A = 12.0
B: .float 0.25		#B = 0.25
C: .float  0.0		#C =  3.0, initialized to 0
.text			#Assembler directive signaling start of text section
main:
la $a0, A		#Load address of A into $a0
la $a1, B		#Load address of B into $a1
lw $t0, 0($a0) 		#Load value of A into $t0, to be A's exponent
addi $t1, $t0, 0	#Copy A into $t1, to be A's significand
lw $t2, 0($a1)		#Load value of B into $t2, to be B's exponent
addi $t3, $t2, 0	#Copy B into $t3, to be B's significand
sll $t5, $t0, 1		#Shift A left 1 bit, then right 24 to get rid of the
srl $t0, $t5, 24	#sign bit and significand, so exponent in $t0
srl $t5, $t5, 1		#Shift $t5 right one bit to get the abs val of A
slt $t5, $t1, $t5	#Store sign bit of A in $t5

sll $t6, $t2, 1		#Shift B left 1 bit, then right 24 to get rid of the
srl $t2, $t6, 24	#sign bit and significand, so exponent in $t2
srl $t6, $t6, 1		#Shift $t6 right one bit to get the abs val of B
slt $t6, $t3, $t6	#Store sign bit of B in $t6

addi $t9, $zero, 254	#Stores 254, the max number stored as an exponent
add $t0, $t0, $t2	#Add exponents together to get sum plus 2*bias
addi $t0, $t0, -127	#Subtract bias from exponents to get sum plus bias
blt $t0, $zero, underflow #If exponent < 0, go to underflow
blt $t9, $t0, overflow	#If 254 < exponent, go to overflow

xor $t5, $t5, $t6	#Xor the sign bits to get the sign of the product

sll $t1, $t1, 9		#Shift A left 9 bits, so significand << 9 in $t1
sll $t3, $t3, 9		#Shift B left 9 bits, so significand << 9 in $t3
srl $t1, $t1, 9		#A's significand in $t1
srl $t3, $t3, 9		#B's significand in $t3
lui $t4, 128		#Stores 128 << 16 = 2^23
add $t1, $t1, $t4	#Adds hidden bit, 2^23, to A's significand
add $t3, $t3, $t4	#Adds hidden bit, 2^23, to B's significand

multu $t1, $t3		#Integer multiplication of significands
mfhi $t2		#Move upper 32 bits of product to $t2
mflo $t3		#Move lower 32 bits of product to $t3

srl $t7, $t2, 15	#Store 48th lowest bit from 64 bit product
blt $t7, $zero, norm	#If that bit is 1, need to normalize exp
j retFP			#Jump to retFP

norm:
beq $t0, $t9, overflow	#If exponent = 254, go to overflow
addi $t0, $t0, 1	#Increment exponent by 1
sll $t2, $t2, 8		#Shift leftmost bit from 16 to 24
srl $t3, $t3, 24	#Get upper 8 bits of lower product, right-aligned
or $t1, $t2, $t3	#Concatenate the significands and store in $t1
j retFP			#Jump to retFP

underflow:		#Underflow returns zero
zero:		
j end			#Go to end

overflow:
addi $t0, $zero, 255	#Set exponent, stored in $t0, to 255 for infinity
add $t1, $zero, $zero	#Set significand, stored in $t1, to 0 for infinity

retFP:			#Submethod to assemble the FP number and return
sll $t9, $t5, 31	#Shift sign bit left by 31, store in $t9
sll $t0, $t0, 23	#Shift exponent left by 23
or $t9, $t9, $t0	#Concatenate sign bit and exponent, store in $t9
addi $t4, $t4, -1	#Subtract 1 from 2^23 to get a bitmask of 22 1's
and $t1, $t1, $t4	#Apply bitmask to significand
or $t9, $t9, $t1	#Concatenate significand to floating point number
sw $t9, C		#Store result from $t9 to C

end:
li $v0, 2		#Code to print to console
l.s $f12, C
syscall
li $v0, 10
syscall