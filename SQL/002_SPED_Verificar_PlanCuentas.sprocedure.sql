USE [GBRA]
GO
-- =============================================
--Propósito. Valida el plan de cuentas sped
--31/7/19 jcf Recreación sin cursores
--
-- =============================================
ALTER PROCEDURE [dbo].[SPED_Verificar_PlanCuentas] 
	@Year1 as int,
	@Comentario as varchar(250) out,
	@error as int out
AS
BEGIN
	declare @c int,@actnum as varchar(50)
	set @c=isnull((select count(*) from gl10110 o where o.YEAR1 =@year1),0)+isnull((select count(*) from gl10111 o where o.YEAR1 =@year1),0)
	if @c=0
	begin
		set @Comentario='Não há movimentos contabilísticos para este ano'
		set @error=1
	end
	else
	begin
		set @error=0
	end

	if @error=0
	begin
		--valida que todas las cuentas gp estén mapeadas a cuentas sped
		select @comentario =
		   replace(
			 replace(
			   replace(
					(
					select top 10 rtrim(a.ACTNUMBR_1) ACTNUMBR_1
					from (
						select p.ACTNUMBR_1 
						from GL10110 O
							inner join gl00100 p on p.ACTINDX = o.ACTINDX
							left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
						where o.YEAR1=@Year1 
						and j.SPED_COD_NAT is null
						union
						select p.ACTNUMBR_1 
						from GL10111 O
							inner join gl00100 p on p.ACTINDX = o.ACTINDX
							left join SPEDtbl004 j on j.SPED_COD_CTA=p.USERDEF1
						where o.YEAR1=@Year1 
						and j.SPED_COD_NAT is null
					) a
					for xml path('')
				),
				 '</ACTNUMBR_1><ACTNUMBR_1>',
				 ', ' -- delimiter
			   ),
			   '</ACTNUMBR_1>',
			   ''
			 ),
			 '<ACTNUMBR_1>',
			 ''
		  )
		IF isnull(@comentario, '') <> ''
		BEGIN
			SET @comentario = 'Conta código de referência não existe pra conta GP:' + char(13) +  @comentario
			set @error=1
		END
	end

	if @error=0
	begin
		--valida si hay cuentas sin código de agrupación
		select @comentario =
		   replace(
			 replace(
			   replace(
					(
					select top 10  rtrim(sped_cod_cta) sped_cod_cta
					from spedtbl004 
					where sped_codagl = ''
					for xml path('')
				),
				 '</sped_cod_cta><sped_cod_cta>',
				 ', ' -- delimiter
			   ),
			   '</sped_cod_cta>',
			   ''
			 ),
			 '<sped_cod_cta>',
			 ''
		  )
		IF isnull(@comentario, '') <> ''
		BEGIN
			SET @comentario = 'Conta SPED não tem um código de aglutinacao:' + char(13) +  @comentario
			set @error=1
		END
	end

	if @error=0
	begin
		--En GIBRA valida que el código de agrupación corresponda a la misma cuenta sped sin puntos
		select @comentario =
		   replace(
			 replace(
			   replace(
					(
					select top 10  rtrim(sped_cod_cta) sped_cod_cta
					from spedtbl004 
					where replace(sped_cod_cta, '.', '') != sped_codagl 
					for xml path('')
				),
				 '</sped_cod_cta><sped_cod_cta>',
				 ', ' -- delimiter
			   ),
			   '</sped_cod_cta>',
			   ''
			 ),
			 '<sped_cod_cta>',
			 ''
		  )
		IF isnull(@comentario, '') <> ''
		BEGIN
			SET @comentario = 'Conta SPED tem um código de aglutinacao inconsistente:' + char(13) +  @comentario
			set @error=1
		END
	end

	declare @longSegmento int = 2;
	declare @ultimoNivelCodResultado int = 6;
	declare @longCodResultado int = (@longSegmento+1) * @ultimoNivelCodResultado -2;
	declare @ultimoNivelCodPatrimonio int = 5;
	declare @longCodPatrimonio int = (@longSegmento+1) * @ultimoNivelCodPatrimonio -2;

	if @error=0
	begin
		--En GIBRA valida que el código de nivel superior sea dos dígitos menos
		select @comentario =
		   replace(
			 replace(
			   replace(
					(
					select top 10  rtrim(sped_cod_cta) sped_cod_cta
					from spedtbl004 
					where reverse(substring(reverse(rtrim(sped_cod_cta)), @longSegmento+2, 30)) != rtrim(sped_cod_cta_sup)
					and sped_nivel > 1
					for xml path('')
				),
				 '</sped_cod_cta><sped_cod_cta>',
				 ', ' -- delimiter
			   ),
			   '</sped_cod_cta>',
			   ''
			 ),
			 '<sped_cod_cta>',
			 ''
		  )
		IF isnull(@comentario, '') <> ''
		BEGIN
			SET @comentario = 'Conta SPED tem um código de nivel superior inconsistente:' + char(13) +  @comentario
			set @error=1
		END
	end

	if @error=0
	begin
		select @comentario =
		   replace(
			 replace(
			   replace(
					(
					select top 10 rtrim(sped_cod_cta) sped_cod_cta
					from spedtbl004 
					where sped_nivel > 1
						and (len(rtrim(sped_cod_cta))+2) / (@longSegmento+1) != sped_nivel
					for xml path('')
				),
				 '</sped_cod_cta><sped_cod_cta>',
				 ', ' -- delimiter
			   ),
			   '</sped_cod_cta>',
			   ''
			 ),
			 '<sped_cod_cta>',
			 ''
		  )
		IF isnull(@comentario, '') <> ''
		BEGIN
			SET @comentario = 'Conta SPED tem um nivel inconsistente:' + char(13) +  @comentario
			set @error=1
		END
	end

END
