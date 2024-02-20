# $t6 userinput   
.data
.align 2        # Align the data segment to a word boundary
fin: .asciiz "Calendar.txt"
.align 2        # Align the data segment to a word boundary
temp: .space 100   # Assuming a maximum of 256 characters for the file names
buffer: .space 1024
line: .space 10240 #line without spaces to consume it
copy_line: .space 10240  # Buffer for the copied line (with spaces) to print it 
alllines: .space 1000240  # to store all lines to a file
lectures_msg:   .asciiz " Total Lectures Hours: "
oh_msg:         .asciiz " Total Office Hours: "
meetings_msg:   .asciiz " Total Meetings Hours: "
avg_msg:  .asciiz " Average lectures per day: "
ratio_msg:  .asciiz " Ratio between total number of hours reserved for lectures and Office Hour : "
menu: .asciiz "\n *** Welcome to Monthly Calendar Application ***\n\n1)View the calendar\n2)View Statistics\n3)Add a new appointment\n4)Delete an appointment\n5)Exit\n If there is any problem press enter again please \n\n"
ViewCalendarOptions: .asciiz "Please choose one of the following:\n1)View Per Day\n2)view Per Set of Days\n3)view for Given Slot\n"
numOfDaysInput: .asciiz "How many days would you like to view?\n"
daynumber: .asciiz " enter day number(1-31) : "
slottype: .asciiz  " enter slot type O/M/L : "
Endtime: .asciiz  " enter end time : "
Starttime: .asciiz  " enter start time : "
matchedline: .asciiz  "  The new appointment added correctly:  try to find the new file or view the calender again"
conflict: .asciiz  "the appointment already esixit in this day "
tryAgain: .asciiz "Try Again\n"
promptAppointment:     .asciiz "Enter the Appointment you want to delete (M, L, O): \n"



.globl main
numoflinesread: .word 0
sumL: .word 0 
sumOH: .word 0 
sumM: .word 0 
ratio: .float 0.0
avg:  .float 0.0
addcounter: .word 0 # to check if i  read the info before
newstarttime: .word 0
newendtime: .word 0
newslottype: .space 2
newdaynmber: .word 0
conflict_checker: .float  0.0 # To complete writing the lines without check for conflict again # 1 continue without check in $f0
one_float: .float 1.0
zero_float: .float 0.0



.text
	main:
		
   l.s $f0, zero_float
	  # Display Main Menu	
 jal DisplayMainMenu
     la $a3,alllines            
 
read_option:	  
   # Get User input 
   li $v0, 5
   syscall
   move $t6, $v0
  beq $t6 , 1,start
  beq $t6 , 2,start
  beq $t6 , 3,start
  beq $t6 , 4,start
  beq $t6 , 5,start

   j read_option
start:
  beq $t6, 1, viewCalendar 
	  	  	  
    la $s1 buffer
    la $s2 line
    li $s3 0      # current line length
    li $t9 0      # number of lines read
    
    

    # open file for reading
    li $v0 13     # syscall for open file
    la $a0 fin    # input file name
    li $a1 0      # read flag
    li $a2 0      # ignore mode 
    syscall       # open file 
    move $s0 $v0  # save the file descriptor 
    


  beq $t6, 4, DeleteAppointment

reading_loop:
    # read byte from file
    li $v0 14     # syscall for read file
    move $a0 $s0  # file descriptor 
    move $a1 $s1  # address of dest buffer
    li $a2 1      # buffer length
    syscall       # read byte from file

    # keep reading until bytes read <= 0
  blez $v0 read_done

    # naively handle exceeding line size by exiting
    slti $t0 $s3 1024
  beqz $t0 read_done


    # if current byte is a newline, consume line
    lb $s4 ($s1)
    li $t0 10
  beq $s4 $t0 consume_line
  


    # otherwise, append byte to line
    add $s5 $s3 $s2
    sb $s4 ($s5)

    # increment line length
    addi $s3 $s3 1
   

b reading_loop

	#finish reading the whole line
#///////////////////////////////////////////////
consume_line:


    # increment number of lines read

    lw $t9,numoflinesread
    add  $t9,$t9,1
    sw $t9,numoflinesread
    
        # null terminate line
    add $s5 $s3 $s2
    sb $zero ($s5)
    
    


#_______________________________________________

  # Copy the line to a new buffer
   la $t8, ($s2)           # $t8 points to the beginning of the original line
   la $t9, copy_line         # $t9 points to the beginning of the new buffer

   copy_line_loop:
      lb $t0, 0($t8)        # Load a byte from the original line
      beqz $t0, done_copy   # If null-terminator is reached, exit loop

      sb $t0, 0($t9)        # Store the byte in the new buffer
      addi $t8, $t8, 1      # Move to the next byte in the original line
      addi $t9, $t9, 1      # Move to the next position in the new buffer
     

      j copy_line_loop      # Repeat the loop

   done_copy:
       # Null terminate the COPY line
    sb $zero, 0($t9)
    addi $t9,$t9,1
  
 

#__________________________________________________


    # Remove white spaces from the line
    la $t8, ($s2)  # $t8 points to the beginning of the line
    la $t9, ($s2)  # $t9 is used for writing back the modified line
remove_spaces_loop:
    lb $t0, 0($t8)         # Load a byte from the line
  beqz $t0, add_comma_and_remove_spaces  # If null-terminator is reached, exit loop

    # Check if the current byte is not a white space (ASCII 32 for space)
  beq $t0, 32, skip_space
    sb $t0, 0($t9)         # Store the non-white space byte in the modified line
    addi $t9, $t9, 1       # Move to the next position in the modified line

