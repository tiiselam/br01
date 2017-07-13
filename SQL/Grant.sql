/*Count : 1 */

declare @cStatement varchar(255)

declare G_cursor CURSOR for select 'grant select,update,insert,delete on [' + convert(varchar(64),name) + '] to DYNGRP' from sysobjects 
	where (type = 'U' or type = 'V') and uid = 1

set nocount on
OPEN G_cursor
FETCH NEXT FROM G_cursor INTO @cStatement 
WHILE (@@FETCH_STATUS <> -1)
begin
	EXEC (@cStatement)
	FETCH NEXT FROM G_cursor INTO @cStatement 
end
DEALLOCATE G_cursor

declare G_cursor CURSOR for select 'grant execute on [' + convert(varchar(64),name) + '] to DYNGRP' from sysobjects 
	where type = 'P'  

set nocount on
OPEN G_cursor
FETCH NEXT FROM G_cursor INTO @cStatement 
WHILE (@@FETCH_STATUS <> -1)
begin
	EXEC (@cStatement)
	FETCH NEXT FROM G_cursor INTO @cStatement 
end
DEALLOCATE G_cursor
