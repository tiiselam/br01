USE [GBRA]
GO
/****** Object:  StoredProcedure [dbo].[SPED_ArchivoTXT_Hist_v400]    Script Date: 6/26/2018 4:18:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SPED_ArchivoTXT_Hist_v400] 
	@IdCompañia varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	declare @contador int
	set @contador=1
	---CREATE TABLE spedtbl9000 (LINEA datetime,SECCION VARCHAR(4),DATOS VARCHAR(8000))
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT on;

    -- Insert statements for procedure here

delete spedtbl9000
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador,'0000',isnull('|0000|'+	---REG   C1,
		'LECD|'+	--- LEC C1D,
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+	--- DT_INI C3,
		rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+	---DT_FIN C4,
		rtrim(isnull(com.CMPNYNAM,''))+'|'+	---NOME C5
		rtrim(isnull(com.TAXREGTN,''))+'|'+	---CNPJ, C6
		rtrim(isnull(conf.speduf,''))+'|'+		--- UF, C7
		rtrim(isnull(conf.spedIE,''))+'|'+		---IE, C8
		rtrim(isnull(com.COUNTY,''))+'|'+		--- AS CÓD_MUN, C9
		rtrim(isnull(conf.sped_IM,''))+'|'+	--- AS IM, C10
		rtrim( case when conf.SPED_IND_SIT_ESP=0 then '' else str(conf.SPED_IND_SIT_ESP) end)+'|','')+	--- AS IND_SIT_ESP C11
		'0|1|0|||0|0||N|'
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
			'4.00|'	,''))	--- AS CÓD_VER_LC						---SECCION I010
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
declare @docdate as DATETIME
declare @SPED_COD_NAT as varchar(2)
declare @sped_cod_cta as varchar(50)
declare @SPED_IND_CTA as varchar
declare @SPED_NIVEL as int
declare @SPED_COD_CTA_SUP as varchar(50)
declare @SPED_CTA as varchar(50)
declare @ACTDESCR as varchar(80)
DECLARE @USERDEF1 AS VARCHAR(50)
DECLARE @USERDEF2 AS VARCHAR(50)
declare @codigogp as varchar(50)
declare @CODAGL as varchar(50)
declare PlanCuentas_Cursor cursor for
(SELECT DOCDATE,
		SPED_COD_NAT,
		SPED_COD_CTA,--- isnull(left(pc.userdef1,10),SPED_COD_CTA),
		SPED_IND_CTA,
		SPED_NIVEL,
		SPED_COD_CTA_SUP,
		SPED_CTA,
		gc.ACTDESCR, ---isnull(pc.ACTDESCR,gc.ACTDESCR) AS ACTDESCR,
		'',---replace(replace(isnull(PC.USERDEF1,''),'-','.'),' ','') as userdef1,
		'',---isnull(PC.USERDEF2,''),
		'' ---isnull(pc.ACTNUMBR_1,'')
		---,case when sped_ind_cta='A' then userdef1 else '1' end
	from SPEDtbl004 gc WHERE GC.SPED_ES_SN=1
	----left join GL00100 pc on pc.USERDEF1=gc.SPED_COD_CTA
	/*where SPED_NIVEL <=4*/
	) ---(case when sped_ind_cta='A' then userdef1 else '1' end) is not null)
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
		@USERDEF1,
		@USERDEF2,
		@codigogp

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
				LTRIM(STR(@SPED_NIVEL))+'|'+	--- AS NÍVEL,
				RTRIM(@sped_cod_cta)+'|'+	---  AS CÓD_CTA,
				RTRIM(@SPED_COD_CTA_SUP)+'|'+	--- AS CÓD_CTA_SUP,
				RTRIM(@ACTDESCR)+'|',''))
	end
	if @SPED_IND_CTA='A'
	begin
		declare Cuentas_gp cursor for (select ACTNUMBR_1,USERDEF1,max(cgp.ACTDESCR) as ACTDESCR,USRDEFS1  from gl00100 cgp 
		where LTRIM(RTRIM(USERDEF1))=@sped_cod_cta 
		group by ACTNUMBR_1,userdef1,USRDEFS1) ---,ACTDESCR)
		order by ACTNUMBR_1
		open Cuentas_gp
		fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr,@CODAGL
		while @@FETCH_STATUS=0
		begin
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion,datos)	
				values (@contador+1,'I050',
						isnull('|I050|'+	--- AS REG,'',
						rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
						RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
						'A|'+	--- AS IND_CTA,
						LTRIM(STR(@SPED_NIVEL))+'|'+	--- AS NÍVEL,
						RTRIM(LEFT(@sped_cod_cta,10))+'.'+rtrim(@codigogp)+'|'+	---  AS CÓD_CTA,
						RTRIM(@SPED_COD_CTA_SUP)+'|'+	--- AS CÓD_CTA_SUP,
						RTRIM(@ACTDESCR)+'|',''))
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion, datos)	
				VALUES (@contador+1,'I051',
						isnull('|I051|'+	--- AS REG,
						'1|'+	--- AS CÓD_ENT _REF
						'|'+	--- AS CÓD_CCUS,
						rtrim(LTRIM(@USERDEF1))+'|',''))	--- CÓD_CTA_REF
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion, datos)	
				VALUES (@contador+1,'I052',
						isnull('|I052|'+'|'+replace(rtrim(ltrim(@CODAGL)),'.','')+'|',''))	--- AS COD_AGL,
			fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr,@CODAGL
		end
		close cuentas_gp
		deallocate cuentas_gp
	end
	FETCH NEXT FROM PlanCuentas_Cursor into @docdate,@SPED_COD_NAT ,@sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL,@SPED_COD_CTA_SUP,@SPED_CTA,@ACTDESCR,@USERDEF1,@USERDEF2,@codigogp
