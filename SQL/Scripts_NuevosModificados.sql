use gbra
go
alter PROCEDURE [dbo].[SPED_Total_Saldo_Cta_Open]
	@actindx as int,
	@year1 as int,
	@periodid as int,
	@TipoTotal as int,		-----1=Movimiento    2=Inicial     3=Final
	@Debito as decimal(18,2) out,
	@Credito as decimal(18,2) out,
	@Res as tinyint output
AS
BEGIN
	declare @Nat as int
	declare @ctaUt as int
	set @Nat =(select j.SPED_COD_NAT from GL00100 pc
				left join SPEDtbl004 j on pc.USERDEF1=j.SPED_COD_CTA
				where pc.ACTINDX=@actindx)
	set @ctaUt = (select RERINDX from GL40000)
	if @TipoTotal=1 
	begin
		set @credito=isnull((SELECT round(isnull(abs(sum(case  when CRDTAMNT>0 then CRDTAMNT else case when DEBITAMT<0 then abs(DEBITAMT) else 0 end end)),0),2)
			FROM GL20000 
			WHERE PERIODID<>0 and (OPENYEAR=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+
			case when (@periodid=12) and @Nat=4 then 
				isnull((SELECT isnull(CASE WHEN SUM(DEBITAMT)>SUM(CRDTAMNT) THEN SUM(DEBITAMT)-SUM(CRDTAMNT) ELSE 0 END,0)
					FROM GL20000
					WHERE PERIODID<>0 and (OPENYEAR=@year1 and  PERIODID<=@periodid) and ACTINDX=@actindx),0)
			else 0 end

		set @debito=isnull((SELECT round(isnull(abs(sum(case when DEBITAMT>0 then DEBITAMT else case when CRDTAMNT<0 then abs(CRDTAMNT) else 0 end end)),0),2)
			FROM GL20000 
			WHERE PERIODID<>0 and (OPENYEAR=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+
			case when (@periodid=12) and @Nat=4 then 
				isnull((SELECT isnull(CASE WHEN SUM(CRDTAMNT)>SUM(DEBITAMT) THEN SUM(CRDTAMNT)-SUM(DEBITAMT) ELSE 0 END,0)
					FROM GL20000
					WHERE PERIODID<>0 and (OPENYEAR=@year1 and  PERIODID<=@periodid) and ACTINDX=@actindx),0)
			else 0 end
	end
	if @TipoTotal=2
	begin
		set @credito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where ((PERIODID<@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)+
			case when @nat<>4 then isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where ((YEAR1<@year1)) and ACTINDX=@actindx),0) else 0 end+
			case when @actindx=@ctaUt then isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 m left join GL00100 c on c.ACTINDX=m.ACTINDX
			left join SPEDtbl004 s on s.SPED_COD_CTA=c.USERDEF1  where ((YEAR1<@year1 and s.SPED_COD_NAT='04'))),0) else 0 end

		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where ((PERIODID<@periodid and YEAR1=@year1)) and ACTINDX=@actindx)+case when @nat<>4 then
			isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where ((YEAR1<@year1)) and ACTINDX=@actindx),0) else 0 end+
			case when @actindx=@ctaUt then isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 m left join GL00100 c on c.ACTINDX=m.ACTINDX
			left join SPEDtbl004 s on s.SPED_COD_CTA=c.USERDEF1  where ((YEAR1<@year1 and s.SPED_COD_NAT='04'))),0) else 0 end
	end
	if @TipoTotal=3 
	begin
		set @credito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where ((PERIODID<=@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)+case when @nat<>4 then
			isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where ((YEAR1<@year1)) and ACTINDX=@actindx),0)  else 0 end+
			case when @actindx=@ctaUt then isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 m left join GL00100 c on c.ACTINDX=m.ACTINDX
			left join SPEDtbl004 s on s.SPED_COD_CTA=c.USERDEF1  where ((YEAR1<@year1 and s.SPED_COD_NAT='04'))),0) else 0 end
		set @debito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where ((PERIODID<=@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)+case when @nat<>4 then
			isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where ((YEAR1<@year1)) and ACTINDX=@actindx),0) else 0 end+
			case when @actindx=@ctaUt then isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 m left join GL00100 c on c.ACTINDX=m.ACTINDX
			left join SPEDtbl004 s on s.SPED_COD_CTA=c.USERDEF1  where ((YEAR1<@year1 and s.SPED_COD_NAT='04'))),0) else 0 end

	end
	if @TipoTotal=4 
	begin
		set @Debito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where ((PERIODID<=@periodid and YEAR1=@year1 )) and ACTINDX=@actindx),0)+
			isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where ((YEAR1<@year1)) and ACTINDX=@actindx),0)
		set @Credito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where ((PERIODID<=@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)+
			isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where ((YEAR1<@year1)) and ACTINDX=@actindx),0)
	end
	if @nat=4 and @periodid=12 and @actindx<>@ctaUt
	begin
		if @TipoTotal=3 
		begin
			set @credito=0
			set @Debito=0
		end
	end
	if @nat=4 and @periodid=1 and @actindx<>@ctaUt
	begin
		if @TipoTotal=2 
		begin
			set @credito=0
			set @Debito=0
		end
	end
	if @ctaUt=@actindx and @periodid=12 and @TipoTotal<>2
	begin
		declare @ResDebito as decimal(18,2)
		declare @ResCredito as decimal(18,2)
		set @ResDebito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and j.SPED_COD_NAT=4),0)

		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and j.SPED_COD_NAT=4),0)

		set @Debito=@debito+@ResDebito
		set @Credito=@credito+@ResCredito
		if @Debito>@Credito
		begin
			set @debito=@Debito-@Credito
			set @Credito = 0
		end
		else
		begin
			set @Credito=@Credito-@Debito
			set @Debito=0
		end
	end
	set @res=0
	if isnull(@debito,0)+isnull(@credito,0)<>0
	begin
		set @res=1
	end
	else
	begin 
		set @res=0
	end
END
go

alter  PROCEDURE SPED_Total_Saldo_Cta_Hist
	@actindx as int,
	@year1 as int,
	@periodid as int,
	@TipoTotal as int,		-----1=Movimiento    2=Inicial     3=Final
	@Debito as decimal(18,2) out,
	@Credito as decimal(18,2) out,
	@Res as tinyint output
