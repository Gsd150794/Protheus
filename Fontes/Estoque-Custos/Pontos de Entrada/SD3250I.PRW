/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: SD3250I
Autor-------------: André Carvalho
Data da Criacao---: 21/01/2016
Descrição---------: Atualizações das tabelas de apontamento de produção 
					Executado na função A250Atu(), rotina responsável pela atualização das tabelas de apontamentos de 
						produção simples.DESCRIÇÃO : Após atualização dos arquivos na rotina de produções. Executa após atualizar 
						SD3, SB2, SB3 e SC2.
Parametros--------: 
Retorno-----------: 
===============================================================================================================================
*/ 
User Function SD3250I()

Local _cOP		:= SD3->D3_OP
Local _aarea	:= FWGetArea()

While (!Eof() .And. ( xFilial("SD3") + _cOP == SD3->D3_FILIAL + SD3->D3_OP ))
	
	RecLock("SD3")

	SD3->D3_I_HRAP := Time()
	SD3->D3_I_DTAP := Date()

	MSUnLock()
	
	SD3->( DBSkip())
	
End		

FWRestArea(_aarea)

Return 
