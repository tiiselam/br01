
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[SPED_VerificarBalance] 
	@Year1 as int,
	@Comentario as varchar(250) out,
	@error as int out
AS
BEGIN

	if isnull(
			(select sum(o.perdblnc) 
			from GL10110 O
			where o.YEAR1=@Year1),0) +
		isnull(
			(select sum(o.perdblnc) 
			from GL10111 O
			where o.YEAR1=@Year1),0) = 0
	begin
		set @comentario='Balanço OK'
		set @error=0
	end
	else 
	begin
		set @Comentario='Error Balanço'
		set @error=1
	end
END

go
GRANT EXECUTE ON SPED_VerificarBalance TO DYNGRP;
go