end
close PlanCuentas_Cursor
deallocate PlanCuentas_Cursor;
set @contador=@contador+1

declare @sgmtid varchar(10)
declare @dscriptn varchar(80)
declare @fecha datetime
declare cc_cursor cursor for (select cc.SGMNTID,cc.DSCRIPTN,cc.DEX_ROW_TS from GL40200 cc where SGMTNUMB=2 AND cc.SGMNTID<>'')
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
declare @actindxm as int,@actindxi as int, @actindxf as int
declare @vfi as datetime
declare @vff as datetime
declare @vanio as int
declare @vper as int
declare periodos_cursor cursor for
(SELECT year1,PERIODID,PERIODDT,PERDENDT FROM SY40100 
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
		rtrim(replace(convert(char,convert(datetime,@vff,103),103),'/',''))+'|',''))
		declare @tieneM as tinyint
		declare @tieneI as tinyint
		declare @tieneF as tinyint
		declare @actnumbr_2 varchar(50)
		declare @debito decimal(18,2)
		declare @credito decimal(18,2)
		declare @idebito decimal(18,2)
		declare @icredito decimal(18,2)
		declare @fdebito decimal(18,2)
		declare @fcredito decimal(18,2)
		declare @actindx int
		declare @year1 int
		declare @periodid int
		declare PlanCuenta_cursor cursor for SELECT ACTINDX,ltrim(rtrim(left(USERDEF1,10)))+'.'+ACTNUMBR_1,ACTNUMBR_2 
		from gl00100 where USERDEF1<>'' 
		order by ltrim(rtrim(left(USERDEF1,10)))+'.'+ACTNUMBR_1,ACTNUMBR_2
		open PlanCuenta_cursor
		FETCH NEXT FROM PlanCuenta_cursor into @actindx,@userdef1,@actnumbr_2
		declare @texto as varchar(800)
		WHILE @@FETCH_STATUS = 0  
		begin
			exec SPED_Total_Saldo_Cta_Open @actindx,@vanio,@vper,1,@debito out,@credito out,@tieneM output
			exec SPED_Total_Saldo_Cta_Open @actindx,@vanio,@vper,2,@idebito out,@icredito out,@tieneI output
			exec SPED_Total_Saldo_Cta_Open @actindx,@vanio,@vper,3,@fdebito out,@fcredito out,@tieneF output
			set @texto= isnull(LTRIM(RTRIM(REPLACE(CAST(abs(@idebito-@icredito) as nvarchar),'.',','))),'0,00')+'|'+
						isnull(case when @idebito>=@icredito then 'D' else 'C' end,'D')+'|'+
						REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@debito,0)) AS nvarchar))),'.',',')+'|'+
						REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@credito,0)) AS nvarchar))),'.',',')+'|'+
						isnull(LTRIM(RTRIM(REPLACE(CAST(abs(@fdebito-@fcredito) as nvarchar),'.',','))),'0,00')+'|'+
						isnull(case when @fdebito>=@fcredito then 'D' else 'C' end,'D')
			if @texto<>'0,00|D|0,00|0,00|0,00|D'
			begin
				
				set @contador=@contador+1
				insert into spedtbl9000 (linea,seccion,datos)
				VALUES(@contador+1,'I155',
						isnull('|I155|'+						----REG
						rtrim(ltrim(@USERDEF1))+'|'+	----COD_CTA
						rtrim(ltrim(@actnumbr_2))+'|'+ ---COD_CCUS
						isnull(LTRIM(RTRIM(REPLACE(CAST(abs(@idebito-@icredito) as nvarchar),'.',','))),'0,00')+'|'+			----VL_SLD_INI
						isnull(case when @idebito>=@icredito then 'D' else 'C' end,'D')+'|'+			----IND_DC_INI
						REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@debito,0)) AS nvarchar))),'.',',')+'|'+			----VL_DEB
						REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@credito,0)) AS nvarchar))),'.',',')+'|'+			----VL_CRED
						isnull(LTRIM(RTRIM(REPLACE(CAST(abs(@fdebito-@fcredito) as nvarchar),'.',','))),'0,00')+'|'+			----VL_SLD_FIN
						isnull(case when @fdebito>=@fcredito then 'D' else 'C' end,'D')+'|',''))			----IND_DC_FIN
			END
			set @debito=0
			set @credito=0
			set @fdebito=0
			set @fcredito=0
			set @idebito=0
			set @icredito=0
			FETCH NEXT FROM PlanCuenta_cursor into @actindx,@userdef1,@actnumbr_2
		END
		CLOSE PlanCuenta_CURSOR
		DEALLOCATE PlanCuenta_CURSOR
		FETCH NEXT FROM periodos_cursor into @vanio,@vper,@vfi,@vff
	end
