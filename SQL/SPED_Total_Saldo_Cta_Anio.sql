/****** Object:  StoredProcedure [dbo].[SPED_Total_Saldo_Cta_Anio]    Script Date: 6/14/2017 7:45:31 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SPED_Total_Saldo_Cta_Anio]
	@actindx as int,
	@USERDEF1 AS VARCHAR(30),
	@year1 as int,
	@per as int,
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
		FROM gl10110 where (PERIODID=0 and YEAR1=@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where (PERIODID=0 and YEAR1=@year1) and ACTINDX=@actindx)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (PERIODID<>0 and YEAR1=@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where (PERIODID=0 and YEAR1=@year1) and ACTINDX=@actindx)
	end
	if @TipoTotal=3 
	begin
		set @credito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10110 where (YEAR1<=@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 where (YEAR1<=@year1) and ACTINDX=@actindx)
		set @debito=(SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10110 where (YEAR1<=@year1) and ACTINDX=@actindx)+(
		SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 where (YEAR1<=@year1) and ACTINDX=@actindx)
	end
	if @TipoTotal=4
	begin
		if @actindx=0
		begin
			set @uctaUt = (select ACTINDX FROM GL00100 WHERE left(USERDEF1,13)=@USERDEF1 and ACTINDX=@ctaUt)
			set @Debito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110
			left join GL00100 p on p.ACTINDX=GL10110.ACTINDX
			where ((YEAR1=@year1 and PERIODID<=@per)) and p.USERDEF1 like @USERDEF1+'%')+(
			SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10111
			left join GL00100 p on p.ACTINDX=GL10111.ACTINDX
			where ((YEAR1=@year1 and PERIODID<=@per)) and p.USERDEF1 like @USERDEF1+'%')
			set @Credito=(SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 
			left join GL00100 p on p.ACTINDX=GL10110.ACTINDX
			where ((YEAR1=@year1 and PERIODID<=@per)) and p.USERDEF1 like @USERDEF1+'%')+(
			SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10111 
			left join GL00100 p on p.ACTINDX=GL10111.ACTINDX
			where ((YEAR1=@year1 and PERIODID<=@per)) and p.USERDEF1 like @USERDEF1+'%')
		end
		else
		begin
			set @Debito=(SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1  and PERIODID<=@per /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
			SELECT isnull(abs(sum(CRDTAMNT)),0)
			FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 and PERIODID<=@per /*and PERIODID <>0*/)) and ACTINDX=@actindx)
			set @Credito=(SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10110 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 and PERIODID<=@per /*and PERIODID <>0*/)) and ACTINDX=@actindx)+(
			SELECT isnull(abs(sum(DEBITAMT)),0)
			FROM gl10111 where (/*(PERIODID<>0 and YEAR1<@year1) or*/ (YEAR1=@year1 and PERIODID<=@per /*and PERIODID <>0*/)) and ACTINDX=@actindx)
		end
	end

	if @ctaUt=@actindx and (@TipoTotal<>2 AND @TipoTotal<>4)
	begin
		set @ResDebito=isnull((SELECT isnull(abs(sum(DEBITAMT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and PERIODID<=@per) and j.SPED_COD_NAT=4),0)
		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and PERIODID<=@per) and j.SPED_COD_NAT=4),0)
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
		WHERE PERIODID<>0 and (YEAR1=@year1 and PERIODID<=@per) and j.SPED_COD_NAT=4),0)
		set @ResCredito=isnull((SELECT isnull(abs(sum(CRDTAMNT)),0)
		FROM gl10111 c
		left join GL00100 p on p.ACTINDX = c.ACTINDX
		left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
		WHERE PERIODID<>0 and (YEAR1=@year1 and PERIODID<=@per) and j.SPED_COD_NAT=4),0)
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
