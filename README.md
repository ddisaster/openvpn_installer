# openvpn_installer

- Neuen Hyper-V Server erstellen (min. 2 Kerne, 1GB RAM, 64GB HDD)
- download debian https://www.debian.org/distrib/  --> 64-Bit-PC Netinst-ISO
- installation
	- alles logisch...
	- Partitionierung: Geführt - vollständige Festplatte
	- keine andere CD
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