skip_space:
    addi $t8, $t8, 1       # Move to the next byte in the original line
j  remove_spaces_loop   # Repeat the loop

add_comma_and_remove_spaces:


    # Null terminate the modified line
    sb $zero, 0($t9)


    
      # Branch to the functionality chosen

 	beq $t6, 2, ViewStatistics
  	beq $t6, 3, addAppointment
 	beq $t6, 4, DeleteAppointment
  	beq $t6, 5, ExitProgram






#******************************************************************************************
   read_done:

    # close file
    	li $v0, 16     # syscall for close file
    	move $a0, $s0  # file descriptor to close
    	syscall       # close file
    
    
  j printresult


	#start again 
   return:
	sw  $zero,addcounter # to allow user to add new appointment
	sw  $zero,numoflinesread # to start count from 0 

	j main 

             
  ExitProgram:
    	# exit the program
    	li $v0, 10
    	syscall
  

   DisplayMainMenu:
    	li $v0, 4
    	la $a0, menu
    	syscall
    	jr $ra
#------------------------------------------------->    Option 2: Statistics   #---------------------------------------------------------------------> 


ViewStatistics:
    la $t0, ($s2)

process_parts:

    lb $t8, 0($t0)
    beqz $t8, read_loop  # If null-terminator is reached, exit loop

    # Check if the current character is a comma (`,`)
    beq $t8,',', foudnacomma   
    beq $t8,':', foudnacomma

    add $t0,$t0,1
    j process_parts
  
foudnacomma:

la $t5,($t0)

starttime:
    # Calculate start time
    add $t5,$t5,1
    lb $t4, 0($t5)
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    move $t2, $t4
    
    add $t5,$t5,1
    lb $t4, 0($t5)
    beq $t4, '-', endtime
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    mul $t2, $t2, 10
    add $t2, $t2, $t4
    add $t5,$t5,1


endtime:
    add $t5,$t5,1
    lb $t4, 0($t5)
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    move $t3, $t4
 
    add $t5,$t5,1
    lb $t4, 0($t5)
    beq $t4, 'O',update_office_hours
    beq $t4, 'M',update_meetings
    beq $t4, 'L',update_lectures
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    mul $t3, $t3, 10
    add $t3, $t3, $t4


 optype:
    add $t5,$t5,1
    lb $t4, 0($t5)
   # Update counters based on appointment type
 beq $t4, 'L', update_lectures
 beq $t4, 'O', update_office_hours
 beq $t4, 'M', update_meetings   
          
 
         # Update functions
update_lectures:

   lw $t7,sumL
   sub $t4,$t3,$t2
   bgt $t2,$t3,grater
fgtarter:
   add $t7,$t7,$t4
   sw $t7,sumL
   		
j finish1
grater:
   addi  $t4,$t4,12  # 3-10 ->10 -3 = 7 / 10-3 -> 3-10=-7 ,-7+12= 5 
    	
j fgtarter
   
update_office_hours:

   lw $t7,sumOH
   sub $t4,$t3,$t2
   bgt $t2,$t3,grater2
 fgtarter2:
   add $t7,$t7,$t4
   sw $t7,sumOH 
           
 j finish1
         
grater2:
   addi  $t4,$t4,12
j fgtarter2
   

     update_meetings:

    	lw $t7,sumM
   	sub $t4,$t3,$t2
    	bgt $t2,$t3,grater3
    fgtarter3:
    	add $t7,$t7,$t4
    	sw $t7,sumM
	j finish1                 
    grater3:
    	addi  $t4,$t4,12
    j fgtarter3
   
   
    finish1:  
    	add $t0,$t0,1
    j process_parts
    
    avgratio:
    	 
     # ratio= TL/TOH
     lw $t0, sumL
    lw $t1, sumOH
    # Convert to floating-point values
    mtc1 $t0, $f2
    mtc1 $t1, $f4
   # Calculate Floating Ratio (TL / TO)
    div.s $f6, $f2, $f4  # $f6 = $f2 / $f4
    
    #avg = totl L / numofdays
    
        lw $t0, sumL
        lw $t9,numoflinesread
        mtc1 $t9,$f16 # $t9 = # of lines =31
        mtc1 $t0, $f18     
        div.s $f8, $f18, $f16  
    

j finishavgratio
 

#------------------------------------------------->    Option 3: ADD   #---------------------------------------------------------------------> 

 
    addAppointment:
    
   # if 0 go to read day slot type 
   lw $s5,addcounter 
   beqz  $s5,readaddinput
   # if one just chek 
   

   
    l.s $f10, zero_float
    c.eq.s $f0,$f10   # Compare $f0 with 0.0
    bc1t ch    # Branch to equal_label if the comparison is true
    j read_loop
   
ch:
finishreading_add:

 # $t2#day


              
    lb $t7, 0($s2)       # load the first character from the line buffer 
    lw $t9,numoflinesread
    sub $t7, $t7, 48  # Subtract ASCII value of '0'
    
      # Check if the counter is less than 10
    #li $s6, 10           # Set the threshold for the counter
    blt $t9, 10, lessthan10
    # If the counter is greater than or equal to 10, load the second character
    lb $t9, 1($s2)       # load the first character from the line buffer
    sub $t9, $t9, 48  # Subtract ASCII value of '0'
    mul $t7, $t7, 10
    add $t7, $t7, $t9
    beq $t7,$t2,day_matched
     j read_loop  # to check another day

lessthan10:  

    beq $t7,$t2,day_matched
              j read_loop 
              

                                       
                                                                      
