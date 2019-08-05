USE [GBRA]
GO

IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = 'dbo'
     AND SPECIFIC_NAME = 'SPED_ArchivoTXT_l600' 
)
   DROP PROCEDURE dbo.SPED_ArchivoTXT_l600;
GO

-- =========================================================================================================================
-- Propósito. Genera los datos del archivo SPED en la tabla spedtbl9000
-- Requisito. El mapeo de plan de cuentas debe estar en el campo gl00100.userdef1
--			Una cuenta local puede agrupar varias cuentas GP
--			La jerarquía de cuentas locales debe estar en SPEDtbl004. 
--			El campo SPED_CODAGL es el código agrupador. Puede diferir del sped_cod_cuenta.
--			El campo SPED_IND_CTA debe indicar el valor A cuando es el último nivel, S cuando es cualquier otro nivel
--2017.. ltoro
--24/06/19 jcf Redefine funciones de generación de saldos y extiende el uso de jerarquia de cuentas de cualquier nivel
--05/08/19 jcf Obtiene código referencial de userdef2
-- =========================================================================================================================

create PROCEDURE [dbo].[SPED_ArchivoTXT_l600] 
	@IdCompañia varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	declare @contador int
	set @contador=1

	SET NOCOUNT on;

	delete spedtbl9000

INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador,'0000',isnull('|0000|'+	---REG   C1,
		'LECD|'+								--- LEC C1D,
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+	--- DT_INI C3,
		rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+	---DT_FIN C4,
		rtrim(isnull(com.CMPNYNAM,''))+'|'+	---NOME C5
		rtrim(isnull(com.TAXREGTN,''))+'|'+	---CNPJ, C6
		rtrim(isnull(conf.speduf,''))+'|'+	--- UF, C7
		rtrim(isnull(conf.spedIE,''))+'|'+	---IE, C8
		rtrim(isnull(com.COUNTY,''))+'|'+	--- AS CÓD_MUN, C9
		rtrim(isnull(conf.sped_IM,''))+'|'+	--- AS IM, C10
		rtrim(case when conf.SPED_IND_SIT_ESP=0 then '' else str(conf.SPED_IND_SIT_ESP) end)+	--- AS IND_SIT_ESP C11
		'|0|1|0||'+cast(CONF.sped_ind_grande_porte as varchar(1))+								--- AS IND_GRANDE_PORTE C16
		'|0||'+CASE CONF.SPED_IDENT_MF WHEN 0 THEN 'N' ELSE 'S' END+							--- AS IDENT_MF C19
		'|N|','')
			---SECCION 0000
	from dynamics.dbo.SY01500  com 
	left join SPEDtbl001 conf on com.INTERID =conf.INTERID
insert into spedtbl9000 (linea, seccion, datos)	
		SELECT @contador+1,'0001',isnull('|0001|'+	--- AS REG,
			'0|','')	--- AS INI
insert into spedtbl9000 (linea,seccion, datos)	
	values(@contador+2,'0007',isnull('|0007|'+	--- AS REG,
		   'SP|'+		---  AS COD_ENT_REF,
		   'Livro Diário Completo|',''))	--- AS CÓD_INSCR			---SECCION 0007
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+3,'0990',isnull('|0990|'+	--- AS REG,
			'4|',''))		--- AS QTD_LIN_0							---SECCION 0990
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+4,'I001',isnull('|I001|'+	--- AS REG,
			'0|',''))		---AS IND_DAD								---SECCION I001
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+5,'I010',isnull('|I010|'+	--- AS REG,
			'G|'+		--- AS IND_ESC,
			'6.00|'	,''))	--- AS CÓD_VER_LC						---SECCION I010
			set @contador=@contador+5
