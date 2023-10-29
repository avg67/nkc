#include <algorithm>
//#include <vector>
#include "highscore.h"

#define SetCurrentColor SetCurrentFgColor
#define BGCOLOR             (WHITE|DARK)
#define BUFFER_SIZE         1024u

highscore::highscore(const char* const p_FileName)
{
//    this->FileName=FileName;
    strncpy(this->FileName,p_FileName,MAX_FILE_NAME_LENGTH);
    this->FileName[MAX_FILE_NAME_LENGTH - 1]='\0';
    this->p_buffer = (char *) malloc(BUFFER_SIZE);
    memset(this->p_buffer,0,BUFFER_SIZE);
    this->loaded=Load();
}

highscore::~highscore()
{
    free(this->p_buffer);
}

//bool highscore::load_highscore(highscore_t * const p_highscore, const size_t hs_buf_len) {
bool highscore::Load(void) {
    jdfcb_t myfcb={0};
    const size_t hs_buf_len = BUFFER_SIZE;
    highscore_t* p_hs = (highscore_t*)this->p_buffer;
    //iprintf("BFR: 0x%X ",(unsigned int)this->p_buffer);
    uint8_t result = jd_fillfcb(&myfcb,this->FileName);
    if (result==0) {
        //iprintf("FCB:0x%X ",(unsigned int)&myfcb);
        jdfile_info_t info __attribute__ ((aligned (4))) = {0u};
        result = jd_fileinfo(&myfcb, &info);
        //iprintf("Fileinfo-Result: 0x%X length: %u %u date:0x%lX, att:0x%X\r\n",result, (unsigned int)info.length, (unsigned int)hs_buf_len, info.date, info.attribute);
        if ((result==0) && (hs_buf_len>=info.length)) {
            result = jd_fileload(&myfcb, (char*const)p_hs);
            //iprintf("Fileload-Result: %u filename:%s %s\r\n",result, myfcb.filename, myfcb.fileext);
        }
   }else{
        // file not found. Create a new one
        p_hs->nr_entries=0u;
   }
   return (result==0)?true:false;
}

bool highscore::Append(const char* const p_name, const time_t time, const uint16_t duration, const uint16_t level)
{
    bool success=false;
    highscore_t* p_hs = (highscore_t*)this->p_buffer;
    if (p_hs->nr_entries < ARRAY_SIZE(p_hs->hs)) {
        const uint16_t i= p_hs->nr_entries;
        p_hs->nr_entries++;
        strncpy(p_hs->hs[i].name,p_name,MAX_NAME_LENGTH);
        filter_string(p_hs->hs[i].name);
        p_hs->hs[i].name[MAX_NAME_LENGTH-1u]='\0';
        p_hs->hs[i].date     = time;
        p_hs->hs[i].duration = duration;
        p_hs->hs[i].level    = level;
//        success=save_highscore(&hs,sizeof(hs));
        //iprintf("Appended %u\r\n",i);
        success=true;
    }

    return success;
}

bool highscore::Save(void) {
   jdfcb_t myfcb={0};
   uint8_t result = jd_fillfcb(&myfcb,this->FileName);
   if (result==0) {
      result = jd_filesave(&myfcb, (const char*const)this->p_buffer, sizeof(highscore_t));
      //iprintf("Filesave-Result: 0x%X\r\n",result);
   }
   return (result==0)?true:false;
}

bool highscore::GetLoaded(void)
{
    return this->loaded;
}

uint8_t highscore::InsertSorted(const char* const p_name, const time_t time, const uint16_t duration, const uint16_t level)
{
    uint16_t found_idx = 0u;
    bool found = false;
    highscore_t* p_hs = (highscore_t*)this->p_buffer;
    if (p_hs->nr_entries>0u) {
        for (uint16_t i=0u;i<p_hs->nr_entries;i++) {
            if((p_hs->hs[i].level == level) && (p_hs->hs[i].duration >= duration)) {
                found_idx = i;
                found     = true;
                iprintf("Found: %u for level %u\r\n",i, level);
                break;
            }
        }
        const uint16_t nr_items = std::min(p_hs->nr_entries, (uint16_t)(MAX_ENTRIES-1u));
        if (found) {
            for (uint16_t j=nr_items;j>found_idx;j--) {
                memcpy(&p_hs->hs[j], &p_hs->hs[j-1], sizeof(highscore_entry_t));
            }
        }else if (p_hs->nr_entries < MAX_ENTRIES) {
             // Append one item
            found_idx = p_hs->nr_entries;
        }
    }

    p_hs->hs[found_idx] = {
        .date     = time,
        .duration = duration,
        .level    = level
    };
    strncpy(p_hs->hs[found_idx].name,p_name,MAX_NAME_LENGTH);
    filter_string(p_hs->hs[found_idx].name);
    p_hs->hs[found_idx].name[MAX_NAME_LENGTH-1u]='\0';
    if(p_hs->nr_entries < MAX_ENTRIES) {
        p_hs->nr_entries++;
    }

    return found_idx;
}
#ifdef USE_GDP_FPGA
void highscore::write_with_bg(const char * const p_text, const uint8_t fg, const uint8_t bg, uint8_t length)
{
   gp_setcolor(fg,bg);
   const size_t len = strlen(p_text);
   puts(p_text);

   uint16_t x_pos=0u;
   uint16_t y_pos=0u;
   gp_getxy(&x_pos,&y_pos);
   //gp_erapen();
   gp_setxor(true);

   uint16_t dx; //= (41-4+24)*6u;
   if(!length) {
      dx = (len*6u); // use text-length
   }else{
      dx = length*6u;
   }
   uint8_t loops=1u;
   if(dx>=256u) {
      dx/=2u;
      loops++;
   }

   for(uint8_t page=0u;page<2u; page++) {
      gp_newpage(page,0u);

      uint16_t x = x_pos-(len*6u);
      for(uint8_t j=0u;j<loops;j++) {
         gp_draw_filled_rect(x,y_pos*2u,dx,18u);   // need to keep dx < 256 to prevent xor artifacts
         x+=dx;
      }
      //gp_draw_filled_rect(x+dx,y_pos*2u,dx,16u);   // //(len*6u),16u);
   }
   //gp_setpen();
   gp_setxor(false);
}
#endif

