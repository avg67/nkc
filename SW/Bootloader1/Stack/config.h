/*----------------------------------------------------------------------------
 Copyright:      Radig Ulrich  mailto: mail@ulrichradig.de
 Author:         Radig Ulrich
 Remarks:
 known Problems: none
 Version:        16.11.2008
 Description:    Webserver Config-File

 Dieses Programm ist freie Software. Sie k�nnen es unter den Bedingungen der
 GNU General Public License, wie von der Free Software Foundation ver�ffentlicht,
 weitergeben und/oder modifizieren, entweder gem�� Version 2 der Lizenz oder
 (nach Ihrer Option) jeder sp�teren Version.

 Die Ver�ffentlichung dieses Programms erfolgt in der Hoffnung,
 da� es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE,
 sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT
 F�R EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

 Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
 Programm erhalten haben.
 Falls nicht, schreiben Sie an die Free Software Foundation,
 Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
------------------------------------------------------------------------------*/
#include <stdbool.h>
#include <stdint.h>

/**
 * \ingroup main	Hauptprogramm
 *
 */

/**
 * \file
 * Konfigurationsdatei
 *
 * \author Ulrich Radig & W.Wallucks, Andreas Voggeneder
 */

#ifndef _CONFIG_H_
	#define _CONFIG_H_

	#define USE_ENC28J60	0	// ETH_M32_EX / Webmodul (www.ulrichradig.de)
	#define USE_RTL8019		0	// Holger Buss (www.mikrocontroller.com) Mega32-Board
	#define NET_IO_BOARD	0	// NET_IO_BOARD (Pollin)
    #define USE_CS8900      1

	//! Umrechnung von IP zu unsigned long
	#define IP(a,b,c,d) ((unsigned long)(d)<<24)+((unsigned long)(c)<<16)+((unsigned long)(b)<<8)+a

	//IP des Webservers
	#define MYIP		IP(192,168,0,99)	//!< default IP des Webservers

	//Netzwerkmaske
	#define NETMASK		IP(255,255,255,0)	//!< default Netzwerkmaske

	//IP des Routers
	#define ROUTER_IP	IP(192,168,0,1)		//!< default IP des Routers/Gateway

    //DHCP-Server
    #define USE_DHCP    1 //1 = DHCP Client on
	//IP des DNS-Servers
	#define USE_DNS		1					//!< mit/ohne DNS-Client
	#define DNS_IP		IP(192,168,0,1)		//!< IP des DNS-Servers
    #define USE_IP      0
    #define USE_UDP     1

	//NTP Einstellen der Zeit mittels NTP
	//#define USE_NTP		1 					//!< 1 = NTP Client on
	#define NTP_IP		IP(85,10,196,184)	//!< IP des NTP-Servers z.B. Server 1.de.pool.ntp.org
	#define NTP_SERVER	"1.de.pool.ntp.org"	//!< hostname des NTP-Servers, wird �ber DNS aufgel�st

	// don't touch! -- NTP-Server wird über DNS aufgelöst
	#if USE_NTP
	#undef	USE_DNS
	#define USE_DNS			1
	#endif

	//Broadcast-Adresse für WOL
	#define USE_WOL			0 				//!< 1 = WOL on
	#define WOL_BCAST_IP	IP(192,168,0,255)
	#define WOL_MAC 		{0x00,0x1A,0xA0,0x9C,0xC6,0x0A}

	//! MAC Adresse des Webservers
	#define MYMAC1	0x00
	#define MYMAC2	0x20
	#define MYMAC3	0x18
	#define MYMAC4	0xB1
	#define MYMAC5	0x15
	#define MYMAC6	0x3F


/** Kamera ************/
	//Kamera mit einbinden
	//Kamera arbeitet nur mit einem 14,7456Mhz Quarz!
	#define USE_CAM			0
	#define USE_SERVO		0
	//In cam.c k�nnen weitere Parameter eingestellt werde
	//z.B. Licht, Kompression usw.
	//Aufl�sungen
	//0 = 160x120 Pixel k�rzer (zum testen OK ;-)
	//1 = 320x240 Pixel ca. 10 Sek. bei einem Mega644
	//2 = 640x480 Pixel l�nger (dauert zu lang!)
	#define CAM_RESOLUTION	1

/** SD-Karte **********/
	// USE_MMC ist Voraussetzung f�r
	// - TCP_SERVICE	FTP ohne Dateisystem ist nicht sinnvoll ;-)
	// - E_Mail			Mailtexte werden von Karte gelesen
	// - Scheduler		Konfiguration der Schaltzeiten auf SD-Karte
	// - Logdatei		8-))
	//
	#define USE_MMC			0		//!< mit/ohne SD-Karte
	#define MAX_PATH		63		//!< maximale Pfadl�nge f�r FAT16-Directory