insert into spedtbl9000 (linea,seccion, datos)	
	SELECT @contador+1,'I030',
			isnull('|I030|'+				--- AS REG,  C1
			'TERMO DE ABERTURA|'+	--- AS DNRC_ABERT,    C2
			ltrim(rtrim(STR(CONF.SPED_NUM_ORD)))+'|'+	--- AS NUM_ORD	, C3
			'G|'+					--- AS NAT_LIVR,
			'*|'+					--- AS QTD_LIN,					--- CANTIDAD DE LINEAS DEL ARCHIVO   C4
			rtrim(COM1.CMPNYNAM)+'|'+	--- AS NOME,
			ltrim(rtrim(CONF.SPED_NIRE))+'|'+	--- AS NIRE,
			Rtrim(COM1.TAXREGTN)+'|'+	---  AS CNPJ,
			rtrim(replace(convert(char,convert(datetime,CONF.SPED_DT_ARQ,103),103),'/',''))+'|'+	--- AS DT_ARQ,
			rtrim(replace(convert(char,convert(datetime,CONF.SPED_DT_ARQ_CONV,103),103),'/',''))+'|'+	--- AS DT_ARQ_CONV,
			rtrim(com1.CITY)+'|','')+	--- AS DESC_MUN				----SECCION I030
			rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|' 
	from dynamics.dbo.SY01500  com1 
	left join SPEDtbl001 conf on com1.INTERID =conf.INTERID
	where com1.INTERID =@IdCompañia
--------------------------------------------------------------------------------
--Inicio I050 Plano de Contas
declare @docdate as DATETIME
declare @SPED_COD_NAT as varchar(2)
declare @sped_cod_cta as varchar(50)
declare @SPED_IND_CTA as varchar
declare @SPED_NIVEL as int
declare @SPED_COD_CTA_SUP as varchar(50)
declare @SPED_CTA as varchar(50)
declare @ACTDESCR as varchar(80)
DECLARE @SPED_CODAGL AS VARCHAR(20)
DECLARE @USERDEF1 AS VARCHAR(50)
DECLARE @USERDEF2 AS VARCHAR(50)
declare @codigogp as varchar(50)

declare PlanCuentas_Cursor cursor for
(SELECT DOCDATE,
		SPED_COD_NAT,
		SPED_COD_CTA,
		SPED_IND_CTA,
		SPED_NIVEL,
		SPED_COD_CTA_SUP,
		SPED_CTA,
		gc.ACTDESCR, 
		gc.sped_codagl
	from SPEDtbl004 gc 
	WHERE SPED_ES_SN=1
	) 
	order by SPED_COD_CTA

open PlanCuentas_Cursor
FETCH NEXT FROM PlanCuentas_Cursor into 
		@docdate,
		@SPED_COD_NAT,
		@sped_cod_cta,
		@SPED_IND_CTA,
		@SPED_NIVEL,
		@SPED_COD_CTA_SUP,
		@SPED_CTA,
		@ACTDESCR,
		@SPED_CODAGL

