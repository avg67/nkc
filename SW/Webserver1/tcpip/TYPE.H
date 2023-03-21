/* $Workfile:   type.h $									 								  			*/
/* $Revision: 1.1 $                                              	*/
/* $Author: hse00045 $                           	                */
/* $Date: 2003/09/02 19:31:38 $																    */
/* Description:	Datatype definitions for Socket Library        		*/
/*																											          */
/* Remarks:     No remarks.                                       */

#ifndef _TYPE_H_
#define _TYPE_H_


typedef	unsigned char	BYTE;		// 8-bit value
typedef	unsigned char	UCHAR;		// 8-bit value
typedef	unsigned int	INT;		// 16-bit value
typedef	unsigned int	UINT;		// 16-bit value
typedef	unsigned short	USHORT;		// 16-bit value
typedef	unsigned short	WORD;		// 16-bit value
typedef	unsigned long	ULONG;		// 32-bit value
typedef	unsigned long	DWORD;		// 32-bit value

// bsd
typedef unsigned char	u_char;		// 8-bit value
typedef unsigned short	u_short;	// 16-bit value
typedef unsigned int	u_int;		// 16-bit value
typedef unsigned long	u_long;		// 32-bit value

typedef UCHAR	SOCKET;


/* Type for treating 4 byte variables with byte by byte */
typedef union _un_l2cval {
	u_long	lVal;
	u_char	cVal[4];
}un_l2cval;

/* Type for treating 2 byte variables with byte by byte */
typedef union _un_i2cval {
	u_int	iVal;
	u_char	cVal[2];
}un_i2cval;

#endif
