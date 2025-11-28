/*
===============================================================================================================================
               ULTIMAS ATUALIZAÇÕES EFETUADAS - CONSULTAR LOG DO VERSIONADOR PARA HISTORICO COMPLETO
===============================================================================================================================
   Autor      |   Data   |                              Motivo                                                          
-------------------------------------------------------------------------------------------------------------------------------
Josué Prestes |28/12/2015| Chamado 12895. Inclusão de gravação de campo BZ_I_LOCAL
===============================================================================================================================
*/

#Include "TOTVS.ch"   

/*
===============================================================================================================================
Programa----------: MT340D3
Autor-------------: Xavier
Data da Criacao---: 10-04-2015                                                                                               
Descrição---------: Ponto de entrada da rotina MATA340 processamento do inventario
Parametros--------: Nenhum
Retorno-----------: Nenhum
===============================================================================================================================
*/
User Function MT340D3()

Local _aArea := FWGetArea()
Local _cEnder    := Posicione("SBZ",1,xFilial("SBZ")+SB7->B7_COD,"BZ_I_LOCAL")


//============================================================
//Grava log de acerto de inventário no B7
//============================================================
RecLock("SB7",.F.)
SB7->B7_I_ACERT := "1" //SIM
SB7->B7_I_DTACE := Date()
SB7->(MSUnLock())

//============================================================
//Se usuário/gatilho atualiza local, atualiza BZ 
//============================================================
If !Empty(SB7->B7_I_LOCAL) .And. AllTrim(_cEnder) <> AllTrim(SB7->B7_I_LOCAL)

	RecLock("SBZ",.F.)
	SBZ->BZ_I_LOCAL	:= SB7->B7_I_LOCAL
	SBZ->(MSUnLock())

EndIf

//============================================================
//gravar documento do inventario no SD3
//============================================================
SD3->D3_I_DOCIN := SB7->B7_DOC

FWRestArea(_aArea)

Return