WHILE @@FETCH_STATUS = 0  
begin
	set @contador=@contador+1
	if /*@SPED_NIVEL=4 ---*/@SPED_IND_CTA='S'
	begin
	insert into spedtbl9000 (linea,seccion,datos)	
		values (@contador+1,'I050',
				isnull('|I050|'+	--- AS REG,'',
				rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
				RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
				rtrim(ltrim(@SPED_IND_CTA))+'|'+	--- AS IND_CTA,
				LTRIM(STR(@SPED_NIVEL))+'|'+		--- AS NÍVEL,
				RTRIM(@sped_cod_cta)+'|'+			--- AS CÓD_CTA,
				RTRIM(@SPED_COD_CTA_SUP)+'|'+		--- AS CÓD_CTA_SUP,
				RTRIM(@ACTDESCR)+'|',''))			--- CTA
	end
	if @SPED_IND_CTA='A'
	begin
		declare Cuentas_gp cursor for 
		(select cuentaGP, cuentaSped, cuentaRefSped, max(cgp.ACTDESCR) as ACTDESCR  
		from dbo.vwSpedPlanDeCuentasGP cgp 
		where cgp.cuentaSped = rtrim(@sped_cod_cta)
		group by cuentaGP, cuentaSped, cuentaRefSped)
		order by cuentaGP

		open Cuentas_gp
		fetch next from cuentas_gp into @codigogp, @USERDEF1, @USERDEF2, @Actdescr
		while @@FETCH_STATUS=0
		begin
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion,datos)	
				values (@contador+1,'I050',
						isnull('|I050|'+					--- AS REG,'',
						rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
						RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
						RTRIM(@SPED_IND_CTA)+'|'+			--- AS IND_CTA,
						LTRIM(STR(@SPED_NIVEL))+'|'+		--- AS NÍVEL,
						RTRIM(@sped_cod_cta)+'.'+rtrim(@codigogp)+'|'+	---  AS CÓD_CTA,
						RTRIM(@SPED_COD_CTA_SUP)+'|'+		--- AS CÓD_CTA_SUP,
						RTRIM(@ACTDESCR)+'|',''))
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion, datos)	
				VALUES (@contador+1,'I051',
						isnull('|I051|'+					--- AS REG,
						'1|'+								--- AS CÓD_PLAN_REF
						'|'+								--- AS CÓD_CCUS,
						rtrim(LTRIM(@USERDEF2))+'|',''))	--- CÓD_CTA_REF
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion, datos)	
				VALUES (@contador+1,'I052',
						--isnull('|I052|'+'|'+replace(rtrim(ltrim(@SPED_COD_CTA)),'.','')+'|',''))	--- AS COD_AGL,
						isnull('|I052|'+'|'+rtrim(@SPED_CODAGL)+'|',''))	--- AS COD_AGL,
			fetch next from cuentas_gp into @codigogp, @USERDEF1, @USERDEF2, @Actdescr
		end
		close cuentas_gp
		deallocate cuentas_gp
	end
	FETCH NEXT FROM PlanCuentas_Cursor into @docdate,@SPED_COD_NAT ,@sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL,@SPED_COD_CTA_SUP,@SPED_CTA,@ACTDESCR, @SPED_CODAGL
end
close PlanCuentas_Cursor
deallocate PlanCuentas_Cursor;
set @contador=@contador+1
--fin I050
----------------------------------------------------------------------------------

--inicio I100
declare @sgmtid varchar(10)
declare @dscriptn varchar(80)
declare @fecha datetime
declare cc_cursor cursor for 
(select centroCostoGp, max(centroCostoGpDesc) centroCostoGpDesc, max(DEX_ROW_TS) fecha
from dbo.vwSpedPlanDeCuentasGP 
group by centroCostoGp)

open cc_cursor
fetch next from cc_cursor into @sgmtid,@dscriptn,@fecha
WHILE @@FETCH_STATUS = 0  
begin 
set @contador=@contador+1
insert into spedtbl9000 (linea,SECCION,datos)
	values( @contador+1,'I100',
		isnull('|I100|'+
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,103),103),'/',''))+'|'+
		rtrim(ltrim(@sgmtid))+'|'+
		rtrim(ltrim(@DSCRIPTN))+'|',''))
	fetch next from cc_cursor into @sgmtid,@dscriptn,@fecha
end
CLOSE CC_CURSOR
DEALLOCATE CC_CURSOR
--FIN I100
------------------------------------------------------------------------------------
--INICIO I150, I155
--declare @actindxm as int,@actindxi as int, @actindxf as int
declare @vfi as datetime
declare @vff as datetime
declare @vanio as int
declare @vper as int
declare periodos_cursor cursor for
	(SELECT year1,PERIODID,PERIODDT,PERDENDT 
	FROM SY40100 
	where PERIODID >0 AND (CONVERT(DATETIME,PERIODDT,102)>= CONVERT(DATETIME,@FechaDesde,102) AND CONVERT(DATETIME,PERDENDT,102)<= CONVERT(DATETIME,@FechaHasta,102)) 
	GROUP BY YEAR1,PERIODID,PERIODDT,PERDENDT)
