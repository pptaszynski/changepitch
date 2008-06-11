#
#   ChangePitch v. 0.1
#
#   Pawe³ Ptaszyñski 
#   Grupa: J1I3
#

.globl main

	.data

# Etykiety interfejsu
intwe:		.asciiz		"Nazwa pliku wejsciowego:\n"
intwy:		.asciiz		"Nazwa pliku wyjsciowego:\n"
intprob:	.asciiz		"Nowa ilosc probek w pliku: \n"
intprocess:	.asciiz		"Przetwarzanie w toku ..."
succhwrite:	.asciiz		"Zapisano naglowek\n"
succfwrite:	.asciiz		"Zapisano plik\n"
endl:		.asciiz		"\n"
.align 2
naglowek:	.space		44
inf:		.space		255
.align 2
outf:	.space		255
.align 2
outln:	.space		4


	.text

#############################
#							#
#			Main			#
#							#
#############################

main:
#begin
	sub	$sp, $sp, 4		# zapisanie ra na stosie
	sw	$ra, 0($sp)

#
#	Interface
#
#begin

	la	$a0, intwe		# Wejscie
	li	$v0, 4
	syscall
	#wywolanie readfname
	la	$a0, inf		# Wczytaj nazwe pliku
	li	$a1, 255
	jal	readfname

	la	$a0, intwy		# Wyjscie
	li	$v0, 4
	syscall
	#wywolanie readfname
	la	$a0, outf		# Wczytaj nazwe pliku
	li	$a1, 255
	jal	readfname
	
	la $a0, intprob		# Ilosc sampli pliku wyjsciowego
	li $v0, 4
	syscall
	#wywolanie readnl	# Wczytaj nowa ilosc sampli
	jal readnl
	move $s4, $v0		#nowa_ilosc_sampli -> $s4

#end
#

#
#	Odczyt z pliku wejscioweg
#	begin/*{{{*/

	#otwarcie pliku
	la	$a0, inf
	jal	fopen
    move	$s0, $v0	#zapamietam file descriptor
	#pobranie naglowka
	move	$a0, $s0
	jal	readh
	move	$s2, $v0	#wielkosc obszaru danych -> $s2
	move	$s3, $v1	#ilosc sampli -> $s3

	#test
	#	move	$a0, $s2	#echo wielkosc_danych_in
	#	li	$v0, 1
	#	syscall
	#	la	$a0,endl		#echo "\n"\
	#	li	$v0, 4
	#	syscall
	#	move	$a0, $s3	#echo ilosc_sampli_in
	#	li	$v0, 1
	#	syscall
	#	la $a0, endl		#echo "\n"
	#	li $v0, 4
	#	syscall
	#tset

	#alokacja pamieci
	move	$a0, $s2	#zaalokuj wielkosc_wielkosc_obszaru_danych bajtow pamieci
	jal	malloc
	move $s1, $v0		#zachowaj adres zaalokowanej pamieci
	#odczytanie pliku do pamieci
	move $a0, $s0		#odczytaj z pliku wskazywanego przez file-descriptor $s0
	move $a1, $s1		#odczytaj do pamieci zaczynajacej sie od adresu w $s1
	move $a2, $s2		#odczytaj $s2 bajtow pamieci
	jal read
	#test
	#	move $a0,$v0	#echo ilosc bajtow odczytanych
	#	li	$v0, 1
	#	syscall			
	#	la	$a0, endl	#echo \n
	#	li	$v0, 4
	#	syscall
	#tset

	#zamykanie pliku wejsciowego
	move $a0, $s0
	jal fclose

#	end
#	/Odczyt.../*}}}*/
#	
#	Wynik (saved temporary regs)
#	$s0 In-File Descriptor
#	$s1	Adres poczatku zaalokowanego obszaru danych wejsciowych
#	$s2	Wielkosc obszaru danych wejsciowych
#	$s3 ilosc probek wejsciowych
#	$s4 ilosc probek w pliku docelowym
#	

#
#	Przygotowanie danych do processingu
#	begin
	sll	$s5, $s4, 2		#nowa_wielkosc_danych = nowa_ilosc_sampli*4
	#Modyfikuje nadglowek dla nowego pliku
	la $t0, naglowek	
	addi $t1, $s5, 36	#nowa_wielkosc_calego_pliku = nowa_wielkosc_danych + 36 //wielkosc naglowka
	#test
	#	move $a0, $t1	#echo nowa_wielkosc_calego_pliku
	#	li $v0, 1
	#	syscall
	#	la $a0, endl	#echo "\n"
	#	li $v0, 4
	#	syscall
	#tset
	sw $t1, 4($t0)		#zapisz ChunkSize
	sw $s5, 40($t0)		#zapisz SubChunk2Size

	
	#alokacja pamieci dla probek pliku wyjsciowego
	move $a0, $s5		#zaalokuj $s5 bajtow pamieci //nowa_wielkosc_danych
	jal malloc			
	move $s6, $v0		#zachowaj adres zaalokowanej pamieci w $s6