CLOSE periodos_cursor;  
DEALLOCATE periodos_cursor;
declare periodos_cursor cursor for
(SELECT year1,PERIODID,PERIODDT,PERDENDT FROM SY40100 
	where PERIODID<>0 AND CONVERT(DATETIME,PERIODDT,102) >= CONVERT(DATETIME,@FechaDesde,102) AND CONVERT(DATETIME,PERDENDT,102)<= CONVERT(DATETIME,@FechaHasta,102) 
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
	(select JRNENTRY,TRXDATE,sum(CRDTAMNT),sum(DEBITAMT) from GL30000 AC 
		where ac.HSTYEAR=@vanio and ac.PERIODID = @vper
		group by ac.HSTYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE
	union
	select JRNENTRY,TRXDATE,sum(CRDTAMNT),sum(DEBITAMT) from GL30000 AC 
		where ac.HSTYEAR=@vanio and ac.PERIODID = @vper 
		group by ac.HSTYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE ) order by JRNENTRY
	open total_asientos_cursor 
	fetch next from total_asientos_cursor into @jrnentry,@trxdate,@crdtamnt,@debitamt
	while @@fetch_status =0
	begin
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'I200',isnull('|I200|'+
				ltrim(rtrim(str(@JRNENTRY)))+'|'+
				rtrim(replace(convert(char,convert(datetime,@TRXDATE,103),103),'/',''))+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),sum(@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|N|','')
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		select @contador+1,'I250',
				isnull('|I250|'+						----REG
				rtrim(ltrim(left(pc.USERDEF1,10)))+'.'+rtrim(pc.actnumbr_1)+'|'+	----COD_CTA
				rtrim(ltrim(pc.ACTNUMBR_2))+'|'+ ---COD_CCUS
				isnull(LTRIM(RTRIM(REPLACE(cast(convert(decimal(10,2),ac.DEBITAMT+ac.CRDTAMNT)AS nvarchar),'.',','))),'0,00')+'|'+			----VL_DC
				CASE WHEN ac.DEBITAMT>0 THEN 'D' ELSE 'C' END +'|'+			----IND_DC
				LTRIM(RTRIM(str(ac.jrnentry)))+'|'+			----NUM_ARQ
				'|'+			----COD_HIST_PAD
				LTRIM(RTRIM(replace(ac.refrence,'|','')))+'|'+			----HIST
				'|'	,'')		----COD_PART
			from GL30000 AC
			left join gl00100 pc on pc.actindx=ac.ACTINDX
			WHERE ac.JRNENTRY =@JRNENTRY
		fetch next from total_asientos_cursor into @jrnentry,@trxdate,@crdtamnt,@debitamt
	end
	CLOSE total_asientos_cursor;  
	DEALLOCATE total_asientos_cursor;
	FETCH NEXT FROM periodos_cursor into @vanio,@vper,@vfi,@vff
end
CLOSE periodos_cursor;  
DEALLOCATE periodos_cursor;
		set @actindx=(select RERINDX from GL40000)
		set @sped_cod_cta=(select rtrim(left(p.userdef1,10))+'.'+rtrim(p.actnumbr_1) from GL00100 p left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1 where p.ACTINDX=@actindx)
		set @sgmtid=(select rtrim(p.actnumbr_2) from GL00100 p left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1 where p.actindx=@actindx)
		exec SPED_Total_Saldo_Cta_Open @actindx,@vanio,12,1,@debitamt out,@crdtamnt out,@tieneF out
		declare @resultado as decimal(18,2)
		set @resultado=@debitamt-@CRDTAMNT
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'I200',isnull('|I200|'+
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),(select case when SUM(r.c)>SUM(r.d) then SUM(r.c) else sum(r.d) end  
				from (select AC.ACTINDX,case when sum(ac.CRDTAMNT)>sum(AC.DEBITAMT) then sum(aC.CRDTAMNT)-sum(AC.DEBITAMT) else 0 end as d,
						case when sum(ac.CRDTAMNT)<sum(AC.DEBITAMT) then sum(aC.DEBITAMT)-sum(AC.CRDTAMNT) else 0 end as c
					FROM GL10111 AC
					LEFT JOIN GL00100 PC ON PC.ACTINDX=ac.ACTINDX
					LEFT JOIN SPEDtbl004 J ON J.SPED_COD_CTA=pc.USERDEF1
			where j.SPED_COD_NAT=4 and ac.YEAR1=@vanio and PERIODID<>0
			group by AC.ACTINDX union select AC.ACTINDX,case when sum(ac.CRDTAMNT)>sum(AC.DEBITAMT) then sum(aC.CRDTAMNT)-sum(AC.DEBITAMT) else 0 end as d,
					case when sum(ac.CRDTAMNT)<sum(AC.DEBITAMT) then sum(aC.DEBITAMT)-sum(AC.CRDTAMNT) else 0 end as c
			FROM GL10111 AC
			LEFT JOIN GL00100 PC ON PC.ACTINDX=ac.ACTINDX
			LEFT JOIN SPEDtbl004 J ON J.SPED_COD_CTA=pc.USERDEF1
			where j.SPED_COD_NAT=4 and ac.YEAR1=@vanio and PERIODID<>0
			group by AC.ACTINDX) r)) as nvarchar),'.',','))),'0,00')+'|E|','')
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		values (@contador+1,'I250',
				isnull('|I250|'+						----REG
				@sped_cod_cta+'|'+	----COD_CTA
				rtrim(ltrim(@sgmtid))+'|'+ ---COD_CCUS
				isnull(LTRIM(RTRIM(REPLACE(cast(convert(decimal(10,2),abs(@resultado)) AS nvarchar),'.',','))),'0,00')+'|'+			----VL_DC
				CASE WHEN abs(@DEBITAMT)>abs(@CRDTAMNT) THEN 'D' ELSE 'C' END +'|'+			----IND_DC
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+			----NUM_ARQ
				'|'+			----COD_HIST_PAD
				'Apuração do Resultado|'+			----HIST
				'|'	,''))		----COD_PART
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		select @contador+1,'I250',
				isnull('|I250|'+						----REG
				rtrim(ltrim(left(pc.USERDEF1,10)))+'.'+rtrim(pc.actnumbr_1)+'|'+	----COD_CTA
				rtrim(ltrim(pc.ACTNUMBR_2))+'|'+ ---COD_CCUS
				isnull(LTRIM(RTRIM(REPLACE(cast(convert(decimal(10,2),abs(abs(sum(ac.DEBITAMT))-abs(sum(ac.CRDTAMNT)))) AS nvarchar),'.',','))),'0,00')+'|'+			----VL_DC
				CASE WHEN abs(sum(ac.DEBITAMT))>abs(sum(ac.CRDTAMNT)) THEN 'C' ELSE 'D' END +'|'+			----IND_DC
				rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+			----NUM_ARQ
				'|'+			----COD_HIST_PAD
				'Apuração do Resultado|'+			----HIST
				'|'	,'')		----COD_PART
			from GL30000 AC
			left join gl00100 pc on pc.actindx=ac.ACTINDX
			LEFT JOIN SPEDtbl004 J ON J.SPED_COD_CTA=pc.USERDEF1
			where (j.SPED_COD_NAT=4) and ac.HSTYEAR=@vanio
			group by pc.USERDEF1,pc.ACTNUMBR_1,pc.ACTNUMBR_2 
			order by rtrim(left(pc.USERDEF1,10))+'.'+pc.ACTNUMBR_1,pc.ACTNUMBR_2
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'I350',
	'|I350|'+
	rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|')	---DT_RES,