void highscore::filter_string(char* p_string)
{
   char ch;
   do {
      ch = *p_string;
      if (ch<' ') {
         *p_string = '\0';
      }
      p_string++;
   }while(ch!='\0');
}

void highscore::Display(const uint16_t filter)
{
    this->Display(filter, UINT8_MAX);
}

#ifdef USE_GDP_FPGA
void highscore::Display(const uint16_t filter, const uint8_t hlEntry) {
   char linebuf[80];
   siprintf(linebuf," Highscore: for %s Level",(filter)?"Intermediate":"Beginner");
   //write_with_bg(" Highscore:",BLUE, BLACK, 0u);
   write_with_bg(linebuf,BLUE, BLACK, 0u);
   puts("\r\n");

   highscore_t * const p_hs = (highscore_t * const)this->p_buffer;
   write_with_bg(" Nr: Duration  Played at         Name",WHITE,BLACK,HS_TABLE_LENGTH);   // 41 characters, name max 24 chars
   gp_setcolor(BLACK,BLACK);
   char timebuf[20];
   uint16_t line=0u;

    for (uint16_t i=0;i<std::min(p_hs->nr_entries,(uint16_t)MAX_ENTRIES_TO_SHOW);i++) {
        if ((filter == UINT16_MAX) || (p_hs->hs[i].level == filter)) {
            const struct tm * const p_tm = localtime(&p_hs->hs[i].date);
            filter_string(p_hs->hs[i].name);
            //strftime(timebuf, sizeof(timebuf), "%d.%m.%y %H:%M:%S", localtime(&p_hs->hs[i].date));
            //const char mode=(p_hs->hs[i].level>0u)?'I':'B';
            siprintf(timebuf,"%02u.%02u.%02u %02u:%02u:%02u",p_tm->tm_mday,p_tm->tm_mon+1u,p_tm->tm_year-100u,p_tm->tm_hour,p_tm->tm_min,p_tm->tm_sec);
            siprintf(linebuf," %-2u: %-6u %20s %s",line+1u, (unsigned int)p_hs->hs[i].duration, timebuf, p_hs->hs[i].name);
            uint8_t fg = (line & 1u)?GRAY:WHITE|DARK;
            if (i==hlEntry) {
                fg = GREEN;
            }
            write_with_bg(linebuf,fg,BLACK,HS_TABLE_LENGTH);
            line++;
        }
    }
    gp_setcolor(BLACK,BLACK);
}
#else
void highscore::Display(const uint16_t filter, const uint8_t hlEntry) {
   iprintf(" Highscore: for %s Level\r\n\r\n",(filter)?"Intermediate":"Beginner");

   highscore_t * const p_hs = (highscore_t * const)this->p_buffer;
   iprintf(" Nr: Duration  Played at         Name\r\n");   // 41 characters, name max 24 chars
   char timebuf[20];
   uint16_t line=0u;

    for (uint16_t i=0;i<std::min(p_hs->nr_entries,(uint16_t)MAX_ENTRIES_TO_SHOW);i++) {
        if ((filter == UINT16_MAX) || (p_hs->hs[i].level == filter)) {
            const struct tm * const p_tm = localtime(&p_hs->hs[i].date);
            filter_string(p_hs->hs[i].name);
            char c=' ';
            if (i==hlEntry) {
                c='*';
            }
            siprintf(timebuf,"%02u.%02u.%02u %02u:%02u:%02u",p_tm->tm_mday,p_tm->tm_mon+1u,p_tm->tm_year-100u,p_tm->tm_hour,p_tm->tm_min,p_tm->tm_sec);
            iprintf("%c%-2u: %-6u %20s %s\r\n",c,line+1u, (unsigned int)p_hs->hs[i].duration, timebuf, p_hs->hs[i].name);

            line++;
        }
    }
}
#endif



