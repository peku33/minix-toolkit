#!/bin/bash

######################################################
#
# Skrypt przygotowany do pracy z obrazem minixa
# oraz emulatorem qemu na laboratorium SOI
# 
# Copyright 2015, Paweł Kubrak <peku33@gmail.com>
#
######################################################

QEMU_CMD='qemu-system-i386'																# Nazwa polecenia emulatoara
ZIP_CMD='zip'																			# Komenda służąca do tworzenia archiwum
CREATE_DATE_CMD="date +%Y_%m_%d_%H_%M_%S"												# Polecenie tworzące datę w postaci którą można zawrzeć w nazwie pliku
MINIX_MOUNT_CMD='mount -t minix -o loop,offset=1483776'									# Polecenie montujące dla minixa


MINIX_CUR_NAME='minix203.img.cur'														# Nazwa obrazu roboczego
MINIX_SOURCE_IMAGE_NAME="minix203.img.ori"												# Nazwa obrazu źródłowego - to ten, który będzie czystym minixem
MINIX_SOURCE_URL='http://www.ia.pw.edu.pl/~tkruk/edu/soi.b/lab/minix/minix203.img'		# Skąd pobieramy czysty obraz?
MINIX_USR_LOCAL_DIR='minix_usr'															# Katalog roboczy pod którym będzie montowany minix



# Sprawdź w pierwszym kroku, czy jesteśmy rootem.
# Bezwzględnie potrzebujemy tego do mount itp
if test $UID -ne 0
then
	echo 'Ta aplikacja musi zostać uruchomiona z prawami roota (potrzebne mount)'
	exit 1
fi

# Sprawdź, czy dysponujemy qemu
if ! which $QEMU_CMD >> /dev/null
then
	echo "Nie odnaleziono polecenia $QEMU_CMD. Czy aby na pewno qemu jest zainstalowane?"
	exit 1
fi

# Sprawdź, czy istnieje obraz minixa, który posłuży jako źródło
if ! test -f $MINIX_SOURCE_IMAGE_NAME
then
	echo "Brak domyślnego obrazu minixa ($MINIX_SOURCE_IMAGE_NAME), pobieram"
	while ! wget -O $MINIX_SOURCE_IMAGE_NAME $MINIX_SOURCE_URL
	do
		echo "Nie udało się pobrać obrazu minixa... Naciśnij dowolny przycisk, aby spróbować ponownie"
		read
	done
fi

# Jeśli nie istnieje obraz roboczy - staje się nim oryginalny obraz minixa
if ! test -f $MINIX_CUR_NAME
then
	cp -v $MINIX_SOURCE_IMAGE_NAME $MINIX_CUR_NAME
fi

# Tworzymy katalog roboczy
mkdir -p $MINIX_USR_LOCAL_DIR

# Uruchom minixa.
run_minix()
{
	$QEMU_CMD $MINIX_CUR_NAME
}

# Backupuje aktualny obraz
# Tworzona jest kopia z nazwą zawierającą aktualną datę
image_create_backup()
{
	if test -f $MINIX_CUR_NAME
	then
		BACKUP_TIMESTAMP=`$CREATE_DATE_CMD`
		BACKUP_FILENAME="${MINIX_CUR_NAME}_${BACKUP_TIMESTAMP}"
		cp -v $MINIX_CUR_NAME $BACKUP_FILENAME
	fi
	
	echo "-> Utworzono backup obecnej wersji pod nazwą $BACKUP_FILENAME"
}

# Zamontuj obraz minixa w katalogu roboczym
# Działanie qemu kiedy obraz jest zamontowany jest (dla mnie) nieznane - po zmianach odmontowuję obraz
mount_image()
{
	if ! mount | grep "$PWD/$MINIX_CUR_NAME" > /dev/null
	then
		$MINIX_MOUNT_CMD $MINIX_CUR_NAME $MINIX_USR_LOCAL_DIR
	fi
	
	echo "-> Minix został zamontowany w katalogu $MINIX_USR_LOCAL_DIR"
}

# Odmontowuje obraz
umount_image()
{
	if mount | grep "$PWD/$MINIX_CUR_NAME" > /dev/null
	then
		while ! umount "$PWD/$MINIX_CUR_NAME"
		do
			echo "Nie udało się odmontować katalogu. Sprawdź, czy żaden edytor, ani żadna konsola nie znajduje się w katalogu roboczym. Naciśnij dowolny klawisz, aby kontynuować."
			read
		done
	fi
	
	echo "-> Minix został odmontowany z katalogu $MINIX_USR_LOCAL_DIR"
}

# Pusta linia estetyki
echo

# Zaczynamy z zamontowanym obrazem.
mount_image