open periodos_cursor
FETCH NEXT FROM periodos_cursor into @vanio,@vper,@vfi,@vff
WHILE @@FETCH_STATUS = 0  
	begin
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		values(@contador+1,'I150',isnull('|I150|'+
			rtrim(replace(convert(char,convert(datetime,@vfi,103),103),'/',''))+'|'+
			rtrim(replace(convert(char,convert(datetime,@vff,103),103),'/',''))+'|',''));

		set @contador=@contador+1;
		WITH SaldosPorCuentaSped (cuentaSped, centroCostoGp, debito, credito, perdblnc, saldo_acumulado) as (
			select pc.cuentaSped+'.'+pc.cuentaGp, pc.centroCostoGp,	
				sum(res.debitamt + case when @vper=12 then isnull(acierre.debito, 0) else 0 end), 
				sum(res.crdtamnt + case when @vper=12 then isnull(acierre.credito, 0) else 0 end), 
				sum(res.perdblnc + case when @vper=12 then isnull(acierre.debito, 0) - isnull(acierre.credito, 0) else 0 end), 
				sum(res.saldo_acumulado + case when @vper=12 then isnull(acierre.debito, 0) - isnull(acierre.credito, 0) else 0 end)
			from dbo.vwResumenDeCuentaAcumulado res
				inner join dbo.vwSpedPlanDeCuentasGP pc
				on pc.actindx = res.actindx
				outer apply (select case when p.tipoSaldo_acumulado='D' then abs(p.Saldo_Acumulado) else 0 end debito,
									case when p.tipoSaldo_acumulado='C' then abs(p.Saldo_Acumulado) else 0 end credito,
								tipoSaldo_acumulado
							from dbo.fSpedAsientoDeCierre (res.year1) p
							where p.cuentaSped = pc.cuentaSped
							and p.cuentaGp = pc.cuentaGp
							and p.centroCostoGp = pc.centroCostoGp
							) acierre
			where res.year1 = @vanio
			and res.periodid = @vper
			group by pc.cuentaSped, pc.cuentaGp, pc.centroCostoGp
			)

			insert into spedtbl9000 (linea,seccion,datos)
				select @contador+1,'I155',
						isnull('|I155|'+						----REG
						rtrim(ltrim(cuentaSped))+'|'+			----COD_CTA
						rtrim(ltrim(centroCostoGp))+'|'+		---COD_CCUS
						isnull(LTRIM(RTRIM(REPLACE(CAST(abs(cast(saldo_acumulado - perdblnc as decimal(18,2))) as nvarchar),'.',','))),'0,00')+'|'+	----VL_SLD_INI
						isnull(case when saldo_acumulado - perdblnc > 0 then 'D' else 'C' end, 'D')+'|'+											----IND_DC_INI
						REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(debito,0)) AS nvarchar))),'.',',')+'|'+								----VL_DEB
						REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(credito,0)) AS nvarchar))),'.',',')+'|'+								----VL_CRED
						isnull(LTRIM(RTRIM(REPLACE(CAST(abs( cast(saldo_acumulado as decimal(18,2)) ) as nvarchar),'.',','))),'0,00')+'|'+			----VL_SLD_FIN
						isnull(case when saldo_acumulado>0 then 'D' else 'C' end, 'D')+'|'															----IND_DC_FIN
						,'')
			--			)
			--Select cuentaSped, centroCostoGp, debito, credito, perdblnc, saldo_acumulado
			from SaldosPorCuentaSped
			where isnull(debito, 0) != 0 
			or isnull(credito, 0) != 0  
			or isnull(perdblnc, 0) != 0 
			or isnull(saldo_acumulado, 0) != 0 

		FETCH NEXT FROM periodos_cursor into @vanio,@vper,@vfi,@vff
	end
CLOSE periodos_cursor;  
DEALLOCATE periodos_cursor;
--fin I150
--------------------------------------------------------------------------------------------
--inicio I200, I250
declare periodos_cursor cursor for
	(SELECT year1,PERIODID,PERIODDT,PERDENDT 
	FROM SY40100 
	where PERIODID<>0 
	AND CONVERT(DATETIME,PERIODDT,102) >= CONVERT(DATETIME,@FechaDesde,102) 
	AND CONVERT(DATETIME,PERDENDT,102)<= CONVERT(DATETIME,@FechaHasta,102) 
	GROUP BY YEAR1,PERIODID,PERIODDT,PERDENDT)

