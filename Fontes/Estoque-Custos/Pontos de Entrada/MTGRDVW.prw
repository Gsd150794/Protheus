/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Lucas C.	     |01/09/2014| Chamado 7276. Incluído "Estoque Segurança/Mínimo" campo BZ_ESTSEG.
Lucas Borges  |11/09/2024| Chamado 48465. Removendo warning de compilação.
Lucas Borges  |16/09/2024| Chamado 48547. Corrgido o nome da variável.
===============================================================================================================================
*/

#Include "TOTVS.ch"

/*
===============================================================================================================================
Programa----------: MTGRDVW
Autor-------------: Talita Teixeira
Data da Criacao---: 13/03/2013
Descrição---------: Incluido na rotina de consulta  de estoque (F4) a informação referente a localização do produto de acordo
					com o campo BZ_I_LOCAL.
Parametros--------: Nenhum
Retorno-----------: .T. = Permite confirmar lancamento - .F. = Nao Permite confirmar lancamento
===============================================================================================================================
*/
User Function MTGRDVW()

Local oDlg := nil
Local _cLoc := ""
Local _nEstSeg := 0

DBSelectArea("SBZ")
SBZ->(DBSetOrder(1))
SBZ->(DBSeek(xFilial("SBZ")+SB1->B1_COD))
	
_cLoc:= SBZ->BZ_I_LOCAL
_nEstSeg := SBZ->BZ_ESTSEG

@ 225,007 Say "Localização" of oDlg PIXEL
@ 224,075 MsGet _cLoc Picture PesqPict("SBZ","BZ_I_LOCAL") of oDlg PIXEL SIZE 070,009 When .F.  

@ 240,007 Say "Est. Segurança/Mínimo" of oDlg PIXEL
@ 239,075 MsGet _nEstSeg Picture PesqPict("SBZ","BZ_ESTSEG") of oDlg PIXEL SIZE 070,009 When .F.  
																																					
SBZ->(DBCloseArea())

Return