day_matched: 
 #---------------------------                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     
  # $t3 #startnew
  # $s6 #endnew
  # $t8 startnow   
  # $t1    endnow  
  
      la $t7,($s2)                
    process_parts2:

    lb $t0, 0($t7)
    beqz $t0,addnewappointment # If null-terminator is reached, exit loop                                
     # Check if the current character is a comma (`,`)
    beq $t0,',', foudnacomma2   
    beq $t0,':', foudnacomma2

    add $t7,$t7,1
    j process_parts2           
    
  foudnacomma2:
 la $t5,($t7)                
    # check start time
    add $t5,$t5,1
    lb $t4, 0($t5)
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    move $t8, $t4
    
    add $t5,$t5,1
    lb $t4, 0($t5)
    beq $t4, '-', endtime2
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    mul $t8, $t8, 10
    add $t8, $t8, $t4
    add $t5,$t5,1               
                                                                                                                                    
     endtime2:          
    add $t5,$t5,1
    lb $t4, 0($t5)
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    move $t1, $t4
    add $t5,$t5,1
    lb $t4, 0($t5)
    beq $t4, 'O',conver24hours
    beq $t4, 'M',conver24hours
    beq $t4, 'L',conver24hours
    sub $t4, $t4, 48  # Subtract ASCII value of '0'
    mul $t1, $t1, 10
    add $t1, $t1, $t4

                                                                                                                                                                                                                                                                                                                                                                                                                    
conver24hours:

	beq $t8, 1 Convert24HrClockt8
    	beq $t8, 2 Convert24HrClockt8
    	beq $t8, 3 Convert24HrClockt8
    	beq $t8, 4 Convert24HrClockt8
    	beq $t8, 5 Convert24HrClockt8
    	finshConvert24HrClockt8:
	beq $t1, 1 Convert24HrClockt1
    	beq $t1, 2 Convert24HrClockt1
    	beq $t1, 3 Convert24HrClockt1
    	beq $t1, 4 Convert24HrClockt1
    	beq $t1, 5 Convert24HrClockt1
    	finshConvert24HrClockt1:	
      j check_conflict    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
     
     
     Convert24HrClockt8:
	addi $t8, $t8, 12
     j finshConvert24HrClockt8
     Convert24HrClockt1:
     addi $t1, $t1, 12
     j finshConvert24HrClockt1   
   #convert to 24 hours 
        
       check_conflict:                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
        # Check for conflict
        bge $t3, $t1, no_conflict    # If start time of new appointment is after or equal to the end time of the existing appointment, no conflict
        ble $s6, $t8, no_conflict    # If end time of new appointment is before or equal to the start time of the existing appointment, no conflict


        # Conflict detected
	j cantaddnewappo

     no_conflict:
       #can add new appo
      add $t7,$t7,1
      j process_parts2                                     

 #----------------------------   
                                          
   addnewappointment:  

     l.s $f0, conflict_checker
    l.s $f1, one_float
    add.s $f0, $f0, $f1
 
   li $v0, 4         # System call for print string
   la $a0, matchedline
   syscall 
   li $a0, 10
   li $v0, 11    # print newline
   syscall
#***************************************************************************** 
        la $t7,copy_line 
            move $t0, $zero               
    process_parts3:

	addi $t0,$t0,1
    beq $t0,$s3,gotit # If LAST BYTE IN THE LINE is reached, exit loop                                

    add $t7,$t7,1
    j process_parts3      
    #add the new appoinmtent       
gotit:                
   #     subi $t7, $t7,1 #  subi $t7, $t7,1  ->7SAB EL MZAJ
        li $t0, 44
        sb $t0, 0($t7)      # store ,
    
        addi $t7, $t7, 1   
        li $t0, 32
        sb $t0, 0($t7)      # store ' '
    
        addi $t7, $t7, 1   
   	lb $t0, newstarttime  #store start time 
   	
   	
   	li $t2, 10
	blt $t0, $t2, Singledigit ##(10-11-12)
		
   	div $t0,$t0,$10 #-> 12/10 = 1.2 1 =q , 2=R	
   	mflo $t0             # Move the remainder from hi register to $t2
   	addi $t0 $t0 '0'                        
     	sb $t0 , 0($t7)   	    
	addi $t7, $t7, 1   
        mfhi $t0             # Move the qoutien from low register to $t2
        addi $t0 $t0 '0'                        
     	sb $t0 , 0($t7)  	
     	addi $s3,$s3,2                                   	    
	j cont
Singledigit:   	
	addi $t0 $t0 '0'
    	sb $t0 , 0($t7) 
    	addi $s3,$s3,1                                 

cont:    	 
                              
    	
	addi $t7, $t7, 1   
        li $t0, 45
        sb $t0, 0($t7)      # store '-'
    
    
     	addi $t7, $t7, 1   
   	lb $t0, newendtime 
   	
   	
   	li $t2, 10
	blt $t0, $t2, Singledigit2 #(10-11-12)
		
   	div $t0,$t0,$10 #-> 12/10 = 1.2 1 =q , 2=R	
   	mflo $t0             # Move the remainder from hi register to $t2
   	addi $t0 $t0 '0'                        
     	sb $t0 , 0($t7)   	    
	addi $t7, $t7, 1   
        mfhi $t0             # Move the qoutien from low register to $t2
        addi $t0 $t0 '0'                        
     	sb $t0 , 0($t7) 
     	 	
     	addi $s3,$s3,2                                   	    
	j cont2