while true
do
	# Dopóki użytkownik nie wyjdzie z programu pokazujemy my takie oto menu
	echo
	echo 	"==================================================="
	echo 	"== Wybierz polecenie: "
	echo 	"== 1) Uruchom minixa"
	echo 	"== 2) Stwórz backup obecnego obrazu"
	echo 	"== 3) Rozpocznij od czystego obrazu"
	echo 	"== 4) Przywróć poprzednią wersję"
	echo 	"== 5) Wyeksportuj zmienione pliki do archiwum"
	echo 	"== 6) Przenieś aktualny obraz na nośnik zewnętrzny"
	echo 	"== g) Uruchom gedit jako root"
	echo 	"== q) Zakończ pracę, idę spać."
	echo -n	"== Wybór: "; read CHOICE
	echo 	"==================================================="
	echo
	
	case $CHOICE in
		"1")
			# Obraz musi być odmontowany na czas pracy emulatora
			umount_image
			# Przed zmianami 
			image_create_backup
			
			echo "-> QEMU rozpoczyna pracę"
			run_minix
			echo "-> QEMU kończy pracę"
			
			# Zamontuj z powrotem obraz do pracy
			mount_image
			;;
		"2")
			# Odmintuj obraz, aby zapisać zmiany
			umount_image
			# Stwórz kopię
			image_create_backup
			# Zamontuj z powrotem obraz do pracy
			mount_image
			;;
		"3")
			echo -n	"-> Czy na pewno chcesz zastąpić obecny obraz czystą wersją? [T/n]: "
			read YN
			if test "$YN" == "" || test "$YN" == "T" || test "$YN" == "t"
			then
				echo "Przenoszenie obrazu..."
				
				# Odmontuj obecny obraz
				umount_image
				# Wykonaj kopię obrazu, gdyby ktoś jednak chciał do niej wrócić
				image_create_backup
				# Skopiuj domyślny czysty obraz jako roboczy
				cp -v $MINIX_SOURCE_IMAGE_NAME $MINIX_CUR_NAME
				# Zamontuj nowy obraz
				mount_image
				
				echo "-> Gotowe"
			fi
			;;
		"4")
			# Lista wszystkich obrazów które mogą zostać przywrócone
			CANCEL_NAME='Anuluj'
			FILES_AVAILIBLE=`ls -t ${MINIX_CUR_NAME}_*`
			
			# Super polecenie select oszczędza kupę roboty - wyświetla listę i pozwala wybrać
			select FILE_NAME in $CANCEL_NAME $FILES_AVAILIBLE
			do
				if test "$FILE_NAME" == $CANCEL_NAME
				then
					break
				fi
				
				# Coś wybraliśmy - odmontowujemy stary
				umount_image
				# Na wszelki wypadek backup
				image_create_backup
				# Zastępujemy roboczy wybranym
				cp -v $FILE_NAME $MINIX_CUR_NAME
				# Montujemy przywrócony obraz
				mount_image
				
				# Nic więcej nie chcemy
				break
			done
			
			;;
		"5")
			# Sprawdzamy, czy system dysponuje odpowiednim poleceniem
			if which $ZIP_CMD >> /dev/null
			then
				# Tworzymy tymczasowy katalog do którego zamontujemy czysty obraz, aby wykonać porównanie
				TMPDIR=`mktemp -d`
				
				# Montujemy czysty obraz w tymczasowym katalogu
				$MINIX_MOUNT_CMD $MINIX_SOURCE_IMAGE_NAME $TMPDIR
				
				# Wyklucz te pliki
				EXCLUDES='/adm/\|.o$\|.pid$\|/src/tools/'
				# Szukamy różnic. LANG= zmianie język na angielski, aby grep mógł rozpoznać i wyciągnąć zmienione pliki.
				FILES_DIFF=`(LANG= diff -rqN $MINIX_USR_LOCAL_DIR/ $TMPDIR/ | grep "^Only in $MINIX_USR_LOCAL_DIR" | awk '{print substr($3, 0, length($3))"/"$4}' ; LANG= diff -rqN $MINIX_USR_LOCAL_DIR/ $TMPDIR/ | grep "^Files" | awk '{print $2}') | grep -v $EXCLUDES`
				
				# Czy są jakiekolwiek zmiany?
				if test ${#FILES_DIFF[@]} -ne 0
				then
					# Nazwa docelowego zip'a
					ZIP_NAME="minix_diff_`$CREATE_DATE_CMD`.zip"
					# Stwórz archiwum, ale tylko z plików, dla których file pokazuje, że się nadają.
					echo ${FILES_DIFF[@]} | xargs file --separator '' | grep -iv 'executable' | awk '{print substr($1, 0, length($1)+1)}' | $ZIP_CMD $ZIP_NAME -@
					
					echo "-> Utworzone archiwum: $ZIP_NAME"
				else
					echo "-> Brak różnic..."
				fi
				
				# Odmontowujemy obraz roboczy
				umount $TMPDIR
				# Kasujemy tymczasowy katalog
				rmdir $TMPDIR
			else
				echo "-> Nie odnaleziono polecenia $ZIP_CMD."
			fi
			;;
		"6")
			
			CANCEL_NAME='Anuluj'
			DRIVES_AVAILIBLE=`mount | grep '/media/' | awk '{print $3}'`
			
			select DRIVE_NAME in $CANCEL_NAME $DRIVES_AVAILIBLE
			do
				if test "$DRIVE_NAME" == "$CANCEL_NAME"
				then
					break
				fi
				
				TARGET_DEFAULT_NAME='minix203.img.final'
				
				echo -n "-> Podaj nazwę pliku do zapisania: [$TARGET_DEFAULT_NAME]: " ; read TARGET_NAME
				if test "$TARGET_NAME" == ""
				then
					TARGET_NAME=$TARGET_DEFAULT_NAME
				fi
				
				cp -v $MINIX_CUR_NAME "$DRIVE_NAME/$TARGET_NAME"
				
				break
			done
			
			;;
		"g")
			gedit &
			echo "Chwileczkę..."
			;;
		"q")
			echo "-> No elo."
			break
			;;
	esac
done

umount_image
