:        4CASE15.ALS by Kenneth Albanowski [70705,126]
:
:                          V 1.6
:
:     Version 1         - Mid 1991
:     Version 1.5       - January 1992
:       I implemented some suggestions from Marshall Giguere
:     Version 1.6       - July 1992
:       Corrected bug
:
:   This is a set of aliases for 4DOS Version 4.0 only.
:
:   Load it with ALIAS /R 4CASE.ALS
:
:   Have you been looking for a way to make your batch files clearer?
:   Miss the SWITCH (or SELECT) statement from your favorite programming
:   language? This alias file contains a set of aliases to allow you to use
:   PASCAL style SWITCH statements in your 4DOS batch files. Like IFF
:   commands, they are fully nestable.
:
:   They are used as follows:
:
:     SWITCH "%VAR"   ^REM  To use text, you should surround it in quotes
:        CASE "ABC"
:           ECHO This will be echoed if %VAR is equal to ABC
:        CASEIF NE "DEF"
:           ECHO This will be echoed if %VAR is not equal to DEF
:        CASETEST 1 gt 3
:           ECHO This will never be echoed.
:           ECHO Note that CASETEST does not use the original SWITCH parameter
:        CASEELSE ^rem Or ELSECASE!
:           ECHO This will only be echoed if none of the other tests
:           ECHO succeeded.
:     ENDSWITCH ^REM Or ENDCASE!
:
: If you need to contact me, E-MAIL me a message at [70705,126]
:

SWITCH*F=set case_l=%@eval[0%case_l+1]^set case_v%[case_l]=%1^IFF 1==2 then
CASE=ELSEIFF %[case_v%[case_l]] == %1 then
CASEIF=elseiff %[case_v%[case_l]] %& then
CASETEST=elseiff %& then
CASEELSE=else
:CASEDEFAULT=else
:DEFAULT=else
ENDSWITCH*F=endiff^set case_l=%@eval[%case_l-1]^if %case_l le 0 unset case_l