Singledigit2:   	
        addi $t0 $t0 '0'                        
     	sb $t0 , 0($t7)    #store end time
     	addi $s3,$s3,1                                 
   cont2:   	
  	
     	addi $t7, $t7, 1   
        li $t0, 32
        sb $t0, 0($t7)      # store ' '
        
        addi $t7, $t7, 1   
   	lb $t0, newslottype                         
     	sb $t0 , 0($t7)    #add slottype
     	
                                       
     	addi $t7, $t7, 1                        
     	li $t0,10 
     	sb $t0 , 0($t7) #store '\n' 
                                                                                                                                                                                                     
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
     addi $s3,$s3,5 #      addi $s3,$s3,4                            
  #***********************************************************************                                                 
 j read_loop
     
                                                                                 
cantaddnewappo:

# the appointment already exisit
   li $v0, 4         # System call for print string
   la $a0, conflict
   syscall 

    la $a0, ($s2)  
    li $v0, 4
    syscall
    li $a0, 10
    li $v0, 11    # print newline
    syscall
        
   
    j read_done
    
  #----------------------------------------------------------- 
readaddinput:

 read_day_again:
    li $v0, 4         # System call for print string
    la $a0, daynumber
    syscall
   li $v0, 5
   syscall
   move $t2, $v0 
    blt $t2, 1, read_day_again   # Check if day number is less than 1
    bgt $t2, 31, read_day_again  # Check if day number is greater than 31
    sw $t2, newdaynmber
    
   read_start_again:  
  
    li $v0, 4         # System call for print string
   la $a0, Starttime
   syscall
   li $v0, 5
   syscall
   move $t3, $v0
   sw $t3,newstarttime
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             

	beq $t3, 1 Convert24HrClockt3
    	beq $t3, 2 Convert24HrClockt3
    	beq $t3, 3 Convert24HrClockt3
    	beq $t3, 4 Convert24HrClockt3
    	beq $t3, 5 Convert24HrClockt3
    	j finshConvert24HrClockt3
    	
    	Convert24HrClockt3:
	addi $t3, $t3, 12

  finshConvert24HrClockt3:  	
    blt $t3, 8,read_start_again    # Check if start time is less than 8
    bge $t3, 17,read_start_again    # Check if start time is greater than 17

   
    read_end_again:      
   li $v0, 4         # System call for print string
   la $a0, Endtime
   syscall
   li $v0, 5
   syscall
   move $s6, $v0
   sw $s6,newendtime

	beq $s6, 1 Convert24HrClocks6
    	beq $s6, 2 Convert24HrClocks6
    	beq $s6, 3 Convert24HrClocks6
    	beq $s6, 4 Convert24HrClocks6
    	beq $s6, 5 Convert24HrClocks6
    	j finshConvert24HrClocks6
    	
    	Convert24HrClocks6:
	addi $s6, $s6, 12

  finshConvert24HrClocks6:  	 
   
    blt $s6, 8,read_end_again    # Check if start time is less than 8
    bgt $s6, 17,read_end_again    # Check if start time is greater than 17
    beq  $s6, $t3,read_end_again    # Check if start time is greater than 17

   
    readslotagain:   
    li $v0, 4         # System call for print string
   la $a0, slottype
   syscall
   li $v0,12 #read string #12 for char
   syscall
   move $t5, $v0
   beq $t5 , 'L',donereading
   beq $t5 , 'O',donereading
   beq $t5 , 'M',donereading

   j readslotagain
    donereading:
   sw $t5,newslottype
   
    li $a0 10
    li $v0,11 
     syscall
   
   li  $t7,1
   sw  $t7,addcounter # to prevent adding new slot until the loop_readinig finish
   
   
      j finishreading_add   
      

    
 #------------------------------------------------------------------------------------------------------------------------------------------------   
printresult:
    
 
  beq $t6, 1, return
  beq $t6, 2, printStatistics
  beq $t6, 3, goaddtofile
  beq $t6, 4, goaddtofile

#---------------------------------------------------------
 printStatistics:  
    j avgratio 
   finishavgratio:
    li $v0, 4         # System call for print string
    la $a0,lectures_msg
    syscall
    lw $a0, sumL
    li $v0, 1
    syscall
    li $a0 10
    li $v0,11 
     syscall
    
    li $v0, 4         # System call for print string
    la $a0, oh_msg
    syscall
    lw $a0, sumOH
    li $v0, 1
    syscall
    li $a0 10
    li $v0,11 
    syscall
    
    li $v0, 4         # System call for print string
    la $a0, meetings_msg
    syscall
    lw $a0, sumM
    li $v0, 1
    syscall
    li $a0 10
    li $v0,11 
    syscall
    
    li $v0, 4
    la $a0, ratio_msg
    syscall
    li $v0, 2
    mov.s $f12, $f6
    syscall
    li $a0 10
    li $v0,11 
    syscall
    
      
    li $v0, 4
    la $a0, avg_msg
    syscall
    li $v0, 2
    mov.s $f12, $f8
    syscall 
      li $a0 10
    li $v0,11 
     syscall 
   
   # If we want to print it again
    sw $zero,sumL
    sw $zero,sumM  
    sw $zero,sumOH
    sw $zero,ratio
    sw $zero,avg
      
 j return
    #-----------------------------------------------------
    goaddtofile:
    
    
    	# if there was a conflict don't chnge the file name 
 	#change the files name .le the input file = outputfile
 
 	l.s $f10, one_float
 	c.eq.s $f0,$f10   # Compare $f0 with 0.0
    	bc1t changefilename    # Branch to equal_label if the comparison is true
        j return
 
changefilename:

    # open output file
    li $v0 13     # syscall for open file
    la $a0 fin   # output file name
    li $a1 1      # write flag (create new file if it doesn't exist)
    li $a2 0      # ignore mode 
    syscall       # open file 
    move $s0 $v0  # save the file descriptor for output 


   # write the byte to the output file
    li $v0, 15         # syscall for write to file
    move $a0, $s0      # file descriptor for output file         
    la $a1, alllines     # byte to write
    li $a2,10025          # number of characters
    syscall
      

    # close file
    li $v0, 16     # syscall for close file
    move $a0, $s0  # file descriptor to close
    syscall       # close file
    
    
    j return
    
    
