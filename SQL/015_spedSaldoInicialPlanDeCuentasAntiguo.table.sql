IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.spedSaldoInicialPlanDeCuentasAntiguo') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE [dbo].[spedSaldoInicialPlanDeCuentasAntiguo](
		gestion int not null default 2019,
		mes int not null default 1,
		[Nat] varchar(1) not null,
		[CuentaAnterior] [varchar](50) not NULL,
		[CentroCostoAnterior] [varchar](50) not NULL,
		[Descripcion] [varchar](150) not NULL,
		[SaldoIni] [numeric](18, 2) NULL default 0,
		CuentaActual varchar(50) not null,
		CentroCostoActual varchar(50)
	) ON [PRIMARY]
end
GO

grant select, insert, update, delete on [dbo].[spedSaldoInicialPlanDeCuentasAntiguo] to dyngrp;
go


--drop table _tmpSaldoInicialPlanDeCuentasAntiguo

--Carga el mapeo del plan de cuentas antiguo con el nuevo. Se asume que el mes del saldo inicial es el 1.
--   insert into spedSaldoInicialPlanDeCuentasAntiguo (nat, [CuentaAnterior],	[CentroCostoAnterior] ,	[Descripcion] ,	[SaldoIni], CuentaActual, CentroCostoActual)
--   select nat, [CuentaAnterior],	[CentroCostoAnterior] ,	[Descripción] ,	[SaldoIni], CuentaActual, CentroCostoActual
--   from [dbo]._tmpSaldoInicialPlanDeCuentasAntiguo

-- select *
-- from spedSaldoInicialPlanDeCuentasAntiguo

--Validación
-- select *
-- from _tmpSaldoInicialPlanDeCuentasAntiguo mapeo
-- left join vwSpedPlanDeCuentasGP pc
-- 					on pc.cuentaSped+'.'+pc.cuentaGp = mapeo.CuentaActual
-- 				and pc.centroCostoGp = mapeo.CentroCostoActual
-- where pc.cuentaGp is null


-- select *
-- from GL00100
-- where rtrim(ACTNUMBR_1)+'-'+rtrim(ACTNUMBR_2) in ( '30563-6459', '30591-6459', '30561-6459', '30601-8513')
-- order by 2
