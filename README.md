# openvpn_installer

- Neuen Hyper-V Server erstellen (min. 2 Kerne, 1GB RAM, 64GB HDD)
- download debian https://www.debian.org/distrib/  --> 64-Bit-PC Netinst-ISO
- installation
	- alles logisch...
	- Root-Passwort ist für den Benutzer root. Damit kann man sich nicht über ssh einloggen
	- Zusätzlicher Benutzer darf sich über SSH einloggen und dann befehle mit der Root-Berechtigung ausführen
	- Partitionierung: Geführt - vollständige Festplatte
	- Einzige Platte auswählen (Hyper-V: SCSI3 (0,0,0) (sda))
	- Alle Dateien auf eine Partition, für Anfänger empfohlen
	- keine andere CD für Zusätzliche Software / Treiber
	- Spiegelserver alles belassen, wie es ist
	- kein Proxy
	- An der Paketerfassung teilnehmen? Nein!
	- Softwareauswahl: Nur ssh und Standard-Systemwerkzeuge
	- GRUB installieren? Ja!
	- auf /dev/sda
- als root anmelden
- Installationsscript herungerladen: 
	wget https://raw.githubusercontent.com/ddisaster/openvpn_installer/master/installer.sh
- starten:
	bash installer.sh