open periodos_cursor
FETCH NEXT FROM periodos_cursor into @vanio,@vper,@vfi,@vff
WHILE @@FETCH_STATUS = 0  
begin
	declare @JRNENTRY as int
	declare @TRXDATE as datetime
	declare @CRDTAMNT as decimal(18,2)
	declare @DEBITAMT as decimal(18,2)
	declare total_asientos_cursor cursor for
	(select ac.JRNENTRY, ac.TRXDATE, abs(sum(ac.CRDTAMNT)), abs(sum(ac.DEBITAMT))
		from DBO.vwFINAsientosAH ac 
		where ac.OPENYEAR=@vanio 
		and ac.PERIODID = @vper
		group by ac.JRNENTRY,ac.TRXDATE
	) 
	order by JRNENTRY

	open total_asientos_cursor 
	fetch next from total_asientos_cursor into @jrnentry,@trxdate,@crdtamnt,@debitamt
	while @@fetch_status =0
	begin
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'I200',isnull('|I200|'+
				ltrim(rtrim(str(@JRNENTRY)))+'|'+
				rtrim(replace(convert(char,convert(datetime,@TRXDATE,103),103),'/',''))+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),sum(@CRDTAMNT)) as nvarchar),'.',','))),'0,00')
				+'|N|'
				,'')
		set @contador=@contador+1

		insert into spedtbl9000 (linea,seccion,datos)
		select @contador+1,'I250',
				isnull('|I250|'+													----REG
				pc.cuentaSped+'.'+pc.cuentaGp+'|'+									----COD_CTA
				rtrim(ltrim(pc.centroCostoGp))+'|'+									----COD_CCUS
				isnull(LTRIM(RTRIM(REPLACE(cast(convert(decimal(10,2),abs(ac.DEBITAMT)+abs(ac.CRDTAMNT))AS nvarchar),'.',','))),'0,00')+'|'+			----VL_DC
				CASE WHEN ac.DEBITAMT>0 THEN 'D' ELSE 'C' END +'|'+					----IND_DC
				LTRIM(RTRIM(str(ac.jrnentry)))+'|'+									----NUM_ARQ
				'|'+																----COD_HIST_PAD
				LTRIM(RTRIM(replace(ac.refrence,'|','')))+'|'+						----HIST
				'|'	,'')															----COD_PART
			from DBO.vwFINAsientosAH ac
			left join dbo.vwSpedPlanDeCuentasGP pc 
			on pc.actindx=ac.ACTINDX
			WHERE ac.JRNENTRY =@JRNENTRY

		fetch next from total_asientos_cursor into @jrnentry,@trxdate,@crdtamnt,@debitamt
	end
	CLOSE total_asientos_cursor;  
	DEALLOCATE total_asientos_cursor;
	FETCH NEXT FROM periodos_cursor into @vanio,@vper,@vfi,@vff
end
CLOSE periodos_cursor;  
DEALLOCATE periodos_cursor;

--Asiento de cierre
		declare @resultado as decimal(18,2)
		select @resultado = SUM(Saldo_Acumulado)
		from dbo.fSpedAsientoDeCierre (@vanio) 
		where tipoSaldo_acumulado = 'D';

set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'I200',isnull('|I200|'+
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),
				abs(@resultado)
					) as nvarchar),'.',','))),'0,00')
					+'|E|','')
set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		select @contador+1,'I250',
				isnull('|I250|'+					----REG
				cuentaSped+'.'+cuentaGp+'|'+	----COD_CTA
				centroCostoGp+'|'+				---COD_CCUS
				isnull(LTRIM(RTRIM(REPLACE(cast(
					convert(decimal(10,2),abs(saldo_acumulado))
				AS nvarchar),'.',','))),'0,00')+'|'+ ----VL_DC
				tipoSaldo_acumulado +'|'+		----IND_DC Signo invertido debido a que es asiento de cierre
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+	----NUM_ARQ
				'|'+								----COD_HIST_PAD
				'Apuração do Resultado|'+			----HIST
				'|'	,'')							----COD_PART
			from dbo.fSpedAsientoDeCierre (@vanio) 

--fin I200, I250
--------------------------------------------------------------------------------------------------
--inicio I350, I355
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'I350',
	'|I350|'+
	rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|')	---DT_RES,

insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1, 'I355', isnull('|I355|'+
		pc.cuentaSped+'.'+pc.cuentaGp +'|'+
		pc.centroCostoGp +'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(sum(ac.saldo_acumulado))) as nvarchar),'.',','))),'0,00')+'|'+
		case when sum(ac.Saldo_Acumulado) < 0 then 'C' else 'D' end+'|','')
	from dbo.vwResumenDeCuentaAcumulado ac
	inner join dbo.vwSpedPlanDeCuentasGP pc 
		on pc.actindx=ac.ACTINDX
	where ac.YEAR1 = @vanio
	and ac.PERIODID = 12
	and ac.PSTNGTYP = 1	--resultado
	and ac.saldo_acumulado != 0
	group by pc.cuentaSped, pc.cuentaGp, pc.centroCostoGp

set @contador=@contador+1
--fin I350, I355
--------------------------------------------------------------------------------------------------
--Inicio I990
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'I990',
	'|I990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='I')) as nvarchar))),'0')+'|')
set @contador=@contador+1
--fin I990
--------------------------------------------------------------------------------------------------

--inicio J001
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'J001',
	'|J001|0|')
set @contador=@contador+1
--fin J001
------------------------------------------------------------------------------------------------------
--inicio J005
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'J005',
	isnull('|J005|'+
	rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+	---DT_INI
	rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))		---DT_FIN
	+'|1||','')) 																	---ID_DEM
--fin J005
------------------------------------------------------------------------------------------------------
--inicio J100
DECLARE @TIPO VARCHAR
declare @Saldo decimal(18,2)
declare @inicial as decimal (18,2)
declare @tipoinicial as varchar
declare Balance_cursor cursor for
(
select		
	case when g.SPED_NIVEL=1 then 'TG.' else '' end + RTRIM(g.SPED_CODAGL),
	g.SPED_IND_CTA,
	g.SPED_NIVEL,
	g.SPED_COD_NAT,
	g.ACTDESCR,
	abs(gestionAnterior.Saldo_Acumulado) saldoInicial,
	case when gestionAnterior.Saldo_Acumulado > 0
		then 'D' else 'C' 
	end tipoSaldoInicial,
	abs(gestionActual.saldo_acumulado) saldoFinal,
	case when gestionActual.saldo_acumulado > 0
		then 'D' else 'C' 
	end tipoSaldoFinal
from SPEDtbl004 g
outer apply (select b.cuentaSped, sc.SPED_CODAGL
				from GL40000 a 
				inner join dbo.vwSpedPlanDeCuentasGP b 
					on a.RERINDX=b.ACTINDX
				inner join SPEDtbl004 sc 
					on sc.SPED_COD_CTA = b.cuentaSped
			) utilidadr
outer apply (select sum(ac.saldo_acumulado) resultado
			from dbo.vwResumenDeCuentaAcumulado ac
			where ac.YEAR1 = @vanio
			and ac.PERIODID = 12
			and ac.PSTNGTYP = 1	--resultado
			) resActual
outer apply (select sum(ac.saldo_acumulado) resultado
			from dbo.vwResumenDeCuentaAcumulado ac
			where ac.YEAR1 = @vanio-1
			and ac.PERIODID = 12
			and ac.PSTNGTYP = 1	--resultado
			) resAnterior
outer apply (
			select sum(ac.perdblnc) perdblnc, 
				sum(ac.saldo_acumulado) 
				+ case when (utilidadr.SPED_CODAGL like ltrim(rtrim(g.SPED_CODAGL)) + '%')
						--and ac.HISTORYR = 0 --open
					then resActual.resultado
					else 0 
				end saldo_acumulado
			from dbo.vwResumenDeCuentaAcumulado ac
			inner join dbo.vwSpedPlanDeCuentasGP pc 
				on pc.actindx=ac.ACTINDX
			inner join SPEDtbl004 sc 
				on sc.SPED_COD_CTA = pc.cuentaSped
			where ac.YEAR1 = @vanio
			and ac.PERIODID = 12
			and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
			) gestionActual
outer apply (
			select sum(ac.perdblnc) perdblnc, 
				sum(ac.saldo_acumulado) 
				+ case when (utilidadr.SPED_CODAGL like ltrim(rtrim(g.SPED_CODAGL)) + '%')
					then resAnterior.resultado
					else 0 
				end 
				saldo_acumulado
			from dbo.vwResumenDeCuentaAcumulado ac
			inner join dbo.vwSpedPlanDeCuentasGP pc 
				on pc.actindx=ac.ACTINDX
			inner join SPEDtbl004 sc 
				on sc.SPED_COD_CTA = pc.cuentaSped
			where ac.YEAR1 = @vanio-1
			and ac.PERIODID = 12
			and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
			) gestionAnterior
where G.SPED_COD_NAT IN ('01','02','03')
and abs(isnull(gestionActual.Saldo_Acumulado, 0)) + ABS(isnull(gestionAnterior.saldo_acumulado, 0)) != 0
)
order by g.SPED_COD_CTA

