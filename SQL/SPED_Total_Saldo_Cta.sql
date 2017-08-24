/****** Object:  StoredProcedure [dbo].[SPED_Total_Saldo_Cta]    Script Date: 6/14/2017 7:44:52 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SPED_Total_Saldo_Cta]
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
		set @credito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+isnull((
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+
		case when @periodid=12 and @Nat=4 then 
		(SELECT isnull(CASE WHEN SUM(DEBITAMT)>SUM(CRDTAMNT) THEN SUM(DEBITAMT)-SUM(CRDTAMNT) ELSE 0 END,0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and ACTINDX=@actindx) 
		else 0 end

		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx)+isnull((
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID=@periodid) and ACTINDX=@actindx),0)+
		case when @periodid=12 and @Nat=4 then 
		(SELECT isnull(CASE WHEN SUM(CRDTAMNT)>SUM(DEBITAMT) THEN SUM(CRDTAMNT)-SUM(DEBITAMT) ELSE 0 END,0)
		FROM gl10111
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and ACTINDX=@actindx) else 0 end
	end
	if @TipoTotal=2
	begin
		set @credito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
	end
	if @TipoTotal=3 
	begin
		set @credito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)

	end
	if @TipoTotal=4 
	begin
		set @Debito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
		set @Credito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (PERIODID<=@periodid and YEAR1=@year1 /*and PERIODID <>0*/)) and ACTINDX=@actindx)
	end
	if @nat=4 and @periodid=12 and @actindx<>@ctaUt
	begin
		/*if @TipoTotal=1 AND @actindx=@ctaUt
		begin 
			if @debito>@Credito 
			begin
				set @debito=@debito-@credito
				set @Credito=0
			end
			else
			begin
				set @credito=@credito-@debito
				set @Debito=0
			end
		end*/
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
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and  PERIODID<=@periodid) and j.SPED_COD_NAT=4),0)
		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 c
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
