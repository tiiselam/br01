use gbra;
go


IF (OBJECT_ID ('dbo.vwSpedPlanDeCuentasGP', 'V') IS NULL)
   exec('create view dbo.vwSpedPlanDeCuentasGP as SELECT 1 as t');
go

alter view dbo.vwSpedPlanDeCuentasGP 
--Propósito. Indica los segmentos que componen la cuenta contable GP
--Requisitos. 
--18/06/19 jcf Creación
as
	select actindx, rtrim(ACTNUMBR_1) cuentaGp, rtrim(ACTNUMBR_2) centroCostoGp, rtrim(USERDEF1) cuentaSped, rtrim(USERDEF2) cuentaRefSped,
			case when cgp.accatnum in (31, 32, 43, 45, 46) then 'R' else 'D' end tipoResultado, 
			--31 sales, 32 sales returns, 43 Other Income, 45 Revenues Not Producing Working Capital, 46 Gain/Loss on Asset Disposal
			rtrim(cgp.ACTDESCR) ACTDESCR,
			rtrim(cc.DSCRIPTN) centroCostoGpDesc, cc.DEX_ROW_TS 
	from gl00100 cgp 
	left join GL40200 cc
		on rtrim(cc.sgmntid) = rtrim(cgp.actnumbr_2)
		and cc.sgmtnumb = 2
go
IF (@@Error = 0) PRINT 'Creación exitosa de: vwSpedPlanDeCuentasGP'
ELSE PRINT 'Error en la creación de: vwSpedPlanDeCuentasGP'
GO
--------------------------------------------------------------------------------------------------------