#------------------------------------------------->    Option 1: view   #---------------------------------------------------------------------> 

   viewCalendar: 
		#printing Calendar Options
		li $v0, 4
		la $a0, ViewCalendarOptions
		syscall
		#Get User input
		li $v0, 5
    		syscall
   		move $t1, $v0 
		#Options for viewCalndar
		beq $t1, 1, viewPerDay
		beq $t1, 2, viewPerSetDays
		beq $t1, 3, viewForSlot
		# If not one of the option let user enter again
		li $v0, 4
		la $a0, tryAgain
		syscall
    		j viewCalendar
    		
#--------->Part 1 ViewPerDay   		
    	viewPerDay:
    		jal viewPerDayFunctionality   		
    		li $v0, 4
    		move $a0, $s2 
    		syscall 			
    		j main
    		
#--------->Part 2 ViewPerSetDays       		
    	viewPerSetDays:
    		li $v0, 4
    		la $a0, numOfDaysInput
   		syscall
    		li $v0, 5
    		syscall
    		move $t6, $v0   		
    		# loop through the number of days
    		LoopThroughDay:
    			beqz $t6, endLoop
    			jal viewPerDayFunctionality
    		 	li $v0, 4
    		 	move $a0, $s2 
    		 	syscall
    			subi $t6, $t6, 1
    			j LoopThroughDay
    		endLoop:
    			j main		
  				
#--------->Part 1 and 2 functionality

    	viewPerDayFunctionality:
    		#Get User Input
    		li $v0, 4
    		la $a0, daynumber
   		syscall
    		li $v0, 5
    		syscall
    		move $t1, $v0  		    			
    		la $s1 buffer
    		la $s2 line
    		li $s3 0      # current line length
    		li $t9 0      # number of lines read
		#openFile
    		li $v0 13    
    		la $a0 fin    # input file name
    		li $a1 0      # read flag
    		li $a2 0      
    		syscall      
    		move $s0 $v0   
	readFromFileLoop:
    		# read byte from file
    		li $v0 14     
   		move $a0 $s0  
    		move $a1 $s1  
    		li $a2 1     
    		syscall       	
		# Check if the read syscall returned zero (indicating the end of the file)
    		blez $v0 doneReading
    		# naively handle exceeding line size by exiting
    		slti $t0 $s3 1024
    		beqz $t0 doneReading
    		# if current byte is a newline, consume line
    		lb $s4 ($s1)
    		li $t0 10
    		beq $s4 $t0 consumeLine3
    		# otherwise, append byte to line
    		add $s5 $s3 $s2
    		sb $s4 ($s5)
    		# increment line length
    		addi $s3 $s3 1
		b readFromFileLoop
	#finish reading the whole line
	consumeLine3:
    		# null terminate line
    		add $s5 $s3 $s2
    		sb $zero ($s5)
    		# reset bytes read
    		li $s3 0
    		# increment number of lines read
    		addi $t9 $t9 1
    		j loadDay   #t9 has same address as s2 which is the base address of the line  		

	doneReading:
    		# close file
    		li $v0, 16     # syscall for close file
    		move $a0, $s0  # file descriptor to close
    		syscall       # close file	    

    	loadDay:
    		la $t0, ($s2) #This has the Entire Line!
    	processLine:
		li $t5, 0            # Initialize $t5 to 0, store the integer
		convert_to_int_loop:
		 	lb $t8, 0($t0) #lb $t8, 0($t0)
    			beq $t8, 58, convert_to_int_end 
    			sub $t8, $t8, '0'
    			mul $t5, $t5, 10
    			add $t5, $t5, $t8
    			addi $t0, $t0, 1
    			j convert_to_int_loop
		convert_to_int_end:
    			#Compare between t1 and t5  		
    			beq $t1, $t5, foundDay
    			j readFromFileLoop #if day not found go back to reading next line
		foundDay:					
    			li $v0, 16     # syscall for close file
    			move $a0, $s0  # file descriptor to close
    			syscall       # close file
    			jr $ra
