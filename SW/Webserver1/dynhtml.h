#ifndef _DYNHTML_INCLUDED_
#define _DYNHTML_INCLUDED_

// Structure for ROM- FS
typedef const struct{
    unsigned char const * const pData;				// Pointer to File Data Structure
    char const * const pName;						// Pointer to File Name
    char const * const pTypeStr;					// Pointer to Typestring
    uint16_t size;						            // Filesize (sizeof(Data))
    char const * const pRealm;						// Realm for Authentification
    //	tDynHtml code *pDyn;
    unsigned char (*f)(char *, char *, unsigned char);  // Pointer to Callback Function to insert dynamic Values
}tFile;

#endif
