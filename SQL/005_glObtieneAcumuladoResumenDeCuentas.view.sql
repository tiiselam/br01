
IF OBJECT_ID ('dbo.fObtieneAcumulado') IS NOT NULL
   DROP FUNCTION dbo.fObtieneAcumulado
GO

create function dbo.fObtieneAcumulado(@actindx int, @anno smallint, @periodo smallint) returns numeric(19,6)
--Propósito. Obtiene acumulado de resumen de cuentas
--18/11/10 jcf Creación
as
begin
	return(
		select isnull(sum(PERDBLNC), 0)
		FROM GL10110 (nolock)	--GL_Account_SUM_MSTR
		where ACTINDX = @actindx	--18		
		and year1 = @anno
		and PERIODID <= @periodo	--6
	)
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fObtieneAcumulado()'
ELSE PRINT 'Error en la creación de: fObtieneAcumulado()'
GO
----------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fObtieneAcumuladoHist') IS NOT NULL
   DROP FUNCTION dbo.fObtieneAcumuladoHist
GO

create function dbo.fObtieneAcumuladoHist(@actindx int, @anno smallint, @periodo smallint) returns numeric(19,6)
--Propósito. Obtiene acumulado de resumen de cuentas histórico
--18/11/10 jcf Creación
as
begin
	return(
		select isnull(sum(PERDBLNC), 0)
		FROM GL10111 (nolock)	--GL_Account_SUM_HIST
		where ACTINDX = @actindx	--18		
		and year1 = @anno
		and PERIODID <= @periodo	--6
	)
end
go

IF (@@Error = 0) PRINT 'Creación exitosa de: fObtieneAcumuladoHist()'
ELSE PRINT 'Error en la creación de: fObtieneAcumuladoHist()'
GO
-----------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fPeriodosAbiertosAnteriores') IS NOT NULL
   DROP FUNCTION dbo.fPeriodosAbiertosAnteriores
GO
create function dbo.fPeriodosAbiertosAnteriores(@anno smallint) 
returns smallint as
begin
return
(
	select count(year1)
	from	SY40101 
	where HISTORYR = 0
	and year1 < @anno
)
end
go
IF (@@Error = 0) PRINT 'Creación exitosa de: fPeriodosAbiertosAnteriores()'
ELSE PRINT 'Error en la creación de: fPeriodosAbiertosAnteriores()'
GO
-----------------------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwPeriodosDeCompania]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.vwPeriodosDeCompania;
GO
create view dbo.vwPeriodosDeCompania as
select pr.YEAR1, pr.PERIODID, pr.PERNAME, hp.HISTORYR, 
	case when dbo.fPeriodosAbiertosAnteriores(pr.year1) > 0 then 'Verifique saldo acumulado. Año abierto ' + convert(varchar(5), pr.year1-1) + '. ' else '-' end Observacion
from SY40100 pr					--sy_period_setp
inner join SY40101 hp			--sy_period_hdr
	on hp.YEAR1 = pr.YEAR1
	and pr.FORIGIN = 1
	and pr.SERIES = 0
	and pr.ODESCTN = ''
go 
IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwPeriodosDeCompania'
ELSE PRINT 'Error en la creación de la vista: vwPeriodosDeCompania'
go
-----------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID ('dbo.fResumenDeCuenta') IS NOT NULL
   DROP FUNCTION dbo.fResumenDeCuenta
GO
create function dbo.fResumenDeCuenta (@actindx int, @anno smallint, @periodo smallint, @historico smallint) 
returns table as
return(
		select sm.DEBITAMT, sm.CRDTAMNT, sm.perdblnc
		from GL10110 sm (nolock) --GL_Account_SUM_MSTR
		where sm.ACTINDX = @actindx
		and sm.YEAR1 = @anno
		and sm.PERIODID = @periodo
		and @historico = 0
		UNION ALL
		select sm.DEBITAMT, sm.CRDTAMNT, sm.perdblnc
		from GL10111 sm (nolock) --GL_Account_SUM_HIST
		where sm.ACTINDX = @actindx
		and sm.YEAR1 = @anno
		and sm.PERIODID = @periodo
		and @historico = 1
		)