#--------->Part 3 View Per Set of Slots  

	viewForSlot:
		#Get specifc day
		jal viewPerDayFunctionality
		# Ask for User start Time
	userStartTime_S3:
    		li $v0, 4
		la $a0, Starttime
		syscall
    		li $v0, 5
    		syscall
    		move $s5, $v0   # $s5 start time slot
    		
      		#Convert to 24 Hour Clock
    		beq $s5, 1 Convert24HrClock_strtime_S3
    		beq $s5, 2 Convert24HrClock_strtime_S3
    		beq $s5, 3 Convert24HrClock_strtime_S3
    		beq $s5, 4 Convert24HrClock_strtime_S3 		
    		b checkTime_S3
    		
    	Convert24HrClock_strtime_S3:
		addi $s5, $s5, 12
		#Check if start time is within Calendar Time(8AM-5PM)
	checkTime_S3:	
		blt $s5, 8 userStartTime_S3
		bgt $s5, 16 userStartTime_S3 
		
		
	userEndTime_S3:	
    		# Ask for User end Time
    		li $v0, 4
		la $a0, Endtime
		syscall
    		li $v0, 5
    		syscall
    		move $s6, $v0   # $s6 start time slot
    		
    		#Convert to 24 Hour Clock
    		beq $s6, 1 Convert24HrClock_endtime_S3
    		beq $s6, 2 Convert24HrClock_endtime_S3
    		beq $s6, 3 Convert24HrClock_endtime_S3
    		beq $s6, 4 Convert24HrClock_endtime_S3
    		beq $s6, 5 Convert24HrClock_endtime_S3
    		b checkTime2_S3
    		
    	Convert24HrClock_endtime_S3:   		
    		addi $s6, $s6, 12	
    		
    	checkTime2_S3:
    		blt $s6, 9, userEndTime_S3
    		bgt $s6, 17, userEndTime_S3
   	
	#Remove white spaces from the line to facilitate computation
    	la $t8, ($s2)  
    	la $t9, ($s2)  
    	remove_spaces_loop_S3:
    		lb $t0, 0($t8)        
    		beqz $t0, add_comma_and_remove_spaces_S3  # If null-terminator is reached, exit loop
    		# Check if the current byte is not a white space (ASCII 32 for space)
    		beq $t0, 32, skip_space_S3  # Check if byte is white space (ASCII 32 for space)
    		sb $t0, 0($t9)         # Store (non-space)byte in modified line
    		addi $t9, $t9, 1       
    	skip_space_S3:
    		addi $t8, $t8, 1       # Move to the next byte in the original line
    		j remove_spaces_loop_S3   # Repeat the loop
	add_comma_and_remove_spaces_S3:
    		sb $zero, 0($t9)
    		la $t0, ($s2)
	process_parts2_S3:
    		lb $t8, 0($t0)
    		beqz $t8, finish22_S3  # If null-terminator is reached, exit loop

    		# Check if the current character is a comma (,)
    		beq $t8,',', foudnacomma_S3   
    		beq $t8,':', foudnacomma_S3
    		add $t0,$t0,1
    	j process_parts2_S3

	foudnacomma_S3:
		la $t5,($t0)
	 	# start time -> $t2
  	 	# end time -> $t3
  	 	#optype - > $t7	
	starttime_S3:
    		#Calculate start time
    		add $t5,$t5,1
    		lb $t4, 0($t5)
    		sub $t4, $t4, 48  # to convert to integer subtract '0'
    		move $t2, $t4
    		add $t5,$t5,1
    		lb $t4, 0($t5)
    		beq $t4, '-', endtime_S3
    		sub $t4, $t4, 48  
    		mul $t2, $t2, 10
    		add $t2, $t2, $t4
     		add $t5,$t5,1
	endtime_S3:	
    		add $t5,$t5,1
    		lb $t4, 0($t5)
    		sub $t4, $t4, 48 
    		move $t3, $t4
 		#Move to next character
    		add $t5,$t5,1
    		lb $t4, 0($t5)
    		beq $t4, 'O', One_Digit_S3
    		beq $t4, 'M', One_Digit_S3
    		beq $t4, 'L', One_Digit_S3
    		sub $t4, $t4, 48 
    		mul $t3, $t3, 10
    		add $t3, $t3, $t4
 	One_Digit_S3:
 	#-----> Check Slots for start time t2
 		#Change start and End time to 24hr clock 
 		bge $t2, 8 continue_S3
 		addi $t2, $t2, 12 
 	continue_S3:
 		bge $t3, 8 checkSlot_S3
 		addi $t3, $t3, 12	
 	checkSlot_S3:
 	   	bge $t2, $s5 checkUpBound_S3
	   	j checkNextNum_S3
	checkUpBound_S3:
	   	blt $t2, $s6 takeFileValue_S3 
	   	beq $t2, $s6 main
	   	j main #no need to continue   	 	   
 	takeFileValue_S3: #if between the 2 numbers file value t2
 	   	li $v0, 1
 	   	move $a0, $t2
	   	syscall
 	skip_S3:				
           	lb $t4, 0($t5)
      		#should print a slash
    	  	li $v0, 11              
    	  	li $a0, '-'          
    	  	syscall
	 #-----> Check Slots for end time t3 	
            	bge $t3, $s5 checkUpBound2_S3 
 	   	li $v0, 1 #if No take user input s5
 	   	move $a0, $s6
	   	syscall
	   	j skip2_S3
	checkUpBound2_S3:
	   	ble $t3, $s6 takeFileValue2_S3
	   	li $v0, 1 #Not between the 2 numbers so take user input s5
 	   	move $a0, $s6
	   	syscall
	   	j skip2_S3 	   
	takeFileValue2_S3: #if between the 2 numbers file value t3
 	   	li $v0, 1
 	   	move $a0, $t3
	   	syscall
 	  	j skip2_S3
	checkNextNum_S3:
		bgt $t3, $s5 checkUpBoundFort3_S3
		lb $t4, 0($t5)
		j here_S3
	checkUpBoundFort3_S3:
		ble $t3, $s6 takeStrtUserInput_S3
		li $v0, 1
 		move $a0, $s5
		syscall
		#should print a slash
    		li $v0, 11              
    		li $a0, '-'          
    		syscall
    		li $v0, 1
 		move $a0, $s6
		syscall
		lb $t4, 0($t5)
		j skip2_S3
	takeStrtUserInput_S3:
	 	li $v0, 1
 	 	move $a0, $s5
	 	syscall
	 	#should print a slash
    	 	li $v0, 11              
    	 	li $a0, '-'          
    	 	syscall
    	 	li $v0, 1
 	 	move $a0, $t3
	 	syscall  	 	    	    	    	   	    	    	    	   
 		lb $t4, 0($t5)
    
 	skip2_S3:				
		#Brancg to print the appropriate appointment  
            	beq $t4, 'L', update_L_S3
            	beq $t4, 'O', update_OH_S3
            	beq $t4, 'M', update_M_S3
            	addi $t5, $t5, 1
            	lb $t4, 0($t5) 
            	j skip2_S3
            
	update_L_S3:
	    	#print L
    		li $v0, 11             
    		li $a0, 'L'     
    		syscall
    		li $v0, 11             
    		li $a0, '\n'      
    		syscall
    		j here_S3
	update_OH_S3:
	     	#print OH 
    		li $v0, 11            
    		li $a0, 'O'          
    		syscall
    		li $v0, 11             
    		li $a0, 'H'            
    		syscall	     	
    		li $v0, 11             
    		li $a0, '\n'           
    		syscall
    		j here_S3
	update_M_S3:
             	#print M 
    		li $v0, 11             
    		li $a0, 'M'            
    		syscall
    		li $v0, 11             
    		li $a0, '\n'          
    		syscall
	here_S3: 
 		add $t0,$t0,1
    		j process_parts2_S3
 	finish22_S3:
 		j main
   	
    			
    			
    			
    			
    	
    			
    			
    			
    			
