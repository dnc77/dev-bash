#!/bin/bash
: '

/*
Date: 03 May 2022 02:15:09.914343561
File: shellcmdcounter.sh

Copyright Notice
This document is protected by the GNU General Public License v3.0.

This allows for commercial use, modification, distribution, patent and private
use of this software only when the GNU General Public License v3.0 and this
copyright notice are both attached in their original form.

For developer and author protection, the GPL clearly explains that there is no
warranty for this free software and that any source code alterations are to be
shown clearly to identify the original author as well as any subsequent changes
made and by who.

For any questions or ideas, please contact:
github:  https://github(dot)com/dnc77
email:   dnc77(at)hotmail(dot)com
web:     http://www(dot)dnc77(dot)com

Copyright (C) 2022 Duncan Camilleri, All rights reserved.
End of Copyright Notice

Purpose: Someone in a public channel has asked for help to get the bash shell
echo line numbers such that for every command entered, the next line number
will be displayed on the shell prompt. As this sparked curiosity, I looked
into it so here is a quick attempt at doing that.

Run as follows:
. ./shellcmdcounter.sh

This will change your command prompt to: [1] <path> >
Each line will be incremented accordingly.

Other uses for this; let''s say you would like to display free disk space
on the prompt, this can easily be done using a similar approach. 

Notes: We might think of a solution to try and eliminate the use of a file.

Version control
03 May 2022 Duncan Camilleri           Initial development
*/

'

terminallines() {
   CUR=`cat ~/.termlinecount.txt`
   echo $(((CUR+1))) > ~/.termlinecount.txt
   echo "[$CUR] $PWD> "
}

echo 1 > ~/.termlinecount.txt
export PS1="\$(terminallines)"

