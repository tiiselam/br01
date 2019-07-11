use gbra;
go
IF OBJECT_ID ('dbo.fSpedAsientoDeCierre') IS NOT NULL
   DROP FUNCTION dbo.fSpedAsientoDeCierre
GO
create function dbo.fSpedAsientoDeCierre (@vanio smallint) 
returns table as
return(
		select p.cuentaSped, p.cuentaGp , p.centroCostoGp, 
			isnull(-res.Saldo_Acumulado, 0) Saldo_Acumulado,									--Signo invertido debido a que es asiento de cierre
			CASE WHEN isnull(res.Saldo_Acumulado, 0) >0 THEN 'D' ELSE 'C' END tipoSaldo_acumulado ----IND_DC
		from dbo.GL40000 cuentares
		left join dbo.vwSpedPlanDeCuentasGP  p 
			on p.actindx = cuentares.rerindx
		outer apply (select SUM(saldo.Saldo_Acumulado) Saldo_Acumulado
					from dbo.vwResumenDeCuentaAcumulado saldo
					where saldo.YEAR1 = @vanio
					and saldo.PERIODID = 12
					and saldo.PSTNGTYP = 1	--resultado
					) res
		
		union all

		select pc.cuentaSped, pc.cuentaGp, ----COD_CTA
			pc.centroCostoGp, 		---COD_CCUS
			sum(ac.saldo_acumulado) saldo_acumulado,
			CASE WHEN sum(ac.saldo_acumulado) >= 0 THEN 'C' ELSE 'D' END tipoSaldo_acumulado	--Signo invertido debido a que es asiento de cierre
		from dbo.vwResumenDeCuentaAcumulado ac
		left join dbo.vwSpedPlanDeCuentasGP pc 
			on pc.actindx=ac.ACTINDX
		where ac.YEAR1 = @vanio
		and ac.PERIODID = 12
		and ac.PSTNGTYP = 1	--resultado
		group by pc.cuentaSped, pc.cuentaGp, pc.centroCostoGp
	)
go
IF (@@Error = 0) PRINT 'Creación exitosa de: fSpedAsientoDeCierre()'
ELSE PRINT 'Error en la creación de: fSpedAsientoDeCierre()'
go

--------------------------------------------------------------------------------------------------------
