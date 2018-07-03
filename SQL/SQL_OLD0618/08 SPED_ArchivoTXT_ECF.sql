/****** Object:  StoredProcedure [dbo].[SPED_ArchivoTXT_ECF]    Script Date: 29/01/2017 11:21:56 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[SPED_ArchivoTXT_ECF] 
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
		'0002|'+ --- COD_VER
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
	values(@contador+2,'0010',isnull('|0010||N|N|1|A|01|RRRR|BBBBBBBBBBBB|||||N|N|',''))---SECCION 0010
insert into spedtbl9000 (linea,seccion, datos)	
	values(@contador+3,'0020',isnull('|0020|1||N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|S|N|N|N|N|N|N|N|N|N|N|N|',''))---SECCION 0020
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