#	end
#	/Przygotowanie danych do processingu
#

#	Processing
#	begin
	la	$a0, intprocess
	li	$v0, 4
	syscall
	
	move	$a0, $s1	#przekaz adres bloku danych wejsciowych
	move	$a1, $s3	#przekaz ilosc probek wejsciowych
	move	$a2, $s6	#przekaz adres bloku danych wyjsciowych
	move	$a3, $s4	#przekaz ilosc probek wyjsciowych
	jal process
#	
#	Wynik (saved temporary regs)
#	$s0	In-File Descriptor
#	$s1	Adres poczatku zaalokowanego obszaru danych wejsciowych
#	$s2	Wielkosc obszaru danych wejsciowych
#	$s3	Ilosc probek wejsciowych
#	$s4	Ilosc probek wyjsciowych
#	$s5	Wielkosc danych wyjsciowych
#	$s6	Adres obszaru danych wyjsciowych
#

#	Zapis do pliku
#	begin
	#Wywolanie funkcji otwierania pliku do zapisu foutopen
	la	$a0, outf
	jal	foutopen
	move	$s0, $v0

#	$s0	Out-File Descriptor

	#Zapisywanie naglowka
	move	$a0, $s0
	la	$a1, naglowek
	li	$a2, 44
	jal	fwrite
	#test
	#	move	$a0, $v0
	#	li	$v0, 1
	#	syscall
	#	la	$a0, endl
	#	li	$v0, 4
	#	syscall
	#tset
	la	$a0, succhwrite
	li	$v0, 4
	syscall

	#Zapisywanie zawartosc danych
	move	$a0, $s0	#przekazanie out-file descriptora
	move	$a1, $s6	#przekazanie bufora pamieci do zapisu
	move	$a2, $s5	#przekazanie wielkosci bufora do zapisu
	jal	fwrite
	#test
	#	move	$a0, $v0
	#	li	$v0, 1
	#	syscall
	#	la	$a0, endl
	#	li	$v0, 4
	#	syscall
	#tset
	la	$a0, succfwrite
	li	$v0, 4
	syscall

	move	$a0, $s0
	jal fclose
#	end
#	/Zapis do pliku
#

	lw $ra, 0($sp)
	addi	$sp, $sp, 4
	jr $ra

#end

#############################
#							#
#			Func			#
#							#
#############################

#
#	readfname
#	Wczytuje nazwe pliku z konsoli uzytkownika. Usuwa znak konca linii.
#	@arg	$a0	adres zapisania nazwy pliku
#	@arg	$a1	maksymalna dlugosc nazwy pliku
#	
readfname:
#begin/*{{{*/
	li	$v0, 8
	syscall
	li	$t0, 10 		# 10 znak konca lini w ASCII, przechowujemy w t0 dla porownywania
	
	lookendl:
	#begin
		lbu	$t1, 0($a0)
		add $a0, $a0, 1
		bne	$t1, $t0, lookendl
	#end
	li	$t0,0		# wstawienie znaku \0 na koniec lancucha znakow zamiast \n
	sb	$t0, -1($a0)

	jr	$ra
#end/*}}}*/

#
#	fopen
#	Otwiera plik
#	@arg	$a0 nazwa pliku
#	@returns	$v0	File Descriptor
#
fopen:
#begin/*{{{*/
	li	$a1, 0
	li	$a2, 0
	li	$v0, 13
syscall
	jr $ra
#end/*}}}*/

#
#	foutopen
#	Otwiera plik do zapisu
#	@arg	$a0	nazwa pliku
#	@returns	$v0	File Descriptor
#
foutopen:
#begin/*{{{*/
	li	$v0, 13
#	li	$a1, 0x301	#win32
#	li	$a2, 0x180		
	li	$a1, 65		#linux
	li	$a2, 511
	syscall
	jr	$ra
#end/*}}}*/

#
#	fwrite
#	Zapisuje zawartosc pamieci do pliku
#	@arg	$a0	File Descriptor
#	@arg	$a1	Poczatek bloku pamieci do zapisu
#	@arg	$a2	Ilosc danych do zapisania (w bajtach)
fwrite:
#begin/*{{{*/
	li $v0, 15
	syscall
	jr $ra
