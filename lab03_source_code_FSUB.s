.data			#Assembler directive signaling start of data section
A: .float  2.5		#A =   2.5
B: .float 4.75		#B =  4.75
C: .float  0.0		#C = -2.25, C initialized to 0
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
xori $t6, $t6, 1	#Xor sign bit of B with 1, to add -B

sll $t1, $t1, 9		#Shift A left 9 bits, so significand << 9 in $t1
sll $t3, $t3, 9		#Shift B left 9 bits, so significand << 9 in $t3
srl $t1, $t1, 9		#A's significand in $t1
srl $t3, $t3, 9		#B's significand in $t3
lui $t4, 128		#Stores 128 << 16 = 2^23, significand min value
add $t1, $t1, $t4	#Adds hidden bit, 2^23, to A's significand
add $t3, $t3, $t4	#Adds hidden bit, 2^23, to B's significand

beq $t0, $t2, signs	#If A's exponent = B's exponent, go to signs
blt $t0, $t2, expALessThanB	#If A's exponent < B's exponent, fix it
expBLessThanA:		#Submethods to make exponents equal before adding
addi $t2, $t2, 1	#Increment B's exponent by 1
srl $t3, $t3, 1		#Shift B's significand right by 1
beq $t0, $t2, signs	#If A's exponent = B's exponent, go to signs
j expBLessThanA		#Else loop expBLessThanA
expALessThanB:
addi $t0, $t0, 1	#Increment A's exponent by 1
srl $t1, $t1, 1		#Shift A's significand right by 1
bne $t0, $t2, expALessThanB	#Loop expALessThanB while exponents unequal

signs:			#Submethod to add differently depending on signs
beq $t5, $t6, signsEq	#Skip to signsEq if A's sign = B's sign
blt $t1, $t3, sigALessThanB	#Branch if A's significand < B's
sub $t1, $t1, $t3	#Subtract B's significand from A's, store in $t1
j exps			#Jump to the next segment of the program, exponents
sigALessThanB:		#A's significand < B's
sub $t1, $t3, $t1	#Subtract A's significand from B's, store in $t1
addi $t5, $t6, 0	#Sign bit of result is in $t5
j exps			#Jump to the next segment of the program, exponents
signsEq:
add $t1, $t1, $t3	#Add significands of A and B together, store in $t1

exps:			#Submethod to normalize exponents
lui $t6, 255		#Stores 255 << 16 = 2^23 + 2^22 + ... + 2^16
ori $t6, $t6, 65535	#Adds 2^16 - 1 to 255 << 16 to get max significand
addi $t7, $zero, 254	#Stores 254, the max number stored as an exponent
beq $t1, $zero, zero	#If significand is zero, go to zero
blt $t1, $t4, expDecr	#If significand < normalized min, decrease exponent
blt $t6, $t1, expIncr	#If normalized max < significand, increase exponent
j retFP			#Else jump to retFP

expDecr:
addi $t0, $t0, -1	#Subtract 1 from exponent
beq $t0, $zero, underflow	#If exponent = 0, go to underflow
sll $t1, $t1, 1		#Multiply significand by 2
blt $t1, $t4, expDecr	#If significand < normalized min, decrease exponent
j retFP			#Else jump to retFP

expIncr:
addi $t0, $t0, 1	#Add 1 to exponent
blt $t7, $t0, overflow	#If normalized max < exponent, go to overflow
srl $t1, $t1, 1		#Divide significand by 2
blt $t6, $t1, expIncr	#If normalized min < significand, increase exponent
j retFP			#Else jump to retFP

underflow:		#Underflow returns zero.
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