open Balance_cursor
fetch next from Balance_cursor into @SPED_CODAGL, @SPED_IND_CTA, @SPED_NIVEL, @SPED_COD_NAT, @ACTDESCR,@inicial,@tipoinicial,@Saldo,@TIPO
while @@fetch_status =0
begin
	IF @Saldo<>0
	BEGIN
		--if @SPED_NIVEL<5
		--begin
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'J100',isnull('|J100|'+
				RTRIM(@SPED_CODAGL)+'|'+											--COD_AGL
				LTRIM(STR(@SPED_NIVEL))+'|'+										--NIVEL_AGL
				case when rtrim(@SPED_COD_NAT) = '01' then '1' else '2' end+'|'+	--IND_GRP_BAL
				RTRIM(@ACTDESCR)+'|'+												--DESCR_COD_AGL
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@Saldo) as nvarchar),'.',','))),'0,00')+'|'+
				@TIPO+'|'+															--IND_DC_BAL
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@inicial) as nvarchar),'.',','))),'0,00')+'|'+
				@tipoinicial+'|'+													--IND_DC_BAL_INI
				'|'																	--NOTA_EXP_REF
				,'|')
		--end
	END
	fetch next from Balance_cursor into @SPED_CODAGL, @SPED_IND_CTA, @SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@Saldo,@TIPO
end
CLOSE Balance_cursor;  
DEALLOCATE Balance_cursor;
--fin J100
----------------------------------------------------------------------------------------------
--inicio J150
declare @tipoResultado varchar(2);
declare Resultado_Cursor cursor for
	(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+ltrim(rtrim(g.sped_codagl)),
		g.SPED_IND_CTA,
		g.SPED_NIVEL,
		g.SPED_COD_NAT,
		g.ACTDESCR,
		ABS(isnull(acumulados.saldo_acumulado, 0)) saldo,
		case when acumulados.saldo_acumulado > 0 then 'D' else 'C' end tipo,
		case when acumulados.saldo_acumulado > 0 then 'D' else 'R' end tipoResultado
	from SPEDtbl004 g
	outer apply (
			select	sum(ac.perdblnc) perdblnc, 
					sum(ac.saldo_acumulado) saldo_acumulado
			from dbo.vwResumenDeCuentaAcumulado ac
			inner join dbo.vwSpedPlanDeCuentasGP pc 
				on pc.actindx=ac.ACTINDX
			left join SPEDtbl004 sc 
				on sc.SPED_COD_CTA = pc.cuentaSped
			where ac.YEAR1 = @vanio
			and ac.PERIODID = 12
			and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
			) acumulados
	where G.SPED_COD_NAT = '04'
	and acumulados.saldo_acumulado != 0
	) 
	order by g.sped_codagl

open Resultado_Cursor
fetch next from Resultado_Cursor into @SPED_CODAGL, @SPED_IND_CTA, @SPED_NIVEL, @SPED_COD_NAT, @ACTDESCR, @Saldo, @TIPO, @tipoResultado
while @@fetch_status =0
begin
	--IF @Saldo>0
	--BEGIN
		set @contador=@contador+1;
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'J150', isnull('|J150|'+
				RTRIM(@SPED_CODAGL)+'|'+											--COD_AGL
				LTRIM(STR(@SPED_NIVEL))+'|'+										--NIVEL_AGL
				RTRIM(@ACTDESCR)+'|'+												--DESCR_COD_AGL
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),@Saldo) as nvarchar),'.',','))),'0,00')+'|'+
				CASE WHEN @TIPO='C' THEN 'N' ELSE 'P' END+'|'						--IND_VL
			,'')+
				'|||'
	--END
	fetch next from Resultado_Cursor into @SPED_CODAGL, @SPED_IND_CTA, @SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@Saldo,@TIPO, @tipoResultado
