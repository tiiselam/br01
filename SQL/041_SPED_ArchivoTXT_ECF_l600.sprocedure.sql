IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = 'dbo'
     AND SPECIFIC_NAME = 'SPED_ArchivoTXT_ECF_l600' 
)
   DROP PROCEDURE dbo.SPED_ArchivoTXT_ECF_l600;
GO


-- =============================================
-- Propósito. Genera los datos del archivo SPED ECF en la tabla spedtbl9000 para el layout 6.00
-- Requisito. El mapeo de plan de cuentas debe estar en el campo gl00100.userdef1
--			Una cuenta local puede agrupar varias cuentas GP
--			La jerarquía de cuentas locales debe estar en SPEDtbl004. 
--24/03/20 jcf Creación
-- =============================================
CREATE PROCEDURE [dbo].[SPED_ArchivoTXT_ECF_l600] 
	@IdCompania varchar (8),
	@FechaDesde varchar(10),
	@FechaHasta varchar(10)
AS
BEGIN
	DECLARE @contador int
	set @contador=1
	SET NOCOUNT ON;

	--Limpia la tabla con la que se arma el archivo.
	DELETE SPEDtbl9000

	--------------------------------------------------------
	--BLOQUE 0. Se recuperan datos y se envian registros   -
	--------------------------------------------------------
	---REGISTRO 0000
	INSERT INTO SPEDtbl9000 (LINEA,seccion, datos) 
		SELECT	@contador
				,'0000'
				,isnull('|0000|'+						--- REG,
						'LECF|'+								--- NOME_ESC,
						'0006|'+								--- COD_VER
						rtrim(isnull(com.TAXREGTN,''))+'|'+		--- CNPJ
						rtrim(isnull(com.CMPNYNAM,''))+'|'+		--- NOME
						'0|'+									--- IND_SIT_INI_PE
						'0|'+									--- SIT_ESPECIAL
						'||'+									--- PAT_REMAN_CIS y DT_SIT_ESP
						rtrim(replace(convert(char,convert(datetime,@FechaDesde,102),103),'/',''))+'|'+	--- DT_INI C3,
						rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|'+	---DT_FIN C4,
						'N|'+									--- RECTIFICADORA
						'|' +									--- NUM_REC 
						'0|'+									--- TIP_ECF
						'|','')									--- COD_SCP
		FROM	dynamics.dbo.SY01500  com 
				left join SPEDtbl001 conf on com.INTERID =conf.INTERID
	
	-- REGISTRO 0001
	INSERT INTO SPEDtbl9000 (linea, seccion, datos)	
		SELECT	@contador+1
				,'0001'
				,isnull('|0001|0|','')

	-- REGISTRO 0010
	INSERT INTO SPEDtbl9000 (linea
							,seccion
							, datos)	
				values		(@contador+2
							,'0010'
							,isnull('|0010||N|N|1|A|01|RRRR|BBBBBBBBBBBB||||||',''))

	-- REGISTRO 0020
	INSERT INTO SPEDtbl9000 (linea
							,seccion
							, datos)	
				values		(@contador+3
							,'0020'
							,isnull('|0020|1||N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|N|S|N|N|N|N|N|N|N|N|N|N|N|N|N|',''))

	---REGISTRO 0030
	INSERT INTO SPEDtbl9000 (linea, seccion	, datos)
			SELECT	@contador+4
					,'0030'
					,ISNULL('|0030|2062|6391700|'+
							substring(RTRIM(COM.ADDRESS1),1,LEN(rtrim(com.address1))-6)+
							'|'+RIGHT(rtrim(com.address1),4)+'|'+
							rtrim(com.address2)+'|'+
							rtrim(com.address3)+'|SP|'+
							rtrim(com.county)+'|'+
							replace(rtrim(com.ZIPCODE),'-','')+'|'+
							rtrim(com.phone1)+'|'+
							(SELECT rtrim(INET1) FROM SY01200 WHERE Master_ID=conf.INTERID and ADRSCODE = 'PRIMARY')+'|','')
			FROM	DYNAMICS.DBO.SY01500 COM
					LEFT JOIN SPEDtbl001 CONF ON COM.INTERID=CONF.INTERID 

	--SECCION 0930
	set @contador=@contador+4
	INSERT INTO SPEDtbl9000 (LINEA, seccion, datos) 
			SELECT	@contador+1
					,'0930'
					,isnull('|0930|'+								--- REG,
							rtrim(ltrim(conf.SPED_IDENT_NOM))+'|'+	--- SIDENT_NOM
							rtrim(ltrim(conf.SPED_IDENT_CPF))+'|'+	--- CPF
							rtrim(ltrim(conf.SPED_COD_ASSIM))+'|'+	--- COD_ASSIM
							rtrim(ltrim(conf.SPED_IND_CRC))+'|'+	--- IND_CRC 
							rtrim(ltrim(conf.sped_email))+'|'+		--- EMAIL
							rtrim(ltrim(conf.SPED_FONE))+'|'		--- FONE
							,'')	
			FROM SPEDtbl002 conf
			WHERE conf.INTERID =@IdCompania

	-- SECCION 0990
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea
							,seccion
							,datos)	
				values		(@contador+1
							,'0990'
							,isnull('|0990|'+	--- AS REG,
									+ltrim(rtrim(cast(@contador+2 as varchar)))+'|',''))		--- AS QTD_LIN

	
	--------------------------------------------------------
	--BLOQUE J. Se recuperan datos y se envian registros   -
	--------------------------------------------------------
	---REGISTRO J001
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion, datos)	
				values		(@contador+1,'J001',isnull('|J001|0|',''))		

	DECLARE @docdate as DATETIME
	DECLARE @SPED_COD_NAT as varchar(2)
	DECLARE @sped_cod_cta as varchar(50)
	DECLARE @SPED_IND_CTA as varchar
	DECLARE @SPED_NIVEL as int
	DECLARE @SPED_COD_CTA_SUP as varchar(50)
	DECLARE @SPED_CTA as varchar(50)
	DECLARE @ACTDESCR as varchar(80)
	DECLARE PlanCuentas_Cursor cursor for
				(SELECT	DOCDATE,
						SPED_COD_NAT,
						SPED_COD_CTA,
						SPED_IND_CTA,
						SPED_NIVEL,
						SPED_COD_CTA_SUP,
						SPED_CTA,
						gc.ACTDESCR 
				FROM SPEDtbl004 gc 
				WHERE SPED_ES_SN=1	) 
				ORDER BY SPED_COD_CTA

	OPEN PlanCuentas_Cursor
	FETCH NEXT FROM PlanCuentas_Cursor into 
		@docdate,
		@SPED_COD_NAT,
		@sped_cod_cta,
		@SPED_IND_CTA,
		@SPED_NIVEL,
		@SPED_COD_CTA_SUP,
		@SPED_CTA,
		@ACTDESCR

	WHILE @@FETCH_STATUS = 0  
	BEGIN
		---REGISTRO J050
		set @contador=@contador+1

		--   print 'LLEGUE CTA ' + @sped_cod_cta

		if @SPED_IND_CTA='S' --MSAL Si es cuenta resumen se informa la cuenta SPED tal cual viene.
			INSERT INTO SPEDtbl9000 (linea
									,seccion
									,datos)	
					values			(@contador+1
									,'J050'
									,isnull('|J050|'+	--- AS REG,'',
											rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
											RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
											rtrim(ltrim(@SPED_IND_CTA))+'|'+	--- AS IND_CTA,
											LTRIM(STR(@SPED_NIVEL))+'|'+	--- AS NÍVEL,
											RTRIM(@sped_cod_cta)+'|'+	---  AS CÓD_CTA,
											RTRIM(@SPED_COD_CTA_SUP)+'|'+	--- AS CÓD_CTA_SUP,
											RTRIM(@ACTDESCR)+'|',''))

		IF @SPED_IND_CTA='A'
		BEGIN
							
			DECLARE @cuentaGP AS VARCHAR(50)
			DECLARE @cuentaSped AS VARCHAR(50)
			DECLARE @actdescrgp as varchar(60)
			DECLARE @cuentaRefSped as varchar(50)
			DECLARE @centroCostoGp as varchar(50)

			DECLARE Cuentas_gp cursor for(
						SELECT	cuentaGP
								,cuentaSped
								,cuentaRefSped
								--,max(cgp.ACTDESCR + '|' + centroCostoGp) as ACTDESCR  --MSAL REVISAR SI ESTA BIEN
						FROM dbo.vwSpedPlanDeCuentasGP cgp 
						WHERE cgp.cuentaSped = rtrim(@sped_cod_cta)
						GROUP BY cuentaGP, cuentaSped,cuentaRefSped)
						ORDER BY cuentaGP
		
			OPEN Cuentas_gp
			FETCH NEXT FROM cuentas_gp into @cuentaGP,@cuentaSped,@cuentaRefSped--, @actdescrgp

			WHILE @@FETCH_STATUS=0
			BEGIN
				---REGISTRO J050
				set @contador=@contador+1
				INSERT INTO SPEDtbl9000 (linea
										,seccion
										,datos)	
							values		(@contador+1
										,'J050'
										,isnull('|J050|'+	--- AS REG,'',
												rtrim(replace(convert(char,convert(datetime,@docdate,103),103),'/',''))+'|'+	--- AS DT_ALT,
												RTRIM(LTRIM(@SPED_COD_NAT))+'|'+	--- AS COD_NAT,
												rtrim(ltrim(@SPED_IND_CTA))+'|'+	--- AS IND_CTA,
												LTRIM(STR(@SPED_NIVEL))+'|'+	--- AS NÍVEL,
												RTRIM(@sped_cod_cta)+'.'+rtrim(@cuentaGP)+'|'+	---  AS CÓD_CTA,
												RTRIM(@SPED_COD_CTA_SUP)+'|'+	--- AS CÓD_CTA_SUP,
												RTRIM(@ACTDESCR)+'|',''))

		
				---REGISTRO J051
				set @contador=@contador+1
				INSERT INTO SPEDtbl9000 (linea
										,seccion
										, datos)	
							--VALUES		(@contador+1
							SELECT	     @contador+1
										,'J051'
										,isnull('|J051|'+	--- AS REG,
												--rtrim(LTRIM(@centroCostoGp))+'|'+	--- AS CÓD_CCUS,
												RTRIM(LTRIM(centroCostoGp) ) +'|'+
												rtrim(LTRIM(cuentaRefSped))+'|','')	--- CÓD_CTA_REF
							FROM dbo.vwSpedPlanDeCuentasGP cgp
						    WHERE cgp.cuentaSped = rtrim(@sped_cod_cta)
							  and cgp.cuentaGp = rtrim(@cuentaGP)
						
			
				FETCH NEXT FROM cuentas_gp INTO @cuentaGP,@cuentaSped,@cuentaRefSped--,@actdescrgp
			END
			CLOSE cuentas_gp
			DEALLOCATE cuentas_gp
		END

		FETCH NEXT FROM PlanCuentas_Cursor INTO --@docdate,@SPED_COD_NAT ,@sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL,@SPED_COD_CTA_SUP,@SPED_CTA,@ACTDESCR,@USERDEF1,@USERDEF2,@codigogp
				@docdate,
				@SPED_COD_NAT,
				@sped_cod_cta,
				@SPED_IND_CTA,
				@SPED_NIVEL,
				@SPED_COD_CTA_SUP,
				@SPED_CTA,
				@ACTDESCR

	END
	CLOSE PlanCuentas_Cursor
	DEALLOCATE PlanCuentas_Cursor;

	DECLARE @sgmtid varchar(10)
	DECLARE @dscriptn varchar(80)
	DECLARE @fecha datetime
	DECLARE cc_cursor cursor for (
				SELECT	centroCostoGp
						,max(centroCostoGpDesc) centroCostoGpDesc
						,max(DEX_ROW_TS) fecha
				FROM dbo.vwSpedPlanDeCuentasGP 
				GROUP BY centroCostoGp)

	OPEN cc_cursor
	FETCH NEXT FROM cc_cursor INTO @sgmtid,@dscriptn,@fecha
	WHILE @@FETCH_STATUS = 0  
	BEGIN 

		--REGISTRO J100
		set @contador=@contador+1
		INSERT INTO SPEDtbl9000 (linea
								,SECCION
								,datos)
					values		(@contador+1
								,'J100'
								,isnull('|J100|'+
										rtrim(replace(convert(char,convert(datetime,@FechaDesde,103),103),'/',''))+'|'+
										rtrim(ltrim(@sgmtid))+'|'+
										rtrim(ltrim(@DSCRIPTN))+'|',''))
		FETCH NEXT FROM cc_cursor into @sgmtid,@dscriptn,@fecha
	END
	CLOSE CC_CURSOR
	DEALLOCATE CC_CURSOR

	--REGISTRO J990
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea
							,seccion
							,datos)
				values		(@contador+1
							,'J990'
							,'|J990|'+
							isnull(ltrim(rtrim(cast(convert(int,(SELECT count(*)+1 FROM SPEDtbl9000 WHERE left(seccion,1)='J')) as nvarchar))),'0')+'|')

	--------------------------------------------------------
	--BLOQUE K. Se recuperan datos y se envian registros   -
	--------------------------------------------------------
	---REGISTRO K001
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea
							,seccion
							,datos)
				values		(@contador+1,
							'K001'
							,'|K001|0|')

	declare @fechainicio	as datetime
	declare @fechafin		as datetime
	declare @anio as int
	declare @periodo as int
	declare @vanio as int

	set @vanio = YEAR(@FechaDesde)

	-- Lo abro por periodo ya que no se si es el anio completo. Recibe fechas
	declare periodos_cursor cursor for (
				SELECT	year1
						,0 PERIODID
						,min(PERIODDT)
						,max(PERDENDT )
				FROM SY40100 
				WHERE PERIODID >0 
				AND (CONVERT(DATETIME,PERIODDT,102)>= CONVERT(DATETIME,@FechaDesde,102) 
				AND CONVERT(DATETIME,PERDENDT,102)<= CONVERT(DATETIME,@FechaHasta,102)) 
				GROUP BY YEAR1--,PERIODID
				--,PERIODDT,PERDENDT
				)
	OPEN periodos_cursor

	FETCH NEXT FROM periodos_cursor into @anio,@periodo,@fechainicio,@fechafin
	WHILE @@FETCH_STATUS = 0  
	BEGIN

		set @contador=@contador+1
		INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values			(@contador+1
								,'K030'
								,isnull('|K030|'+
										rtrim(replace(convert(char,@fechainicio,103),'/',''))+'|'+
										rtrim(replace(convert(char,@fechafin,103),'/',''))+'|'+
										'A'+RIGHT(RTRIM('00' + convert(char,@periodo)),2)+ '|'
										--'A'+convert(char,@periodo)+ '|'
										,''))

		set @contador=@contador+1;

		DECLARE @debito decimal(18,2)
		DECLARE @credito decimal(18,2)
		DECLARE @perdblnc decimal(18,2)
		DECLARE @saldo_acumulado decimal(18,2)
		
		DECLARE SaldosPorCuentaSped cursor for (
				SELECT	pc.cuentaSped+'.'+pc.cuentaGp
						,pc.cuentaRefSped
						,pc.centroCostoGp
						,SUM(case when res.periodid=0 then 0  else res.debitamt end + case when res.periodid=12 then isnull(acierre.debito, 0) else 0 end) debito
						,SUM(case when res.periodid=0 then 0  else res.crdtamnt end + case when res.periodid=12 then isnull(acierre.credito, 0) else 0 end) credito
						,SUM(case when res.periodid=0 then res.saldo_acumulado  else 0 end) saldo_inicial
						,SUM(case when res.periodid=12 then isnull(acierre.debito, 0) - isnull(acierre.credito, 0) + res.saldo_acumulado else 0 end) saldo_final
						--El CODIGO COMENTADO SIRVE SI LA APERTURA ES POR PERIORO.
						--,SUM(res.debitamt + case when @periodo=12 then isnull(acierre.debito, 0) else 0 end)
						--,SUM(res.crdtamnt + case when @periodo=12 then isnull(acierre.credito, 0) else 0 end)
						--,SUM(res.perdblnc + case when @periodo=12 then isnull(acierre.debito, 0) - isnull(acierre.credito, 0) else 0 end)
						--,SUM(res.saldo_acumulado + case when @periodo=12 then isnull(acierre.debito, 0) - isnull(acierre.credito, 0) else 0 end)
				FROM	dbo.vwSpedPlanDeCuentasGP pc
						inner join spedtbl004 SP on SP.SPED_COD_CTA = pc.cuentaSped
						inner join dbo.vwResumenDeCuentaAcumulado res	on pc.actindx = res.actindx
						outer apply (SELECT case when p.tipoSaldo_acumulado='D' then abs(p.Saldo_Acumulado) else 0 end debito,
											case when p.tipoSaldo_acumulado='C' then abs(p.Saldo_Acumulado) else 0 end credito,
											tipoSaldo_acumulado
									FROM dbo.fSpedAsientoDeCierre (res.year1) p
									WHERE p.cuentaSped = pc.cuentaSped
									and p.cuentaGp = pc.cuentaGp
									and p.centroCostoGp = pc.centroCostoGp
									) acierre
				WHERE res.year1 = @anio
				--and res.periodid = @periodo
				and SP.SPED_COD_NAT in('01','02','03')
				GROUP BY pc.cuentaSped, pc.cuentaGp, pc.cuentaRefSped, pc.centroCostoGp)
				ORDER BY cuentaSped

        --WITH SaldosPorCuentaSped (cuentaSped, centroCostoGp, debito, credito, perdblnc, saldo_acumulado) as (
		OPEN SaldosPorCuentaSped
		FETCH NEXT FROM SaldosPorCuentaSped into @sped_cod_cta,  @cuentaRefSped, @centroCostoGp,@debito, @credito, @perdblnc, @saldo_acumulado
	
		WHILE @@fetch_status =0
		BEGIN
			IF	isnull(@debito, 0) != 0   or	isnull(@credito, 0) != 0  or 
				isnull(@perdblnc, 0) != 0 or isnull(@saldo_acumulado, 0) != 0  
			BEGIN
				INSERT INTO spedtbl9000 (linea,seccion,datos)
					SELECT	@contador+1
							,'K155'
							,isnull('|K155|'+						----REG
								rtrim(ltrim(@sped_cod_cta))+'|'+			----COD_CTA
								rtrim(ltrim(@centroCostoGp))+'|'+		---COD_CCUS
								isnull(LTRIM(RTRIM(REPLACE(CAST(abs(cast(@perdblnc as decimal(18,2))) as nvarchar),'.',','))),'0,00')+'|'+	--VL_SLD_INI
								isnull(case when @perdblnc > 0 then 'D' else 'C' end, 'D')+'|'+	--IND_DC_INI
								-- EL CODIGO COMENTADO SIRVE SI SE ABRE POR PERIODO
								--isnull(LTRIM(RTRIM(REPLACE(CAST(abs(cast(saldo_acumulado - perdblnc as decimal(18,2))) as nvarchar),'.',','))),'0,00')+'|'+	----VL_SLD_INI		----VL_SLD_INI
								--isnull(case when saldo_acumulado - perdblnc > 0 then 'D' else 'C' end, 'D')+'|'+			----IND_DC_INI
								REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@debito,0)) AS nvarchar))),'.',',')+'|'+ --VL_DEB
								REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@credito,0)) AS nvarchar))),'.',',')+'|'+ --VL_CRED
								isnull(LTRIM(RTRIM(REPLACE(CAST(abs( cast(@saldo_acumulado as decimal(18,2)) ) as nvarchar),'.',','))),'0,00')+'|'+			----VL_SLD_FIN
								isnull(case when @saldo_acumulado>0 then 'D' else 'C' end, 'D')+'|'			----IND_DC_FIN
								,'')					
					--FROM SaldosPorCuentaSped
					--WHERE 
					--ORDER BY cuentaSped
				set @contador=@contador+1
				INSERT INTO SPEDtbl9000 (linea,seccion,datos)
					SELECT	@contador+1
							,'K156'
							,isnull('|K156|'+
									@cuentaRefSped+'|'+
									isnull(LTRIM(RTRIM(REPLACE(CAST(abs(cast(@perdblnc as decimal(18,2))) as nvarchar),'.',','))),'0,00')+'|'+	--VL_SLD_INI
									isnull(case when @perdblnc > 0 then 'D' else 'C' end, 'D')+'|'+	--IND_DC_INI
									--	EL CODIGO COMENTADO SIRVE SI SE ABRE POR PERIODO
									--isnull(LTRIM(RTRIM(REPLACE(CAST(abs(cast(saldo_acumulado - perdblnc as decimal(18,2))) as nvarchar),'.',','))),'0,00')+'|'+	----VL_SLD_INI		----VL_SLD_INI
									--isnull(case when saldo_acumulado - perdblnc > 0 then 'D' else 'C' end, 'D')+'|'+			----IND_DC_INI
							        REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@debito,0)) AS nvarchar))),'.',',')+'|'+			----VL_DEB
							        REPLACE(LTRIM(RTRIM(cast(convert(decimal(18,2),isnull(@credito,0)) AS nvarchar))),'.',',')+'|'+			----VL_CRED
							        isnull(LTRIM(RTRIM(REPLACE(CAST(abs( cast(@saldo_acumulado as decimal(18,2)) ) as nvarchar),'.',','))),'0,00')+'|'+			----VL_SLD_FIN
							        isnull(case when @saldo_acumulado>0 then 'D' else 'C' end, 'D')+'|'			----IND_DC_FIN
									,'')
			END
			FETCH NEXT FROM SaldosPorCuentaSped into @sped_cod_cta,  @cuentaRefSped, @centroCostoGp,@debito, @credito, @perdblnc, @saldo_acumulado
		END
		CLOSE SaldosPorCuentaSped;  
		DEALLOCATE SaldosPorCuentaSped;

		FETCH NEXT FROM periodos_cursor into @anio,@periodo,@fechainicio,@fechafin
	END
	CLOSE periodos_cursor;  
	DEALLOCATE periodos_cursor;

	
	--REGISTRO K355
	set @contador=@contador+1

	DECLARE GP_CursorK355 cursor for (	
			SELECT	 pc.cuentaSped
					,pc.cuentaGp
					,pc.centroCostoGp
					,sum(ac.saldo_acumulado) saldo_acumulado
			FROM	dbo.vwResumenDeCuentaAcumulado ac
					inner join dbo.vwSpedPlanDeCuentasGP pc on pc.actindx=ac.ACTINDX
			WHERE ac.YEAR1 = @vanio
			and ac.PERIODID = 12
			and ac.PSTNGTYP = 1	--resultado
			and ac.saldo_acumulado != 0
			GROUP BY pc.cuentaSped, pc.cuentaGp, pc.centroCostoGp)

	OPEN GP_CursorK355
	FETCH NEXT FROM GP_CursorK355 into @cuentaSped, @cuentaGp ,  @centroCostoGp, @saldo_acumulado
	
	WHILE @@fetch_status =0
	BEGIN
		
		INSERT INTO spedtbl9000 (linea,seccion,datos)
			SELECT	@contador+1
					,'K355'
					,isnull('|K355|'+
					@cuentaSped+'.'+@cuentaGp +'|'+
					@centroCostoGp +'|'+
					isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(sum(@saldo_acumulado))) as nvarchar),'.',','))),'0,00')+'|'+
					case when @saldo_acumulado < 0 then 'C' else 'D' end+'|','')
		

		INSERT INTO spedtbl9000 (linea,seccion,datos)
			SELECT	@contador+1
					,'K356'
					,isnull('|K356|'+
					pc.cuentaRefSped   +'|'+
					isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),abs(sum(ac.saldo_acumulado))) as nvarchar),'.',','))),'0,00')+'|'+
					case when sum(ac.Saldo_Acumulado) < 0 then 'C' else 'D' end+'|','')
			FROM	dbo.vwResumenDeCuentaAcumulado ac
					inner join dbo.vwSpedPlanDeCuentasGP pc on pc.actindx=ac.ACTINDX
			WHERE ac.YEAR1 = @vanio
			and ac.PERIODID = 12
			and ac.PSTNGTYP = 1	--resultado
			and ac.saldo_acumulado != 0
			and pc.cuentaSped = @cuentaSped
			and pc.cuentaGp = @cuentaGp 
			and pc.centroCostoGp = @centroCostoGp
			GROUP BY pc.cuentaRefSped 
			
		FETCH NEXT FROM GP_CursorK355 into @cuentaSped, @cuentaGp ,  @centroCostoGp, @saldo_acumulado
	END
	CLOSE GP_CursorK355;  
	DEALLOCATE GP_CursorK355;
			
	-- REGISTRO K990
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (LINEA,seccion, datos) 
				values (@contador+1
						,'K990'
						,'|K990|'+
						isnull(ltrim(rtrim(cast(convert(int,(SELECT count(*)+1 FROM SPEDtbl9000 WHERE left(seccion,1)='K')) as nvarchar))),'0')+'|')

	--------------------------------------------------------
	--BLOQUE L. Se recuperan datos y se envian registros   -
	--------------------------------------------------------
	---REGISTRO L001
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values		(@contador+1,
							'L001',
							'|L001|0|')

	--REGISTRO L30
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values		(@contador+1,
							'L030',
							'|L030|'+
							rtrim(replace(convert(char,convert(datetime,@fechadesde,102),103),'/',''))+'|'+	---DT_INI,
							rtrim(replace(convert(char,convert(datetime,@FechaHasta,102),103),'/',''))+'|A00|') 	---DT_FIN,

	DECLARE @TIPO VARCHAR
	DECLARE @tipoinicial VARCHAR
	DECLARE @tipofinal   VARCHAR
	DECLARE @inicial decimal(18,2) 
	DECLARE @final decimal(18,2)
	DECLARE @RMonto decimal(18,2)
	DECLARE @RMontoC decimal(18,2) 
	DECLARE @RMontoD decimal(18,2)
	

	DECLARE Balance_cursor cursor for
		(SELECT		
			--RTRIM(g.SPED_CODAGL),
			g.SPED_COD_CTA,
			g.SPED_IND_CTA,
			g.SPED_NIVEL,
			g.SPED_COD_NAT,
			g.SPED_COD_CTA_SUP,
			g.ACTDESCR,
			abs(gestionAnterior.Saldo_Acumulado) saldoInicial,
			case when gestionAnterior.Saldo_Acumulado > 0
					then 'D' else 'C' end tipoSaldoInicial,
			gestionanio.credito,
			gestionanio.debito,
			abs(gestionActual.saldo_acumulado) saldoFinal,
			case when gestionActual.saldo_acumulado > 0
					then 'D' else 'C' 	end tipoSaldoFinal
		FROM SPEDtbl004 g
		outer apply (select b.cuentaSped, sc.SPED_CODAGL
					 from GL40000 a 
						inner join dbo.vwSpedPlanDeCuentasGP b 	on a.RERINDX=b.ACTINDX
						inner join SPEDtbl004 sc 	on sc.SPED_COD_CTA = b.cuentaSped
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
										then resActual.resultado else 0 end saldo_acumulado
					from dbo.vwResumenDeCuentaAcumulado ac
						inner join dbo.vwSpedPlanDeCuentasGP pc 	on pc.actindx=ac.ACTINDX
						inner join SPEDtbl004 sc 	on sc.SPED_COD_CTA = pc.cuentaSped
					where ac.YEAR1 = @vanio
					and ac.PERIODID = 12
					and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
					) gestionActual
		outer apply (
					select sum(DEBITAMT) debito, 
							sum(CRDTAMNT)
								+ case when (utilidadr.SPED_CODAGL like ltrim(rtrim(g.SPED_CODAGL)) + '%')
						--and ac.HISTORYR = 0 --open
										then resActual.resultado else 0 end   credito
					from dbo.vwResumenDeCuentaAcumulado ac
						inner join dbo.vwSpedPlanDeCuentasGP pc 	on pc.actindx=ac.ACTINDX
						inner join SPEDtbl004 sc 	on sc.SPED_COD_CTA = pc.cuentaSped
					where ac.YEAR1 = @vanio
			--and ac.PERIODID = 12
					and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
					) gestionanio
		outer apply (
					select sum(ac.perdblnc) perdblnc, 
							sum(ac.saldo_acumulado) 
								+ case when (utilidadr.SPED_CODAGL like ltrim(rtrim(g.SPED_CODAGL)) + '%')
									then resAnterior.resultado	else 0 	end saldo_acumulado
					from dbo.vwResumenDeCuentaAcumulado ac
						inner join dbo.vwSpedPlanDeCuentasGP pc 	on pc.actindx=ac.ACTINDX
						inner join SPEDtbl004 sc 			on sc.SPED_COD_CTA = pc.cuentaSped
					where ac.YEAR1 = @vanio-1
					and ac.PERIODID = 12
					and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
					) gestionAnterior
		WHERE G.SPED_COD_NAT IN ('01','02','03')
		and abs(isnull(gestionActual.Saldo_Acumulado, 0)) + ABS(isnull(gestionAnterior.saldo_acumulado, 0)) != 0
		)

	OPEN Balance_cursor
	FETCH NEXT FROM Balance_cursor into @sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL, @SPED_COD_NAT, @SPED_COD_CTA_SUP, @ACTDESCR,@inicial,@tipoinicial,@credito,@debito,@final,@tipofinal
	
	WHILE @@fetch_status =0
	BEGIN
		IF @CREDITO<>0 or 1=1
		BEGIN
			set @contador=@contador+1
			INSERT INTO SPEDtbl9000 (linea,seccion,datos)
					SELECT	@contador+1
							,'L100'
							,isnull('|L100|'+
									RTRIM(@sped_cod_cta)+'|'+
									RTRIM(@ACTDESCR)+'|'+
									RTRIM(@SPED_IND_CTA) +'|'+
									LTRIM(STR(@SPED_NIVEL))+'|'+
									rtrim(@SPED_COD_NAT)+'|'+
									isnull(rtrim(@SPED_COD_CTA_SUP),'')+'|'+
									isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@inicial) as nvarchar),'.',','))),'0,00')+'|'+
									@tipoinicial+'|'+
									isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
									isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@debito) as nvarchar),'.',','))),'0,00')+'|'+
									isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(18,2),@final) as nvarchar),'.',','))),'0,00')+'|'+
									@tipofinal+'|','|')
		END
		FETCH NEXT FROM Balance_cursor into @sped_cod_cta,@SPED_IND_CTA,@SPED_NIVEL, @SPED_COD_NAT, @SPED_COD_CTA_SUP, @ACTDESCR,@inicial,@tipoinicial,@credito,@debito,@final,@tipofinal
	END
	CLOSE Balance_cursor;  
	DEALLOCATE Balance_cursor;

	declare @tipoResultado varchar(2);
	declare Resultado_Cursor cursor for
		(select --case when g.SPED_NIVEL=1 then 'TG.' else '' end+ltrim(rtrim(g.sped_codagl)),
			g.SPED_COD_CTA,
			g.SPED_IND_CTA,
			g.SPED_NIVEL,
			g.SPED_COD_NAT,
			g.SPED_COD_CTA_SUP,
			g.ACTDESCR,
			ABS(isnull(acumulados.saldo_acumulado, 0)) saldo,
			case when acumulados.saldo_acumulado > 0 then 'D' else 'C' end tipo
			--,			case when acumulados.saldo_acumulado > 0 then 'D' else 'R' end tipoResultado
		FROM SPEDtbl004 g
		outer apply (
			select	sum(ac.perdblnc) perdblnc, 
					sum(ac.saldo_acumulado) saldo_acumulado
			from dbo.vwResumenDeCuentaAcumulado ac
				inner join dbo.vwSpedPlanDeCuentasGP pc 	on pc.actindx=ac.ACTINDX
				left join SPEDtbl004 sc 	on sc.SPED_COD_CTA = pc.cuentaRefSped--pc.cuentaSped
			where ac.YEAR1 = @vanio
			and ac.PERIODID = 12
			and ltrim(rtrim(sc.sped_codagl)) like ltrim(rtrim(g.sped_codagl)) +'%'
			) acumulados
		where G.SPED_COD_NAT = '04'
		and acumulados.saldo_acumulado != 0
		) 
		order by g.sped_codagl

	OPEN Resultado_Cursor
	FETCH NEXT FROM Resultado_Cursor into @sped_cod_cta, @SPED_IND_CTA, @SPED_NIVEL  , @SPED_COD_NAT, @ACTDESCR, @SPED_COD_CTA_SUP, @CREDITO, @TIPO
	--FETCH NEXT FROM Resultado_Cursor into @sped_cod_cta               ,@SPED_NIVEL   ,@SPED_COD_NAT ,@ACTDESCR,@TIPO
	WHILE @@fetch_status =0
	BEGIN
		IF @CREDITO>0
		BEGIN
			BEGIN
				set @contador=@contador+1
				INSERT INTO SPEDtbl9000 (linea,seccion,datos)
							SELECT	@contador+1
									,'L300'
									,isnull('|L300|'+
											RTRIM(@sped_cod_cta)+'|'+
											RTRIM(@ACTDESCR)+'|'+
											RTRIM(LTRIM(@SPED_IND_CTA))+'|'+
											LTRIM(STR(@SPED_NIVEL))+'|'+
											rtrim(@SPED_COD_NAT)+'|'+
											RTRIM(LTRIM(@SPED_COD_CTA_SUP))+'|'+
											isnull(ltrim(rtrim(REPLACE(cast(convert(decimal(10,2),@credito) as nvarchar),'.',','))),'0,00')+'|'+
											@TIPO+'|','')
			END
		END
		FETCH NEXT FROM Resultado_Cursor into @sped_cod_cta, @SPED_IND_CTA, @SPED_NIVEL  , @SPED_COD_NAT, @ACTDESCR, @SPED_COD_CTA_SUP, @CREDITO, @TIPO
	END
	CLOSE Resultado_Cursor;  
	DEALLOCATE Resultado_Cursor;

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (LINEA,seccion, datos) 
				values	(@contador+1,
						'L990',
						'|L990|'+
						isnull(ltrim(rtrim(cast(convert(int,(SELECT count(*)+1 FROM SPEDtbl9000 WHERE left(seccion,1)='L')) as nvarchar))),'0')+'|')

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values	(@contador+1,
						'9001',
						'|9001|'+
						'0|')

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
		SELECT @contador+1,
				'9900',
				'|9900|'+
				ltrim(rtrim(seccion))+'|'+
				isnull(ltrim(rtrim(cast(convert(int,count(*)) as nvarchar))),'0')+'|'
		FROM SPEDtbl9000 GROUP BY seccion order by seccion

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values (@contador+1,
						'9900',
						'|9900|9900|'+
						isnull(ltrim(rtrim(cast(convert(int,(SELECT count(*) FROM SPEDtbl9000 WHERE left(seccion,1)='9')+2) as nvarchar))),'0')+'|')

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values (@contador+1,
						'9900',
						'|9900|9990|1|')

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values (@contador+1,
						'9900',
						'|9900|9999|1|')
	
	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values (@contador+1,
						'9990',
						'|9990|'+
						isnull(ltrim(rtrim(cast(convert(int,(SELECT count(*)+2 FROM SPEDtbl9000 WHERE left(seccion,1)='9')) as nvarchar))),'0')+'|')

	set @contador=@contador+1
	INSERT INTO SPEDtbl9000 (linea,seccion,datos)
				values (@contador+1,
						'9999',
						'|9999|'+
						isnull(ltrim(rtrim(cast(convert(int,(SELECT count(*)+1 FROM SPEDtbl9000)) as nvarchar))),'0')+'|')

END

GO

-----------------------------------------------------------------------
IF (@@Error = 0) PRINT 'Creación exitosa de: SPED_ArchivoTXT_ECF_l600'
ELSE PRINT 'Error en la creación de: SPED_ArchivoTXT_ECF_l600'
GO

