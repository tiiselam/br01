IF not EXISTS (SELECT 1 FROM dbo.sysobjects WHERE id = OBJECT_ID(N'dbo.spedSaldoInicialPlanDeCuentasAntiguo') AND OBJECTPROPERTY(id,N'IsTable') = 1)
begin
	CREATE TABLE [dbo].[spedSaldoInicialPlanDeCuentasAntiguo](
		[Nat] varchar(50) not null,
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


--   insert into spedSaldoInicialPlanDeCuentasAntiguo (nat, [CuentaAnterior],	[CentroCostoAnterior] ,	[Descripcion] ,	[SaldoIni], CuentaActual, CentroCostoActual)
--   select nat, [CuentaAnterior],	[CentroCostoAnterior] ,	[Descripción] ,	[SaldoIni], CuentaActual, CentroCostoActual
--   from [dbo]._tmpSaldoInicialPlanDeCuentasAntiguo