#------------------------------------------------->    Option 4: Delete   #---------------------------------------------------------------------> 	
    			
    			
   		
 #######################################################################################################################################			
    viewPerDayFunctionalitydelete:

    			#Get User Input
    			li $v0, 4
    			la $a0, daynumber
   			syscall
    			li $v0, 5
    			syscall
    			move $t1, $v0   # $t1 contains the user-input day number
    			 blt $t1, 1, viewPerDayFunctionalitydelete  # Check if day number is less than 1
   			 bgt $t1, 31, viewPerDayFunctionalitydelete # Check if day number is greater than 31
   			 
   			 


    			li $s3 0      # current line length
    			    			

		readFromFileLoopdelete:
    			# read byte from file
    			li $v0 14     # syscall for read file
   			move $a0 $s0  # a0 stores file descriptor 
    			move $a1 $s1  # a1 stores address of dest buffer
    			li $a2 1      # buffer length, reading one character at a time
    			syscall       # read byte from file
    			
			# Check if the read syscall returned zero (indicating the end of the file)
    			blez $v0 read_done
    			# naively handle exceeding line size by exiting
    			slti $t0 $s3 1024
    			beqz $t0 read_done
    		
    		   	# if current byte is a newline, consume line
    			lb $s4 ($s1)
    			li $t0 10
    			beq $s4 $t0 consumeLinedelete

    			# otherwise, append byte to line
    			add $s5 $s3 $s2
    			sb $s4 ($s5)

    			# increment line length
    			addi $s3 $s3 1

   			b readFromFileLoopdelete

		#finish reading the whole line
		consumeLinedelete:
    			# null terminate line
    			add $s5 $s3 $s2
    			sb $zero ($s5)
    			addi $s5, $s5, 1
			li $t3, 10
			sb $t3 ($s5)
			
			
    			j loadDaydelete   #t9 has same address as s2 which is the base address of the line  		
   

    		loadDaydelete:
    			la $t0, ($s2) #This has the Entire Line!
    		processLinedelete:
			#------------------------------------------------------------------->
			    	li $t5, 0            # Initialize $t5 to 0, store the integer
				convert_to_int_loopdelete:
		 			lb $t8, 0($t0) #lb $t8, 0($t0)
    					beq $t8, 58, convert_to_int_enddelete 
    					sub $t8, $t8, '0'
    					mul $t5, $t5, 10
    					add $t5, $t5, $t8
    					addi $t0, $t0, 1
    					j convert_to_int_loopdelete
				convert_to_int_enddelete:
    					#Compare between t1 and t5  		
    					beq $t1, $t5, foundDaydelete
    					j write_loopfordelete

    					
				foundDaydelete:	
    				jr $ra
 		
    		

   