#end/*}}}*/

#
#	fclose
#	Zamyka plik wskazany przed file descriptor
#	@arg	$a0	File descriptor
#
fclose:
#begin/*{{{*/
	li	$v0, 16
	syscall
	jr $ra
#end/*}}}*/

#
#	readnl
#	Odczytuje docelowa dlugosc pliku wynikowego
#
readnl:
#begin/*{{{*/
	li $v0, 5
	syscall
	jr $ra
#end/*}}}*/

#
#	readh
#	Wczytuje informacje naglowkowe pliku WAVE.
#	@arg	$a0	File Descriptor
#	@returns	$v0 Wielkosc obszaru danych pliku WAVE
#	@returns	$v1 Ilosc probek w pliku
#
readh:
#begin/*{{{*/
	sub $sp, $sp, 4
	sw	$ra, 0($sp)
	
	#wywolanie funkcji odczytu pliku
	la	$a1, naglowek	#wskazanie bufora naglowka
	li	$a2, 44			#wskaznaie dlugosci naglowka do odczytu
	jal read
	#test
		move	$a0, $v0
		li	$v0, 1
		syscall
		la	$a0, endl
		li	$v0, 4
		syscall
	#tset
	#zwracanie wartosci
	la	$t0, naglowek
	lw	$v0, 40($t0)	#dlugosc pliku
	srl	$v1, $v0,2	#ilosc sampli
	#wyjscie z funkcji
	lw	$ra, 0($sp)
	add	$sp, $sp, 4
	jr $ra
#end/*}}}*/

#
#	read
#	Odczytuje dane ze wskazanego file descriptor i zapisuje je w pamieci
#	@arg	$a0	File Descriptor
#	@arg	$a1	Adres pamieci do zapisu
#	@arg	$a2	dlugosc odczytu (w bajtach)
#
read:
#begin/*{{{*/
	li	$v0, 14
	syscall
	jr $ra
#end/*}}}*/

#
#	malloc
#	Alokuje blok pamieci
#	@arg	$a0	Wielkosc pamieci do zaalokowania (w bajtach)
#	@returns	$v0	Adres poczatku zaalokowanej pamieci
#
malloc:
#begin/*{{{*/
	li	$v0, 9
	syscall
	jr $ra
#end/*}}}*/

#
#	process
#	Tworzy probki dla pliku wyjsciowego
#	@arg		$a0		Adres obszaru danych wejsciowych
#	@arg		$a1		Ilosc probek wejsciowych
#	@arg		$a2		Adres obszaru danych wyjsciowych
#	@arg		$a3		Ilosc probek wyjsciowych
#
process:
#begin
	move $t6, $a0			#Zachowaj adres obszaru danych wejsciowych (na potrzeby testow)
	li $t7, 0				#Zacznij od szukania wartosci pierwszej probki
	sll $t0, $a1, 16		#Pomnoz ilosc probek pliku wejsciowego x2^16
	div $t0, $a3			#Podziel otrzymany wynik przez zadana ilosc probek
	mflo $t0				#zapisz wynik w $t0
	#rozpocznij petle przetwarzania
	processloop:
	#begin
		addi $t7, $t7, 1	#przejdz do kolejnej probki do badani.
		mult $t0, $t7		#mnoz wynik stosunku probek razy numer probki
		mflo $t1			#zapisz w $t1
		#mfhi $t2
		#bnez $t2
		srl $t1, $t1, 16	#dziel przez 2^16 
		
		#sub $t5, $a1, $t1
		#if
		#	bgez $t5, cploop
		#then	
		#	move $t1, $a1
		#fi
		cploop:
		#test
			#move $a0, $t1
			#li $v0,1
			#syscall

			#la $a0, endl
			#li $v0, 4
			#syscall
		#tset
		
		addi	$t1, $t1, -1 #Oblilcz presuniecie wzgledem poczatka bloku probek zrodlowych
		sll $t1, $t1, 2		 #
		add $t3, $t6, $t1	 #Oblicz adres probek do pobrania
		lw	$t4, 0($t3)		 #Pobierz 4 probki 16 bytes * 2 channels = 32 bytes = 1 word
		sw	$t4, 0($a2)		 #
		addi	$a2, $a2,4		 #Przejdz do miejsca zapisu kolejnej probki
		bne $t7, $a3, processloop #jesli nie skonczono powtorz.
	#end
	jr $ra
#end
