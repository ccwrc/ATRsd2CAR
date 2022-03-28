/*--------------------------------------------------------------------*/
#include <stdio.h>	
/*--------------------------------------------------------------------*/
int main(void)
{
	unsigned int i,j;
    FILE *fi,*fo;
    fi=fopen("starter.bin","rb");
    if (fi)
    {
		fo=fopen("starter.h","w");
		if (fo)
		{
			fprintf(fo,"unsigned char starter[8192]={\n");
			for (j=0; j<512; j++)		
			{
				for (i=0; i<16; i++)
				{
					unsigned char c;
					c=getc(fi);
					fprintf(fo,"0x%02x",(unsigned int)(c));	
					if ((i==15) && (j==511))
					{
						fprintf(fo,"};");
					}
					else
					{
						fprintf(fo,",");
					};		
				};
				fprintf(fo,"\n");
			};
			fclose(fo);
		}
		fclose(fi);
	};
	return 0;
}
/*--------------------------------------------------------------------*/
