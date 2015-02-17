=========================================================
== 
== Skrypt wspierający pracę z systemem MINIX 2.0.3
==
== Autor: Paweł Kubrak, peku33.net, peku33@gmail.com
==
== 26.01.2015
==
=========================================================


Skrypt wspierający pracę z systemem MINIX 2.0.3 w środowisku emulatora qemu uruchamianego pod systemem Linux.

- Objaśnienia wstępne
	System MINIX 2.0.3 dostępny w postaci obrazu (.img) stanowi pełny, funkcjonujący system operacyjny, który można zainstalować na swoim komputerze. Jego obsługa jest jednak dość trudna, a funkcje ograniczone. Dodatkowo podczas modyfikacji jądra systemu istnieje możliwość sprowadzenia go do postaci niedziałającej, co zmuszałoby do ciągłych reinstalacji, utraty postępu i rozpoczynania od początku.
	
	Dlatego też system MINIX uruchamiany jest poprzez emulator qemu, który po podaniu nazwy wirtualnego dysku / obrazu emuluje działanie komputera. W przypadku unieruchomienia systemu MINIX - można rozpocząć od działającej kopii.
	
- Cel skryptu
	Skrypt powstał w celu jeszcze większej automatyzacji i uproszczenia pracy z systemem MINIX. Skrypt umożliwia między innymi:
		- Automatyczne pobranie czystego obrazu MINIX 2.0.3 używanego w trakcie zajęć
		- Zamontowanie aktywnego obrazu w katalogu roboczym (można przeglądać i edytować pliki wewnątrz obrazu za pośrednictwem Linux'a)
		- Uruchomienie emulatora qemu i automatyczne stworzenie kopii zapasowej obrazu
		- Przywrócenie kopii zapasowej obrazu
		- Uruchomienie edytora gedit jako root

- Instrukcja pracy ze skryptem (w środowisku systemu Ubuntu Linux 14.04)
	1. Skrypt należy pobrać i zapisać w dowolnym katalogu (na przykład nowym katalogu na pulpicie) pod wybraną nazwą. Przyjęte tu 'minix.sh'
	2. Uruchomić terminal i przejść do katalogu w którym znajduje się skrypt
	3. Upewnić się, że skrypt ma flagę umożliwiającą wykonanie, jeśli nie, nadać ją poleceniem 'chmod +x minix.sh'
	----------------
	4. Skrypt musi być uruchamiany z prawami root'a (potrzebne polecenia mount / umount) - należy go uruchomić na przykład poprzez 'sudo ./minix.sh'
		Na tym etapie skrypt sprawdzi istnienie czystego obrazu minixa (minix203.img.ori) w swoim katalogu. Jeśli taki plik nie istnieje, zostanie automatycznie pobrany i zapisany pod tą nazwą. Skrypt utworzy katalog roboczy minix_usr, w którym widoczne będą pliki z obrazu. Skrypt sprawdzi istnienie obrazu roboczego (tego, nad którym aktualnie pracujemy), jeśli takowy nie istniał - stanie się nim czysty obraz.
		Aby nie doprowadzić do błędów - obraz musi zostać odmontowany kiedy uruchamiany jest emulator albo tworzona kopia zapasowa. Dzieję się to automatycznie, jednak w tym czasie żadne pliki znajdujące się w folderze minix_usr nie mogą być otwarte. W przypadku zaistnienia takiej sytuacji - skrypt pokaże błąd.
	5. Kiedy wyświetli się menu - pliki minixa dostępne są w katalogu minix_usr i jesteśmy gotowi do pracy
		Możemy teraz rozpocząć edycję systemu. Należy zauważyć, że pliki zamontowane w katalogu minix_usr mają jako właściciela root'a - tylko root może je wyedytować. Dlatego też powstała funkcja uruchomienia edytora tekstu gedit jako root. Edytor uruchomiony jako root ma możliwość edycji plików w katalogu minix_usr
	6. Po zakończeniu wprowadzania pierwszej serii zmian - można przystąpić do uruchomienia systemu. Należy zamknąć wszystkie okna edytora, terminale otwarte wewnątrz minix_usr. Wybierając pozycję 'Uruchom minixa' - obraz zostanie odmontowany. Następnie zostanie stworzona jego kopia zapasowa (nazwa zawierająca datę utworzenia) i obraz zostanie uruchomiony w środowisku qemu. Po zamknięciu emulatora - obraz zostanie ponownie zamontowany w katalogu minix_usr - można powrócić do jego edycji.
	----------------
	7. W przypadku gdy obecnie edytowany obraz stanie się martwy (na przykład skompilowane jądro nie uruchamia się) możliwe jest przywrócenie poprzedniej wersji. Po wybraniu odpowiedniej wersji - skrypt skopiuje ją jako roboczą. Możliwe jest też rozpoczęcie od czystej wersji systemu.
	----------------
	8. Po zakończonej pracy istnieje możliwość:
		- Wyeksportowania zmian do archiwum. Skrypt porówna oryginalny i obecny obraz pod kątem zmian - wszystkie zmienione pliki zostaną spakowane do archiwum .zip, którego nazwa zostanie wyświetlona. Archiwum zostanie utworzone w tym katalogu, co skrypt. Przy tworzeniu archiwum pomijane są pliki wykonywalne i obiekty. Do uruchomienia tej funkcji - system macierzysty (Linux) potrzebuje dostępnego polecenia zip.
		- Przeniesienia obecnego obrazu na nośnik zewnętrzny (na przykład pendrive). Skrypt zakłada, że system automatycznie montuje pendrive'y w katalogu /media/?/?. W przypadku gdy system tego nie robi - konieczne jest zamontowanie ręczne. 



FAQ:
	Q:	Błąd: Nie odnaleziono polecenia qemu-system-i386 (...)
	A:	Na komputerze nie jest zainstalowany emulator qemu. Pod Ubuntu / Debianem należy wykonać: 'sudo apt-get update' (aktualizacja listy pakietów), następnie 'sudo apt-get install qemu'
	
	Q:	Błąd: Nie udało się odmontować katalogu (...)
	A:	Katalog roboczy jest obecnie zajęty - któryś z plików znajdujących się w nim jest otwarty lub sam katalog znajduje się w którymś terminalu