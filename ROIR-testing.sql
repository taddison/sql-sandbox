/*
- Pre/post tests for CU12 and resumable rebuilds
- This singular example seems to show it takes longer and fragments the index
  - TBD if this applies widely or not
- Looks like it drives higher reads when resumable (much higher - millions vs. tens of thousands)
- Have only tested on RTM so far, once I've got a decent sample onto CU12
*/

use AdventureWorksDW2017
go
alter database current set delayed_durability = forced;
go

declare @start datetime2 = sysutcdatetime(),@timeTaken int;
alter index PK_FactProductInventory on dbo.FactProductInventory rebuild with (online=on, maxdop=1, resumable=on)
set @timeTaken = datediff(ms, @start, sysutcdatetime());

select @timeTaken as time_taken_ms, i.avg_fragmentation_in_percent, i.page_count, i.avg_fragment_size_in_pages
from sys.dm_db_index_physical_stats(db_id(),object_id('dbo.FactProductInventory'),1,null,'DETAILED') as i
where i.index_level = 0;
go

declare @start datetime2 = sysutcdatetime(),@timeTaken int;
alter index PK_FactProductInventory on dbo.FactProductInventory rebuild with (online=on, maxdop=1, resumable=off)
set @timeTaken = datediff(ms, @start, sysutcdatetime());

select @timeTaken as time_taken_ms, i.avg_fragmentation_in_percent, i.page_count, i.avg_fragment_size_in_pages
from sys.dm_db_index_physical_stats(db_id(),object_id('dbo.FactProductInventory'),1,null,'DETAILED') as i
where i.index_level = 0;
go

/*
RTM
- ROIR ON - 22s duration, 50% fragmentation
- ROIR OFF - 2s duration, 0% fragmentation

CU12
- ROIR ON - 2s duration, 0% fragmentation
- ROIR OFF - 2s duration, 0% fragmentation
*/