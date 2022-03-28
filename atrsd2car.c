/*--------------------------------------------------------------------*/
/* ATRsd2CAR                                                          */
/* by GienekP                                                         */
/* (c) 2022                                                           */
/*--------------------------------------------------------------------*/
#include <stdio.h>
/*--------------------------------------------------------------------*/
typedef unsigned char U8;
/*--------------------------------------------------------------------*/
#define ATRSIZE (720*128)
#define CARSIZE (128*1024)
#define LDRSIZE (8*1024)
/*--------------------------------------------------------------------*/
extern U8 starter[LDRSIZE];
/*--------------------------------------------------------------------*/
U8 checkATR(const U8 *data)
{
	U8 ret=0;
	if ((data[0]==0x96) && (data[1]==02) && (data[2]==0x80) && (data[4]==0x80))
	{
		ret=1;
	};
	return ret;
}
/*--------------------------------------------------------------------*/
U8 loadATR(const char *filename, U8 *data)
{
	U8 header[16];
	U8 ret=0;
	int i;
	FILE *pf;
	pf=fopen(filename,"rb");
	if (pf)
    {
		i=fread(header,sizeof(U8),16,pf);
		if (i==16)
		{
			if (checkATR(header))
			{
				i=fread(data,sizeof(U8),ATRSIZE,pf);
				if (i==ATRSIZE)
				{
					ret=1;
				}
				else
				{
					printf("Wrong ATR data.\n");
				};
			}
			else
			{
				printf("Unknown ATR SD header.\n");
			};
		}
		else
		{
			printf("Wrong ATR header size.\n");
		}
		fclose(pf);
	}
	else
	{
		printf("\"%s\" does not exist.\n",filename);
	};
	return ret;
}
/*--------------------------------------------------------------------*/
U8 saveCAR(const char *filename, U8 *data)
{
	U8 header[16]={0x43, 0x41, 0x52, 0x54, 0x00, 0x00, 0x00, 0x23,
		           0x01, 0xFE, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	U8 ret=0;
	int i;
	FILE *pf;
	pf=fopen(filename,"wb");
	if (pf)
    {
		i=fwrite(header,sizeof(U8),16,pf);
		if (i==16)
		{
			i=fwrite(data,sizeof(U8),CARSIZE,pf);
			if (i==CARSIZE)
			{
				ret=1;
			};			
		};
	};
	return ret;
}
/*--------------------------------------------------------------------*/
void buildCar(const U8 *loader, const U8 *atrdata, U8 *cardata)
{
	unsigned int i;
	for (i=0; i<CARSIZE; i++)
	{
		cardata[i]=0xFF;
	};
	for (i=0; i<ATRSIZE; i++)
	{
		cardata[i]=atrdata[i];
	};
	for (i=0; i<LDRSIZE; i++)
	{
		cardata[CARSIZE-LDRSIZE+i]=loader[i];
	};
}
/*--------------------------------------------------------------------*/
void first(U8 mode, U8 *atrdata, unsigned int i)
{
	static U8 f=0;
	if (mode=='c')
	{
		atrdata[i+1]=0x00;
		atrdata[i+2]=0x01;
	};
	if (f==0)
	{
		f=1;
		if (mode=='c')
		{
			printf("Replace calls:\n");
		}
		else
		{
			printf("Possible calls:\n");
		};
	};
}
/*--------------------------------------------------------------------*/
void checkJDSKINT(U8 *atrdata, U8 mode)
{
	unsigned int i;
	for (i=0; i<ATRSIZE-3; i++)
	{
		if ((atrdata[i+1]==0x53) && (atrdata[i+2]==0xE4))
		{
			if (atrdata[i]==0x20)
			{
				first(mode,atrdata,i);
				printf(" JSR JDSKINT ; 0x%06X 20 53 E4 -> 20 00 01\n",i+16);
				
			};
			if (atrdata[i]==0x4C)
			{
				first(mode,atrdata,i);
				printf(" JMP JDSKINT ; 0x%06X 4C 53 E4 -> 4C 00 01\n",i+16);
			};			
		};
		if ((atrdata[i+1]==0xB3) && (atrdata[i+2]==0xC6))
		{
			if (atrdata[i]==0x20)
			{
				first(mode,atrdata,i);
				printf(" JSR DSKINT ; 0x%06X 20 B3 C6 -> 20 00 01\n",i+16);
			};
			if (atrdata[i]==0x4C)
			{
				first(mode,atrdata,i);
				printf(" JMP DSKINT ; 0x%06X 4C B3 C6 -> 4C 00 01\n",i+16);
			};			
		};	
	};
}
/*--------------------------------------------------------------------*/
void atrsd2car(const char *atrfn, const char *carfn, U8 mode)
{
	U8 atrdata[ATRSIZE];
	U8 cardata[CARSIZE];
	if (loadATR(atrfn,atrdata))
	{
		printf("Load \"%s\"\n",atrfn);
		checkJDSKINT(atrdata,mode);
		buildCar(starter,atrdata,cardata);
		if (saveCAR(carfn,cardata))
		{
			printf("Save \"%s\"\n",carfn);
		}
		else
		{
			printf("Save \"%s\" ERROR!\n",carfn);
		};
	}
	else
	{
		printf("Load \"%s\" ERROR!\n",atrfn);
	};
}
/*--------------------------------------------------------------------*/
int main( int argc, char* argv[] )
{	
	printf("ATRsd2CAR - ver: %s\n",__DATE__);
	if (argc==3)
    {
		atrsd2car(argv[1],argv[2],0);
    }
    else if (argc==4)
    {
		char *ptr;
		ptr=argv[3];
		U8 mode=ptr[1];
		atrsd2car(argv[1],argv[2],mode);
    }
    else
    {
		printf("(c) GienekP\n");
		printf("use:\natrsd2car game.atr game.car [-c]\n");
    };
    return 0;
}
/*--------------------------------------------------------------------*/
#include "starter.h"
/*--------------------------------------------------------------------*/