declare GP_Cursor cursor for
(select rtrim(left(pc.userdef1,10))+'.'+rtrim(pc.actnumbr_1) as cta,rtrim(pc.actnumbr_2),pc.ACTINDX from GL00100 pc
	left join spedtbl004 sp on sp.sped_cod_cta=pc.userdef1
	where sp.sped_cod_nat=4
	group by rtrim(left(pc.userdef1,10))+'.'+rtrim(pc.actnumbr_1),rtrim(pc.actnumbr_2),pc.ACTINDX )
	order by cta
open GP_cursor
fetch next from gp_cursor into @sped_cod_cta,@sgmtid,@actindx
while @@fetch_status =0
begin
exec SPED_Total_Saldo_Cta @actindx,@vanio,12,4,@debitamt out,@crdtamnt out,@tieneF out
if @DEBITAMT+@CRDTAMNT<>0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'I355',isnull('|I355|'+
		@sped_cod_cta+'|'+
		@sgmtid+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta,@sgmtid,@actindx
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'I990',
	'|I990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='I')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'J001',
	'|J001|0|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'J005',
	isnull('|J005|'+
	rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+	---DT_INI,
	rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|1||','')) 	---DT_FIN,
DECLARE @TIPO VARCHAR
declare @RMonto decimal(18,2)
declare @RMontoC decimal(18,2) 
declare @RMontoD decimal(18,2)
DECLARE @RSped_Cod_Cta_N1 varchar(50)
DECLARE @RSped_cod_cta_n2 varchar(50)
DECLARE @RSped_cod_cta_n3 varchar(50)
DECLARE @RSped_cod_cta_n4 varchar(50)
DECLARE @RSped_cod_cta_n5 varchar(50)
DECLARE @CtaUtilGP varchar(50)
Set @CtaUtilGP=(select USERDEF1 from GL40000 a inner join GL00100 b on a.RERINDX=b.ACTINDX)
set @rMontoC=isnull((select SUM(abs(r.CRDTAMNT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
/******/
set @rMontoD=isnull((select SUM(abs(r.DEBITAMT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
/******/
set @rMonto=isnull((select SUM(r.PERDBLNC) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
/******/
set @RSped_Cod_Cta_N4=(select j.SPED_COD_CTA_SUP from SPEDtbl004 j 
						inner join gl00100 p on p.USERDEF1=j.SPED_COD_CTA
						inner join GL40000 c on c.RERINDX=p.ACTINDX)

set @RSped_Cod_Cta_N3=(select j.SPED_COD_CTA_SUP from SPEDtbl004 j 
						where j.SPED_COD_CTA=@RSped_cod_cta_n4)
set @RSped_Cod_Cta_N2=(select j.SPED_COD_CTA_SUP from SPEDtbl004 j 
						where j.SPED_COD_CTA=@RSped_cod_cta_n3)
set @RSped_Cod_Cta_N1=(select j.SPED_COD_CTA_SUP from SPEDtbl004 j 
						where j.SPED_COD_CTA=@RSped_cod_cta_n2)

declare @inicial as decimal (18,2)
declare @tipoinicial as varchar
declare Balance_cursor cursor for
(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+replace(rtrim(G.SPED_CODAGL),'.',''),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
isnull((select abs(isnull(sum(s.DEBITAMT-s.CRDTAMNT),0))						-----saldo inicial en año abierto
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%' and PERIODID =0),0)
	as inicial,
isnull((select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%' and PERIODID =0),0)
	as tipoInicial,
isnull((select abs(isnull((select sum(S.PERDBLNC)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMonto else 0 end)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%'),0)
	 as saldo,
isnull((select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMontoc else 0 end>isnull(SUM(ABS(s.DEBITAMT)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMontoc else 0 end then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%'),0)
	as tipo
from SPEDtbl004 g
	LEFT JOIN GL00100 C ON C.USERDEF1=G.SPED_COD_CTA
where G.SPED_COD_NAT IN (1,2,3)
GROUP BY G.SPED_CODAGL,G.SPED_COD_CTA,G.SPED_NIVEL,C.USRDEFS1,G.SPED_COD_NAT,G.ACTDESCR) order by g.SPED_CODAGL
open Balance_cursor
fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
while @@fetch_status =0
begin
	IF @CREDITO<>0
	BEGIN
		if @SPED_NIVEL<5
		begin
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'J100',isnull('|J100|'+
				RTRIM(@sped_cod_cta)+'|'+
				LTRIM(STR(@SPED_NIVEL))+'|'+
				case when LTRIM(STR(@SPED_COD_NAT)) = 3 then '2' else LTRIM(STR(@SPED_COD_NAT)) end+'|'+
				RTRIM(@ACTDESCR)+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
				@TIPO+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@inicial) as nvarchar),'.',','))),'0,00')+'|'+
				@tipoinicial+'|','|')
		end
	END
	fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
end
CLOSE Balance_cursor;  
DEALLOCATE Balance_cursor;
declare Resultado_Cursor cursor for
(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+ltrim(rtrim(G.SPED_CODAGL)),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
isnull((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(PC.USRDEFS1)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	 as saldo,
isnull((select case when ABS(isnull(SUM(s.CRDTAMNT),0))>ABS(isnull(SUM(s.DEBITAMT),0)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(PC.USRDEFS1)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	as tipo
from SPEDtbl004 g
LEFT JOIN GL00100 C ON C.USERDEF1=G.SPED_COD_CTA
where G.SPED_COD_NAT IN (4)
GROUP BY G.SPED_CODAGL,G.SPED_NIVEL,SPED_COD_NAT,G.ACTDESCR) order by g.sped_codagl
open Resultado_Cursor
fetch next from Resultado_Cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@CREDITO,@TIPO
while @@fetch_status =0
begin
	IF @CREDITO>0
	BEGIN
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'J150',isnull('|J150|'+
				RTRIM(@sped_cod_cta)+'|'+
				LTRIM(STR(@SPED_NIVEL))+'|'+
				RTRIM(@ACTDESCR)+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
				CASE WHEN @TIPO='C' THEN 'N' ELSE 'P' END+'|','')+'||'
	END
	fetch next from Resultado_Cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@CREDITO,@TIPO
end
CLOSE Resultado_Cursor;  
DEALLOCATE Resultado_Cursor;

set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador+1,'J900',isnull('|J900|'+	---REG,
		'TERMO DE ENCERRAMENTO|'+	---DNRC_ENCER
		ltrim(rtrim(STR(CONF.SPED_NUM_ORD)))+'|'+	--- NUM_ORD,
		'G|'+	--- NAT_LIVRO,
		rtrim(ltrim(com.CMPNYNAM))+'|'+		---NOME
		'*|'+	---QTD_LIN
		rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+	---DT_INI_ESCR,
		rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|','') 	---DT_FIN_ESCR,
	 from dynamics.dbo.SY01500  com 
	left join SPEDtbl001 conf on com.INTERID =conf.INTERID
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador+1,'J930',isnull('|J930|'+	---REG,
		rtrim(ltrim(conf.SPED_IDENT_NOM))+'|'+		---SIDENT_NOM
		rtrim(ltrim(conf.SPED_IDENT_CPF))+'|'+		---CPF
		rtrim(ltrim(conf.SPED_IDENT_QUALIF))+'|'+		---IDENT_QUALIF
		rtrim(ltrim(conf.SPED_COD_ASSIM))+'|'+		---COD_ASSIM
		rtrim(ltrim(conf.SPED_IND_CRC))+'|'+				---IND_CRC 
		rtrim(ltrim(conf.sped_email))+'|'+							----EMAIL
		rtrim(ltrim(conf.SPED_FONE))+'|'+							----FONE
		'SP|'+														----UF_CRC
		LTRIM(RTRIM(CONF.SPED_NUM_SEQ_CRC))+'|'+					----NUM_SEQ_CRC
		rtrim(replace(convert(char,convert(datetime,conf.sped_DT_CRC,102),103),'/',''))+'|'+ 	---DT_CRC,
		RTRIM(ltrim(conf.SPED_IND_RESP_LEGAL))+'|'
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
----select * from spedtbl9000 order by linea

end