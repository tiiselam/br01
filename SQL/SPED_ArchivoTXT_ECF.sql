/****** Object:  StoredProcedure [dbo].[SPED_ArchivoTXT_ECF]    Script Date: 6/14/2017 7:44:16 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SPED_ArchivoTXT_ECF] 
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
	values(@contador+3,'0020',isnull('|0020|1||N|N|N|N|N|N|S|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|',''))---SECCION 0020
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