end
CLOSE Resultado_Cursor;  
DEALLOCATE Resultado_Cursor;
--FIN J150
--------------------------------------------------------------------------------------------------
--inicio J900
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador+1,'J900',isnull('|J900|'+		---REG,
		'TERMO DE ENCERRAMENTO|'+					---DNRC_ENCER
		ltrim(rtrim(STR(CONF.SPED_NUM_ORD)))+'|'+	--- NUM_ORD,
		'G|'+										--- NAT_LIVRO,
		rtrim(ltrim(com.CMPNYNAM))+'|'+				---NOME
		'*|'+										---QTD_LIN
		rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+		---DT_INI_ESCR,
		rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|','') 	---DT_FIN_ESCR,
	 from dynamics.dbo.SY01500  com 
	left join SPEDtbl001 conf on com.INTERID =conf.INTERID
set @contador=@contador+1

INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador+1,'J930',isnull('|J930|'+		---REG,
		rtrim(ltrim(conf.SPED_IDENT_NOM))+'|'+		---IDENT_NOM
		rtrim(ltrim(conf.SPED_IDENT_CPF))+'|'+		---IDENT_CPF_CNPJ
		rtrim(ltrim(conf.SPED_IDENT_QUALIF))+'|'+	---IDENT_QUALIF
		rtrim(ltrim(conf.SPED_COD_ASSIM))+'|'+		---COD_ASSIM
		rtrim(ltrim(conf.SPED_IND_CRC))+'|'+		---IND_CRC 
		rtrim(ltrim(conf.sped_email))+'|'+			----EMAIL
		rtrim(ltrim(conf.SPED_FONE))+'|'+			----FONE
		'SP|'+										----UF_CRC
		LTRIM(RTRIM(CONF.SPED_NUM_SEQ_CRC))+'|'+	----NUM_SEQ_CRC
		rtrim(replace(convert(char,convert(datetime,conf.sped_DT_CRC,102),103),'/',''))+'|'+ 	---DT_CRC,
		RTRIM(ltrim(conf.SPED_IND_RESP_LEGAL))+'|'	--IND_RESP_LEGAL
		,'')	
	 from SPEDtbl002 conf
	 where conf.INTERID =@IdCompañia
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	values (@contador+1,
	'J990',
	'|J990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='J')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'9001',
	'|9001|'+
	'0|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
select @contador+1,
	'9'+ltrim(rtrim(seccion)),
	'|9900|'+
	ltrim(rtrim(seccion))+'|'+
	isnull(ltrim(rtrim(cast(convert(int,count(*)) as nvarchar))),'0')+'|'
from spedtbl9000 group by seccion order by seccion
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values (@contador+1,
	'9900',
	'|9900|9900|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*) from spedtbl9000 where left(seccion,1)='9')+2) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values (@contador+1,
	'9900',
	'|9900|9990|1|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values (@contador+1,
	'9900',
	'|9900|9999|1|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values (@contador+1,
	'9990',
	'|9990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+2 from spedtbl9000 where left(seccion,1)='9')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values (@contador+1,
	'9999',
	'|9999|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000)) as nvarchar))),'0')+'|')
set @contador=(select COUNT(linea) from SPEDtbl9000)
update SPEDtbl9000 set datos=replace(datos,'*',cast(@contador as varchar)) where datos like '|I030|%'
update SPEDtbl9000 set datos=replace(datos,'*',cast(@contador as varchar)) where datos like '|J900|%'


end
go
-----------------------------------------------------------------------
IF (@@Error = 0) PRINT 'Creación exitosa de: SPED_ArchivoTXT_l600'
ELSE PRINT 'Error en la creación de: SPED_ArchivoTXT_l600'
GO