go
IF (@@Error = 0) PRINT 'Creación exitosa de: fResumenDeCuenta()'
ELSE PRINT 'Error en la creación de: fResumenDeCuenta()'
go
----------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'[vwResumenDeCuentaAcumulado]') AND OBJECTPROPERTY(id,N'IsView') = 1)
    DROP view dbo.vwResumenDeCuentaAcumulado;
GO
create view dbo.vwResumenDeCuentaAcumulado as
--Propósito. Obtiene resumen de todas las cuentas con saldos acumulados para cada periodo
--18/11/10 jcf Creación
--21/09/16 jcf Agrega active
--21/06/19 jcf Agrega HISTORYR
--01/07/19 jcf Corrige filtro
--
select rc.actindx, rc.year1, rc.periodid, rc.ACTNUMST, rc.ACTNUMBR_1, rc.ACTNUMBR_2, rc.ACTNUMBR_3, rc.ACCATNUM, rc.ACTDESCR,
		rc.USERDEF1, rc.USERDEF2, rc.USRDEFS1, rc.USRDEFS2, rc.ACCTTYPE, rc.PSTNGTYP, rc.active,
		rc.DEBITAMT, rc.CRDTAMNT, rc.perdblnc, rc.Saldo_Acumulado, rc.Observacion, rc.HISTORYR
from (
	select ma.actindx, pc.year1, pc.periodid, mt.ACTNUMST, ma.ACTNUMBR_1, ma.ACTNUMBR_2, ma.ACTNUMBR_3, ma.ACCATNUM, ma.ACTDESCR,
		ma.USERDEF1, ma.USERDEF2, ma.USRDEFS1, ma.USRDEFS2, ma.ACCTTYPE, ma.PSTNGTYP, ma.active,
		isnull(sm.DEBITAMT, 0) DEBITAMT, isnull(sm.CRDTAMNT, 0) CRDTAMNT, isnull(sm.perdblnc, 0) perdblnc, 
		case when pc.historyr = 0	then dbo.fObtieneAcumulado(ma.ACTINDX, pc.YEAR1, pc.PERIODID) 
									else dbo.fObtieneAcumuladoHist(ma.ACTINDX, pc.YEAR1, pc.PERIODID) 
		end Saldo_Acumulado,
		pc.Observacion, pc.HISTORYR
	from dbo.vwPeriodosDeCompania pc
	cross join GL00100 ma (nolock)  
	inner join GL00105 mt (nolock)
		on mt.ACTINDX = ma.ACTINDX
	outer apply (select * from dbo.fResumenDeCuenta (mt.ACTINDX, pc.year1, pc.periodid, pc.HISTORYR)) sm
	) rc
where abs(rc.DEBITAMT) + abs(rc.CRDTAMNT) + abs(rc.perdblnc) + abs(rc.Saldo_Acumulado) <> 0
go

IF (@@Error = 0) PRINT 'Creación exitosa de la vista: vwResumenDeCuentaAcumulado'
ELSE PRINT 'Error en la creación de la vista: vwResumenDeCuentaAcumulado'
go
-----------------------------------------------------------------------------------------------------------------------------
grant select on dbo.vwResumenDeCuentaAcumulado to dyngrp;

-----------------------------------------------------------------------------------------------------------------------------

--TEST

--select --DISTINCT actnumst	--
--year1, periodid, actnumst, actnumbr_3, actdescr, debitamt, crdtamnt, perdblnc, saldo_acumulado, pstngtyp, observacion
--from dbo.vwResumenDeCuentaAcumulado
--where year1 = 2015
--and periodid >= 0
--and actnumst like 'F%-000-605%'
--order by actnumbr_3

