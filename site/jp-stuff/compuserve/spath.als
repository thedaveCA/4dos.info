;
;                       PushPath & PopPath
;
; Aliases for PATH Stack - Saves and Restores up to 10 levels of
;    PATHs (SPath, SPath1, Spath2, ... SPath9) using environment
;    variables.
;
; NOTE: Enough environment memory must be available
;
; Commands are: PushP*ath, PopP*ath, AddP*ath and ClrP*ath
;
; PushPath Saves Current PATH on SPATH Stack & Sets New PATH
; PopPath Restores Previous PATH from SPATH Stack
; AddPath Saves Current PATH on SPATH Stack & Appends additional
;    entry(ies) in the PATH (placing them at beginning of PATH)
; ClrPath empties the SPATH Stack and restores PATH to DOSPATH
; DOSPATH is: "SET DOSPATH=%PATH%" in my AutoExec.Bat File
;
; Comments and improvements are welcomed and appreciated. In
;    particular, I'd like a more elegant way to implement
;    SpPo, SpPu, and ClrPath.
;
; Happy Computing with 4DOS
;
; --------------------------------------------------------------

AddP*ath=PushP1^AddP1 %&
AddP1=IFF NOT %&!==! THEN^SP2 %&;%Path%^ELSE^SP3^EndIFF
PopP*ath=IFF NOT %SPath%!==! THEN^SP0^ELSE^SPEmpty^EndIFF
PushP*ath=PushP1^PushP2 %&
PushP1=IF NOT %SPath9%!==! SPFull^SP1
PushP2=IFF NOT %&!==! THEN^SP2 %&^ELSE SP3^EndIFF
SP0=Set Path=%SPath%^SpPo^OutWPut 0 Previous Path Restored^1L
SP1=SpPu^Set SPath=%Path%^OutWPut 0 Current Path Saved^1L
SP2=Set Path=%&^OutWPut 0 Specified Path Set^1L
SP3=OutWPut 0 No Path Specified - Path Unchanged^1L
SPFull=1L^SPFull1^SPFull2^1L
SPFull1=ErrWPut -1 SPath Stack Full; Oldest Path is Lost
SPFull2=ErrWPut 0 Original Path Still Saved in DosPath.
SPEmpty=ErrWPut 0 SPath Empty - No Path to Restore^1L
ErrWPut=ScrPut %@EVAL[%_Row+%1] 7 Bri Yel ON Bla %2&
OutWPut=ScrPut %@EVAL[%_Row+%1] 7 Bri Cya ON Bla %2&
SpPo=Set SPath=%SPath1%^Set SPath1=%SPath2%^Set SPath2=%SPath3%^Set SPath3=%SPath4%^Set SPath4=%SPath5%^Set SPath5=%SPath6%^Set SPath6=%SPath7%^Set SPath7=%SPath8%^Set SPath8=%SPath9%^UnP SPath9
SpPu=Set SPath9=%SPath8%^Set SPath8=%SPath7%^Set SPath7=%SPath6%^Set SPath6=%SPath5%^Set SPath5=%SPath4%^Set SPath4=%SPath3%^Set SPath3=%SPath2%^Set SPath2=%SPath1%^Set SPath1=%SPath%
ClrP*ath=Set Path=%DosPath%^UnP SPath9^UnP SPath8^UnP SPath7^UnP SPath6^UnP SPath5^UnP SPath4^UnP SPath3^UnP SPath2^UnP SPath1^UnP SPath
UnP=IF NOT %%1!==! UnSet %1

; --------------------------------------------------------------
; Alternative Aliases (replaces the same four aliases above) for
; stacking only 4 levels of PATHs (SPath to SPath3). These four
; aliases can be changed to provide virtually any number of levels
; up to the limits of the command line. Even with 10 levels (in
; testing only, I've never used more than 2-3 levels) in use, I
; have not exceeded maximum command line length (512 in 4DOS 5.0),
; and have not run out of environment space (with a 2K
; environment). I actually use these - they use much less memory
; (I'm already pushing 16K of aliases).
; --------------------------------------------------------------

PushP1=IF NOT %SPath3%!==! SPFull^SP1
SpPo=Set SPath=%SPath1%^Set SPath1=%SPath2%^Set SPath2=%SPath3%^UnP SPath3
SpPu=Set SPath3=%SPath2%^Set SPath2=%SPath1%^Set SPath1=%SPath%
ClrP*ath=Set Path=%DosPath%^UnP SPath3^UnP SPath2^UnP SPath1^UnP SPath

; --------------------------------------------------------------
; StackPath Aliases - Version 1.00 - January 14, 1993
; First Public Release - Released into the Public Domain
; Dale F. Ogden - San Pedro, California - CIS: 96044,3556
;