/** TCP-Service *******/
	#define TCP_SERVICE		0		//!< mit/ohne TCP-Service (FTP, Telnet-Cmdline)
	#define MYTCP_PORT		61234	//!< Port# f�r Telnet-Cmd Interpreter
	#define DOS_LIST		1		//!< DOS style Directory-Listing
	//#define UNIX_LIST		1
	#define FTP_ANONYMOUS	1		//!< anonymen Login (ohne User/Kennwort) erlauben
	#define FTP_USER		"chef"	//!< FTP-User, falls nicht anonym
	#define FTP_PASSWORD	"123"	//!< FTP-Passwort

	// don't touch!
	#ifdef DOS_LIST
		#undef UNIX_LIST
	#endif

/** Passwort **********/
	#define HTTP_AUTH_DEFAULT	1	//!< Webserver mit Passwort? (0 == mit Passwort)

	//AUTH String "USERNAME:PASSWORT" max 14Zeichen
	//f�r Username:Passwort
	#define HTTP_AUTH_STRING "admin:uli1"

/** E-Mail ************/
    #define USE_MAIL			1			//!< sendmail verwenden
	#define MAIL_DATAFILE		"mail.ini"	//!< Datei f�r E-Mail Runtime-Konfiguration

	// don't touch! -- Mail ben�tigt DNS-Aufl�sung und die SD-Karte
	#if USE_MAIL
	#undef	USE_DNS
	//#define USE_DNS			1
	#endif

/** Webserver abfragen **/
    //! Empfang von Wetterdaten auf der Console (�ber HTTP_GET)
    #define GET_WEATHER			0

/** Telnet -> Befehlszeile oder USART *********/
    #define CMD_TELNET      	0			//!< Kommandos und Ausgaben erfolgen �ber Telnet (Port 23)

/** Infrarot Fernbedienung **/
	#define USE_RC5				0
	#define	RC5_DDR				DDRC		//!< IR input port Data Direction Register
	#define	RC5_INPORT			PINC		//!< IR input port
	#define	RC5_PIN				PC5			//!< \port PC5 - IR input pin

/** Scheduler *********/
    #define USE_SCHEDULER		1			//!< Scheduler verwenden
	#define	TM_MAX_SCHALTZEITEN	16			//!< Anzahl unterschiedlicher Schaltzeiten
	#define SCHED_INIFILE		"avr.ini"	//!< Dateiname f�r Schaltzeiten
	#define TIME_TEMP			60			//!< jede Minute (60 sec) Temperaturen messen
	//#define USE_LOGDATEI		1			//!< Logdatei schreiben

	#define MAX_VAR_ARRAY		10			//!< Anzahl Speicherpl�tze f�r Messwerte etc.

/*------------------------------------*/
    // don't touch!
    #if NET_IO_BOARD
        #undef	USE_ENC28J60		// Net_IO l�uft mit ENC28J60
        #define USE_ENC28J60	1

        #undef	USE_MMC				// Net_IO hat keine SD-Karte
        #define USE_MMC			0
    #endif

    // don't touch! -- siehe oben unter SD-Karte
    #if !USE_MMC
        #undef  TCP_SERVICE
        #define TCP_SERVICE 	0

        #undef  USE_MAIL
        #define USE_MAIL 		0

        #undef  USE_SCHEDULER
        #define USE_SCHEDULER	0

        #undef  USE_LOGDATEI
        #define USE_LOGDATEI	0

        #undef	USE_DNS
        #define USE_DNS			0
    #endif

    //#if TCP_SERVICE
        #define _CMD_H_
    //#else
    //	#define _TCPCMD_H_
    //#endif

/*------------------------------------
*	typedefs
*/
#ifndef __STDINT_H_
	#include <stdint.h>
#endif


#if USE_MMC

#include "sdkarte/fat16.h"	// Definitionen f�r Dateisystem-Strukturen

/**
 *	\ingroup sdkarte
 *	FAT Dateistruktur
 */
typedef struct fat16_file_struct
{
    struct fat16_fs_struct* fs;					//!<
    struct fat16_dir_entry_struct dir_entry;	//!<
    uint32_t pos;								//!< aktuelle Schreib-/Lese-Position in Datei
    uint16_t pos_cluster;						//!< aktueller Datei cluster im Puffer
	char	mode;								//!< file open mode
} File;

/**
 *	\ingroup main
 *	Status der Logdatei
 */
typedef struct
{
    const char			log_datei[13];	//!< aktueller Dateiname der Logdatei
    File 				*logfile;		//!< Zeiger auf FILE-Struktur der offenen Logdatei
    volatile uint8_t	logTag;			//!< Tag der Logdatei
    volatile uint8_t	logMonat;		//!< Monat der Logdatei
    volatile uint8_t	logJahr;		//!< Jahr der Logdatei
} LOG_STATUS;

#endif


/*------------------------------------
*	globale Variable
*/
#if USE_MMC
    extern 			LOG_STATUS		logStatus;
#endif

#endif //_CONFIG_H


/*
 */
