-----------易购购买人群流失标签--------
set hive.merge.mapredfiles = true;
set mapreduce.input.fileinputformat.split.maxsize=536870912;
set mapreduce.input.fileinputformat.split.minsize=134217728;
set mapred.min.split.size.per.node=10000000;
set hive.exec.parallel=true;
set hive.exec.parallel.thread.number=10;
set hive.exec.reducers.bytes.per.reducer=50000000;
set hive.exec.reducers.max=150;
set hive.exec.compress.intermediate=true; --开启中间结果压缩

--set statis_date=20171215;

------------------------------step 1 选取最近3个月有购买行为的会员---------------------
drop table if exists bimining.member_churn_yigou_lose_label_001;
create table bimining.member_churn_yigou_lose_label_001 stored as orc as
select distinct member_id
from   bimining.member_churn_order_info
where  pay_date>=regexp_replace(date_sub(from_unixtime(to_unix_timestamp('${hivevar:statis_date}','yyyymmdd'),'yyyy-mm-dd'),90),"-","") 
       and pay_date<='${hivevar:statis_date}' ; 

------------------------------step 3 针对未来3个月是否购买，为会员打流失标签---------------------	
drop table if exists bimining.member_churn_yigou_lose_label;
create table bimining.member_churn_yigou_lose_label stored as orc as
select t1.member_id,
        case when t2.member_id is null then '1' else '0' end as whether_churn,
		'${hivevar:statis_date}' as statis_date
from bimining.member_churn_yigou_lose_label_001 t1
left join (
             select distinct( member_id)
             from bimining.member_churn_order_info 
             where length(member_id)>2
					and pay_date>='${hivevar:statis_date}'
                    and pay_date<=regexp_replace(date_add(from_unixtime(to_unix_timestamp('${hivevar:statis_date}','yyyymmdd'),'yyyy-mm-dd'),90),"-","")  
            ) t2
on t1.member_id=t2.member_id;