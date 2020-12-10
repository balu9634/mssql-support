if OBJECT_ID('tempdb..#Indexes') is not null
begin
drop table #Indexes
end

create table #Indexes(
SchemaName nvarchar(255),
TableName nvarchar(255),
IndexName nvarchar(255),
IndexType nvarchar(255),
Avg_fragmentation float,
ActionNeed nvarchar(255),
ReorganizeIndex nvarchar(1000),
ReorganizeTable nvarchar(1000),
RebuildIndex nvarchar(1000),
RebuildTable nvarchar(1000),

)

insert into #Indexes(
SchemaName,
TableName,
IndexName,
IndexType,
Avg_fragmentation ,
ActionNeed,
ReorganizeIndex,
ReorganizeTable,
RebuildIndex ,
RebuildTable
)

select 
s.name [Schema],
t.name TableName, 
i.name IndexName,
frag.index_type_desc IndexType,
frag.avg_fragmentation_in_percent,
--frag.alloc_unit_type_desc,

(case
	when frag.avg_fragmentation_in_percent < 5 then 'Nothing'
	when frag.avg_fragmentation_in_percent between 5 and 30 then 'Reorganize'
	when frag.avg_fragmentation_in_percent > 30 then 'Rebuild' end),

CONCAT('ALTER INDEX [',i.name ,'] ON [', s.name, '].[' , t.name , '] REORGANIZE;') [ReorganizeIndex],
CONCAT('ALTER INDEX ALL ON [', s.name, '].[' , t.name ,'] REORGANIZE;') [ReorganizeAllTable],
CONCAT('ALTER INDEX [', i.name, '] ON [', s.name, '].[' , t.name, '] REBUILD ;') [RebuildIndex],
CONCAT('ALTER INDEX ALL ON [', s.name, '].[' ,  t.name ,'] REBUILD WITH (FILLFACTOR = 80, SORT_IN_TEMPDB = ON, STATISTICS_NORECOMPUTE = ON, ONLINE = ON);') [RebuildTable]

from sys.tables t 
join sys.schemas s on t.schema_id = s.schema_id
join sys.indexes i on t.object_id = i.object_id
join sys.dm_db_index_physical_stats(DB_ID(), null, null, null, null) as frag on frag.object_id = t.object_id and frag.index_id = i.index_id
where t.type = 'U' and frag.alloc_unit_type_desc = 'IN_ROW_DATA'
order by frag.avg_fragmentation_in_percent desc 

select * from #Indexes