#------------------------------------------------->    Option 4: Delete   #---------------------------------------------------------------------> 
    
       
    DeleteAppointment:
	#Ask User to Enter Day
	
	
	    	  
		jal viewPerDayFunctionalitydelete
			 							

	li $v0, 11             
    		li $a0, '\n'           
    		syscall
	promptAppointAgain:
    		# # Print prompt to ask the user to enter a character  ########?????######!!!!!!!!!!
    		li $v0, 4              
    		la $a0, promptAppointment       
   		syscall              
   		li $v0, 12  # Read charact
    		syscall
   		move $t1, $v0   #move Charac to t1
   		li $v0, 11             
    		li $a0, '\n'           
    		syscall
   		beq $t1, 'M', continueParsingLine
    		beq $t1, 'L', continueParsingLine
    		beq $t1, 'O', continueParsingLine
		li $v0, 11             
    		li $a0, '\n'           
    		syscall
    		# Invalid input
    		j promptAppointAgain																													

	continueParsingLine:	
    		# Remove white spaces from the line
    		la $t8, ($s2) 
    		la $t9, ($s2) 
    		remove_spaces_loop22:
    		lb $t0, 0($t8)   
    		beqz $t0, ExtractedLineWithoutSpaces  
    		beq $t0, 32, skip_space22
    		sb $t0, 0($t9)       
    		addi $t9, $t9, 1      
    		skip_space22:
    		addi $t8, $t8, 1      
    		j remove_spaces_loop22  
	ExtractedLineWithoutSpaces:
    		sb $zero, 0($t9) # Null terminate	
		#Take User Inputs for start and End
		li $v0, 4
		la $a0, Starttime
		syscall
    		li $v0, 5
    		syscall
    		move $s5, $v0   # $s5 start time slot
    		li $v0, 4
		la $a0, Endtime
		syscall
    		li $v0, 5
    		syscall
    		move $s6, $v0   # $s6 start time slot
    				
		#Parse through Line To delete appointment

		la $t7, ($s2)
	processParts3:
    		lb $t8, 0($t7)
    		beqz $t8, doneDeleting  # If null-terminator is reached, exit loop
    		beq $t8,',', foundComma3  # Check if charac is a comma or colon
    		beq $t8,':', foundComma3
    		addi $t7, $t7, 1
    		j processParts3

	foundComma3: #t2 now contains the position after colon or comma 
   		addi $t7, $t7, 1
   		move $s4, $t7  ##Store the starting address in s4
	starttime33:      # start time -> $t2
    		lb $t4, 0($t7)
    		sub $t4, $t4, 48  # Subtract ASCII value of '0'
    		move $t2, $t4
    		addi $t7, $t7, 1
    		lb $t4, 0($t7)
    		beq $t4, '-', endtime33
    		sub $t4, $t4, 48  # Subtract ASCII value of '0'
    		mul $t2, $t2, 10
    		add $t2, $t2, $t4 #t2 Has the start time
    		addi $t7, $t7, 1
    
	endtime33:        # end time -> $t3
    		addi $t7, $t7, 1  
    		lb $t4, 0($t7)
    		sub $t4, $t4, 48  # Subtract ASCII value of '0'
   		move $t3, $t4 
    		addi $t7, $t7, 1
       
    		lb $t4, 0($t7)
   	 	beq $t4, 'O', checkNumber
   		beq $t4, 'M', checkNumber
    		beq $t4, 'L', checkNumber
   
    		sub $t4, $t4, 48  # Subtract ASCII value of '0'
    		mul $t3, $t3, 10
    		add $t3, $t3, $t4
		
		
		#getCharAppointment:
		#lb $t4, 0($t7)
		#move $s7, $t4
	checkNumber:
		
   		addi $t7, $t7, 1
   		lb $t4, 0($t7)
  		beqz $t4, skipHere
   		bne $t4, ',', checkNumber
   		
	skipHere:	
		#If the start and end time match the slot then delete  
		bne $t2, $s5 processParts3   #if not equal check the next slot and go back to loop
		bne $t3, $s6 processParts3
		#bne $t1, $s7  processParts3
		li $t9, ' '   # Replace with space
		sb $t9, 0($s4)
		addi $s4, $s4, 1

	findEndOfSlot:
		lb $t4, 0($s4)
		beq $t4, ',', replaceCommaWithZero 
		beqz $t4, doneDeleting 
		li $t9, ' ' # Replace with space
    		sb $t9, 0($s4)   	   	
    		addi $s4, $s4, 1
    		j findEndOfSlot

	replaceCommaWithZero: 
		li $t9, ' '   
		sb $t9, 0($t7)
	
	doneDeleting:	
    		# Loop to the end of string and add a newLine
  		la $t2, ($s2)
  		Loop:
  		lb $t4, 0($t2)
  		beqz $t4, addSpace
  		addi $t2, $t2, 1
  		b Loop
  	addSpace:
  		addi $t2, $t2, 1
  		lb $t4, 0($t2)
  		beq $t4, 10 endLine
  		li $t4, ' ' # Replace the current character with a space
    		sb $t4, 0($t2) 
    		b addSpace	
	endLine: 
		
  		li $v0, 4
    		move $a0, $s2
    		syscall
    	   		
    l.s $f0, conflict_checker
    l.s $f1, one_float
    add.s $f0, $f0, $f1	 #to allow delete function to write into file
    
    subi $s3,$s3,5 #,1-2o
    
 
    
       # If we want to print it again
    sw $zero,sumL
    sw $zero,sumM  
    sw $zero,sumOH
    sw $zero,ratio
    sw $zero,avg
    
    

	j  write_loopfordelete	
	#j readFromFileLoop
    
 #  ________________________________- 
 write_loopfordelete:

     bne  $t6,4,dontwritedelte
    
 	la $t7,($s2) 
        move $t0, $zero  
   	addi $s3,$s3,1 

    process_partscopydelete:

	addi $t0,$t0,1
    beq $t0,$s3,finishcopydelete # If LAST BYTE IN THE LINE is reached, exit loop                                
    	lb $t5,0($t7)
   	sb $t5,0($a3)
   	add $a3,$a3,1 
   	add $t7,$t7,1
    j process_partscopydelete 
                    
  finishcopydelete:
     	li $t0,10
     	sb $t0 , 0($a3) #store '\n' 
                                               
  dontwritedelte: 

    addi $a3, $a3, 1  # Move to the next position for the next line
    	addi $t9 $t9 1     	# increment number of lines read
    	li $s3 0     	# reset bytes read
            
   	# j readFromFileLoop					
	#j cintinue
 j readFromFileLoopdelete #if day not found go back to reading next line    
   
 #__________________________________________________________________________________________________________________________________________   
    
read_loop:

    
   bne  $t6,3,dontwrite
  
    
 	la $t7,copy_line 
        move $t0, $zero  
  	addi $s3,$s3,1 

    process_partscopy:

	addi $t0,$t0,1
    beq $t0,$s3,finishcopy # If LAST BYTE IN THE LINE is reached, exit loop                                
    	lb $t5,0($t7)
   	sb $t5,0($a3)
   	add $a3,$a3,1 
   	add $t7,$t7,1 
    j process_partscopy      

            
  finishcopy:
     	li $t0,10
     	sb $t0 , 0($a3) #store '\n' 
     	
          	
                                          
  dontwrite: 
    	li $s3 0    # reset bytes read
    addi $a3, $a3, 1  # Move to the next position for the next line

           
                                 
   j reading_loop
  #__________________________________________________________________________________

   
