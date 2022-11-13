@Set Time=`%@Time[%_Time]`
@Prompt `$e[s$e[1;%@eval[%_columns-46]H$e[34;47m Disk:%@diskfree[%_disk:,m]M; Mem:%@dosmem[k]K; %@maketime[%@eval[%time%%%43200]]%@char[%@eval[%@int[%@eval[%time/43200]]*15+97]]m  $d $e[0m$e[u$P$g`