AS
BEGIN
	declare @Nat as int
	declare @ctaUt as int
	set @Nat =(select j.SPED_COD_NAT from GL00100 pc
				left join SPEDtbl004 j on pc.USERDEF1=j.SPED_COD_CTA
				where pc.ACTINDX=@actindx)
	set @ctaUt = (select RERINDX from GL40000)
	if @TipoTotal=1 
	begin
		set @credito=isnull((SELECT round(isnull(abs(sum(case  when CRDTAMNT>0 then CRDTAMNT else case when DEBITAMT<0 then abs(DEBITAMT) else 0 end end)),0),2)
			FROM GL30000 
			WHERE PERIODID<>0 and (HSTYEAR=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+
			case when @periodid=12 and @Nat=4 then 
				isnull((SELECT isnull(CASE WHEN SUM(DEBITAMT)>SUM(CRDTAMNT) THEN SUM(DEBITAMT)-SUM(CRDTAMNT) ELSE 0 END,0)
					FROM GL30000
					WHERE PERIODID<>0 and (HSTYEAR=@year1 and  PERIODID<=@periodid) and ACTINDX=@actindx),0)
			else 0 end

		set @debito=isnull((SELECT round(isnull(abs(sum(case when DEBITAMT>0 then DEBITAMT else case when CRDTAMNT<0 then abs(CRDTAMNT) else 0 end end)),0),2)
			FROM GL30000 
			WHERE PERIODID<>0 and (HSTYEAR=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+
			case when @periodid=12 and @Nat=4 then 
				isnull((SELECT isnull(CASE WHEN SUM(CRDTAMNT)>SUM(DEBITAMT) THEN SUM(CRDTAMNT)-SUM(DEBITAMT) ELSE 0 END,0)
					FROM GL30000
					WHERE PERIODID<>0 and (HSTYEAR=@year1 and  PERIODID<=@periodid) and ACTINDX=@actindx),0)
			else 0 end
	end
	if @TipoTotal=2
	begin
		set @credito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM GL10111 where ((PERIODID<@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM GL10111 where ((PERIODID<@periodid and YEAR1=@year1)) and ACTINDX=@actindx)
	end
	if @TipoTotal=3 
	begin
		set @credito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM GL10111 where ((PERIODID<=@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)
		set @debito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM GL10111 where ((PERIODID<=@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)

	end
	if @TipoTotal=4 
	begin
		set @Debito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM GL10111 where ((PERIODID<=@periodid and YEAR1=@year1 )) and ACTINDX=@actindx),0)
		set @Credito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM GL10111 where ((PERIODID<=@periodid and YEAR1=@year1)) and ACTINDX=@actindx),0)
	end
	if @nat=4 and @periodid=12 and @actindx<>@ctaUt
	begin
		if @TipoTotal=3
		begin
			set @credito=0
			set @Debito=0
		end
	end
	if @ctaUt=@actindx and @periodid=12 and @TipoTotal<>2
	begin
		declare @ResDebito as decimal(18,2)
		declare @ResCredito as decimal(18,2)
		set @ResDebito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM GL10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and j.SPED_COD_NAT=4),0)

		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM GL10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and j.SPED_COD_NAT=4),0)

		set @Debito=@debito+@ResDebito
		set @Credito=@credito+@ResCredito
		if @Debito>@Credito
		begin
			set @debito=@Debito-@Credito
			set @Credito = 0
		end
		else
		begin
			set @Credito=@Credito-@Debito
			set @Debito=0
		end
	end
	set @res=0
	if isnull(@debito,0)+isnull(@credito,0)<>0
	begin
		set @res=1
	end
	else
	begin 
		set @res=0
	end
END
go
alter PROCEDURE [dbo].[SPED_ArchivoTXT_Open_v400] 
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
	select JRNENTRY,TRXDATE,sum(CRDTAMNT),sum(DEBITAMT) from GL20000 AC 
		where ac.OPENYEAR=@vanio and ac.PERIODID = @vper 
		group by ac.OPENYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE ) order by JRNENTRY
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
			from GL20000 AC
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
			FROM GL10110 AC
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
			from GL20000 AC
			left join gl00100 pc on pc.actindx=ac.ACTINDX
			LEFT JOIN SPEDtbl004 J ON J.SPED_COD_CTA=pc.USERDEF1
			where (j.SPED_COD_NAT=4) and ac.OPENYEAR=@vanio
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
set @rMontoC=isnull((select SUM(abs(r.CRDTAMNT)) from GL10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
/******/
set @rMontoD=isnull((select SUM(abs(r.DEBITAMT)) from gl10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
/******/
set @rMonto=isnull((select SUM(r.PERDBLNC) from gl10110 R
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
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%' and PERIODID =0),0)
	as inicial,
isnull((select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%' and PERIODID =0),0)
	as tipoInicial,
isnull((select abs(isnull((select sum(S.PERDBLNC)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMonto else 0 end)
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 =@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%'),0)
	 as saldo,
isnull((select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMontoc else 0 end>isnull(SUM(ABS(s.DEBITAMT)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMontoc else 0 end then 'C' else 'D' end
	from GL10110 s
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
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(PC.USRDEFS1)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	 as saldo,
isnull((select case when ABS(isnull(SUM(s.CRDTAMNT),0))>ABS(isnull(SUM(s.DEBITAMT),0)) then 'C' else 'D' end
	from GL10110 s
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
go
alter PROCEDURE [dbo].[SPED_ArchivoTXT_Hist_v400] 
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
go
alter PROCEDURE [dbo].[SPED_ArchivoTXT_Hist_v600] 
	@IdCompañia varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	declare @contador int
	set @contador=1

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
		rtrim(case when conf.SPED_IND_SIT_ESP=0 then '' else str(conf.SPED_IND_SIT_ESP) end)+	--- AS IND_SIT_ESP C11
		'|0|1|0||'+cast(CONF.sped_ind_grande_porte as varchar(1))+	----- AS IND_GRANDE_PORTE C16
		'|0||'+CASE CONF.SPED_IDENT_MF WHEN 0 THEN 'N' ELSE 'S' END+		---- AS IDENT_MF C19
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
	from SPEDtbl004 gc WHERE SPED_ES_SN=1
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
		declare Cuentas_gp cursor for (select ACTNUMBR_1,USERDEF1,max(cgp.ACTDESCR) as ACTDESCR  from gl00100 cgp 
		where LTRIM(RTRIM(USERDEF1))=@sped_cod_cta 
		group by ACTNUMBR_1,userdef1) ---,ACTDESCR)
		order by ACTNUMBR_1
		open Cuentas_gp
		fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
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
						isnull('|I052|'+'|'+replace(rtrim(ltrim(@SPED_COD_CTA)),'.','')+'|',''))	--- AS COD_AGL,
			fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
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
	(select JRNENTRY,TRXDATE,sum(case when CRDTAMNT>0 then CRDTAMNT else case when DEBITAMT<0 then abs(DEBITAMT) else 0 end end),sum(case when DEBITAMT>0 then DEBITAMT else case when CRDTAMNT<0 then abs(crdtamnt) else 0 end end) from GL30000 AC 
		where ac.HSTYEAR=@vanio and ac.PERIODID = @vper
		group by ac.HSTYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE
	union
	select JRNENTRY,TRXDATE,sum(case when CRDTAMNT>0 then CRDTAMNT else case when DEBITAMT<0 then abs(DEBITAMT) else 0 end end),sum(case when DEBITAMT>0 then DEBITAMT else case when CRDTAMNT<0 then abs(crdtamnt) else 0 end end) from GL20000 AC 
		where ac.OPENYEAR=@vanio and ac.PERIODID = @vper 
		group by ac.OPENYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE ) order by JRNENTRY
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
				isnull(LTRIM(RTRIM(REPLACE(cast(convert(decimal(10,2),abs(ac.DEBITAMT)+abs(ac.CRDTAMNT))AS nvarchar),'.',','))),'0,00')+'|'+			----VL_DC
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
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)/*+
isnull((select SUM(abs(r.CRDTAMNT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)*/
/******/
set @rMontoD=isnull((select SUM(abs(r.DEBITAMT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)/*+
isnull((select SUM(abs(r.DEBITAMT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)*/
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
(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+replace(rtrim(g.SPED_COD_CTA),'.',''),
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
where G.SPED_COD_NAT IN (1,2,3)) order by g.SPED_COD_CTA
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
				@tipoinicial+'||','|')
		end
	END
	fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
end
CLOSE Balance_cursor;  
DEALLOCATE Balance_cursor;
declare Resultado_Cursor cursor for
(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+ltrim(rtrim(g.sped_codagl)),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
isnull((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	 as saldo,
isnull((select case when ABS(isnull(SUM(s.CRDTAMNT),0))>ABS(isnull(SUM(s.DEBITAMT),0)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (4)) order by g.sped_codagl
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
				CASE WHEN @TIPO='C' THEN 'N' ELSE 'P' END+'|','')+'|||'
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
go
alter PROCEDURE [dbo].[SPED_ArchivoTXT_Open_v600] 
	@IdCompañia varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	declare @contador int
	set @contador=1

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
		rtrim(case when conf.SPED_IND_SIT_ESP=0 then '' else str(conf.SPED_IND_SIT_ESP) end)+	--- AS IND_SIT_ESP C11
		'|0|1|0||'+cast(CONF.sped_ind_grande_porte as varchar(1))+	----- AS IND_GRANDE_PORTE C16
		'|0||'+CASE CONF.SPED_IDENT_MF WHEN 0 THEN 'N' ELSE 'S' END+		---- AS IDENT_MF C19
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
	from SPEDtbl004 gc WHERE SPED_ES_SN=1
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
		declare Cuentas_gp cursor for (select ACTNUMBR_1,USERDEF1,max(cgp.ACTDESCR) as ACTDESCR  from gl00100 cgp 
		where LTRIM(RTRIM(USERDEF1))=@sped_cod_cta 
		group by ACTNUMBR_1,userdef1) ---,ACTDESCR)
		order by ACTNUMBR_1
		open Cuentas_gp
		fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
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
						isnull('|I052|'+'|'+replace(rtrim(ltrim(@SPED_COD_CTA)),'.','')+'|',''))	--- AS COD_AGL,
			fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
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
	(select JRNENTRY,TRXDATE,sum(case when CRDTAMNT>0 then CRDTAMNT else case when DEBITAMT<0 then abs(DEBITAMT) else 0 end end),sum(case when DEBITAMT>0 then DEBITAMT else case when CRDTAMNT<0 then abs(crdtamnt) else 0 end end) from GL30000 AC 
		where ac.HSTYEAR=@vanio and ac.PERIODID = @vper
		group by ac.HSTYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE
	union
	select JRNENTRY,TRXDATE,sum(case when CRDTAMNT>0 then CRDTAMNT else case when DEBITAMT<0 then abs(DEBITAMT) else 0 end end),sum(case when DEBITAMT>0 then DEBITAMT else case when CRDTAMNT<0 then abs(crdtamnt) else 0 end end) from GL20000 AC 
		where ac.OPENYEAR=@vanio and ac.PERIODID = @vper 
		group by ac.OPENYEAR,ac.PERIODID,ac.JRNENTRY,ac.TRXDATE ) order by JRNENTRY
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
				isnull(LTRIM(RTRIM(REPLACE(cast(convert(decimal(10,2),abs(ac.DEBITAMT)+abs(ac.CRDTAMNT))AS nvarchar),'.',','))),'0,00')+'|'+			----VL_DC
				CASE WHEN ac.DEBITAMT>0 THEN 'D' ELSE 'C' END +'|'+			----IND_DC
				LTRIM(RTRIM(str(ac.jrnentry)))+'|'+			----NUM_ARQ
				'|'+			----COD_HIST_PAD
				LTRIM(RTRIM(replace(ac.refrence,'|','')))+'|'+			----HIST
				'|'	,'')		----COD_PART
			from GL20000 AC
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
			FROM GL10110 AC
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
			from GL20000 AC
			left join gl00100 pc on pc.actindx=ac.ACTINDX
			LEFT JOIN SPEDtbl004 J ON J.SPED_COD_CTA=pc.USERDEF1
			where (j.SPED_COD_NAT=4) and ac.OPENYEAR=@vanio
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
declare @rAMonto decimal(18,2),@rAMontoC decimal(18,2),@rAMontoD decimal(18,2)
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
set @rMontoC=isnull((select SUM(abs(r.CRDTAMNT)) from GL10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
/******/
set @rMontoD=isnull((select SUM(abs(r.DEBITAMT)) from gl10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)/*+
isnull((select SUM(abs(r.DEBITAMT)) from gl10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)*/
/******/
set @rMonto=isnull((select SUM(r.PERDBLNC) from gl10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1<=@vanio),0)
/*** Resultado anio anterior abierto*/
set @rAMonto=isnull((select SUM(r.PERDBLNC) from gl10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1<@vanio),0)
set @rAMontoC=isnull((select SUM(abs(r.CRDTAMNT)) from GL10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1<@vanio),0)
set @rAMontoD=isnull((select SUM(abs(r.DEBITAMT)) from GL10110 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1<@vanio),0)
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
(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+replace(rtrim(g.SPED_COD_CTA),'.',''),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
isnull((select abs(isnull(sum(s.DEBITAMT-s.CRDTAMNT)+(case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RAMontoD else 0 end-case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RAMontoc else 0 end),0))						-----saldo inicial en año abierto
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 <@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%' ),0)
	as inicial,
isnull((select case when sum(abs(s.CRDTAMNT))+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RaMontoC else 0 end>sum(abs(s.DEBITAMT))+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RAMontoD else 0 end then 'C' else 'D' end
	from gl10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 <@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%' ),0)
	as tipoInicial,
isnull((select abs(isnull((select sum(S.PERDBLNC)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMonto else 0 end)
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 <=@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%'),0)
	 as saldo,
isnull((select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMontoc else 0 end>isnull(SUM(ABS(s.DEBITAMT)),0)+case when ltrim(rtrim(@CtaUtilGP)) like ltrim(rtrim(g.sped_cod_cta))+'%' then  @RMontoc else 0 end then 'C' else 'D' end
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	where s.YEAR1 <=@vanio and ltrim(rtrim(pc.USERDEF1)) like ltrim(rtrim(g.sped_cod_cta))+'%'),0)
	as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (1,2,3)) order by g.SPED_COD_CTA
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
				@tipoinicial+'||','|')
		end
	END
	fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
end
CLOSE Balance_cursor;  
DEALLOCATE Balance_cursor;
declare Resultado_Cursor cursor for
(select case when g.SPED_NIVEL=1 then 'TG.' else '' end+ltrim(rtrim(g.sped_codagl)),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
isnull((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	 as saldo,
isnull((select case when ABS(isnull(SUM(s.CRDTAMNT),0))>ABS(isnull(SUM(s.DEBITAMT),0)) then 'C' else 'D' end
	from GL10110 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 sc on pc.USERDEF1=sc.SPED_COD_CTA
	where s.YEAR1 =@vanio and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'),0)
	as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (4)) order by g.sped_codagl
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
				CASE WHEN @TIPO='C' THEN 'N' ELSE 'P' END+'|','')+'|||'
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
go
alter PROCEDURE [dbo].[SPED_Total_Saldo_Cta_Anio]
	@actindx as int,
	@USERDEF1 AS VARCHAR(30),
	@year1 as int,
	@TipoTotal as int,		-----1=Movimiento    2=Inicial     3=Final
	@Debito as decimal(18,2) out,
	@Credito as decimal(18,2) out,
	@Res as tinyint output
AS
BEGIN
	declare @Nat as int
	declare @ctaUt as int
	DECLARE @UCTAUT AS INT
	declare @ResDebito as decimal(18,2)
	declare @ResCredito as decimal(18,2)

	set @Nat =(select j.SPED_COD_NAT from GL00100 pc
				left join SPEDtbl004 j on pc.USERDEF1=j.SPED_COD_CTA
				where pc.ACTINDX=@actindx)
	set @ctaUt = (select RERINDX from GL40000)
	if @TipoTotal=1 
	begin
		set @credito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 
		WHERE PERIODID<>0 and (YEAR1=@year1) and ACTINDX=@actindx),0)+isnull((
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1) and ACTINDX=@actindx),0)+
		case when @Nat=4 then 
		(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1) and ACTINDX=@actindx) 
		else 0 end

		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 
		WHERE PERIODID<>0 and (YEAR1=@year1) and ACTINDX=@actindx)+isnull((
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1) and ACTINDX=@actindx),0)+
		case when @Nat=4 then 
		(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1) and ACTINDX=@actindx) else 0 end
	end
	if @TipoTotal=2
	begin
		set @credito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 where (PERIODID<>0 and YEAR1<@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where ((PERIODID<>0 and YEAR1<@year1)) and ACTINDX=@actindx)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (PERIODID<>0 and YEAR1<@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where (PERIODID<>0 and YEAR1<@year1) and ACTINDX=@actindx)
	end
	if @TipoTotal=3 
	begin
		set @credito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 where (PERIODID<>0 and YEAR1<=@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where (PERIODID<>0 and YEAR1<=@year1) and ACTINDX=@actindx)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (PERIODID<>0 and YEAR1<=@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where PERIODID<>0 and (YEAR1<=@year1) and ACTINDX=@actindx)
	end
	if @TipoTotal=4
	begin
		if @actindx=0
		begin
			set @uctaUt = (select ACTINDX FROM GL00100 WHERE left(USERDEF1,13)=@USERDEF1 and ACTINDX=@ctaUt)
			set @Debito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110
			left join GL00100 p on p.ACTINDX=GL10110.ACTINDX
			where ((YEAR1=@year1)) and p.USERDEF1 like @USERDEF1+'%')+(
			SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10111
			left join GL00100 p on p.ACTINDX=GL10111.ACTINDX
			where ((YEAR1=@year1)) and p.USERDEF1 like @USERDEF1+'%')
			set @Credito=(SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 
			left join GL00100 p on p.ACTINDX=GL10110.ACTINDX
			where ((YEAR1=@year1)) and p.USERDEF1 like @USERDEF1+'%')+(
			SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10111 
			left join GL00100 p on p.ACTINDX=GL10111.ACTINDX
			where ((YEAR1=@year1)) and p.USERDEF1 like @USERDEF1+'%')
		end
		else
		begin
			set @Debito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
			SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
			set @Credito=(SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
			SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
		end
	end

	if @ctaUt=@actindx and (@TipoTotal<>2 AND @TipoTotal<>4)
	begin
		set @ResDebito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1) and j.SPED_COD_NAT=4),0)
		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1) and j.SPED_COD_NAT=4),0)
		set @Debito=@Debito+@ResDebito
		set @Credito=@Credito+@ResCredito
		if @Debito>@Credito
		begin
			set @debito=@Debito-@Credito
			set @Credito = 0
		end
		else
		begin
			set @Credito=@Credito-@Debito
			set @Debito=0
		end
	end
	if @UctaUt<>0 and (@TipoTotal=4)
	begin
		set @ResDebito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1) and j.SPED_COD_NAT=4),0)
		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1) and j.SPED_COD_NAT=4),0)
		set @Debito=@Debito+@ResDebito
		set @Credito=@Credito+@ResCredito
		if @Debito>@Credito
		begin
			set @debito=@Debito-@Credito
			set @Credito = 0
		end
		else
		begin
			set @Credito=@Credito-@Debito
			set @Debito=0
		end
	end

	set @res=0
	if isnull(@debito-@credito,0)<>0
	begin
		set @res=1
	end
	else
	begin 
		set @res=0
	end
END

go
alter PROCEDURE [dbo].[SPED_ArchivoTXT_ECF_v300] 
	@IdCompañia varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	declare @contador int
	set @contador=1
	SET NOCOUNT ON;

delete spedtbl9000
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador,'0000',isnull('|0000|'+	---REG,
		'LECF|'+	--- NOME_ESC,
		'0003|'+ --- COD_VER
		rtrim(isnull(com.TAXREGTN,''))+'|'+	---CNPJ
		rtrim(isnull(com.CMPNYNAM,''))+'|'+	---NOME
		'0|'+ ---ND_SIT_INI_PE
		'0|'+ ---SIT_ESPECIAL
		'||'+
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+	--- DT_INI C3,
		rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+	---DT_FIN C4,
		'N||0||','')
			---SECCION 0000
	from dynamics.dbo.SY01500  com 
	left join SPEDtbl001 conf on com.INTERID =conf.INTERID
insert into spedtbl9000 (linea, seccion, datos)	
		SELECT @contador+1,'0001',isnull('|0001|0|','')	--- SECCION 0001
insert into spedtbl9000 (linea,seccion, datos)	
	values(@contador+2,'0010',isnull('|0010||N|N|1|A|01|RRRR|BBBBBBBBBBBB||||||',''))---SECCION 0010
insert into spedtbl9000 (linea,seccion, datos)	
	values(@contador+3,'0020',isnull('|0020|1||N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|S|N|N|N|N|N|N|N|N|N|N|N|N|',''))---SECCION 0020
insert into SPEDtbl9000 (linea,seccion,datos)
	SELECT @contador+4,'0030',ISNULL('|0030|2062|6391700|'+
	substring(RTRIM(COM.ADDRESS1),1,LEN(rtrim(com.address1))-6)+
	'|'+RIGHT(rtrim(com.address1),4)+'|'+
	rtrim(com.address2)+'|'+
	rtrim(com.address3)+'|SP|'+
	rtrim(com.county)+'|'+
	replace(rtrim(com.ZIPCODE),'-','')+'|'+
	rtrim(com.phone1)+'|'+
	(select rtrim(INET1) from SY01200 where Master_ID=conf.INTERID)+'|','')
	FROM DYNAMICS.DBO.SY01500 COM
	LEFT JOIN SPEDtbl001 CONF ON COM.INTERID=CONF.INTERID ---SECCION 0030
set @contador=@contador+4
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador+1,'0930',isnull('|0930|'+	---REG,
		rtrim(ltrim(conf.SPED_IDENT_NOM))+'|'+		---SIDENT_NOM
		rtrim(ltrim(conf.SPED_IDENT_CPF))+'|'+		---CPF
		rtrim(ltrim(conf.SPED_COD_ASSIM))+'|'+		---COD_ASSIM
		rtrim(ltrim(conf.SPED_IND_CRC))+'|'+				---IND_CRC 
		rtrim(ltrim(conf.sped_email))+'|'+							----EMAIL
		rtrim(ltrim(conf.SPED_FONE))+'|'							----FONE
		,'')	
	 from SPEDtbl002 conf
	 where conf.INTERID =@IdCompañia
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+1,'0990',isnull('|0990|'+	--- AS REG,
			+ltrim(rtrim(cast(@contador+2 as varchar)))+'|',''))		--- AS QTD_LIN_0							---SECCION 0990
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+1,'J001',isnull('|J001|0|'	--- AS REG,
			,''))					---SECCION J001
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
declare PlanCuentas_Cursor cursor for
(SELECT DOCDATE,
		SPED_COD_NAT,
		isnull(left(pc.userdef1,10),SPED_COD_CTA),
		SPED_IND_CTA,
		SPED_NIVEL,
		SPED_COD_CTA_SUP,
		SPED_CTA,
		gc.ACTDESCR, ---isnull(pc.ACTDESCR,gc.ACTDESCR) AS ACTDESCR,
		isnull(PC.USERDEF1,'') as userdef1,
		isnull(PC.USERDEF2,''),
		isnull(pc.ACTNUMBR_1,'')
	from SPEDtbl004 gc 
	left join GL00100 pc on pc.USERDEF1=gc.SPED_COD_CTA
	where SPED_NIVEL <=4) ---(case when sped_ind_cta='A' then userdef1 else '1' end) is not null)
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
	insert into spedtbl9000 (linea,seccion,datos)	
		values (@contador+1,'J050',
				isnull('|J050|'+	--- AS REG,'',
				rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
				RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
				rtrim(ltrim(@SPED_IND_CTA))+'|'+	--- AS IND_CTA,
				LTRIM(STR(@SPED_NIVEL))+'|'+	--- AS NÍVEL,
				RTRIM(@sped_cod_cta)+'|'+	---  AS CÓD_CTA,
				RTRIM(@SPED_COD_CTA_SUP)+'|'+	--- AS CÓD_CTA_SUP,
				RTRIM(@ACTDESCR)+'|',''))
	if @SPED_NIVEL=4 ---@SPED_IND_CTA='A'
	begin
		declare Cuentas_gp cursor for (select ACTNUMBR_1,USERDEF1,cgp.ACTDESCR from gl00100 cgp where left(userdef1,10)=@sped_cod_cta group by ACTNUMBR_1,userdef1,ACTDESCR)
		order by ACTNUMBR_1
		open Cuentas_gp
		fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
		while @@FETCH_STATUS=0
		begin
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion,datos)	
				values (@contador+1,'J050',
						isnull('|J050|'+	--- AS REG,'',
						rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
						RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
						'A|'+	--- AS IND_CTA,
						'5|'+	--- AS NÍVEL,
						RTRIM(@sped_cod_cta)+'.'+rtrim(@codigogp)+'|'+	---  AS CÓD_CTA,
						RTRIM(@SPED_COD_CTA)+'|'+	--- AS CÓD_CTA_SUP,
						RTRIM(@ACTDESCR)+'|',''))
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion, datos)	
				VALUES (@contador+1,'J051',
						isnull('|J051|'+	--- AS REG,
						'|'+	--- AS CÓD_CCUS,
						rtrim(LTRIM(@USERDEF1))+'|',''))	--- CÓD_CTA_REF
			fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
		end
		close cuentas_gp
		deallocate cuentas_gp
	end
	FETCH NEXT FROM PlanCuentas_Cursor into @docdate,@SPED_COD_NAT ,@sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL,@SPED_COD_CTA_SUP,@SPED_CTA,@ACTDESCR,@USERDEF1,@USERDEF2,@codigogp
end
close PlanCuentas_Cursor
deallocate PlanCuentas_Cursor;
declare @sgmtid varchar(10)
declare @dscriptn varchar(80)
declare @fecha datetime
declare cc_cursor cursor for (select cc.SGMNTID,cc.DSCRIPTN,cc.DEX_ROW_TS from GL40200 cc where SGMTNUMB=2)
open cc_cursor
fetch next from cc_cursor into @sgmtid,@dscriptn,@fecha
WHILE @@FETCH_STATUS = 0  
begin 
set @contador=@contador+1
insert into spedtbl9000 (linea,SECCION,datos)
	values( @contador+1,'J100',
		isnull('|J100|'+
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,103),103),'/',''))+'|'+
		rtrim(ltrim(@sgmtid))+'|'+
		rtrim(ltrim(@DSCRIPTN))+'|',''))
	fetch next from cc_cursor into @sgmtid,@dscriptn,@fecha
end
CLOSE CC_CURSOR
DEALLOCATE CC_CURSOR
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'J990',
	'|J990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='J')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'K001',
	'|K001|0|')
declare @actindxm as int,@actindxi as int, @actindxf as int
declare @vanio as int
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,'K030',isnull('|K030|'+
rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+
rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|A00|',''))
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
set @vanio = YEAR(@FechaDesde)
WHILE @@FETCH_STATUS = 0  
begin
	exec SPED_Total_Saldo_Cta_Anio @actindx,'',@vanio,1,@debito out,@credito out,@tieneM output
	exec SPED_Total_Saldo_Cta_Anio @actindx,'',@vanio,2,@idebito out,@icredito out,@tieneI output
	exec SPED_Total_Saldo_Cta_Anio @actindx,'',@vanio,3,@fdebito out,@fcredito out,@tieneF output
	if @tieneF+@tieneI+@tieneM>0
	begin		
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		VALUES(@contador+1,'K155',
				isnull('|K155|'+						----REG
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
CLOSE PLANCUENTA_CURSOR
DEALLOCATE PLANCUENTA_CURSOR 
declare GP_Cursor cursor for
(select left(rtrim(pc.userdef1),13) as cta from GL00100 pc
	left join spedtbl004 sp on sp.sped_cod_cta=pc.userdef1
	group by left(rtrim(pc.userdef1),13))
	order by cta
open GP_cursor
fetch next from gp_cursor into @sped_cod_cta
declare @debitamt as decimal(18,2)
declare @crdtamnt as decimal(18,2)
while @@fetch_status =0
begin
exec SPED_Total_Saldo_Cta_Anio 0,@sped_cod_cta,@vanio,4,@debitamt out,@crdtamnt out,@tieneF out
if @tieneF+@tieneI+@tieneM<> 0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'K156',isnull('|K156|'+
		@sped_cod_cta+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
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
exec SPED_Total_Saldo_Cta_anio @actindx,'',@vanio,4,@debitamt out,@crdtamnt out,@tieneF out
if @DEBITAMT+@CRDTAMNT<>0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'K355',isnull('|K355|'+
		@sped_cod_cta+'|'+
		@sgmtid+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta,@sgmtid,@actindx
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
declare GP_Cursor cursor for
(select rtrim(left(pc.userdef1,13)) as cta from GL00100 pc
	left join spedtbl004 sp on sp.sped_cod_cta=pc.userdef1
	where sp.sped_cod_nat=4
	group by rtrim(left(pc.userdef1,13)) )
	order by cta
open GP_cursor
fetch next from gp_cursor into @sped_cod_cta
while @@fetch_status =0
begin
exec SPED_Total_Saldo_Cta_anio 0,@sped_cod_cta,@vanio,4,@debitamt out,@crdtamnt out,@tieneF out
if @DEBITAMT+@CRDTAMNT<>0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'K356',isnull('|K356|'+
		@sped_cod_cta+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	values (@contador+1,
	'K990',
	'|K990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='K')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'L001',
	'|L001|0|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'L030',
	'|L030|'+
	rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+	---DT_INI,
	rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|A00|') 	---DT_FIN,
DECLARE @TIPO VARCHAR
declare @RMonto decimal(18,2)
declare @RMontoC decimal(18,2) 
declare @RMontoD decimal(18,2)
DECLARE @RSped_Cod_Cta_N1 varchar(50)
DECLARE @RSped_cod_cta_n2 varchar(50)
DECLARE @RSped_cod_cta_n3 varchar(50)
DECLARE @RSped_cod_cta_n4 varchar(50)

set @rMontoC=isnull((select SUM(abs(r.CRDTAMNT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)+isnull((select SUM(abs(r.CRDTAMNT)) from gl10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
set @rMontoD=(select SUM(abs(r.DEBITAMT)) from gl10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio)
set @rMonto=(select SUM(r.PERDBLNC) from gl10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio)
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
(select g.SPED_COD_CTA,
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
case SPED_NIVEL when 1 then
	abs(isnull((select sum(s.DEBITAMT-s.CRDTAMNT)						-----saldo inicial en año abierto
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0),
	isnull((select sum(s.DEBITAMT-s.CRDTAMNT)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA  and PERIODID =0),
	(select sum(s.DEBITAMT-s.CRDTAMNT)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))))
	when 2 then abs((select sum(s.DEBITAMT-s.CRDTAMNT)
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))
	when 3 then abs((select sum(s.DEBITAMT-s.CRDTAMNT)
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))
	when 4 then abs((select sum(s.DEBITAMT-s.CRDTAMNT)
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))
	end as inicial,
case SPED_NIVEL 
	when 1 then	(select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 2 then (select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 3 then (select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 4 then (select case when abs(sum(s.CRDTAMNT))>abs(sum(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 5 then (select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	end as tipoInicial,
case SPED_NIVEL when 1 then
	abs(case when @RSped_Cod_Cta_N1 = g.SPED_COD_CTA then (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)+@RMonto
	else (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	when 2 then 
	abs(case when @RSped_cod_cta_n2 =g.SPED_COD_CTA then isnull((select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	when 3 then abs(case when @RSped_cod_cta_n3=g.SPED_COD_CTA then isnull((select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 4 then abs(case when @RSped_cod_cta_n4=g.SPED_COD_CTA then isnull((select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	when 5 then abs(case when @RSped_cod_cta_n4=g.SPED_COD_CTA then isnull((select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	end as saldo,
case SPED_NIVEL 
	when 1 then	(case when @RSped_Cod_Cta_N1 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 2 then (case when @RSped_Cod_Cta_N2 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@rMontod then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 3 then (case when @RSped_Cod_Cta_N3 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA) 
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 4 then (case when @RSped_Cod_Cta_N4 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 5 then (case when @RSped_Cod_Cta_N4 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA) end)
	end as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (1,2,3)) order by g.SPED_COD_CTA
open Balance_cursor
fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
while @@fetch_status =0
begin
	IF @CREDITO<>0
	BEGIN
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'L100',isnull('|L100|'+
				RTRIM(@sped_cod_cta)+'|'+
				RTRIM(@ACTDESCR)+'|'+
				case when @SPED_NIVEL<5 then 'S' else 'A' end +'|'+
				LTRIM(STR(@SPED_NIVEL))+'|'+
				rtrim(@SPED_COD_NAT)+'|'+
				isnull((select rtrim(j.SPED_COD_CTA_SUP) from  spedtbl004 j where j.SPED_COD_CTA=@sped_cod_cta),'')+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
				@TIPO+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@inicial) as nvarchar),'.',','))),'0,00')+'|'+
				@tipoinicial+'|','|')
	END
	fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
end
CLOSE Balance_cursor;  
DEALLOCATE Balance_cursor;
declare Resultado_Cursor cursor for
(select rtrim(g.SPED_COD_CTA),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
case SPED_NIVEL when 1 then
	abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA))
	when 2 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA))
	when 3 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA))
	when 4 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA))
	when 5 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA))
	when 6 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n6.SPED_COD_CTA=g.SPED_COD_CTA))
	end as saldo,
case SPED_NIVEL 
	when 1 then	(select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)
	when 2 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA)
	when 3 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA)
	when 4 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA)
	when 5 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA)
	when 6 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n6.SPED_COD_CTA=g.SPED_COD_CTA)
	end as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (4)) order by g.SPED_COD_CTA
open Resultado_Cursor
fetch next from Resultado_Cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@CREDITO,@TIPO
while @@fetch_status =0
begin
	IF @CREDITO>0
	BEGIN
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'L300',isnull('|L300|'+
				RTRIM(@sped_cod_cta)+'|'+
				RTRIM(@ACTDESCR)+'|'+
				case when @SPED_NIVEL<5 then 'S' else 'A' end+'|'+
				LTRIM(STR(@SPED_NIVEL))+'|'+
				rtrim(@sped_cod_nat)+'|'+
				(select rtrim(j.SPED_COD_CTA_SUP) from spedtbl004 j where j.SPED_COD_CTA=@sped_cod_cta )+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
				@TIPO+'|','')
	END
	fetch next from Resultado_Cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@CREDITO,@TIPO
end
CLOSE Resultado_Cursor;  
DEALLOCATE Resultado_Cursor;
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	values (@contador+1,
	'L990',
	'|L990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='L')) as nvarchar))),'0')+'|')

set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'9001',
	'|9001|'+
	'0|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
select @contador+1,
	'9900',
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

----select * from spedtbl9000 order by linea

end

GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
alter PROCEDURE [dbo].[SPED_ArchivoTXT_ECF_v400] 
	@IdCompañia varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	declare @contador int
	set @contador=1
	SET NOCOUNT ON;

delete spedtbl9000
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador,'0000',isnull('|0000|'+	---REG,
		'LECF|'+	--- NOME_ESC,
		'0004|'+ --- COD_VER
		rtrim(isnull(com.TAXREGTN,''))+'|'+	---CNPJ
		rtrim(isnull(com.CMPNYNAM,''))+'|'+	---NOME
		'0|'+ ---ND_SIT_INI_PE
		'0|'+ ---SIT_ESPECIAL
		'||'+
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+	--- DT_INI C3,
		rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+	---DT_FIN C4,
		'N||0||','')
			---SECCION 0000
	from dynamics.dbo.SY01500  com 
	left join SPEDtbl001 conf on com.INTERID =conf.INTERID
insert into spedtbl9000 (linea, seccion, datos)	
		SELECT @contador+1,'0001',isnull('|0001|0|','')	--- SECCION 0001
insert into spedtbl9000 (linea,seccion, datos)	
	values(@contador+2,'0010',isnull('|0010||N|N|1|A|01|RRRR|BBBBBBBBBBBB||||||',''))---SECCION 0010
insert into spedtbl9000 (linea,seccion, datos)	
	values(@contador+3,'0020',isnull('|0020|1||N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|S|N|N|N|N|N|N|N|N|N|N|N|N|N|',''))---SECCION 0020
insert into SPEDtbl9000 (linea,seccion,datos)
	SELECT @contador+4,'0030',ISNULL('|0030|2062|6391700|'+
	substring(RTRIM(COM.ADDRESS1),1,LEN(rtrim(com.address1))-6)+
	'|'+RIGHT(rtrim(com.address1),4)+'|'+
	rtrim(com.address2)+'|'+
	rtrim(com.address3)+'|SP|'+
	rtrim(com.county)+'|'+
	replace(rtrim(com.ZIPCODE),'-','')+'|'+
	rtrim(com.phone1)+'|'+
	(select rtrim(INET1) from SY01200 where Master_ID=conf.INTERID)+'|','')
	FROM DYNAMICS.DBO.SY01500 COM
	LEFT JOIN SPEDtbl001 CONF ON COM.INTERID=CONF.INTERID ---SECCION 0030
set @contador=@contador+4
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	select @contador+1,'0930',isnull('|0930|'+	---REG,
		rtrim(ltrim(conf.SPED_IDENT_NOM))+'|'+		---SIDENT_NOM
		rtrim(ltrim(conf.SPED_IDENT_CPF))+'|'+		---CPF
		rtrim(ltrim(conf.SPED_COD_ASSIM))+'|'+		---COD_ASSIM
		rtrim(ltrim(conf.SPED_IND_CRC))+'|'+				---IND_CRC 
		rtrim(ltrim(conf.sped_email))+'|'+							----EMAIL
		rtrim(ltrim(conf.SPED_FONE))+'|'							----FONE
		,'')	
	 from SPEDtbl002 conf
	 where conf.INTERID =@IdCompañia
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+1,'0990',isnull('|0990|'+	--- AS REG,
			+ltrim(rtrim(cast(@contador+2 as varchar)))+'|',''))		--- AS QTD_LIN_0							---SECCION 0990
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion, datos)	
	values( @contador+1,'J001',isnull('|J001|0|'	--- AS REG,
			,''))					---SECCION J001
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
declare PlanCuentas_Cursor cursor for
(SELECT DOCDATE,
		SPED_COD_NAT,
		isnull(left(pc.userdef1,10),SPED_COD_CTA),
		SPED_IND_CTA,
		SPED_NIVEL,
		SPED_COD_CTA_SUP,
		SPED_CTA,
		gc.ACTDESCR, ---isnull(pc.ACTDESCR,gc.ACTDESCR) AS ACTDESCR,
		isnull(PC.USERDEF1,'') as userdef1,
		isnull(PC.USERDEF2,''),
		isnull(pc.ACTNUMBR_1,'')
	from SPEDtbl004 gc 
	left join GL00100 pc on pc.USERDEF1=gc.SPED_COD_CTA
	where SPED_NIVEL <=4) ---(case when sped_ind_cta='A' then userdef1 else '1' end) is not null)
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
	insert into spedtbl9000 (linea,seccion,datos)	
		values (@contador+1,'J050',
				isnull('|J050|'+	--- AS REG,'',
				rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
				RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
				rtrim(ltrim(@SPED_IND_CTA))+'|'+	--- AS IND_CTA,
				LTRIM(STR(@SPED_NIVEL))+'|'+	--- AS NÍVEL,
				RTRIM(@sped_cod_cta)+'|'+	---  AS CÓD_CTA,
				RTRIM(@SPED_COD_CTA_SUP)+'|'+	--- AS CÓD_CTA_SUP,
				RTRIM(@ACTDESCR)+'|',''))
	if @SPED_NIVEL=4 ---@SPED_IND_CTA='A'
	begin
		declare Cuentas_gp cursor for (select ACTNUMBR_1,USERDEF1,cgp.ACTDESCR from gl00100 cgp where left(userdef1,10)=@sped_cod_cta group by ACTNUMBR_1,userdef1,ACTDESCR)
		order by ACTNUMBR_1
		open Cuentas_gp
		fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
		while @@FETCH_STATUS=0
		begin
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion,datos)	
				values (@contador+1,'J050',
						isnull('|J050|'+	--- AS REG,'',
						rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
						RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
						'A|'+	--- AS IND_CTA,
						'5|'+	--- AS NÍVEL,
						RTRIM(@sped_cod_cta)+'.'+rtrim(@codigogp)+'|'+	---  AS CÓD_CTA,
						RTRIM(@SPED_COD_CTA)+'|'+	--- AS CÓD_CTA_SUP,
						RTRIM(@ACTDESCR)+'|',''))
			set @contador=@contador+1
			insert into spedtbl9000 (linea,seccion, datos)	
				VALUES (@contador+1,'J051',
						isnull('|J051|'+	--- AS REG,
						'|'+	--- AS CÓD_CCUS,
						rtrim(LTRIM(@USERDEF1))+'|',''))	--- CÓD_CTA_REF
			fetch next from cuentas_gp into @codigogp,@userdef1,@Actdescr
		end
		close cuentas_gp
		deallocate cuentas_gp
	end
	FETCH NEXT FROM PlanCuentas_Cursor into @docdate,@SPED_COD_NAT ,@sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL,@SPED_COD_CTA_SUP,@SPED_CTA,@ACTDESCR,@USERDEF1,@USERDEF2,@codigogp
end
close PlanCuentas_Cursor
deallocate PlanCuentas_Cursor;
declare @sgmtid varchar(10)
declare @dscriptn varchar(80)
declare @fecha datetime
declare cc_cursor cursor for (select cc.SGMNTID,cc.DSCRIPTN,cc.DEX_ROW_TS from GL40200 cc where SGMTNUMB=2)
open cc_cursor
fetch next from cc_cursor into @sgmtid,@dscriptn,@fecha
WHILE @@FETCH_STATUS = 0  
begin 
set @contador=@contador+1
insert into spedtbl9000 (linea,SECCION,datos)
	values( @contador+1,'J100',
		isnull('|J100|'+
		rtrim(replace(convert(char,convert(datetime,@FechaDesde,103),103),'/',''))+'|'+
		rtrim(ltrim(@sgmtid))+'|'+
		rtrim(ltrim(@DSCRIPTN))+'|',''))
	fetch next from cc_cursor into @sgmtid,@dscriptn,@fecha
end
CLOSE CC_CURSOR
DEALLOCATE CC_CURSOR
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'J990',
	'|J990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='J')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'K001',
	'|K001|0|')
declare @actindxm as int,@actindxi as int, @actindxf as int
declare @vanio as int
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,'K030',isnull('|K030|'+
rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+
rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|A00|',''))
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
set @vanio = YEAR(@FechaDesde)
WHILE @@FETCH_STATUS = 0  
begin
	exec SPED_Total_Saldo_Cta_Anio @actindx,'',@vanio,1,@debito out,@credito out,@tieneM output
	exec SPED_Total_Saldo_Cta_Anio @actindx,'',@vanio,2,@idebito out,@icredito out,@tieneI output
	exec SPED_Total_Saldo_Cta_Anio @actindx,'',@vanio,3,@fdebito out,@fcredito out,@tieneF output
	if @tieneF+@tieneI+@tieneM>0
	begin		
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
		VALUES(@contador+1,'K155',
				isnull('|K155|'+						----REG
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
CLOSE PLANCUENTA_CURSOR
DEALLOCATE PLANCUENTA_CURSOR 
declare GP_Cursor cursor for
(select left(rtrim(pc.userdef1),13) as cta from GL00100 pc
	left join spedtbl004 sp on sp.sped_cod_cta=pc.userdef1
	group by left(rtrim(pc.userdef1),13))
	order by cta
open GP_cursor
fetch next from gp_cursor into @sped_cod_cta
declare @debitamt as decimal(18,2)
declare @crdtamnt as decimal(18,2)
while @@fetch_status =0
begin
exec SPED_Total_Saldo_Cta_Anio 0,@sped_cod_cta,@vanio,4,@debitamt out,@crdtamnt out,@tieneF out
if @tieneF+@tieneI+@tieneM<> 0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'K156',isnull('|K156|'+
		@sped_cod_cta+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
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
exec SPED_Total_Saldo_Cta_anio @actindx,'',@vanio,4,@debitamt out,@crdtamnt out,@tieneF out
if @DEBITAMT+@CRDTAMNT<>0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'K355',isnull('|K355|'+
		@sped_cod_cta+'|'+
		@sgmtid+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta,@sgmtid,@actindx
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
declare GP_Cursor cursor for
(select rtrim(left(pc.userdef1,13)) as cta from GL00100 pc
	left join spedtbl004 sp on sp.sped_cod_cta=pc.userdef1
	where sp.sped_cod_nat=4
	group by rtrim(left(pc.userdef1,13)) )
	order by cta
open GP_cursor
fetch next from gp_cursor into @sped_cod_cta
while @@fetch_status =0
begin
exec SPED_Total_Saldo_Cta_anio 0,@sped_cod_cta,@vanio,4,@debitamt out,@crdtamnt out,@tieneF out
if @DEBITAMT+@CRDTAMNT<>0
begin
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
	select @contador+1,'K356',isnull('|K356|'+
		@sped_cod_cta+'|'+
		isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(@DEBITAMT-@CRDTAMNT)) as nvarchar),'.',','))),'0,00')+'|'+
		case when @CRDTAMNT>@DEBITAMT then 'D' else 'C' end+'|','')
end
	fetch next from gp_cursor into @sped_cod_cta
end
CLOSE GP_Cursor;  
DEALLOCATE GP_Cursor;
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	values (@contador+1,
	'K990',
	'|K990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='K')) as nvarchar))),'0')+'|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'L001',
	'|L001|0|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'L030',
	'|L030|'+
	rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+	---DT_INI,
	rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|A00|') 	---DT_FIN,
DECLARE @TIPO VARCHAR
declare @RMonto decimal(18,2)
declare @RMontoC decimal(18,2) 
declare @RMontoD decimal(18,2)
DECLARE @RSped_Cod_Cta_N1 varchar(50)
DECLARE @RSped_cod_cta_n2 varchar(50)
DECLARE @RSped_cod_cta_n3 varchar(50)
DECLARE @RSped_cod_cta_n4 varchar(50)

set @rMontoC=isnull((select SUM(abs(r.CRDTAMNT)) from GL10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)+isnull((select SUM(abs(r.CRDTAMNT)) from gl10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio),0)
set @rMontoD=(select SUM(abs(r.DEBITAMT)) from gl10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio)
set @rMonto=(select SUM(r.PERDBLNC) from gl10111 R
inner join GL00100 p on p.ACTINDX=r.ACTINDX
inner join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
where j.SPED_COD_NAT=4 and r.YEAR1=@vanio)
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
(select g.SPED_COD_CTA,
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
case SPED_NIVEL when 1 then
	abs(isnull((select sum(s.DEBITAMT-s.CRDTAMNT)						-----saldo inicial en año abierto
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0),
	isnull((select sum(s.DEBITAMT-s.CRDTAMNT)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA  and PERIODID =0),
	(select sum(s.DEBITAMT-s.CRDTAMNT)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))))
	when 2 then abs((select sum(s.DEBITAMT-s.CRDTAMNT)
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))
	when 3 then abs((select sum(s.DEBITAMT-s.CRDTAMNT)
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))
	when 4 then abs((select sum(s.DEBITAMT-s.CRDTAMNT)
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0))
	end as inicial,
case SPED_NIVEL 
	when 1 then	(select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 2 then (select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 3 then (select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 4 then (select case when abs(sum(s.CRDTAMNT))>abs(sum(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	when 5 then (select case when sum(abs(s.CRDTAMNT))>sum(abs(s.DEBITAMT)) then 'C' else 'D' end
	from gl10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA and PERIODID =0)
	end as tipoInicial,
case SPED_NIVEL when 1 then
	abs(case when @RSped_Cod_Cta_N1 = g.SPED_COD_CTA then (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)+@RMonto
	else (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	when 2 then 
	abs(case when @RSped_cod_cta_n2 =g.SPED_COD_CTA then isnull((select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	when 3 then abs(case when @RSped_cod_cta_n3=g.SPED_COD_CTA then isnull((select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select SUM(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 4 then abs(case when @RSped_cod_cta_n4=g.SPED_COD_CTA then isnull((select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	when 5 then abs(case when @RSped_cod_cta_n4=g.SPED_COD_CTA then isnull((select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA),0)+@RMonto
	else (select sum(S.PERDBLNC)
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA)
	end)
	end as saldo,
case SPED_NIVEL 
	when 1 then	(case when @RSped_Cod_Cta_N1 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 2 then (case when @RSped_Cod_Cta_N2 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@rMontod then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 3 then (case when @RSped_Cod_Cta_N3 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA) 
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 4 then (case when @RSped_Cod_Cta_N4 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA) end)
	when 5 then (case when @RSped_Cod_Cta_N4 = g.SPED_COD_CTA then (select case when isnull(SUM(ABS(s.CRDTAMNT)),0)+@RMontoC>isnull(SUM(ABS(s.DEBITAMT)),0)+@RMontoD then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA)
	else (select case when SUM(ABS(s.CRDTAMNT))>SUM(ABS(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n5 on n5.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA) end)
	end as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (1,2,3)) order by g.SPED_COD_CTA
open Balance_cursor
fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
while @@fetch_status =0
begin
	IF @CREDITO<>0
	BEGIN
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'L100',isnull('|L100|'+
				RTRIM(@sped_cod_cta)+'|'+
				RTRIM(@ACTDESCR)+'|'+
				case when @SPED_NIVEL<5 then 'S' else 'A' end +'|'+
				LTRIM(STR(@SPED_NIVEL))+'|'+
				rtrim(@SPED_COD_NAT)+'|'+
				isnull((select rtrim(j.SPED_COD_CTA_SUP) from  spedtbl004 j where j.SPED_COD_CTA=@sped_cod_cta),'')+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
				@TIPO+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@inicial) as nvarchar),'.',','))),'0,00')+'|'+
				@tipoinicial+'|','|')
	END
	fetch next from Balance_cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@inicial,@tipoinicial,@CREDITO,@TIPO
end
CLOSE Balance_cursor;  
DEALLOCATE Balance_cursor;
declare Resultado_Cursor cursor for
(select rtrim(g.SPED_COD_CTA),
g.SPED_NIVEL,
g.SPED_COD_NAT,
g.ACTDESCR,
case SPED_NIVEL when 1 then
	abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1=@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA))
	when 2 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA))
	when 3 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA))
	when 4 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA))
	when 5 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA))
	when 6 then abs((select abs(SUM(s.DEBITAMT)-SUM(s.CRDTAMNT))
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n6.SPED_COD_CTA=g.SPED_COD_CTA))
	end as saldo,
case SPED_NIVEL 
	when 1 then	(select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n1.SPED_COD_CTA=g.SPED_COD_CTA)
	when 2 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n2.SPED_COD_CTA=g.SPED_COD_CTA)
	when 3 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n3.SPED_COD_CTA=g.SPED_COD_CTA)
	when 4 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n4.SPED_COD_CTA=g.SPED_COD_CTA)
	when 5 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n5.SPED_COD_CTA=g.SPED_COD_CTA)
	when 6 then (select case when abs(SUM(s.CRDTAMNT))>abs(SUM(s.DEBITAMT)) then 'C' else 'D' end
	from GL10111 s
	left join GL00100 pc on s.ACTINDX = pc.actindx
	left join SPEDtbl004 n6 on n6.SPED_COD_CTA = pc.userdef1
	left join spedtbl004 n5 on n5.SPED_COD_CTA = n6.SPED_COD_CTA_SUP
	left join spedtbl004 n4 on n4.SPED_COD_CTA = n5.SPED_COD_CTA_SUP
	left join spedtbl004 n3 on n3.SPED_COD_CTA = n4.SPED_COD_CTA_SUP
	left join spedtbl004 n2 on n2.SPED_COD_CTA = n3.SPED_COD_CTA_SUP
	left join spedtbl004 n1 on n1.SPED_COD_CTA = n2.SPED_COD_CTA_SUP
	where s.YEAR1 =@vanio and n6.SPED_COD_CTA=g.SPED_COD_CTA)
	end as tipo
from SPEDtbl004 g
where G.SPED_COD_NAT IN (4)) order by g.SPED_COD_CTA
open Resultado_Cursor
fetch next from Resultado_Cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@CREDITO,@TIPO
while @@fetch_status =0
begin
	IF @CREDITO>0
	BEGIN
		set @contador=@contador+1
		insert into spedtbl9000 (linea,seccion,datos)
			select @contador+1,'L300',isnull('|L300|'+
				RTRIM(@sped_cod_cta)+'|'+
				RTRIM(@ACTDESCR)+'|'+
				case when @SPED_NIVEL<5 then 'S' else 'A' end+'|'+
				LTRIM(STR(@SPED_NIVEL))+'|'+
				rtrim(@sped_cod_nat)+'|'+
				(select rtrim(j.SPED_COD_CTA_SUP) from spedtbl004 j where j.SPED_COD_CTA=@sped_cod_cta )+'|'+
				isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
				@TIPO+'|','')
	END
	fetch next from Resultado_Cursor into @sped_cod_cta,@SPED_NIVEL,@SPED_COD_NAT,@ACTDESCR,@CREDITO,@TIPO
end
CLOSE Resultado_Cursor;  
DEALLOCATE Resultado_Cursor;
set @contador=@contador+1
INSERT INTO spedtbl9000 (LINEA,seccion, datos) 
	values (@contador+1,
	'L990',
	'|L990|'+
	isnull(ltrim(rtrim(cast(convert(int,(select count(*)+1 from spedtbl9000 where left(seccion,1)='L')) as nvarchar))),'0')+'|')

set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
values(@contador+1,
	'9001',
	'|9001|'+
	'0|')
set @contador=@contador+1
insert into spedtbl9000 (linea,seccion,datos)
select @contador+1,
	'9900',
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

----select * from spedtbl9000 order by linea

end

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
