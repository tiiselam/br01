select *
--distinct SPED_IND_CTA, sped_nivel
from SPEDtbl004
order by SPED_COD_CTA
------------------------------------------------------------------------------------------------
--Verifica la jerarquía de cuentas
select * 
from SPEDtbl004 n2	
left join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 1) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 1
where n2.SPED_NIVEL = 2
and n1.SPED_COD_CTA is null

select * 
from SPEDtbl004 n2	
left join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 4) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 2
where n2.SPED_NIVEL = 3
and n1.SPED_COD_CTA is null

select * 
from SPEDtbl004 n2	
left join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 7) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 3
where n2.SPED_NIVEL = 4
and n1.SPED_COD_CTA is null

select * 
from SPEDtbl004 n2	
left join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 10) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 4
where n2.SPED_NIVEL = 5
and n1.SPED_COD_CTA is null

select * 
from SPEDtbl004 n2	
left join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 13) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 5
where n2.SPED_NIVEL = 6
and n1.SPED_COD_CTA is null
--------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------
--Actualiza el indicador de agrupamiento por niveles
--
--select * into _tmpSPEDtbl004190625
--from SPEDtbl004

--Cuentas de resultado = 04
--último nivel debería ser sólo A
select distinct n2.SPED_IND_CTA
from SPEDtbl004 n2	
where --n2.SPED_IND_CTA = 'S'
 n2.SPED_NIVEL = 6
 and n2.SPED_COD_NAT = '04'

--el nivel 5 debería ser S
select n1.* , n2.*
--update n1 set SPED_IND_CTA = 'S'
from SPEDtbl004 n2	
inner join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 13) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 5
where n2.SPED_NIVEL = 6
 and n2.SPED_COD_NAT = '04'

--el nivel 4 debería ser 4
select n1.* , n2.*
--update n1 set SPED_IND_CTA = 'S'
from SPEDtbl004 n2	
inner join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 10) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 4
where n2.SPED_NIVEL = 5
and n2.SPED_IND_CTA = 'S'
 and n2.SPED_COD_NAT = '04'

-------------------------------------------------------------------------------------------------------
--Cuentas de resultado = 04
--último nivel debería ser sólo A
select distinct n2.SPED_IND_CTA
from SPEDtbl004 n2	
where --n2.SPED_IND_CTA = 'S'
 n2.SPED_NIVEL = 5
 and n2.SPED_COD_NAT in ('01', '02', '03')

--el nivel 4 debería ser S
select n1.* , n2.*
--update n1 set SPED_IND_CTA = 'S'
from SPEDtbl004 n2	
inner join SPEDtbl004 n1	
	on substring(n2.SPED_COD_CTA, 1, 10) = rtrim(n1.SPED_COD_CTA)
	and n1.SPED_NIVEL = 4
where n2.SPED_NIVEL = 5
 and n2.SPED_COD_NAT in ('01', '02', '03')


--se asume que los niveles 1, 2, 3 son S
select distinct SPED_IND_CTA
from SPEDtbl004
where SPED_NIVEL < 4
----------------------------------------------------------------------------------------------------------------
select *
update s set SPED_IND_CTA = 'S'
from SPEDtbl004 s
where s.sped_cod_cta = '3.01.99.01.01'

select *
update s set SPED_IND_CTA = 'S', sped_cod_cta_sup = '3.01.99.01'
from SPEDtbl004 s
where s.sped_cod_cta = '3.01.99.01.02'


insert into SPEDtbl004(DOCDATE,SPED_COD_NAT,SPED_IND_CTA,SPED_NIVEL,SPED_COD_CTA,SPED_COD_CTA_SUP,SPED_CTA,SPED_CODAGL,SPED_ES_SN,ACTDESCR)
select DOCDATE,SPED_COD_NAT, 'A', 6, '3.01.99.01.01.01', '3.01.99.01.01', SPED_CTA, '30199010101', 1, ACTDESCR
from SPEDtbl004 s
where s.sped_cod_cta = '3.01.99.01.01'


insert into SPEDtbl004(DOCDATE,SPED_COD_NAT,SPED_IND_CTA,SPED_NIVEL,SPED_COD_CTA,SPED_COD_CTA_SUP,SPED_CTA,SPED_CODAGL,SPED_ES_SN,ACTDESCR)
select DOCDATE,SPED_COD_NAT, 'A', 6, '3.01.99.01.02.01', '3.01.99.01.01', SPED_CTA, '30199010201', 1, ACTDESCR
from SPEDtbl004 s
where s.sped_cod_cta = '3.01.99.01.02'


select *
--update s set SPED_IND_CTA = 'S'
from SPEDtbl004 s
where s.sped_cod_cta = '3.01.01.07.30'

insert into SPEDtbl004(DOCDATE,SPED_COD_NAT,SPED_IND_CTA,SPED_NIVEL,SPED_COD_CTA,SPED_COD_CTA_SUP,SPED_CTA,SPED_CODAGL,SPED_ES_SN,ACTDESCR)
select DOCDATE,SPED_COD_NAT, 'A', 6, '3.01.01.07.30.01', '3.01.01.07.30', SPED_CTA, '30101073001', 1, ACTDESCR
from SPEDtbl004 s
where s.sped_cod_cta = '3.01.01.07.30'

